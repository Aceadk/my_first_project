import 'package:flutter/material.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing.dart';
import 'package:crushhour/shared/utils/profile_field_options.dart';

/// A modal bottom sheet for picking height with cm/ft toggle.
class ProfileHeightPicker extends StatefulWidget {
  final int? initialHeightCm;
  final ValueChanged<int?> onSelected;

  const ProfileHeightPicker({
    super.key,
    this.initialHeightCm,
    required this.onSelected,
  });

  static Future<int?> show({
    required BuildContext context,
    int? initialHeightCm,
  }) async {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileHeightPicker(
        initialHeightCm: initialHeightCm,
        onSelected: (value) => Navigator.of(context).pop(value),
      ),
    );
  }

  @override
  State<ProfileHeightPicker> createState() => _ProfileHeightPickerState();
}

class _ProfileHeightPickerState extends State<ProfileHeightPicker> {
  bool _useCm = true;
  late int _heightCm;
  late FixedExtentScrollController _cmController;
  late FixedExtentScrollController _feetController;
  late FixedExtentScrollController _inchesController;

  static const int _minCm = 100;
  static const int _maxCm = 250;

  @override
  void initState() {
    super.initState();
    _heightCm = widget.initialHeightCm ?? 170;

    // Initialize cm controller
    _cmController = FixedExtentScrollController(
      initialItem: _heightCm - _minCm,
    );

    // Initialize feet/inches controllers
    final feetInches = ProfileFieldOptions.cmToFeetInchesValues(_heightCm);
    _feetController = FixedExtentScrollController(
      initialItem: feetInches.feet - 3,
    );
    _inchesController = FixedExtentScrollController(
      initialItem: feetInches.inches,
    );
  }

  @override
  void dispose() {
    _cmController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    super.dispose();
  }

  void _onCmChanged(int index) {
    setState(() {
      _heightCm = _minCm + index;
    });
  }

  void _onFeetInchesChanged() {
    final feet = _feetController.selectedItem + 3;
    final inches = _inchesController.selectedItem;
    setState(() {
      _heightCm = ProfileFieldOptions.feetInchesToCm(feet, inches);
    });
  }

  void _toggleUnit() {
    setState(() {
      _useCm = !_useCm;
      if (_useCm) {
        // Sync cm picker to current height
        final index = _heightCm - _minCm;
        if (index >= 0 && index <= _maxCm - _minCm) {
          _cmController.jumpToItem(index);
        }
      } else {
        // Sync feet/inches pickers to current height
        final feetInches = ProfileFieldOptions.cmToFeetInchesValues(_heightCm);
        _feetController.jumpToItem(feetInches.feet - 3);
        _inchesController.jumpToItem(feetInches.inches);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? DsColors.surfaceDark
        : DsColors.surfaceLight;
    final textPrimary = isDark
        ? DsColors.textPrimaryDark
        : DsColors.textPrimaryLight;
    final textMuted = isDark ? DsColors.textMutedDark : DsColors.textMutedLight;
    final dividerColor = isDark ? DsColors.dividerDark : DsColors.dividerLight;

    final displayHeight = _useCm
        ? '$_heightCm cm'
        : ProfileFieldOptions.cmToFeetInchesString(_heightCm);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsetsDirectional.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title and Done button
          Padding(
            padding: const EdgeInsets.all(DsSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Height',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ),
                if (widget.initialHeightCm != null)
                  TextButton(
                    onPressed: () => widget.onSelected(null),
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        color: textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: () => widget.onSelected(_heightCm),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: DsColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: dividerColor),
          // Unit toggle
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DsSpacing.lg,
              vertical: DsSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _UnitToggleButton(
                  label: 'cm',
                  isSelected: _useCm,
                  onTap: _useCm ? null : _toggleUnit,
                ),
                const SizedBox(width: DsSpacing.sm),
                _UnitToggleButton(
                  label: 'ft',
                  isSelected: !_useCm,
                  onTap: !_useCm ? null : _toggleUnit,
                ),
              ],
            ),
          ),
          // Current height display
          Padding(
            padding: const EdgeInsets.symmetric(vertical: DsSpacing.md),
            child: Text(
              displayHeight,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: DsColors.primary,
              ),
            ),
          ),
          // Picker
          SizedBox(
            height: 200,
            child: _useCm
                ? _buildCmPicker(textPrimary)
                : _buildFeetInchesPicker(textPrimary),
          ),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom + DsSpacing.lg,
          ),
        ],
      ),
    );
  }

  Widget _buildCmPicker(Color textColor) {
    return ListWheelScrollView.useDelegate(
      controller: _cmController,
      itemExtent: 50,
      perspective: 0.005,
      diameterRatio: 1.5,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: _onCmChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: _maxCm - _minCm + 1,
        builder: (context, index) {
          final cm = _minCm + index;
          final isSelected = cm == _heightCm;
          return Center(
            child: Text(
              '$cm',
              style: TextStyle(
                fontSize: isSelected ? 28 : 20,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? DsColors.primary
                    : textColor.withValues(alpha: 0.5),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeetInchesPicker(Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Feet picker
        SizedBox(
          width: 80,
          child: ListWheelScrollView.useDelegate(
            controller: _feetController,
            itemExtent: 50,
            perspective: 0.005,
            diameterRatio: 1.5,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (_) => _onFeetInchesChanged(),
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: 6, // 3-8 feet
              builder: (context, index) {
                final feet = index + 3;
                final isSelected = _feetController.selectedItem == index;
                return Center(
                  child: Text(
                    "$feet'",
                    style: TextStyle(
                      fontSize: isSelected ? 28 : 20,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? DsColors.primary
                          : textColor.withValues(alpha: 0.5),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: DsSpacing.lg),
        // Inches picker
        SizedBox(
          width: 80,
          child: ListWheelScrollView.useDelegate(
            controller: _inchesController,
            itemExtent: 50,
            perspective: 0.005,
            diameterRatio: 1.5,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (_) => _onFeetInchesChanged(),
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: 12, // 0-11 inches
              builder: (context, index) {
                final isSelected = _inchesController.selectedItem == index;
                return Center(
                  child: Text(
                    '$index"',
                    style: TextStyle(
                      fontSize: isSelected ? 28 : 20,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? DsColors.primary
                          : textColor.withValues(alpha: 0.5),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _UnitToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _UnitToggleButton({
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? DsColors.borderDark : DsColors.borderLight;
    final textMuted = isDark ? DsColors.textMutedDark : DsColors.textMutedLight;

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DsSpacing.xl,
            vertical: DsSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? DsColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? DsColors.primary : borderColor,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isSelected ? DsColors.surfaceLight : textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
