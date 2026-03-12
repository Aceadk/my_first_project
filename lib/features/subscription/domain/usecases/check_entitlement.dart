import 'package:crushhour/core/utils/constants.dart';
import 'package:crushhour/core/utils/error_messages.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/data/models/subscription.dart';
import 'package:crushhour/domain/use_cases/use_case.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SubscriptionEntitlementFeature {
  likes,
  likesYou,
  rewind,
  passport,
  editMessages,
  unsendMessages,
  readReceipts,
}

class CheckEntitlementParams extends Equatable {
  const CheckEntitlementParams({
    required this.feature,
    this.userId,
    this.forceRefresh = false,
  });

  final SubscriptionEntitlementFeature feature;
  final String? userId;
  final bool forceRefresh;

  @override
  List<Object?> get props => [feature, userId, forceRefresh];
}

class EntitlementDecision extends Equatable {
  const EntitlementDecision({
    required this.feature,
    required this.tier,
    required this.isAllowed,
    this.remainingFreeUses,
    this.blockedMessage,
    this.paywallSource,
  });

  final SubscriptionEntitlementFeature feature;
  final SubscriptionTier tier;
  final bool isAllowed;
  final int? remainingFreeUses;
  final String? blockedMessage;
  final String? paywallSource;

  bool get requiresPaywall => !isAllowed && paywallSource != null;

  @override
  List<Object?> get props => [
    feature,
    tier,
    isAllowed,
    remainingFreeUses,
    blockedMessage,
    paywallSource,
  ];
}

class CheckEntitlementUseCase
    extends UseCase<EntitlementDecision, CheckEntitlementParams> {
  CheckEntitlementUseCase(
    this._subscriptionRepository, {
    Duration cacheTtl = const Duration(minutes: 5),
    SharedPreferences? preferences,
    DateTime Function()? clock,
  }) : _cacheTtl = cacheTtl,
       _preferences = preferences,
       _clock = clock ?? DateTime.now;

  final SubscriptionRepository _subscriptionRepository;
  final Duration _cacheTtl;
  final DateTime Function() _clock;
  SharedPreferences? _preferences;

  SubscriptionTier? _cachedTier;
  DateTime? _cachedTierAt;

  @override
  Future<Result<EntitlementDecision>> call(CheckEntitlementParams params) async {
    if (params.feature == SubscriptionEntitlementFeature.likes &&
        (params.userId == null || params.userId!.trim().isEmpty)) {
      return const Result.failure(
        'User ID is required for like entitlement checks.',
      );
    }

    final tierResult = await _resolveTier(forceRefresh: params.forceRefresh);
    if (!tierResult.isSuccess || tierResult.data == null) {
      return Result.failure(
        tierResult.errorMessage ?? ErrorMessages.loadSubscriptionFailed,
      );
    }

    final tier = tierResult.data!;
    switch (params.feature) {
      case SubscriptionEntitlementFeature.likes:
        if (tier.hasPremium) {
          return Result.success(
            EntitlementDecision(
              feature: params.feature,
              tier: tier,
              isAllowed: true,
            ),
          );
        }

        final remaining = await remainingFreeLikes(params.userId!);
        if (remaining > 0) {
          return Result.success(
            EntitlementDecision(
              feature: params.feature,
              tier: tier,
              isAllowed: true,
              remainingFreeUses: remaining,
            ),
          );
        }

        return Result.success(
          EntitlementDecision(
            feature: params.feature,
            tier: tier,
            isAllowed: false,
            remainingFreeUses: 0,
            blockedMessage:
                'Daily swipe limit reached. Upgrade to Plus for unlimited likes.',
            paywallSource: 'likes_limit',
          ),
        );
      case SubscriptionEntitlementFeature.likesYou:
        return Result.success(_premiumDecision(params.feature, tier));
      case SubscriptionEntitlementFeature.rewind:
        return Result.success(
          _premiumDecision(
            params.feature,
            tier,
            blockedMessage: ErrorMessages.rewindPremiumOnly,
          ),
        );
      case SubscriptionEntitlementFeature.passport:
        return Result.success(
          _premiumDecision(
            params.feature,
            tier,
            blockedMessage:
                'Passport is a premium feature. Upgrade to explore globally.',
          ),
        );
      case SubscriptionEntitlementFeature.editMessages:
        return Result.success(
          _premiumDecision(
            params.feature,
            tier,
            blockedMessage: 'Upgrade to Plus to edit messages.',
          ),
        );
      case SubscriptionEntitlementFeature.unsendMessages:
        return Result.success(
          _premiumDecision(
            params.feature,
            tier,
            blockedMessage: 'Upgrade to Plus to unsend messages.',
          ),
        );
      case SubscriptionEntitlementFeature.readReceipts:
        return Result.success(
          _premiumDecision(
            params.feature,
            tier,
            blockedMessage: 'Upgrade to Plus to view read receipts.',
          ),
        );
    }
  }

  void primeCachedTier(SubscriptionTier tier) {
    _cachedTier = tier;
    _cachedTierAt = _clock();
  }

  void clearCache() {
    _cachedTier = null;
    _cachedTierAt = null;
  }

  Future<int> remainingFreeLikes(String userId) async {
    final prefs = await _prefs;
    final now = _clock();
    final today = _storageDay(now);
    final dateKey = _freeLikesDateKey(userId);
    final remainingKey = _freeLikesRemainingKey(userId);

    if (prefs.getString(dateKey) != today) {
      await prefs.setString(dateKey, today);
      await prefs.setInt(remainingKey, CrushConstants.freeDailySwipeLimit);
      return CrushConstants.freeDailySwipeLimit;
    }

    return prefs.getInt(remainingKey) ?? CrushConstants.freeDailySwipeLimit;
  }

  Future<void> recordSuccessfulLike(String userId) async {
    final remaining = await remainingFreeLikes(userId);
    if (remaining <= 0) {
      return;
    }

    final prefs = await _prefs;
    await prefs.setInt(_freeLikesRemainingKey(userId), remaining - 1);
  }

  Future<void> resetFreeLikes(String userId) async {
    final prefs = await _prefs;
    await prefs.setString(_freeLikesDateKey(userId), _storageDay(_clock()));
    await prefs.setInt(
      _freeLikesRemainingKey(userId),
      CrushConstants.freeDailySwipeLimit,
    );
  }

  EntitlementDecision _premiumDecision(
    SubscriptionEntitlementFeature feature,
    SubscriptionTier tier, {
    String? blockedMessage,
  }) {
    if (tier.hasPremium) {
      return EntitlementDecision(feature: feature, tier: tier, isAllowed: true);
    }

    return EntitlementDecision(
      feature: feature,
      tier: tier,
      isAllowed: false,
      blockedMessage: blockedMessage,
      paywallSource: _paywallSourceFor(feature),
    );
  }

  Future<Result<SubscriptionTier>> _resolveTier({
    bool forceRefresh = false,
  }) async {
    final now = _clock();
    if (!forceRefresh &&
        _cachedTier != null &&
        _cachedTierAt != null &&
        now.difference(_cachedTierAt!) <= _cacheTtl) {
      return Result.success(_cachedTier!);
    }

    final tierResult = await Result.guard(
      () => _subscriptionRepository.getCurrentPlan(),
      logLabel: 'CheckEntitlementUseCase.getCurrentPlan',
      fallbackError: ErrorMessages.loadSubscriptionFailed,
    );
    if (!tierResult.isSuccess || tierResult.data == null) {
      return Result.failure(
        tierResult.errorMessage ?? ErrorMessages.loadSubscriptionFailed,
      );
    }

    primeCachedTier(tierResult.data!);
    return Result.success(tierResult.data!);
  }

  String _paywallSourceFor(SubscriptionEntitlementFeature feature) {
    return switch (feature) {
      SubscriptionEntitlementFeature.likes => 'likes_limit',
      SubscriptionEntitlementFeature.likesYou => 'likes_you_tab',
      SubscriptionEntitlementFeature.rewind => 'rewind',
      SubscriptionEntitlementFeature.passport => 'passport',
      SubscriptionEntitlementFeature.editMessages => 'chat_edit',
      SubscriptionEntitlementFeature.unsendMessages => 'chat_unsend',
      SubscriptionEntitlementFeature.readReceipts => 'read_receipts',
    };
  }

  String _storageDay(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _freeLikesDateKey(String userId) => 'discovery_free_swipes_date_$userId';

  String _freeLikesRemainingKey(String userId) =>
      'discovery_free_swipes_remaining_$userId';

  Future<SharedPreferences> get _prefs async {
    final preferences = _preferences;
    if (preferences != null) {
      return preferences;
    }
    _preferences = await SharedPreferences.getInstance();
    return _preferences!;
  }
}
