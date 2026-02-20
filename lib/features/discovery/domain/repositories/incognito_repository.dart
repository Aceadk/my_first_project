import 'dart:async';

import 'package:crushhour/features/discovery/domain/models/incognito_settings.dart';

abstract class IncognitoRepository {
  Stream<IncognitoSettings> get settingsStream;
  IncognitoSettings get currentSettings;
  bool get isIncognito;

  Future<IncognitoSettings> loadSettings();
  Future<IncognitoSettings> enableIncognito({
    bool hideFromLikedYou = true,
    bool hideLastActive = true,
    bool hideReadReceipts = true,
    bool onlyShowToLiked = false,
    bool isPremium = false,
  });
  Future<IncognitoSettings> disableIncognito();
  Future<IncognitoSettings> updateSettings({
    bool? hideFromLikedYou,
    bool? hideLastActive,
    bool? hideReadReceipts,
    bool? onlyShowToLiked,
  });

  bool isVisibleTo(String viewerUserId, {bool viewerHasLiked = false});
  bool shouldShowReadReceipts();
  bool shouldShowLastActive();
  Duration getRemainingTime();
  void dispose();
}
