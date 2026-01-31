/// Represents a promotional code that can be redeemed for benefits.
class PromoCode {
  const PromoCode({
    required this.code,
    required this.type,
    this.description,
    this.discountPercent,
    this.freeTrialDays,
    this.bonusLikes,
    this.bonusSuperLikes,
    this.expiresAt,
    this.maxRedemptions,
    this.currentRedemptions = 0,
  });

  /// The promo code string (e.g., "WELCOME50", "FREEWEEK").
  final String code;

  /// Type of promotion.
  final PromoCodeType type;

  /// Human-readable description of the offer.
  final String? description;

  /// Discount percentage (0-100) for subscription.
  final int? discountPercent;

  /// Number of free trial days granted.
  final int? freeTrialDays;

  /// Bonus daily likes added.
  final int? bonusLikes;

  /// Bonus super likes added.
  final int? bonusSuperLikes;

  /// When this code expires (null = never).
  final DateTime? expiresAt;

  /// Maximum number of times this code can be redeemed (null = unlimited).
  final int? maxRedemptions;

  /// Current number of redemptions.
  final int currentRedemptions;

  /// Whether the code is still valid.
  bool get isValid {
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) {
      return false;
    }
    if (maxRedemptions != null && currentRedemptions >= maxRedemptions!) {
      return false;
    }
    return true;
  }

  /// Whether the code has expired.
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Whether the code has reached max redemptions.
  bool get isMaxedOut =>
      maxRedemptions != null && currentRedemptions >= maxRedemptions!;

  factory PromoCode.fromJson(Map<String, dynamic> json) {
    return PromoCode(
      code: json['code'] as String,
      type: PromoCodeType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => PromoCodeType.discount,
      ),
      description: json['description'] as String?,
      discountPercent: json['discountPercent'] as int?,
      freeTrialDays: json['freeTrialDays'] as int?,
      bonusLikes: json['bonusLikes'] as int?,
      bonusSuperLikes: json['bonusSuperLikes'] as int?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      maxRedemptions: json['maxRedemptions'] as int?,
      currentRedemptions: json['currentRedemptions'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'type': type.name,
      if (description != null) 'description': description,
      if (discountPercent != null) 'discountPercent': discountPercent,
      if (freeTrialDays != null) 'freeTrialDays': freeTrialDays,
      if (bonusLikes != null) 'bonusLikes': bonusLikes,
      if (bonusSuperLikes != null) 'bonusSuperLikes': bonusSuperLikes,
      if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
      if (maxRedemptions != null) 'maxRedemptions': maxRedemptions,
      'currentRedemptions': currentRedemptions,
    };
  }
}

/// Types of promotional codes.
enum PromoCodeType {
  /// Discount on subscription price.
  discount,

  /// Free trial period.
  freeTrial,

  /// Bonus likes added to daily limit.
  bonusLikes,

  /// Bonus super likes.
  bonusSuperLikes,

  /// Combined offer (multiple benefits).
  combined,
}

extension PromoCodeTypeX on PromoCodeType {
  String get displayName {
    switch (this) {
      case PromoCodeType.discount:
        return 'Discount';
      case PromoCodeType.freeTrial:
        return 'Free Trial';
      case PromoCodeType.bonusLikes:
        return 'Bonus Likes';
      case PromoCodeType.bonusSuperLikes:
        return 'Bonus Super Likes';
      case PromoCodeType.combined:
        return 'Special Offer';
    }
  }

  String get icon {
    switch (this) {
      case PromoCodeType.discount:
        return '%';
      case PromoCodeType.freeTrial:
        return '🎁';
      case PromoCodeType.bonusLikes:
        return '❤️';
      case PromoCodeType.bonusSuperLikes:
        return '⭐';
      case PromoCodeType.combined:
        return '🎉';
    }
  }
}

/// Result of redeeming a promo code.
class PromoCodeRedemptionResult {
  const PromoCodeRedemptionResult({
    required this.success,
    this.promoCode,
    this.errorMessage,
    this.appliedBenefits,
  });

  final bool success;
  final PromoCode? promoCode;
  final String? errorMessage;
  final List<String>? appliedBenefits;

  factory PromoCodeRedemptionResult.success({
    required PromoCode promoCode,
    required List<String> appliedBenefits,
  }) {
    return PromoCodeRedemptionResult(
      success: true,
      promoCode: promoCode,
      appliedBenefits: appliedBenefits,
    );
  }

  factory PromoCodeRedemptionResult.failure(String message) {
    return PromoCodeRedemptionResult(
      success: false,
      errorMessage: message,
    );
  }
}
