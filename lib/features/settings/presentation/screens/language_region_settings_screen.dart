import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/core/ui/snackbar_utils.dart';
import 'package:crushhour/core/extensions/localization_extension.dart';
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
        title: Text(context.l10n.settingsLanguageRegion),
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
                title: Text(context.l10n.settingsLanguage),
                subtitle: Text(_languageLabel(localeState.languageCode)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguageSheet(context, localeState.languageCode),
              ),
              const Divider(indent: 72),
              // Region
              ListTile(
                leading: const Icon(Icons.public),
                title: Text(context.l10n.settingsRegion),
                subtitle: Text(localeState.region),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showRegionDialog(context, localeState.region, localeCubit),
              ),
              const Divider(indent: 72),
              // Auto-detect
              ListTile(
                leading: const Icon(Icons.my_location),
                title: Text(context.l10n.settingsDetectRegion),
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
      case 'zh':
        return 'Mandarin Chinese';
      case 'hi':
        return 'Hindi';
      case 'ne':
        return 'Nepali';
      case 'ar':
        return 'Arabic';
      case 'ja':
        return 'Japanese';
      case 'ko':
        return 'Korean';
      case 'bn':
        return 'Bengali';
      case 'pt':
        return 'Portuguese';
      case 'ru':
        return 'Russian';
      case 'ur':
        return 'Urdu';
      case 'tr':
        return 'Turkish';
      case 'id':
        return 'Indonesian';
      case 'yo':
        return 'Yoruba';
      case 'te':
        return 'Telugu';
      case 'ta':
        return 'Tamil';
      case 'vi':
        return 'Vietnamese';
      case 'yue':
        return 'Cantonese';
      case 'en':
      default:
        return 'English';
    }
  }

  void _showLanguageSheet(BuildContext context, String current) {
    const options = [
      {'code': 'en', 'label': 'English', 'native': 'English'},
      {'code': 'es', 'label': 'Spanish', 'native': 'Español'},
      {'code': 'fr', 'label': 'French', 'native': 'Français'},
      {'code': 'de', 'label': 'German', 'native': 'Deutsch'},
      {'code': 'zh', 'label': 'Mandarin Chinese', 'native': '中文 (简体)'},
      {'code': 'hi', 'label': 'Hindi', 'native': 'हिन्दी'},
      {'code': 'ne', 'label': 'Nepali', 'native': 'नेपाली'},
      {'code': 'ar', 'label': 'Arabic', 'native': 'العربية'},
      {'code': 'ja', 'label': 'Japanese', 'native': '日本語'},
      {'code': 'ko', 'label': 'Korean', 'native': '한국어'},
      {'code': 'bn', 'label': 'Bengali', 'native': 'বাংলা'},
      {'code': 'pt', 'label': 'Portuguese', 'native': 'Português'},
      {'code': 'ru', 'label': 'Russian', 'native': 'Русский'},
      {'code': 'ur', 'label': 'Urdu', 'native': 'اردو'},
      {'code': 'tr', 'label': 'Turkish', 'native': 'Türkçe'},
      {'code': 'id', 'label': 'Indonesian', 'native': 'Bahasa Indonesia'},
      {'code': 'yo', 'label': 'Yoruba', 'native': 'Yorùbá'},
      {'code': 'te', 'label': 'Telugu', 'native': 'తెలుగు'},
      {'code': 'ta', 'label': 'Tamil', 'native': 'தமிழ்'},
      {'code': 'vi', 'label': 'Vietnamese', 'native': 'Tiếng Việt'},
      {'code': 'yue', 'label': 'Cantonese', 'native': '粵語'},
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final cubit = sheetContext.read<LocaleCubit>();
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: Column(
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
                        const Spacer(),
                        Text(
                          '${options.length} languages',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DsColors.ink300,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options[index];
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
                  ),
                ],
              ),
            );
          },
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
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  cubit.setRegion(value);
                }
                Navigator.of(dialogContext).pop();
              },
              child: Text(context.l10n.commonSave),
            ),
          ],
        );
      },
    );
  }
}
