import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/data/models/promo_code.dart';
import 'package:crushhour/design_system/design_system.dart';
import 'package:crushhour/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:crushhour/features/subscription/presentation/bloc/subscription_bloc.dart';

/// Bottom sheet for entering and redeeming promo codes.
class PromoCodeSheet extends StatefulWidget {
  const PromoCodeSheet({super.key, required this.repository});

  final SubscriptionRepository repository;

  /// Shows the promo code sheet as a modal bottom sheet.
  static Future<PromoCodeRedemptionResult?> show(BuildContext context) {
    final repository = context.read<SubscriptionBloc>().subscriptionRepository;
    return showModalBottomSheet<PromoCodeRedemptionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PromoCodeSheet(repository: repository),
    );
  }

  @override
  State<PromoCodeSheet> createState() => _PromoCodeSheetState();
}

class _PromoCodeSheetState extends State<PromoCodeSheet> {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();

  bool _isLoading = false;
  bool _isValidating = false;
  PromoCode? _validatedCode;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Auto-focus the text field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsetsDirectional.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? DsColors.surfaceDark : DsColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? DsColors.ink600 : DsColors.ink200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            DsGap.lg,

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DsColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.card_giftcard_rounded,
                    color: DsColors.primary,
                    size: 24,
                  ),
                ),
                DsGap.mdH,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Redeem Promo Code',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Enter your code to unlock special offers',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? DsColors.textMutedDark
                              : DsColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            DsGap.xl,

            // Code input
            Stack(
              alignment: Alignment.centerRight,
              children: [
                GlassTextField(
                  controller: _codeController,
                  focusNode: _focusNode,
                  label: 'Promo Code',
                  hintText: 'Enter code (e.g., WELCOME50)',
                  prefixIcon: Icons.confirmation_number_outlined,
                  enabled: !_isLoading,
                  errorText: _errorMessage,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                    UpperCaseTextFormatter(),
                  ],
                  onChanged: (_) {
                    if (_errorMessage != null || _validatedCode != null) {
                      setState(() {
                        _errorMessage = null;
                        _validatedCode = null;
                      });
                    }
                  },
                  onSubmitted: (_) => _validateCode(),
                ),
                if (_isValidating)
                  const PositionedDirectional(
                    end: 16,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (_validatedCode != null)
                  const PositionedDirectional(
                    end: 16,
                    child: Icon(Icons.check_circle, color: DsColors.success),
                  ),
              ],
            ),

            // Validated code preview
            if (_validatedCode != null) ...[
              DsGap.lg,
              _PromoCodePreview(promoCode: _validatedCode!),
            ],

            DsGap.xl,

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: GlassOutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                DsGap.mdH,
                Expanded(
                  flex: 2,
                  child: GlassPrimaryButton(
                    onPressed: _isLoading || _codeController.text.isEmpty
                        ? null
                        : _redeemCode,
                    isLoading: _isLoading,
                    child: Text(_validatedCode != null ? 'Redeem' : 'Apply'),
                  ),
                ),
              ],
            ),
            DsGap.lg,

            // Demo codes hint (for development)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? DsColors.info.withValues(alpha: 0.1)
                    : DsColors.info.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DsColors.info.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: DsColors.info,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Try: WELCOME50, FREEWEEK, CRUSH2024, SUPERLOVE',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? DsColors.textMutedDark
                            : DsColors.textMutedLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            DsGap.md,
          ],
        ),
      ),
    );
  }

  Future<void> _validateCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final repository = widget.repository;
      final promoCode = await repository.validatePromoCode(code);

      if (!mounted) return;

      setState(() {
        _isValidating = false;
        _validatedCode = promoCode;
        if (promoCode == null) {
          _errorMessage = 'Invalid or expired promo code';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isValidating = false;
        _errorMessage = 'Failed to validate code. Please try again.';
      });
    }
  }

  Future<void> _redeemCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = widget.repository;
      final result = await repository.redeemPromoCode(code);

      if (!mounted) return;

      if (result.success) {
        Navigator.pop(context, result);
        showSuccessSnackBar(
          context,
          'Promo code redeemed! ${result.appliedBenefits?.join(", ") ?? ""}',
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result.errorMessage ?? 'Failed to redeem code';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to redeem code. Please try again.';
      });
    }
  }
}

/// Displays a preview of the validated promo code benefits.
class _PromoCodePreview extends StatelessWidget {
  const _PromoCodePreview({required this.promoCode});

  final PromoCode promoCode;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DsColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DsColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: DsColors.success, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Valid Code',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: DsColors.success,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DsColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  promoCode.type.displayName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: DsColors.primary,
                  ),
                ),
              ),
            ],
          ),
          if (promoCode.description != null) ...[
            const SizedBox(height: 8),
            Text(
              promoCode.description!,
              style: TextStyle(
                color: isDark
                    ? DsColors.textPrimaryDark
                    : DsColors.textPrimaryLight,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (promoCode.discountPercent != null)
                _BenefitChip(
                  icon: Icons.percent,
                  label: '${promoCode.discountPercent}% off',
                ),
              if (promoCode.freeTrialDays != null)
                _BenefitChip(
                  icon: Icons.card_giftcard,
                  label: '${promoCode.freeTrialDays} day trial',
                ),
              if (promoCode.bonusLikes != null)
                _BenefitChip(
                  icon: Icons.favorite,
                  label: '+${promoCode.bonusLikes} likes',
                ),
              if (promoCode.bonusSuperLikes != null)
                _BenefitChip(
                  icon: Icons.star,
                  label: '+${promoCode.bonusSuperLikes} super likes',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BenefitChip extends StatelessWidget {
  const _BenefitChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? DsColors.surfaceElevatedDark : DsColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: DsColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// Text input formatter that converts text to uppercase.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
