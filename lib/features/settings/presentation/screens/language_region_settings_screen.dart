import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/features/settings/presentation/bloc/locale_cubit.dart';
import 'package:crushhour/design_system/tokens/colors.dart';
import 'package:crushhour/design_system/tokens/spacing_widgets.dart';

class LanguageRegionSettingsScreen extends StatelessWidget {
  const LanguageRegionSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Language & Region'),
      ),
      body: BlocConsumer<LocaleCubit, LocaleState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage ||
            (previous.isDetecting && !current.isDetecting),
        listener: (context, localeState) {
          if (localeState.errorMessage != null &&
              localeState.errorMessage!.isNotEmpty) {
            showErrorSnackBar(context, localeState.errorMessage!);
          } else if (!localeState.isDetecting &&
              localeState.errorMessage == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Region updated from device location.'),
              ),
            );
          }
        },
        builder: (context, localeState) {
          final localeCubit = context.read<LocaleCubit>();
          return ListView(
            children: [
              // Header
              Container(
                padding: DsEdgeInsets.allLg,
                margin: DsEdgeInsets.allLg,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DsColors.secondary.withValues(alpha: 0.1),
                      DsColors.primary.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: DsEdgeInsets.allMd,
                      decoration: BoxDecoration(
                        color: DsColors.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.language,
                        color: DsColors.secondary,
                        size: 28,
                      ),
                    ),
                    DsGap.lgH,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Localization',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          DsGap.xs,
                          Text(
                            'Set your preferred language and region.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Language
              ListTile(
                leading: const Icon(Icons.translate),
                title: const Text('Language'),
                subtitle: Text(_languageLabel(localeState.languageCode)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguageSheet(context, localeState.languageCode),
              ),
              const Divider(indent: 72),
              // Region
              ListTile(
                leading: const Icon(Icons.public),
                title: const Text('Region'),
                subtitle: Text(localeState.region),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showRegionDialog(context, localeState.region, localeCubit),
              ),
              const Divider(indent: 72),
              // Auto-detect
              ListTile(
                leading: const Icon(Icons.my_location),
                title: const Text('Use device location'),
                subtitle: const Text('Detect your region automatically'),
                trailing: localeState.isDetecting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: localeState.isDetecting
                    ? null
                    : () => localeCubit.detectFromLocation(),
              ),
              DsGap.xxl,
              // Info card
              Padding(
                padding: DsEdgeInsets.horizontalLg,
                child: Container(
                  padding: DsEdgeInsets.allMd,
                  decoration: BoxDecoration(
                    color: isDark ? DsColors.surfaceDark : DsColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? DsColors.borderDark : DsColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                      ),
                      DsGap.mdH,
                      Expanded(
                        child: Text(
                          'Your region helps us show you relevant matches nearby.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? DsColors.textMutedDark : DsColors.textMutedLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _languageLabel(String code) {
    switch (code) {
      case 'es':
        return 'Spanish';
      case 'fr':
        return 'French';
      case 'de':
        return 'German';
      case 'en':
      default:
        return 'English';
    }
  }

  void _showLanguageSheet(BuildContext context, String current) {
    const options = [
      {'code': 'en', 'label': 'English', 'native': 'English'},
      {'code': 'es', 'label': 'Spanish', 'native': 'Espanol'},
      {'code': 'fr', 'label': 'French', 'native': 'Francais'},
      {'code': 'de', 'label': 'German', 'native': 'Deutsch'},
    ];

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final cubit = sheetContext.read<LocaleCubit>();
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: DsEdgeInsets.allLg,
                child: Row(
                  children: [
                    const Icon(Icons.translate, color: DsColors.primary),
                    DsGap.mdH,
                    Text(
                      'Choose language',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...options.map(
                (option) {
                  final isSelected = option['code'] == current;
                  return ListTile(
                    leading: Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: isSelected ? DsColors.primary : null,
                    ),
                    title: Text(
                      option['label']!,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : null,
                        color: isSelected ? DsColors.primary : null,
                      ),
                    ),
                    subtitle: Text(option['native']!),
                    onTap: () {
                      cubit.setLanguage(option['code']!);
                      Navigator.of(sheetContext).pop();
                    },
                  );
                },
              ),
              DsGap.md,
            ],
          ),
        );
      },
    );
  }

  void _showRegionDialog(
    BuildContext context,
    String currentRegion,
    LocaleCubit cubit,
  ) {
    final controller = TextEditingController(text: currentRegion);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Set region'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'City, State/Province, Country',
              prefixIcon: Icon(Icons.location_city),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  cubit.setRegion(value);
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
