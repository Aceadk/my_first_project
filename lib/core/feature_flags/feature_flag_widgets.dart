import 'dart:async';
import 'package:flutter/material.dart';
import 'feature_flags.dart';

/// Widget that conditionally renders based on a feature flag.
class FeatureGate extends StatefulWidget {
  const FeatureGate({
    super.key,
    required this.flag,
    required this.child,
    this.fallback,
    this.onDisabled,
  });

  /// The feature flag to check.
  final FeatureFlag flag;

  /// Widget to show when feature is enabled.
  final Widget child;

  /// Widget to show when feature is disabled (optional).
  final Widget? fallback;

  /// Callback when feature is accessed but disabled.
  final VoidCallback? onDisabled;

  @override
  State<FeatureGate> createState() => _FeatureGateState();
}

class _FeatureGateState extends State<FeatureGate> {
  late bool _isEnabled;
  StreamSubscription<FeatureFlag>? _subscription;

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.flag.isEnabled;
    _subscription = FeatureFlagService.instance.onFlagChanged.listen((flag) {
      if (flag == widget.flag && mounted) {
        setState(() {
          _isEnabled = widget.flag.isEnabled;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isEnabled) {
      return widget.child;
    }
    return widget.fallback ?? const SizedBox.shrink();
  }
}

/// Widget that conditionally renders based on multiple feature flags.
class MultiFeatureGate extends StatefulWidget {
  const MultiFeatureGate({
    super.key,
    required this.flags,
    required this.child,
    this.fallback,
    this.requireAll = false,
  });

  /// The feature flags to check.
  final List<FeatureFlag> flags;

  /// Widget to show when conditions are met.
  final Widget child;

  /// Widget to show when conditions are not met.
  final Widget? fallback;

  /// If true, all flags must be enabled. If false, any flag being enabled is enough.
  final bool requireAll;

  @override
  State<MultiFeatureGate> createState() => _MultiFeatureGateState();
}

class _MultiFeatureGateState extends State<MultiFeatureGate> {
  late bool _shouldShow;
  StreamSubscription<FeatureFlag>? _subscription;

  @override
  void initState() {
    super.initState();
    _updateShouldShow();
    _subscription = FeatureFlagService.instance.onFlagChanged.listen((flag) {
      if (widget.flags.contains(flag) && mounted) {
        setState(_updateShouldShow);
      }
    });
  }

  void _updateShouldShow() {
    final service = FeatureFlagService.instance;
    _shouldShow = widget.requireAll
        ? service.areAllEnabled(widget.flags)
        : service.isAnyEnabled(widget.flags);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_shouldShow) {
      return widget.child;
    }
    return widget.fallback ?? const SizedBox.shrink();
  }
}

/// Widget that shows premium upsell when feature is disabled.
class PremiumFeatureGate extends StatelessWidget {
  const PremiumFeatureGate({
    super.key,
    required this.flag,
    required this.child,
    this.upsellTitle,
    this.upsellMessage,
    this.onUpgrade,
  });

  final FeatureFlag flag;
  final Widget child;
  final String? upsellTitle;
  final String? upsellMessage;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    return FeatureGate(
      flag: flag,
      fallback: _PremiumUpsellCard(
        title: upsellTitle ?? _defaultTitle,
        message: upsellMessage ?? _defaultMessage,
        onUpgrade: onUpgrade,
      ),
      child: child,
    );
  }

  String get _defaultTitle {
    switch (flag) {
      case FeatureFlag.unlimitedSwipes:
        return 'Unlimited Swipes';
      case FeatureFlag.seeWhoLikesYou:
        return 'See Who Likes You';
      case FeatureFlag.passport:
        return 'Passport';
      case FeatureFlag.superLikes:
        return 'Super Likes';
      case FeatureFlag.readReceipts:
        return 'Read Receipts';
      case FeatureFlag.unsendMessages:
        return 'Unsend Messages';
      default:
        return 'Premium Feature';
    }
  }

  String get _defaultMessage {
    return 'Upgrade to Plus to unlock this feature.';
  }
}

class _PremiumUpsellCard extends StatelessWidget {
  const _PremiumUpsellCard({
    required this.title,
    required this.message,
    this.onUpgrade,
  });

  final String title;
  final String message;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onUpgrade != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onUpgrade,
                child: const Text('Upgrade to Plus'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A/B test variant widget.
class ABTestVariant extends StatefulWidget {
  const ABTestVariant({
    super.key,
    required this.flag,
    required this.variantA,
    required this.variantB,
  });

  final FeatureFlag flag;
  final Widget variantA;
  final Widget variantB;

  @override
  State<ABTestVariant> createState() => _ABTestVariantState();
}

class _ABTestVariantState extends State<ABTestVariant> {
  late bool _showVariantB;
  StreamSubscription<FeatureFlag>? _subscription;

  @override
  void initState() {
    super.initState();
    _showVariantB = widget.flag.isEnabled;
    _subscription = FeatureFlagService.instance.onFlagChanged.listen((flag) {
      if (flag == widget.flag && mounted) {
        setState(() {
          _showVariantB = widget.flag.isEnabled;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _showVariantB ? widget.variantB : widget.variantA;
  }
}
