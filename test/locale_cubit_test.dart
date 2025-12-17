import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:crushhour/logic/locale/locale_cubit.dart';

void main() {
  group('LocaleCubit', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('loads defaults when no prefs stored', () async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = LocaleCubit(preferences: prefs);

      expect(cubit.state.languageCode, 'en');
      expect(cubit.state.region, 'United States');
      expect(cubit.state.isDetecting, isFalse);
      expect(cubit.state.errorMessage, isNull);
    });

    test('persists language and region updates', () async {
      final prefs = await SharedPreferences.getInstance();
      final cubit = LocaleCubit(preferences: prefs);

      await cubit.setLanguage('es');
      await cubit.setRegion('Madrid, Spain');

      expect(cubit.state.languageCode, 'es');
      expect(cubit.state.region, 'Madrid, Spain');

      // Ensure persistence to prefs
      expect(prefs.getString('locale_language'), 'es');
      expect(prefs.getString('locale_region'), 'Madrid, Spain');
    });
  });
}
