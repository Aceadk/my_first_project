import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_ne.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_ur.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_yo.dart';
import 'app_localizations_yue.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('bn'),
    Locale('de'),
    Locale('en'),
    Locale('en', 'XA'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('id'),
    Locale('ja'),
    Locale('ko'),
    Locale('ne'),
    Locale('pt'),
    Locale('ru'),
    Locale('ta'),
    Locale('te'),
    Locale('tr'),
    Locale('ur'),
    Locale('vi'),
    Locale('yo'),
    Locale('yue'),
    Locale('zh'),
  ];

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get commonError;

  /// No description provided for @commonSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get commonSuccess;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get commonSettings;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @commonOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get commonOn;

  /// No description provided for @commonOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get commonOff;

  /// No description provided for @commonMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get commonMore;

  /// No description provided for @commonLess.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get commonLess;

  /// No description provided for @commonAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

  /// No description provided for @commonNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get commonNone;

  /// No description provided for @commonRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get commonRefresh;

  /// No description provided for @commonSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get commonSubmit;

  /// No description provided for @commonSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get commonSend;

  /// No description provided for @commonApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get commonApply;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @commonReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get commonReset;

  /// No description provided for @commonUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get commonUpdate;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get commonView;

  /// No description provided for @commonShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// No description provided for @commonReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get commonReport;

  /// No description provided for @commonBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get commonBlock;

  /// No description provided for @commonUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get commonUnblock;

  /// No description provided for @commonMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get commonMute;

  /// No description provided for @commonUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get commonUnmute;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Connection error. Check your internet and try again.'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please try again.'**
  String get errorTimeout;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get errorServer;

  /// No description provided for @errorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please sign in again.'**
  String get errorUnauthorized;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'The requested item was not found.'**
  String get errorNotFound;

  /// No description provided for @pageNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFoundTitle;

  /// No description provided for @pageNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'The page you\'re looking for doesn\'t exist or may have moved.'**
  String get pageNotFoundMessage;

  /// No description provided for @goToHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get goToHome;

  /// No description provided for @openingChat.
  ///
  /// In en, this message translates to:
  /// **'Opening chat...'**
  String get openingChat;

  /// No description provided for @chatNotFound.
  ///
  /// In en, this message translates to:
  /// **'Chat not found.'**
  String get chatNotFound;

  /// No description provided for @chatLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load chat right now.'**
  String get chatLoadFailed;

  /// No description provided for @loadingProfile.
  ///
  /// In en, this message translates to:
  /// **'Loading profile...'**
  String get loadingProfile;

  /// No description provided for @profileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile not found.'**
  String get profileNotFound;

  /// No description provided for @errorOffline.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your connection and try again.'**
  String get errorOffline;

  /// No description provided for @errorLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in. Please check your credentials.'**
  String get errorLoginFailed;

  /// No description provided for @errorSignUpFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create account. Please try again.'**
  String get errorSignUpFailed;

  /// No description provided for @errorLogoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign out. Please try again.'**
  String get errorLogoutFailed;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get errorInvalidCredentials;

  /// No description provided for @errorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get errorEmailInUse;

  /// No description provided for @errorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Use at least 8 characters.'**
  String get errorWeakPassword;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get errorInvalidEmail;

  /// No description provided for @errorSendCodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send code. Please try again.'**
  String get errorSendCodeFailed;

  /// No description provided for @errorInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired code. Please try again.'**
  String get errorInvalidCode;

  /// No description provided for @errorVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed. Please try again.'**
  String get errorVerificationFailed;

  /// No description provided for @errorLoadProfileFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load profile. Please try again.'**
  String get errorLoadProfileFailed;

  /// No description provided for @errorSaveProfileFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save profile. Please try again.'**
  String get errorSaveProfileFailed;

  /// No description provided for @errorUploadPhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not upload photo. Please try again.'**
  String get errorUploadPhotoFailed;

  /// No description provided for @errorDeletePhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete photo. Please try again.'**
  String get errorDeletePhotoFailed;

  /// No description provided for @errorUpdateLocationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update location. Please try again.'**
  String get errorUpdateLocationFailed;

  /// No description provided for @errorUploadIdFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not upload ID. Please try again.'**
  String get errorUploadIdFailed;

  /// No description provided for @errorLoadDeckFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load profiles. Please try again.'**
  String get errorLoadDeckFailed;

  /// No description provided for @errorSwipeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not process swipe. Please try again.'**
  String get errorSwipeFailed;

  /// No description provided for @errorLikeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not like profile. Please try again.'**
  String get errorLikeFailed;

  /// No description provided for @errorPassFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not pass on profile. Please try again.'**
  String get errorPassFailed;

  /// No description provided for @errorSuperLikeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not super like. Please try again.'**
  String get errorSuperLikeFailed;

  /// No description provided for @errorRewindFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not undo swipe. Please try again.'**
  String get errorRewindFailed;

  /// No description provided for @errorNoSwipeToUndo.
  ///
  /// In en, this message translates to:
  /// **'No swipe to undo.'**
  String get errorNoSwipeToUndo;

  /// No description provided for @errorFreeUndoUsed.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used your free undo today. Upgrade to Plus for unlimited undos!'**
  String get errorFreeUndoUsed;

  /// No description provided for @errorRewindPremiumOnly.
  ///
  /// In en, this message translates to:
  /// **'Rewind is a Plus feature. Upgrade to undo swipes!'**
  String get errorRewindPremiumOnly;

  /// No description provided for @errorLoadChatsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load chats. Please try again.'**
  String get errorLoadChatsFailed;

  /// No description provided for @errorLoadMessagesFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load messages. Please try again.'**
  String get errorLoadMessagesFailed;

  /// No description provided for @errorSendMessageFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send message. Please try again.'**
  String get errorSendMessageFailed;

  /// No description provided for @errorDeleteMessageFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete message. Please try again.'**
  String get errorDeleteMessageFailed;

  /// No description provided for @errorLoadMatchesFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load matches. Please try again.'**
  String get errorLoadMatchesFailed;

  /// No description provided for @errorUnmatchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not unmatch. Please try again.'**
  String get errorUnmatchFailed;

  /// No description provided for @errorCheckoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start checkout. Please try again.'**
  String get errorCheckoutFailed;

  /// No description provided for @errorLoadSubscriptionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load subscription. Please try again.'**
  String get errorLoadSubscriptionFailed;

  /// No description provided for @errorRestorePurchasesFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not restore purchases. Please try again.'**
  String get errorRestorePurchasesFailed;

  /// No description provided for @errorReportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not submit report. Please try again.'**
  String get errorReportFailed;

  /// No description provided for @errorBlockFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not block user. Please try again.'**
  String get errorBlockFailed;

  /// No description provided for @errorUnblockFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not unblock user. Please try again.'**
  String get errorUnblockFailed;

  /// No description provided for @errorLoadInsightsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load insights. Please try again.'**
  String get errorLoadInsightsFailed;

  /// No description provided for @errorLocationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled. Please enable them in Settings.'**
  String get errorLocationDisabled;

  /// No description provided for @errorLocationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied. Please allow access in Settings.'**
  String get errorLocationPermissionDenied;

  /// No description provided for @errorLocationTimeout.
  ///
  /// In en, this message translates to:
  /// **'Location request timed out. Make sure you have GPS signal and try again.'**
  String get errorLocationTimeout;

  /// No description provided for @errorMediaLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load media. Please try again.'**
  String get errorMediaLoadFailed;

  /// No description provided for @errorMediaUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not upload media. Please try again.'**
  String get errorMediaUploadFailed;

  /// No description provided for @errorCouldNot.
  ///
  /// In en, this message translates to:
  /// **'Could not {action}. Please try again.'**
  String errorCouldNot(String action);

  /// No description provided for @errorPlusFeature.
  ///
  /// In en, this message translates to:
  /// **'{feature} is a Plus feature. Upgrade to unlock!'**
  String errorPlusFeature(String feature);

  /// No description provided for @a11yBackButton.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get a11yBackButton;

  /// No description provided for @a11yCloseButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get a11yCloseButton;

  /// No description provided for @a11yMenuButton.
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get a11yMenuButton;

  /// No description provided for @a11ySettingsButton.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get a11ySettingsButton;

  /// No description provided for @a11ySearchButton.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get a11ySearchButton;

  /// No description provided for @a11yFilterButton.
  ///
  /// In en, this message translates to:
  /// **'Open filters'**
  String get a11yFilterButton;

  /// No description provided for @a11yPassButton.
  ///
  /// In en, this message translates to:
  /// **'Pass on this profile'**
  String get a11yPassButton;

  /// No description provided for @a11yLikeButton.
  ///
  /// In en, this message translates to:
  /// **'Like this profile'**
  String get a11yLikeButton;

  /// No description provided for @a11ySuperLikeButton.
  ///
  /// In en, this message translates to:
  /// **'Super like this profile'**
  String get a11ySuperLikeButton;

  /// No description provided for @a11yRewindButton.
  ///
  /// In en, this message translates to:
  /// **'Undo last action'**
  String get a11yRewindButton;

  /// No description provided for @a11yBoostButton.
  ///
  /// In en, this message translates to:
  /// **'Boost your profile'**
  String get a11yBoostButton;

  /// No description provided for @a11yProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get a11yProfilePhoto;

  /// No description provided for @a11yProfilePhotoOf.
  ///
  /// In en, this message translates to:
  /// **'Profile photo of {name}'**
  String a11yProfilePhotoOf(String name);

  /// No description provided for @a11yUserAvatar.
  ///
  /// In en, this message translates to:
  /// **'User avatar'**
  String get a11yUserAvatar;

  /// No description provided for @a11yAvatarOf.
  ///
  /// In en, this message translates to:
  /// **'Avatar of {name}'**
  String a11yAvatarOf(String name);

  /// No description provided for @a11yEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get a11yEditProfile;

  /// No description provided for @a11yViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View profile'**
  String get a11yViewProfile;

  /// No description provided for @a11yVerifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'Verified profile'**
  String get a11yVerifiedBadge;

  /// No description provided for @a11yOnlineNow.
  ///
  /// In en, this message translates to:
  /// **'Online now'**
  String get a11yOnlineNow;

  /// No description provided for @a11yOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get a11yOffline;

  /// No description provided for @a11ySendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get a11ySendMessage;

  /// No description provided for @a11yAttachPhoto.
  ///
  /// In en, this message translates to:
  /// **'Attach photo'**
  String get a11yAttachPhoto;

  /// No description provided for @a11yAttachFile.
  ///
  /// In en, this message translates to:
  /// **'Attach file'**
  String get a11yAttachFile;

  /// No description provided for @a11yVoiceMessage.
  ///
  /// In en, this message translates to:
  /// **'Record voice message'**
  String get a11yVoiceMessage;

  /// No description provided for @a11yVideoCall.
  ///
  /// In en, this message translates to:
  /// **'Start video call'**
  String get a11yVideoCall;

  /// No description provided for @a11yVoiceCall.
  ///
  /// In en, this message translates to:
  /// **'Start voice call'**
  String get a11yVoiceCall;

  /// No description provided for @a11yMessageFrom.
  ///
  /// In en, this message translates to:
  /// **'Message from {sender}'**
  String a11yMessageFrom(String sender);

  /// No description provided for @a11yUnreadMessages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unread message} other{{count} unread messages}}'**
  String a11yUnreadMessages(int count);

  /// No description provided for @a11yShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get a11yShowPassword;

  /// No description provided for @a11yHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get a11yHidePassword;

  /// No description provided for @a11yLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get a11yLoginButton;

  /// No description provided for @a11ySignUpButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get a11ySignUpButton;

  /// No description provided for @a11yForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get a11yForgotPassword;

  /// No description provided for @a11yResendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend verification code'**
  String get a11yResendCode;

  /// No description provided for @a11yToggleSetting.
  ///
  /// In en, this message translates to:
  /// **'Toggle setting'**
  String get a11yToggleSetting;

  /// No description provided for @a11yLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get a11yLoading;

  /// No description provided for @a11yRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing'**
  String get a11yRefreshing;

  /// No description provided for @a11yErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get a11yErrorOccurred;

  /// No description provided for @a11yRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get a11yRetry;

  /// No description provided for @a11yDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get a11yDismiss;

  /// No description provided for @a11yMoreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get a11yMoreOptions;

  /// No description provided for @a11yDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get a11yDelete;

  /// No description provided for @a11yCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get a11yCancel;

  /// No description provided for @a11yConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get a11yConfirm;

  /// No description provided for @a11ySaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get a11ySaveChanges;

  /// No description provided for @a11yTapToView.
  ///
  /// In en, this message translates to:
  /// **'Double tap to view'**
  String get a11yTapToView;

  /// No description provided for @a11yTapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Double tap to select'**
  String get a11yTapToSelect;

  /// No description provided for @a11yTapToToggle.
  ///
  /// In en, this message translates to:
  /// **'Double tap to toggle'**
  String get a11yTapToToggle;

  /// No description provided for @a11yTapToEdit.
  ///
  /// In en, this message translates to:
  /// **'Double tap to edit'**
  String get a11yTapToEdit;

  /// No description provided for @a11yTapToExpand.
  ///
  /// In en, this message translates to:
  /// **'Double tap to expand'**
  String get a11yTapToExpand;

  /// No description provided for @a11yTapToCollapse.
  ///
  /// In en, this message translates to:
  /// **'Double tap to collapse'**
  String get a11yTapToCollapse;

  /// No description provided for @a11ySwipeToDelete.
  ///
  /// In en, this message translates to:
  /// **'Swipe left to delete'**
  String get a11ySwipeToDelete;

  /// No description provided for @a11ySwipeForActions.
  ///
  /// In en, this message translates to:
  /// **'Swipe left for more actions'**
  String get a11ySwipeForActions;

  /// No description provided for @a11yDragToReorder.
  ///
  /// In en, this message translates to:
  /// **'Long press and drag to reorder'**
  String get a11yDragToReorder;

  /// No description provided for @a11yPinchToZoom.
  ///
  /// In en, this message translates to:
  /// **'Pinch to zoom'**
  String get a11yPinchToZoom;

  /// No description provided for @a11yLoadingPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Loading, please wait'**
  String get a11yLoadingPleaseWait;

  /// No description provided for @a11yLoadingComplete.
  ///
  /// In en, this message translates to:
  /// **'Loading complete'**
  String get a11yLoadingComplete;

  /// No description provided for @a11yMatchFound.
  ///
  /// In en, this message translates to:
  /// **'It\'s a match! You matched with {name}'**
  String a11yMatchFound(String name);

  /// No description provided for @a11yNewMessage.
  ///
  /// In en, this message translates to:
  /// **'New message from {sender}'**
  String a11yNewMessage(String sender);

  /// No description provided for @a11yProfileLiked.
  ///
  /// In en, this message translates to:
  /// **'Profile liked'**
  String get a11yProfileLiked;

  /// No description provided for @a11yProfilePassed.
  ///
  /// In en, this message translates to:
  /// **'Profile passed'**
  String get a11yProfilePassed;

  /// No description provided for @a11yProfileSuperLiked.
  ///
  /// In en, this message translates to:
  /// **'Profile super liked'**
  String get a11yProfileSuperLiked;

  /// No description provided for @a11yMessageSent.
  ///
  /// In en, this message translates to:
  /// **'Message sent'**
  String get a11yMessageSent;

  /// No description provided for @a11ySettingSaved.
  ///
  /// In en, this message translates to:
  /// **'Setting saved'**
  String get a11ySettingSaved;

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authWelcomeBack;

  /// No description provided for @authSignInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue to Crush'**
  String get authSignInToContinue;

  /// No description provided for @authEmailOrUsername.
  ///
  /// In en, this message translates to:
  /// **'Email or username'**
  String get authEmailOrUsername;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get authCurrentPassword;

  /// No description provided for @authNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get authNewPassword;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPassword;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get authSignUp;

  /// No description provided for @authSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get authSignOut;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authContinueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authContinueWithApple;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get authNoAccount;

  /// No description provided for @authAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authAlreadyHaveAccount;

  /// No description provided for @authOrContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get authOrContinueWith;

  /// No description provided for @authGatewayTagline.
  ///
  /// In en, this message translates to:
  /// **'Find your Perfect Match'**
  String get authGatewayTagline;

  /// No description provided for @authGatewayFeatureVerifiedProfiles.
  ///
  /// In en, this message translates to:
  /// **'Verified profiles for safety'**
  String get authGatewayFeatureVerifiedProfiles;

  /// No description provided for @authGatewayFeatureSendMessages.
  ///
  /// In en, this message translates to:
  /// **'Send messages before matching'**
  String get authGatewayFeatureSendMessages;

  /// No description provided for @authGatewayFeatureMeetNearby.
  ///
  /// In en, this message translates to:
  /// **'Meet people near you'**
  String get authGatewayFeatureMeetNearby;

  /// No description provided for @authGatewayAgeVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Age Verification'**
  String get authGatewayAgeVerificationTitle;

  /// No description provided for @authGatewayAgeVerificationDescription.
  ///
  /// In en, this message translates to:
  /// **'Crush is a dating app for adults only. You must be at least 18 years old to create an account.'**
  String get authGatewayAgeVerificationDescription;

  /// No description provided for @authGatewayAgeVerificationQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you 18 years or older?'**
  String get authGatewayAgeVerificationQuestion;

  /// No description provided for @authGatewayAgeVerificationLegalNotice.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you confirm that you are at least 18 years old and agree to our Terms of Service.'**
  String get authGatewayAgeVerificationLegalNotice;

  /// No description provided for @authGatewayAgeUnderageError.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 18 years old to use Crush.'**
  String get authGatewayAgeUnderageError;

  /// No description provided for @authPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get authPhone;

  /// No description provided for @authPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get authPhoneNumber;

  /// No description provided for @authEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get authEnterCode;

  /// No description provided for @authVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get authVerificationCode;

  /// No description provided for @authSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get authSendCode;

  /// No description provided for @authResendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get authResendCode;

  /// No description provided for @authVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get authVerify;

  /// No description provided for @authVerifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify email'**
  String get authVerifyEmail;

  /// No description provided for @authVerifyPhone.
  ///
  /// In en, this message translates to:
  /// **'Verify phone'**
  String get authVerifyPhone;

  /// No description provided for @authCheckEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get authCheckEmail;

  /// No description provided for @authCheckPhone.
  ///
  /// In en, this message translates to:
  /// **'Check your phone'**
  String get authCheckPhone;

  /// No description provided for @authCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Code sent'**
  String get authCodeSent;

  /// No description provided for @authCodeSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a code to {destination}'**
  String authCodeSentTo(String destination);

  /// No description provided for @authEnterCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get authEnterCodeHint;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get authPasswordHint;

  /// No description provided for @authResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get authResetPassword;

  /// No description provided for @authChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get authChangePassword;

  /// No description provided for @authPasswordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully!'**
  String get authPasswordChanged;

  /// No description provided for @authAgreeToTerms.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our Terms of Service and Privacy Policy'**
  String get authAgreeToTerms;

  /// No description provided for @authTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get authTermsOfService;

  /// No description provided for @authPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get authPrivacyPolicy;

  /// No description provided for @authVerifyPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Password'**
  String get authVerifyPasswordTitle;

  /// No description provided for @authChangeEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get authChangeEmailTitle;

  /// No description provided for @authChangeEmailIntro.
  ///
  /// In en, this message translates to:
  /// **'Use a new email to keep your account recoverable.'**
  String get authChangeEmailIntro;

  /// No description provided for @authCurrentEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Current email: {email}'**
  String authCurrentEmailLabel(String email);

  /// No description provided for @authNewEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'New email address'**
  String get authNewEmailAddress;

  /// No description provided for @authCodeWillBeSentToEmail.
  ///
  /// In en, this message translates to:
  /// **'We will send a 6-digit code to this email.'**
  String get authCodeWillBeSentToEmail;

  /// No description provided for @authEnterCodeFromEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code from your email.'**
  String get authEnterCodeFromEmail;

  /// No description provided for @authUseCodeFromEmail.
  ///
  /// In en, this message translates to:
  /// **'Use the 6-digit code from your email'**
  String get authUseCodeFromEmail;

  /// No description provided for @authEnterEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get authEnterEmailAddress;

  /// No description provided for @authVerifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify code'**
  String get authVerifyCode;

  /// No description provided for @authEnterCurrentPasswordPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password to continue.'**
  String get authEnterCurrentPasswordPrompt;

  /// No description provided for @authCouldNotSendCode.
  ///
  /// In en, this message translates to:
  /// **'Could not send code. Please try again.'**
  String get authCouldNotSendCode;

  /// No description provided for @authRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Request failed.'**
  String get authRequestFailed;

  /// No description provided for @authCodeOnTheWayEmail.
  ///
  /// In en, this message translates to:
  /// **'If that email is reachable, a 6-digit code is on the way.'**
  String get authCodeOnTheWayEmail;

  /// No description provided for @authInvalidOrExpiredCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired code. Please try again.'**
  String get authInvalidOrExpiredCode;

  /// No description provided for @authVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed.'**
  String get authVerificationFailed;

  /// No description provided for @authEmailUpdated.
  ///
  /// In en, this message translates to:
  /// **'Email updated.'**
  String get authEmailUpdated;

  /// No description provided for @authEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get authEmailAddress;

  /// No description provided for @authEmailProtectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Email protection'**
  String get authEmailProtectionTitle;

  /// No description provided for @authEmailProtectionIntro.
  ///
  /// In en, this message translates to:
  /// **'Add and verify an email to protect your account and enable recovery.'**
  String get authEmailProtectionIntro;

  /// No description provided for @authEmailVerifiedBadge.
  ///
  /// In en, this message translates to:
  /// **'Email Verified'**
  String get authEmailVerifiedBadge;

  /// No description provided for @authEmailAlreadyVerifiedLocked.
  ///
  /// In en, this message translates to:
  /// **'Your email is already verified. You cannot make any changes to this email address.'**
  String get authEmailAlreadyVerifiedLocked;

  /// No description provided for @authWantDifferentEmail.
  ///
  /// In en, this message translates to:
  /// **'Want to use a different email?'**
  String get authWantDifferentEmail;

  /// No description provided for @authDifferentEmailInstructions.
  ///
  /// In en, this message translates to:
  /// **'To use a different email address, you will need to delete this account and create a new one with the new email.'**
  String get authDifferentEmailInstructions;

  /// No description provided for @authGoToAccountSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to Account Settings'**
  String get authGoToAccountSettings;

  /// No description provided for @authStatusNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Status: not verified'**
  String get authStatusNotVerified;

  /// No description provided for @authEmailAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered to another account. Please use a different email address.'**
  String get authEmailAlreadyRegistered;

  /// No description provided for @authNewDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'New device check'**
  String get authNewDeviceTitle;

  /// No description provided for @authNewDeviceIntro.
  ///
  /// In en, this message translates to:
  /// **'Verify a new device before continuing.'**
  String get authNewDeviceIntro;

  /// No description provided for @authCodeWillBeSentToEmailOnFile.
  ///
  /// In en, this message translates to:
  /// **'We will send a 6-digit code to the email on file.'**
  String get authCodeWillBeSentToEmailOnFile;

  /// No description provided for @authVerifyDevice.
  ///
  /// In en, this message translates to:
  /// **'Verify device'**
  String get authVerifyDevice;

  /// No description provided for @authEnterUsernameOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your username or email'**
  String get authEnterUsernameOrEmail;

  /// No description provided for @authCodeOnTheWayAccount.
  ///
  /// In en, this message translates to:
  /// **'If an account exists, a 6-digit code is on the way.'**
  String get authCodeOnTheWayAccount;

  /// No description provided for @authDeviceVerified.
  ///
  /// In en, this message translates to:
  /// **'Device verified.'**
  String get authDeviceVerified;

  /// No description provided for @authOtpCaption.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code we sent'**
  String get authOtpCaption;

  /// No description provided for @authOtpSentTo.
  ///
  /// In en, this message translates to:
  /// **'OTP sent to {phone}'**
  String authOtpSentTo(String phone);

  /// No description provided for @authEnterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get authEnterOtp;

  /// No description provided for @authEnterCodeFromSms.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code from your SMS.'**
  String get authEnterCodeFromSms;

  /// No description provided for @authEnterCodeToContinue.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code to continue.'**
  String get authEnterCodeToContinue;

  /// No description provided for @authEnterCodeVerifyPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter the code to verify your phone'**
  String get authEnterCodeVerifyPhone;

  /// No description provided for @authCodeShouldBe6Digits.
  ///
  /// In en, this message translates to:
  /// **'The code should be 6 digits'**
  String get authCodeShouldBe6Digits;

  /// No description provided for @authEnterEmailOrUsername.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email or username'**
  String get authEnterEmailOrUsername;

  /// No description provided for @authUsernameMustBe320.
  ///
  /// In en, this message translates to:
  /// **'Username must be 3-20 characters'**
  String get authUsernameMustBe320;

  /// No description provided for @authEnterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get authEnterYourPassword;

  /// No description provided for @authAppleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Apple Sign-In failed. Please try again.'**
  String get authAppleSignInFailed;

  /// No description provided for @wordOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get wordOr;

  /// No description provided for @subscriptionPaywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Get Premium'**
  String get subscriptionPaywallTitle;

  /// No description provided for @subscriptionCancelSubscription.
  ///
  /// In en, this message translates to:
  /// **'Cancel subscription'**
  String get subscriptionCancelSubscription;

  /// No description provided for @authDevLogin.
  ///
  /// In en, this message translates to:
  /// **'Dev Login'**
  String get authDevLogin;

  /// No description provided for @authUsePhoneInstead.
  ///
  /// In en, this message translates to:
  /// **'Use phone instead'**
  String get authUsePhoneInstead;

  /// No description provided for @authUseEmailInstead.
  ///
  /// In en, this message translates to:
  /// **'Use email instead'**
  String get authUseEmailInstead;

  /// No description provided for @authEmailLink.
  ///
  /// In en, this message translates to:
  /// **'Email link'**
  String get authEmailLink;

  /// No description provided for @authEmailOtp.
  ///
  /// In en, this message translates to:
  /// **'Email OTP'**
  String get authEmailOtp;

  /// No description provided for @authEmailPassword.
  ///
  /// In en, this message translates to:
  /// **'Email + password'**
  String get authEmailPassword;

  /// No description provided for @authChooseSignInMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose a sign-in method'**
  String get authChooseSignInMethod;

  /// No description provided for @authSendLink.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get authSendLink;

  /// No description provided for @authAutoCheckingStatus.
  ///
  /// In en, this message translates to:
  /// **'Auto-checking verification status...'**
  String get authAutoCheckingStatus;

  /// No description provided for @authIveVerified.
  ///
  /// In en, this message translates to:
  /// **'I\'ve verified'**
  String get authIveVerified;

  /// No description provided for @authCheckYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get authCheckYourEmail;

  /// No description provided for @authClickLinkToVerify.
  ///
  /// In en, this message translates to:
  /// **'Click the link we sent to verify your email'**
  String get authClickLinkToVerify;

  /// No description provided for @authEmailVerified.
  ///
  /// In en, this message translates to:
  /// **'Email verified successfully!'**
  String get authEmailVerified;

  /// No description provided for @authSkipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get authSkipForNow;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsAppearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Theme and display options'**
  String get settingsAppearanceSubtitle;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your alerts'**
  String get settingsNotificationsSubtitle;

  /// No description provided for @settingsPushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get settingsPushNotifications;

  /// No description provided for @settingsEmailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email notifications'**
  String get settingsEmailNotifications;

  /// No description provided for @settingsSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get settingsSound;

  /// No description provided for @settingsVibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get settingsVibration;

  /// No description provided for @settingsLanguageRegion.
  ///
  /// In en, this message translates to:
  /// **'Language & Region'**
  String get settingsLanguageRegion;

  /// No description provided for @settingsLanguageRegionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App language and location'**
  String get settingsLanguageRegionSubtitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get settingsRegion;

  /// No description provided for @settingsDetectRegion.
  ///
  /// In en, this message translates to:
  /// **'Detect my region'**
  String get settingsDetectRegion;

  /// No description provided for @settingsDiscoveryFilters.
  ///
  /// In en, this message translates to:
  /// **'Discovery & Filters'**
  String get settingsDiscoveryFilters;

  /// No description provided for @settingsDiscoveryFiltersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Who you want to see'**
  String get settingsDiscoveryFiltersSubtitle;

  /// No description provided for @settingsAgeRange.
  ///
  /// In en, this message translates to:
  /// **'Age range'**
  String get settingsAgeRange;

  /// No description provided for @settingsDistance.
  ///
  /// In en, this message translates to:
  /// **'Maximum distance'**
  String get settingsDistance;

  /// No description provided for @settingsDistanceKm.
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String settingsDistanceKm(int distance);

  /// No description provided for @settingsShowMe.
  ///
  /// In en, this message translates to:
  /// **'Show me'**
  String get settingsShowMe;

  /// No description provided for @settingsShowMyDistance.
  ///
  /// In en, this message translates to:
  /// **'Show my distance'**
  String get settingsShowMyDistance;

  /// No description provided for @settingsShowMyAge.
  ///
  /// In en, this message translates to:
  /// **'Show my age'**
  String get settingsShowMyAge;

  /// No description provided for @settingsDataStorage.
  ///
  /// In en, this message translates to:
  /// **'Data & Storage'**
  String get settingsDataStorage;

  /// No description provided for @settingsDataStorageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cache and downloads'**
  String get settingsDataStorageSubtitle;

  /// No description provided for @settingsCacheSize.
  ///
  /// In en, this message translates to:
  /// **'Cache size'**
  String get settingsCacheSize;

  /// No description provided for @settingsClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get settingsClearCache;

  /// No description provided for @settingsMediaDownloads.
  ///
  /// In en, this message translates to:
  /// **'Media downloads'**
  String get settingsMediaDownloads;

  /// No description provided for @settingsWifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi only'**
  String get settingsWifiOnly;

  /// No description provided for @settingsAccountSecurity.
  ///
  /// In en, this message translates to:
  /// **'Account Security'**
  String get settingsAccountSecurity;

  /// No description provided for @settingsAccountSecuritySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Email and phone verification'**
  String get settingsAccountSecuritySubtitle;

  /// No description provided for @settingsAccountActions.
  ///
  /// In en, this message translates to:
  /// **'Account Actions'**
  String get settingsAccountActions;

  /// No description provided for @settingsAccountActionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your account'**
  String get settingsAccountActionsSubtitle;

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get settingsChangePassword;

  /// No description provided for @settingsDeactivateAccount.
  ///
  /// In en, this message translates to:
  /// **'Deactivate account'**
  String get settingsDeactivateAccount;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Control what others can see'**
  String get settingsPrivacySubtitle;

  /// No description provided for @settingsHideFromDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Hide from discovery'**
  String get settingsHideFromDiscovery;

  /// No description provided for @settingsIncognitoMode.
  ///
  /// In en, this message translates to:
  /// **'Incognito mode'**
  String get settingsIncognitoMode;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App info and legal'**
  String get settingsAboutSubtitle;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsRateUs.
  ///
  /// In en, this message translates to:
  /// **'Rate us'**
  String get settingsRateUs;

  /// No description provided for @settingsHelp.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get settingsHelp;

  /// No description provided for @settingsContactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get settingsContactUs;

  /// No description provided for @settingsFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get settingsFeedback;

  /// No description provided for @settingsSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get settingsSubscription;

  /// No description provided for @settingsSubscriptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your plan'**
  String get settingsSubscriptionSubtitle;

  /// No description provided for @settingsGetPlus.
  ///
  /// In en, this message translates to:
  /// **'Get Crush Plus'**
  String get settingsGetPlus;

  /// No description provided for @settingsRestorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get settingsRestorePurchases;

  /// No description provided for @settingsNotificationsEnabledCount.
  ///
  /// In en, this message translates to:
  /// **'{enabled} of {total} enabled'**
  String settingsNotificationsEnabledCount(int enabled, int total);

  /// No description provided for @settingsLanguageRegionSummary.
  ///
  /// In en, this message translates to:
  /// **'{language} - {region}'**
  String settingsLanguageRegionSummary(String language, String region);

  /// No description provided for @settingsDiscoverySummary.
  ///
  /// In en, this message translates to:
  /// **'{distanceKm} km, {minAge}-{maxAge} years'**
  String settingsDiscoverySummary(int distanceKm, int minAge, int maxAge);

  /// No description provided for @settingsCacheSummary.
  ///
  /// In en, this message translates to:
  /// **'Cache: {sizeMb} MB'**
  String settingsCacheSummary(int sizeMb);

  /// No description provided for @settingsAccountNoEmail.
  ///
  /// In en, this message translates to:
  /// **'No email added'**
  String get settingsAccountNoEmail;

  /// No description provided for @settingsAccountEmailVerified.
  ///
  /// In en, this message translates to:
  /// **'Email verified'**
  String get settingsAccountEmailVerified;

  /// No description provided for @settingsAccountEmailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Email not verified'**
  String get settingsAccountEmailNotVerified;

  /// No description provided for @settingsIdVerification.
  ///
  /// In en, this message translates to:
  /// **'ID Verification'**
  String get settingsIdVerification;

  /// No description provided for @settingsIdVerificationVerifiedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verified - Badge active'**
  String get settingsIdVerificationVerifiedSubtitle;

  /// No description provided for @settingsIdVerificationPromptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify to unlock 50% more swipes'**
  String get settingsIdVerificationPromptSubtitle;

  /// No description provided for @settingsChatSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Message retention & auto-delete'**
  String get settingsChatSettingsSubtitle;

  /// No description provided for @settingsCallHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recent audio and video calls'**
  String get settingsCallHistorySubtitle;

  /// No description provided for @settingsIncognitoActivePremium.
  ///
  /// In en, this message translates to:
  /// **'Active (Premium)'**
  String get settingsIncognitoActivePremium;

  /// No description provided for @settingsIncognitoBrowsePrivately.
  ///
  /// In en, this message translates to:
  /// **'Browse profiles privately'**
  String get settingsIncognitoBrowsePrivately;

  /// No description provided for @settingsSubscriptionStatus.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String settingsSubscriptionStatus(String status);

  /// No description provided for @settingsSubscriptionAccessEndsOn.
  ///
  /// In en, this message translates to:
  /// **'Access ends on {date}'**
  String settingsSubscriptionAccessEndsOn(String date);

  /// No description provided for @settingsSubscriptionRenewsOn.
  ///
  /// In en, this message translates to:
  /// **'Renews on {date}'**
  String settingsSubscriptionRenewsOn(String date);

  /// No description provided for @settingsSubscriptionManageBillingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage billing or renew your Plus plan.'**
  String get settingsSubscriptionManageBillingSubtitle;

  /// No description provided for @settingsSubscriptionUpgradePitchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Plus for unlimited likes, rewinds, and Passport.'**
  String get settingsSubscriptionUpgradePitchSubtitle;

  /// No description provided for @settingsSubscriptionFirstMonthDiscount.
  ///
  /// In en, this message translates to:
  /// **'50% off your first month!'**
  String get settingsSubscriptionFirstMonthDiscount;

  /// No description provided for @settingsManageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get settingsManageSubscription;

  /// No description provided for @settingsSafetyBlocking.
  ///
  /// In en, this message translates to:
  /// **'Safety & Blocking'**
  String get settingsSafetyBlocking;

  /// No description provided for @settingsHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'FAQ, contact support, and more'**
  String get settingsHelpSubtitle;

  /// No description provided for @settingsSignOutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get settingsSignOutSubtitle;

  /// No description provided for @settingsLegalSection.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get settingsLegalSection;

  /// No description provided for @settingsAboutCrush.
  ///
  /// In en, this message translates to:
  /// **'About Crush'**
  String get settingsAboutCrush;

  /// No description provided for @settingsManageBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Manage blocked users'**
  String get settingsManageBlockedUsers;

  /// No description provided for @settingsThemeDarkLuxuryRoyal.
  ///
  /// In en, this message translates to:
  /// **'Dark Luxury (Royal)'**
  String get settingsThemeDarkLuxuryRoyal;

  /// No description provided for @settingsThemeDarkLuxuryModern.
  ///
  /// In en, this message translates to:
  /// **'Dark Luxury (Modern)'**
  String get settingsThemeDarkLuxuryModern;

  /// No description provided for @settingsIncognitoBrowseWithoutSeen.
  ///
  /// In en, this message translates to:
  /// **'Browse profiles without being seen'**
  String get settingsIncognitoBrowseWithoutSeen;

  /// No description provided for @settingsIncognitoIsActive.
  ///
  /// In en, this message translates to:
  /// **'Incognito is active'**
  String get settingsIncognitoIsActive;

  /// No description provided for @settingsIncognitoHideFromLikedYou.
  ///
  /// In en, this message translates to:
  /// **'Hide from \"Liked You\"'**
  String get settingsIncognitoHideFromLikedYou;

  /// No description provided for @settingsIncognitoHideFromLikedYouSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your likes won\'t appear in their list'**
  String get settingsIncognitoHideFromLikedYouSubtitle;

  /// No description provided for @settingsIncognitoHideLastActive.
  ///
  /// In en, this message translates to:
  /// **'Hide last active'**
  String get settingsIncognitoHideLastActive;

  /// No description provided for @settingsIncognitoHideLastActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Others won\'t see when you were online'**
  String get settingsIncognitoHideLastActiveSubtitle;

  /// No description provided for @settingsIncognitoHideReadReceipts.
  ///
  /// In en, this message translates to:
  /// **'Hide read receipts'**
  String get settingsIncognitoHideReadReceipts;

  /// No description provided for @settingsIncognitoHideReadReceiptsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Messages won\'t show as read'**
  String get settingsIncognitoHideReadReceiptsSubtitle;

  /// No description provided for @settingsIncognitoFeatureHideFromLikedYou.
  ///
  /// In en, this message translates to:
  /// **'Your likes won\'t appear in \"Liked You\"'**
  String get settingsIncognitoFeatureHideFromLikedYou;

  /// No description provided for @settingsIncognitoFeatureHideLastActive.
  ///
  /// In en, this message translates to:
  /// **'Hide your last active status'**
  String get settingsIncognitoFeatureHideLastActive;

  /// No description provided for @settingsIncognitoFeatureHideReadReceipts.
  ///
  /// In en, this message translates to:
  /// **'Hide read receipts in chats'**
  String get settingsIncognitoFeatureHideReadReceipts;

  /// No description provided for @settingsIncognitoFreeTierNotice.
  ///
  /// In en, this message translates to:
  /// **'Free users get 1 hour. Upgrade for unlimited.'**
  String get settingsIncognitoFreeTierNotice;

  /// No description provided for @settingsSubscriptionFreeSummary.
  ///
  /// In en, this message translates to:
  /// **'Free Plan - Upgrade for unlimited likes'**
  String get settingsSubscriptionFreeSummary;

  /// No description provided for @settingsSubscriptionPlusActiveSummary.
  ///
  /// In en, this message translates to:
  /// **'Plus Member - Active'**
  String get settingsSubscriptionPlusActiveSummary;

  /// No description provided for @settingsSubscriptionPlusEndsSummary.
  ///
  /// In en, this message translates to:
  /// **'Plus Member - Ends on {date}'**
  String settingsSubscriptionPlusEndsSummary(String date);

  /// No description provided for @settingsSubscriptionPlusRenewsSummary.
  ///
  /// In en, this message translates to:
  /// **'Plus Member - Renews on {date}'**
  String settingsSubscriptionPlusRenewsSummary(String date);

  /// No description provided for @settingsNotificationsHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay Connected'**
  String get settingsNotificationsHeaderTitle;

  /// No description provided for @settingsNotificationsHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get notified about matches, messages, and more.'**
  String get settingsNotificationsHeaderSubtitle;

  /// No description provided for @settingsNotificationsPushSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Messages, matches, and app updates'**
  String get settingsNotificationsPushSubtitle;

  /// No description provided for @settingsNotificationsPushEnabled.
  ///
  /// In en, this message translates to:
  /// **'Push notifications enabled.'**
  String get settingsNotificationsPushEnabled;

  /// No description provided for @settingsNotificationsPushDisabled.
  ///
  /// In en, this message translates to:
  /// **'Push notifications disabled.'**
  String get settingsNotificationsPushDisabled;

  /// No description provided for @settingsNotificationsEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Updates sent to your inbox'**
  String get settingsNotificationsEmailSubtitle;

  /// No description provided for @settingsNotificationsSoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play sounds for alerts'**
  String get settingsNotificationsSoundSubtitle;

  /// No description provided for @settingsNotificationsVibrationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Vibrate on new messages or matches'**
  String get settingsNotificationsVibrationSubtitle;

  /// No description provided for @settingsNotificationCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Categories'**
  String get settingsNotificationCategoriesTitle;

  /// No description provided for @settingsNotificationCategoriesEnabledCount.
  ///
  /// In en, this message translates to:
  /// **'{enabled} of {total} enabled'**
  String settingsNotificationCategoriesEnabledCount(int enabled, int total);

  /// No description provided for @settingsNotificationCategoryMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get settingsNotificationCategoryMatchesTitle;

  /// No description provided for @settingsNotificationCategoryMatchesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New match notifications'**
  String get settingsNotificationCategoryMatchesSubtitle;

  /// No description provided for @settingsNotificationCategoryMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get settingsNotificationCategoryMessagesTitle;

  /// No description provided for @settingsNotificationCategoryMessagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New message notifications'**
  String get settingsNotificationCategoryMessagesSubtitle;

  /// No description provided for @settingsNotificationCategoryLikesTitle.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get settingsNotificationCategoryLikesTitle;

  /// No description provided for @settingsNotificationCategoryLikesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When someone likes your profile'**
  String get settingsNotificationCategoryLikesSubtitle;

  /// No description provided for @settingsNotificationCategoryProfileViewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Views'**
  String get settingsNotificationCategoryProfileViewsTitle;

  /// No description provided for @settingsNotificationCategoryProfileViewsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When someone views your profile'**
  String get settingsNotificationCategoryProfileViewsSubtitle;

  /// No description provided for @settingsNotificationCategoryPromotionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get settingsNotificationCategoryPromotionsTitle;

  /// No description provided for @settingsNotificationCategoryPromotionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Special offers and features'**
  String get settingsNotificationCategoryPromotionsSubtitle;

  /// No description provided for @settingsNotificationCategorySafetyAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety Alerts'**
  String get settingsNotificationCategorySafetyAlertsTitle;

  /// No description provided for @settingsNotificationCategorySafetyAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Always on — cannot be disabled'**
  String get settingsNotificationCategorySafetyAlertsSubtitle;

  /// No description provided for @settingsNotificationQuietHoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiet Hours'**
  String get settingsNotificationQuietHoursTitle;

  /// No description provided for @settingsNotificationQuietHoursTileTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours'**
  String get settingsNotificationQuietHoursTileTitle;

  /// No description provided for @settingsNotificationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get settingsNotificationDisabled;

  /// No description provided for @settingsNotificationsDeviceSettingsInfo.
  ///
  /// In en, this message translates to:
  /// **'You can also manage notifications in your device settings.'**
  String get settingsNotificationsDeviceSettingsInfo;

  /// No description provided for @settingsPrivacySnackAllPublic.
  ///
  /// In en, this message translates to:
  /// **'All information set to public'**
  String get settingsPrivacySnackAllPublic;

  /// No description provided for @settingsPrivacySnackAllPrivate.
  ///
  /// In en, this message translates to:
  /// **'All information set to private'**
  String get settingsPrivacySnackAllPrivate;

  /// No description provided for @settingsPrivacySnackResetDefaults.
  ///
  /// In en, this message translates to:
  /// **'Privacy settings reset to defaults'**
  String get settingsPrivacySnackResetDefaults;

  /// No description provided for @settingsPrivacyHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Control Your Privacy'**
  String get settingsPrivacyHeaderTitle;

  /// No description provided for @settingsPrivacyHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose what others can see when they view your profile.'**
  String get settingsPrivacyHeaderSubtitle;

  /// No description provided for @settingsPrivacySectionNameVisibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Name Visibility'**
  String get settingsPrivacySectionNameVisibilityTitle;

  /// No description provided for @settingsPrivacySectionNameVisibilitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Control how your name appears'**
  String get settingsPrivacySectionNameVisibilitySubtitle;

  /// No description provided for @settingsPrivacyFirstNameTitle.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get settingsPrivacyFirstNameTitle;

  /// No description provided for @settingsPrivacyFirstNameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show your first name on your profile'**
  String get settingsPrivacyFirstNameSubtitle;

  /// No description provided for @settingsPrivacyLastNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get settingsPrivacyLastNameTitle;

  /// No description provided for @settingsPrivacyLastNameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show your last name on your profile'**
  String get settingsPrivacyLastNameSubtitle;

  /// No description provided for @settingsPrivacySectionSensitiveInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Sensitive Information'**
  String get settingsPrivacySectionSensitiveInfoTitle;

  /// No description provided for @settingsPrivacySectionSensitiveInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'These are private by default'**
  String get settingsPrivacySectionSensitiveInfoSubtitle;

  /// No description provided for @settingsPrivacyAgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get settingsPrivacyAgeTitle;

  /// No description provided for @settingsPrivacyAgeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show your age on your profile'**
  String get settingsPrivacyAgeSubtitle;

  /// No description provided for @settingsPrivacyDateOfBirthTitle.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get settingsPrivacyDateOfBirthTitle;

  /// No description provided for @settingsPrivacyDateOfBirthSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show your exact birth date'**
  String get settingsPrivacyDateOfBirthSubtitle;

  /// No description provided for @settingsPrivacyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get settingsPrivacyEmailTitle;

  /// No description provided for @settingsPrivacyEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show your email address'**
  String get settingsPrivacyEmailSubtitle;

  /// No description provided for @settingsPrivacyPhoneNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get settingsPrivacyPhoneNumberTitle;

  /// No description provided for @settingsPrivacyPhoneNumberSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show your phone number'**
  String get settingsPrivacyPhoneNumberSubtitle;

  /// No description provided for @settingsPrivacyExactLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Exact Location'**
  String get settingsPrivacyExactLocationTitle;

  /// No description provided for @settingsPrivacyExactLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show exact location instead of city only'**
  String get settingsPrivacyExactLocationSubtitle;

  /// No description provided for @settingsPrivacySectionDatingBasicsTitle.
  ///
  /// In en, this message translates to:
  /// **'Dating Basics'**
  String get settingsPrivacySectionDatingBasicsTitle;

  /// No description provided for @settingsPrivacySectionDatingBasicsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Basic dating profile information'**
  String get settingsPrivacySectionDatingBasicsSubtitle;

  /// No description provided for @settingsPrivacyHeightTitle.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get settingsPrivacyHeightTitle;

  /// No description provided for @settingsPrivacyHeightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show your height'**
  String get settingsPrivacyHeightSubtitle;

  /// No description provided for @settingsPrivacyRelationshipGoalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Relationship Goals'**
  String get settingsPrivacyRelationshipGoalsTitle;

  /// No description provided for @settingsPrivacyRelationshipGoalsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show what you\'re looking for'**
  String get settingsPrivacyRelationshipGoalsSubtitle;

  /// No description provided for @settingsPrivacyZodiacSignTitle.
  ///
  /// In en, this message translates to:
  /// **'Zodiac Sign'**
  String get settingsPrivacyZodiacSignTitle;

  /// No description provided for @settingsPrivacyZodiacSignSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show your zodiac sign'**
  String get settingsPrivacyZodiacSignSubtitle;

  /// No description provided for @settingsPrivacySectionAboutMeTitle.
  ///
  /// In en, this message translates to:
  /// **'About Me'**
  String get settingsPrivacySectionAboutMeTitle;

  /// No description provided for @settingsPrivacySectionAboutMeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Personal characteristics'**
  String get settingsPrivacySectionAboutMeSubtitle;

  /// No description provided for @settingsPrivacyEducationTitle.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get settingsPrivacyEducationTitle;

  /// No description provided for @settingsPrivacyEducationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show your education level'**
  String get settingsPrivacyEducationSubtitle;

  /// No description provided for @settingsPrivacyFamilyPlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Family Plans'**
  String get settingsPrivacyFamilyPlansTitle;

  /// No description provided for @settingsPrivacyFamilyPlansSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show your family plans'**
  String get settingsPrivacyFamilyPlansSubtitle;

  /// No description provided for @settingsPrivacyPersonalityTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Personality Type'**
  String get settingsPrivacyPersonalityTypeTitle;

  /// No description provided for @settingsPrivacyPersonalityTypeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show your MBTI or personality'**
  String get settingsPrivacyPersonalityTypeSubtitle;

  /// No description provided for @settingsPrivacySectionLifestyleTitle.
  ///
  /// In en, this message translates to:
  /// **'Lifestyle'**
  String get settingsPrivacySectionLifestyleTitle;

  /// No description provided for @settingsPrivacySectionLifestyleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your habits and preferences'**
  String get settingsPrivacySectionLifestyleSubtitle;

  /// No description provided for @settingsPrivacyWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get settingsPrivacyWorkoutTitle;

  /// No description provided for @settingsPrivacyWorkoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show your exercise habits'**
  String get settingsPrivacyWorkoutSubtitle;

  /// No description provided for @settingsPrivacySmokingTitle.
  ///
  /// In en, this message translates to:
  /// **'Smoking'**
  String get settingsPrivacySmokingTitle;

  /// No description provided for @settingsPrivacySmokingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show your smoking habits'**
  String get settingsPrivacySmokingSubtitle;

  /// No description provided for @settingsPrivacyDrinkingTitle.
  ///
  /// In en, this message translates to:
  /// **'Drinking'**
  String get settingsPrivacyDrinkingTitle;

  /// No description provided for @settingsPrivacyDrinkingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show your drinking habits'**
  String get settingsPrivacyDrinkingSubtitle;

  /// No description provided for @settingsPrivacyDietTitle.
  ///
  /// In en, this message translates to:
  /// **'Diet'**
  String get settingsPrivacyDietTitle;

  /// No description provided for @settingsPrivacyDietSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show your dietary preferences'**
  String get settingsPrivacyDietSubtitle;

  /// No description provided for @settingsPrivacySleepingHabitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleeping Habits'**
  String get settingsPrivacySleepingHabitsTitle;

  /// No description provided for @settingsPrivacySleepingHabitsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show your sleep schedule'**
  String get settingsPrivacySleepingHabitsSubtitle;

  /// No description provided for @settingsPrivacyPetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get settingsPrivacyPetsTitle;

  /// No description provided for @settingsPrivacyPetsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show your pet preferences'**
  String get settingsPrivacyPetsSubtitle;

  /// No description provided for @settingsPrivacySectionWorkEducationTitle.
  ///
  /// In en, this message translates to:
  /// **'Work & Education'**
  String get settingsPrivacySectionWorkEducationTitle;

  /// No description provided for @settingsPrivacySectionWorkEducationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Professional information'**
  String get settingsPrivacySectionWorkEducationSubtitle;

  /// No description provided for @settingsPrivacyJobTitleTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Title'**
  String get settingsPrivacyJobTitleTitle;

  /// No description provided for @settingsPrivacyJobTitleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show your job title'**
  String get settingsPrivacyJobTitleSubtitle;

  /// No description provided for @settingsPrivacyCompanyTitle.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get settingsPrivacyCompanyTitle;

  /// No description provided for @settingsPrivacyCompanySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show where you work'**
  String get settingsPrivacyCompanySubtitle;

  /// No description provided for @settingsPrivacySchoolTitle.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get settingsPrivacySchoolTitle;

  /// No description provided for @settingsPrivacySchoolSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show your school or university'**
  String get settingsPrivacySchoolSubtitle;

  /// No description provided for @settingsPrivacySectionMusicTitle.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get settingsPrivacySectionMusicTitle;

  /// No description provided for @settingsPrivacySectionMusicSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your music taste'**
  String get settingsPrivacySectionMusicSubtitle;

  /// No description provided for @settingsPrivacyFavoriteSingerTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorite Singer'**
  String get settingsPrivacyFavoriteSingerTitle;

  /// No description provided for @settingsPrivacyFavoriteSingerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show your favorite artist'**
  String get settingsPrivacyFavoriteSingerSubtitle;

  /// No description provided for @settingsPrivacyFavoriteSongsTitle.
  ///
  /// In en, this message translates to:
  /// **'Favorite Songs'**
  String get settingsPrivacyFavoriteSongsTitle;

  /// No description provided for @settingsPrivacyFavoriteSongsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show your favorite songs'**
  String get settingsPrivacyFavoriteSongsSubtitle;

  /// No description provided for @settingsPrivacySectionSocialTitle.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get settingsPrivacySectionSocialTitle;

  /// No description provided for @settingsPrivacySectionSocialSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Social information'**
  String get settingsPrivacySectionSocialSubtitle;

  /// No description provided for @settingsPrivacyLanguagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get settingsPrivacyLanguagesTitle;

  /// No description provided for @settingsPrivacyLanguagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show languages you speak'**
  String get settingsPrivacyLanguagesSubtitle;

  /// No description provided for @settingsPrivacySocialMediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Social Media'**
  String get settingsPrivacySocialMediaTitle;

  /// No description provided for @settingsPrivacySocialMediaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show your social media links'**
  String get settingsPrivacySocialMediaSubtitle;

  /// No description provided for @settingsPrivacySectionActivityStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity Status'**
  String get settingsPrivacySectionActivityStatusTitle;

  /// No description provided for @settingsPrivacySectionActivityStatusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Online presence'**
  String get settingsPrivacySectionActivityStatusSubtitle;

  /// No description provided for @settingsPrivacyOnlineStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Online Status'**
  String get settingsPrivacyOnlineStatusTitle;

  /// No description provided for @settingsPrivacyOnlineStatusSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show when you\'re online'**
  String get settingsPrivacyOnlineStatusSubtitle;

  /// No description provided for @settingsPrivacyLastActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Last Active'**
  String get settingsPrivacyLastActiveTitle;

  /// No description provided for @settingsPrivacyLastActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show when you were last active'**
  String get settingsPrivacyLastActiveSubtitle;

  /// No description provided for @settingsPrivacySensitiveBadge.
  ///
  /// In en, this message translates to:
  /// **'Sensitive'**
  String get settingsPrivacySensitiveBadge;

  /// No description provided for @settingsPrivacyInfoNote.
  ///
  /// In en, this message translates to:
  /// **'Hidden information will only be visible to you. Matches can see public information.'**
  String get settingsPrivacyInfoNote;

  /// No description provided for @accountActionsHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Your Account'**
  String get accountActionsHeaderTitle;

  /// No description provided for @accountActionsHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage security, password, and account status.'**
  String get accountActionsHeaderSubtitle;

  /// No description provided for @accountActionsSectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get accountActionsSectionSecurity;

  /// No description provided for @accountActionsPhoneVerifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Phone verified'**
  String get accountActionsPhoneVerifiedTitle;

  /// No description provided for @accountActionsPhoneVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify phone number'**
  String get accountActionsPhoneVerifyTitle;

  /// No description provided for @accountActionsPhoneAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add phone number'**
  String get accountActionsPhoneAddTitle;

  /// No description provided for @accountActionsPhoneVerifiedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your phone is verified and secured'**
  String get accountActionsPhoneVerifiedSubtitle;

  /// No description provided for @accountActionsPhoneVerifySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your phone for account security'**
  String get accountActionsPhoneVerifySubtitle;

  /// No description provided for @accountActionsChangePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get accountActionsChangePasswordSubtitle;

  /// No description provided for @accountActionsSectionAccountStatus.
  ///
  /// In en, this message translates to:
  /// **'Account Status'**
  String get accountActionsSectionAccountStatus;

  /// No description provided for @accountActionsSnoozeProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Snooze profile'**
  String get accountActionsSnoozeProfileTitle;

  /// No description provided for @accountActionsSnoozeProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hide profile but keep messaging active matches'**
  String get accountActionsSnoozeProfileSubtitle;

  /// No description provided for @accountActionsDeactivateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hide your profile temporarily'**
  String get accountActionsDeactivateSubtitle;

  /// No description provided for @accountActionsSectionDataPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Data & Privacy'**
  String get accountActionsSectionDataPrivacy;

  /// No description provided for @accountActionsExportDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Export your data'**
  String get accountActionsExportDataTitle;

  /// No description provided for @accountActionsExportDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download a copy of your personal data'**
  String get accountActionsExportDataSubtitle;

  /// No description provided for @accountActionsSectionDangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get accountActionsSectionDangerZone;

  /// No description provided for @accountActionsAboutDeactivationTitle.
  ///
  /// In en, this message translates to:
  /// **'About Deactivation'**
  String get accountActionsAboutDeactivationTitle;

  /// No description provided for @accountActionsAboutDeactivationBody.
  ///
  /// In en, this message translates to:
  /// **'When you deactivate your account, your profile will be hidden. You can reactivate anytime by signing back in. If you don\'t sign in for 6 months, your account will be permanently deleted.'**
  String get accountActionsAboutDeactivationBody;

  /// No description provided for @accountActionsAboutDeletionTitle.
  ///
  /// In en, this message translates to:
  /// **'About Deletion'**
  String get accountActionsAboutDeletionTitle;

  /// No description provided for @accountActionsAboutDeletionBody.
  ///
  /// In en, this message translates to:
  /// **'When you delete your account, you have 14 days to change your mind. Simply sign in within 14 days to recover your account. After 14 days, all your data will be permanently deleted.'**
  String get accountActionsAboutDeletionBody;

  /// No description provided for @accountActionsExportSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to export data.'**
  String get accountActionsExportSignInRequired;

  /// No description provided for @accountActionsExportNextAvailableOn.
  ///
  /// In en, this message translates to:
  /// **'You can request your next export on {date}.'**
  String accountActionsExportNextAvailableOn(String date);

  /// No description provided for @accountActionsExportFallbackEmail.
  ///
  /// In en, this message translates to:
  /// **'your email'**
  String get accountActionsExportFallbackEmail;

  /// No description provided for @accountActionsExportItemProfileMedia.
  ///
  /// In en, this message translates to:
  /// **'Profile, photos, and media'**
  String get accountActionsExportItemProfileMedia;

  /// No description provided for @accountActionsExportItemLikesMatches.
  ///
  /// In en, this message translates to:
  /// **'Likes and matches'**
  String get accountActionsExportItemLikesMatches;

  /// No description provided for @accountActionsExportItemMessagesMetadata.
  ///
  /// In en, this message translates to:
  /// **'Messages and chat metadata'**
  String get accountActionsExportItemMessagesMetadata;

  /// No description provided for @accountActionsExportItemPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences and account settings'**
  String get accountActionsExportItemPreferences;

  /// No description provided for @accountActionsExportRateLimitNotice.
  ///
  /// In en, this message translates to:
  /// **'This request is rate-limited to once every {days} days. We will notify you when export generation completes.'**
  String accountActionsExportRateLimitNotice(int days);

  /// No description provided for @accountActionsExportPrimaryContact.
  ///
  /// In en, this message translates to:
  /// **'Primary contact: {email}'**
  String accountActionsExportPrimaryContact(String email);

  /// No description provided for @accountActionsExportRequestedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data export requested. We will send a push notification when it is ready.'**
  String get accountActionsExportRequestedSuccess;

  /// No description provided for @accountActionsExportRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not request data export.'**
  String get accountActionsExportRequestFailed;

  /// No description provided for @accountActionsExportCloudUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Cloud export is not available in this environment. Generating local export now.'**
  String get accountActionsExportCloudUnavailable;

  /// No description provided for @accountActionsExportProgressStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting export...'**
  String get accountActionsExportProgressStarting;

  /// No description provided for @accountActionsExportProgressPercentComplete.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String accountActionsExportProgressPercentComplete(int percent);

  /// No description provided for @accountActionsExportGenerateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not generate data export. Please try again.'**
  String get accountActionsExportGenerateFailed;

  /// No description provided for @accountActionsExportCompletedNextRequest.
  ///
  /// In en, this message translates to:
  /// **'Data export request completed. Next request available in {days} days.'**
  String accountActionsExportCompletedNextRequest(int days);

  /// No description provided for @accountActionsChangePasswordPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password and choose a new one.'**
  String get accountActionsChangePasswordPrompt;

  /// No description provided for @accountActionsCurrentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get accountActionsCurrentPasswordLabel;

  /// No description provided for @accountActionsCurrentPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password'**
  String get accountActionsCurrentPasswordRequired;

  /// No description provided for @accountActionsNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get accountActionsNewPasswordLabel;

  /// No description provided for @accountActionsNewPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a new password'**
  String get accountActionsNewPasswordRequired;

  /// No description provided for @accountActionsNewPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get accountActionsNewPasswordMinLength;

  /// No description provided for @accountActionsNewPasswordMustDiffer.
  ///
  /// In en, this message translates to:
  /// **'New password must be different from current password'**
  String get accountActionsNewPasswordMustDiffer;

  /// No description provided for @accountActionsConfirmNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get accountActionsConfirmNewPasswordLabel;

  /// No description provided for @accountActionsConfirmNewPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Confirm your new password'**
  String get accountActionsConfirmNewPasswordRequired;

  /// No description provided for @accountActionsPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get accountActionsPasswordsDoNotMatch;

  /// No description provided for @accountActionsPasswordChangeFallbackError.
  ///
  /// In en, this message translates to:
  /// **'Could not change password. Please try again.'**
  String get accountActionsPasswordChangeFallbackError;

  /// No description provided for @accountActionsPasswordChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully!'**
  String get accountActionsPasswordChangedSuccess;

  /// No description provided for @accountActionsPasswordChangeFailed.
  ///
  /// In en, this message translates to:
  /// **'Password change failed.'**
  String get accountActionsPasswordChangeFailed;

  /// No description provided for @accountActionsGenericErrorTryAgain.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get accountActionsGenericErrorTryAgain;

  /// No description provided for @accountActionsDeactivateReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Why are you leaving?'**
  String get accountActionsDeactivateReasonTitle;

  /// No description provided for @accountActionsReasonTakingBreakFromDating.
  ///
  /// In en, this message translates to:
  /// **'Taking a break from dating'**
  String get accountActionsReasonTakingBreakFromDating;

  /// No description provided for @accountActionsReasonFoundSomeoneSpecial.
  ///
  /// In en, this message translates to:
  /// **'Found someone special'**
  String get accountActionsReasonFoundSomeoneSpecial;

  /// No description provided for @accountActionsReasonTooManyNotifications.
  ///
  /// In en, this message translates to:
  /// **'Too many notifications'**
  String get accountActionsReasonTooManyNotifications;

  /// No description provided for @accountActionsReasonNotFindingGoodMatches.
  ///
  /// In en, this message translates to:
  /// **'Not finding good matches'**
  String get accountActionsReasonNotFindingGoodMatches;

  /// No description provided for @accountActionsReasonPrivacyConcerns.
  ///
  /// In en, this message translates to:
  /// **'Privacy concerns'**
  String get accountActionsReasonPrivacyConcerns;

  /// No description provided for @accountActionsReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other reason'**
  String get accountActionsReasonOther;

  /// No description provided for @accountActionsDeactivateBulletHiddenFromDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Your profile will be hidden from discovery'**
  String get accountActionsDeactivateBulletHiddenFromDiscovery;

  /// No description provided for @accountActionsDeactivateBulletNoNewMatches.
  ///
  /// In en, this message translates to:
  /// **'You won\'t receive new matches'**
  String get accountActionsDeactivateBulletNoNewMatches;

  /// No description provided for @accountActionsDeactivateBulletKeepMatchesMessages.
  ///
  /// In en, this message translates to:
  /// **'Your existing matches and messages are preserved'**
  String get accountActionsDeactivateBulletKeepMatchesMessages;

  /// No description provided for @accountActionsDeactivateBulletReactivateAnytime.
  ///
  /// In en, this message translates to:
  /// **'You can reactivate anytime by signing in'**
  String get accountActionsDeactivateBulletReactivateAnytime;

  /// No description provided for @accountActionsDeactivateAutoDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'If you don\'t sign in for 6 months, your account will be permanently deleted.'**
  String get accountActionsDeactivateAutoDeleteWarning;

  /// No description provided for @accountActionsDeactivateFailedTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Could not deactivate account. Please try again.'**
  String get accountActionsDeactivateFailedTryAgain;

  /// No description provided for @accountActionsDeactivateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deactivated. Sign in anytime to reactivate.'**
  String get accountActionsDeactivateSuccess;

  /// No description provided for @accountActionsDeactivationFailed.
  ///
  /// In en, this message translates to:
  /// **'Deactivation failed.'**
  String get accountActionsDeactivationFailed;

  /// No description provided for @accountActionsDeleteSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to continue.'**
  String get accountActionsDeleteSignInRequired;

  /// No description provided for @accountActionsDeleteWarningMatches.
  ///
  /// In en, this message translates to:
  /// **'All your matches'**
  String get accountActionsDeleteWarningMatches;

  /// No description provided for @accountActionsDeleteWarningMessages.
  ///
  /// In en, this message translates to:
  /// **'All your messages'**
  String get accountActionsDeleteWarningMessages;

  /// No description provided for @accountActionsDeleteWarningProfile.
  ///
  /// In en, this message translates to:
  /// **'Your profile and photos'**
  String get accountActionsDeleteWarningProfile;

  /// No description provided for @accountActionsDeleteWarningSubscription.
  ///
  /// In en, this message translates to:
  /// **'Your subscription (if any)'**
  String get accountActionsDeleteWarningSubscription;

  /// No description provided for @accountActionsDeleteScheduledOn.
  ///
  /// In en, this message translates to:
  /// **'Deleted on {date}. Sign back in within 14 days to cancel.'**
  String accountActionsDeleteScheduledOn(String date);

  /// No description provided for @accountActionsDeleteReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Optional: Why are you deleting your account?'**
  String get accountActionsDeleteReasonTitle;

  /// No description provided for @accountActionsReasonFoundRelationship.
  ///
  /// In en, this message translates to:
  /// **'Found a relationship'**
  String get accountActionsReasonFoundRelationship;

  /// No description provided for @accountActionsReasonNotHappyWithApp.
  ///
  /// In en, this message translates to:
  /// **'Not happy with the app'**
  String get accountActionsReasonNotHappyWithApp;

  /// No description provided for @accountActionsReasonTooExpensive.
  ///
  /// In en, this message translates to:
  /// **'Too expensive'**
  String get accountActionsReasonTooExpensive;

  /// No description provided for @accountActionsReasonCreatingNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating a new account'**
  String get accountActionsReasonCreatingNewAccount;

  /// No description provided for @accountActionsDeleteNoReasonProvided.
  ///
  /// In en, this message translates to:
  /// **'No reason provided'**
  String get accountActionsDeleteNoReasonProvided;

  /// No description provided for @accountActionsDeleteTypeToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type \"{value}\" to confirm account deletion.'**
  String accountActionsDeleteTypeToConfirm(String value);

  /// No description provided for @accountActionsDeleteTypeUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Type username'**
  String get accountActionsDeleteTypeUsernameLabel;

  /// No description provided for @accountActionsDeletePasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get accountActionsDeletePasswordLabel;

  /// No description provided for @accountActionsDeleteFailedCheckPassword.
  ///
  /// In en, this message translates to:
  /// **'Could not delete account. Please check your password.'**
  String get accountActionsDeleteFailedCheckPassword;

  /// No description provided for @accountActionsDeleteScheduledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your account is scheduled for deletion on {date}. Sign in within 14 days to recover it.'**
  String accountActionsDeleteScheduledSuccess(String date);

  /// No description provided for @accountActionsDeletionFailed.
  ///
  /// In en, this message translates to:
  /// **'Deletion failed.'**
  String get accountActionsDeletionFailed;

  /// No description provided for @accountActionsReasonOtherHint.
  ///
  /// In en, this message translates to:
  /// **'Please tell us more...'**
  String get accountActionsReasonOtherHint;

  /// No description provided for @accountActionsReasonOtherPrefix.
  ///
  /// In en, this message translates to:
  /// **'Other: '**
  String get accountActionsReasonOtherPrefix;

  /// No description provided for @settingsSecurityProviderLinkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'{provider} linking is not available.'**
  String settingsSecurityProviderLinkUnavailable(String provider);

  /// No description provided for @settingsSecurityProviderLinkedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{provider} linked successfully.'**
  String settingsSecurityProviderLinkedSuccess(String provider);

  /// No description provided for @settingsSecurityProviderUnlinkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'{provider} unlink is not available.'**
  String settingsSecurityProviderUnlinkUnavailable(String provider);

  /// No description provided for @settingsSecurityProviderUnlinkedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{provider} unlinked successfully.'**
  String settingsSecurityProviderUnlinkedSuccess(String provider);

  /// No description provided for @settingsSecurityProviderAlreadyLinked.
  ///
  /// In en, this message translates to:
  /// **'{provider} is already linked.'**
  String settingsSecurityProviderAlreadyLinked(String provider);

  /// No description provided for @settingsSecurityProviderLinkedAnotherAccount.
  ///
  /// In en, this message translates to:
  /// **'{provider} is already linked to another account.'**
  String settingsSecurityProviderLinkedAnotherAccount(String provider);

  /// No description provided for @settingsSecurityProviderNotEnabledEnvironment.
  ///
  /// In en, this message translates to:
  /// **'{provider} is not enabled for this environment.'**
  String settingsSecurityProviderNotEnabledEnvironment(String provider);

  /// No description provided for @settingsSecurityProviderLinkCanceled.
  ///
  /// In en, this message translates to:
  /// **'{provider} linking was canceled.'**
  String settingsSecurityProviderLinkCanceled(String provider);

  /// No description provided for @settingsSecurityProviderUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update linked account.'**
  String get settingsSecurityProviderUpdateFailed;

  /// No description provided for @settingsSecurityHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Protect Your Account'**
  String get settingsSecurityHeaderTitle;

  /// No description provided for @settingsSecurityHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add extra layers of security to keep your account safe.'**
  String get settingsSecurityHeaderSubtitle;

  /// No description provided for @settingsSecurityPhoneNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Phone not verified'**
  String get settingsSecurityPhoneNotVerified;

  /// No description provided for @settingsSecurityNoPhoneAdded.
  ///
  /// In en, this message translates to:
  /// **'No phone added'**
  String get settingsSecurityNoPhoneAdded;

  /// No description provided for @settingsSecurityEmailProtectionLocked.
  ///
  /// In en, this message translates to:
  /// **'Email protection (Locked)'**
  String get settingsSecurityEmailProtectionLocked;

  /// No description provided for @settingsSecurityEmailProtection.
  ///
  /// In en, this message translates to:
  /// **'Email protection'**
  String get settingsSecurityEmailProtection;

  /// No description provided for @settingsSecurityVerifiedAndLocked.
  ///
  /// In en, this message translates to:
  /// **'Verified and locked'**
  String get settingsSecurityVerifiedAndLocked;

  /// No description provided for @settingsSecurityVerifyYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get settingsSecurityVerifyYourEmail;

  /// No description provided for @settingsSecurityAddEmailRecoveryOtp.
  ///
  /// In en, this message translates to:
  /// **'Add an email for recovery and OTP'**
  String get settingsSecurityAddEmailRecoveryOtp;

  /// No description provided for @settingsSecurityPhoneProtectionLocked.
  ///
  /// In en, this message translates to:
  /// **'Phone protection (Locked)'**
  String get settingsSecurityPhoneProtectionLocked;

  /// No description provided for @settingsSecurityPhoneProtection.
  ///
  /// In en, this message translates to:
  /// **'Phone protection'**
  String get settingsSecurityPhoneProtection;

  /// No description provided for @settingsSecurityVerifyYourPhone.
  ///
  /// In en, this message translates to:
  /// **'Verify your phone'**
  String get settingsSecurityVerifyYourPhone;

  /// No description provided for @settingsSecurityAddPhoneForSecurity.
  ///
  /// In en, this message translates to:
  /// **'Add a phone number for security'**
  String get settingsSecurityAddPhoneForSecurity;

  /// No description provided for @settingsSecurityBiometricLockTitle.
  ///
  /// In en, this message translates to:
  /// **'{biometric} Lock'**
  String settingsSecurityBiometricLockTitle(String biometric);

  /// No description provided for @settingsSecurityBiometricUnlockWith.
  ///
  /// In en, this message translates to:
  /// **'Unlock Crush with {biometric}'**
  String settingsSecurityBiometricUnlockWith(String biometric);

  /// No description provided for @settingsSecurityBiometricRequireToOpen.
  ///
  /// In en, this message translates to:
  /// **'Require {biometric} to open Crush'**
  String settingsSecurityBiometricRequireToOpen(String biometric);

  /// No description provided for @settingsSecurityLinkedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Linked Accounts'**
  String get settingsSecurityLinkedAccounts;

  /// No description provided for @settingsSecurityProviderEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get settingsSecurityProviderEmail;

  /// No description provided for @settingsSecurityProviderPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get settingsSecurityProviderPhone;

  /// No description provided for @settingsSecurityProviderGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get settingsSecurityProviderGoogle;

  /// No description provided for @settingsSecurityProviderApple.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get settingsSecurityProviderApple;

  /// No description provided for @settingsSecurityLinkedVerified.
  ///
  /// In en, this message translates to:
  /// **'Linked · Verified'**
  String get settingsSecurityLinkedVerified;

  /// No description provided for @settingsSecurityLinkedUnverified.
  ///
  /// In en, this message translates to:
  /// **'Linked · Unverified'**
  String get settingsSecurityLinkedUnverified;

  /// No description provided for @settingsSecurityNotLinked.
  ///
  /// In en, this message translates to:
  /// **'Not linked'**
  String get settingsSecurityNotLinked;

  /// No description provided for @settingsSecurityChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get settingsSecurityChecking;

  /// No description provided for @settingsSecurityActionManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get settingsSecurityActionManage;

  /// No description provided for @settingsSecurityActionLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get settingsSecurityActionLink;

  /// No description provided for @settingsSecurityActionLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked'**
  String get settingsSecurityActionLinked;

  /// No description provided for @settingsSecurityAddVerifyEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Add and verify an email in Email Protection.'**
  String get settingsSecurityAddVerifyEmailHint;

  /// No description provided for @settingsSecurityAddVerifyPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Add and verify a phone in Phone Protection.'**
  String get settingsSecurityAddVerifyPhoneHint;

  /// No description provided for @settingsSecurityTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Security tips'**
  String get settingsSecurityTipsTitle;

  /// No description provided for @settingsSecurityTipsUniquePassword.
  ///
  /// In en, this message translates to:
  /// **'Use a unique password for this app'**
  String get settingsSecurityTipsUniquePassword;

  /// No description provided for @settingsSecurityTipsEnableEmailRecovery.
  ///
  /// In en, this message translates to:
  /// **'Enable email verification for account recovery'**
  String get settingsSecurityTipsEnableEmailRecovery;

  /// No description provided for @settingsSecurityTipsNeverShareCodes.
  ///
  /// In en, this message translates to:
  /// **'Never share your verification codes'**
  String get settingsSecurityTipsNeverShareCodes;

  /// No description provided for @discoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoveryTitle;

  /// No description provided for @discoveryNoMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches yet'**
  String get discoveryNoMatchesTitle;

  /// No description provided for @discoveryNoMatchesMessage.
  ///
  /// In en, this message translates to:
  /// **'Keep swiping to find your perfect match!'**
  String get discoveryNoMatchesMessage;

  /// No description provided for @discoveryStartSwiping.
  ///
  /// In en, this message translates to:
  /// **'Start swiping'**
  String get discoveryStartSwiping;

  /// No description provided for @discoveryAdjustFilters.
  ///
  /// In en, this message translates to:
  /// **'Adjust filters'**
  String get discoveryAdjustFilters;

  /// No description provided for @discoveryAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get discoveryAllCaughtUp;

  /// No description provided for @discoveryNoMorePeople.
  ///
  /// In en, this message translates to:
  /// **'No more people nearby right now.\nCheck back soon or expand your search.'**
  String get discoveryNoMorePeople;

  /// No description provided for @discoveryViewFullProfile.
  ///
  /// In en, this message translates to:
  /// **'View full profile'**
  String get discoveryViewFullProfile;

  /// No description provided for @discoveryReportProfile.
  ///
  /// In en, this message translates to:
  /// **'Report profile'**
  String get discoveryReportProfile;

  /// No description provided for @discoveryBlockProfile.
  ///
  /// In en, this message translates to:
  /// **'Block & hide profile'**
  String get discoveryBlockProfile;

  /// No description provided for @discoveryUnmatch.
  ///
  /// In en, this message translates to:
  /// **'Unmatch'**
  String get discoveryUnmatch;

  /// No description provided for @discoveryLike.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get discoveryLike;

  /// No description provided for @discoveryPass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get discoveryPass;

  /// No description provided for @discoverySuperLike.
  ///
  /// In en, this message translates to:
  /// **'Super Like'**
  String get discoverySuperLike;

  /// No description provided for @discoveryRewind.
  ///
  /// In en, this message translates to:
  /// **'Rewind'**
  String get discoveryRewind;

  /// No description provided for @discoveryBoost.
  ///
  /// In en, this message translates to:
  /// **'Boost'**
  String get discoveryBoost;

  /// No description provided for @discoveryItsAMatch.
  ///
  /// In en, this message translates to:
  /// **'It\'s a Match!'**
  String get discoveryItsAMatch;

  /// No description provided for @discoveryMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'You and {name} liked each other'**
  String discoveryMatchMessage(String name);

  /// No description provided for @discoverySendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get discoverySendMessage;

  /// No description provided for @discoveryKeepSwiping.
  ///
  /// In en, this message translates to:
  /// **'Keep Swiping'**
  String get discoveryKeepSwiping;

  /// No description provided for @discoveryWeeklyPicks.
  ///
  /// In en, this message translates to:
  /// **'Weekly Picks'**
  String get discoveryWeeklyPicks;

  /// No description provided for @discoveryLikesYou.
  ///
  /// In en, this message translates to:
  /// **'Likes You'**
  String get discoveryLikesYou;

  /// No description provided for @discoveryTopPicks.
  ///
  /// In en, this message translates to:
  /// **'Top Picks'**
  String get discoveryTopPicks;

  /// No description provided for @discoveryNewArrivals.
  ///
  /// In en, this message translates to:
  /// **'New Arrivals'**
  String get discoveryNewArrivals;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatTitle;

  /// No description provided for @chatMatches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get chatMatches;

  /// No description provided for @chatMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get chatMessages;

  /// No description provided for @chatNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches yet'**
  String get chatNoMatches;

  /// No description provided for @chatNoMatchesMessage.
  ///
  /// In en, this message translates to:
  /// **'When you match with someone, they\'ll appear here'**
  String get chatNoMatchesMessage;

  /// No description provided for @chatNoMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get chatNoMessages;

  /// No description provided for @chatNoMessagesMessage.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation with one of your matches'**
  String get chatNoMessagesMessage;

  /// No description provided for @chatSayHello.
  ///
  /// In en, this message translates to:
  /// **'Say hello!'**
  String get chatSayHello;

  /// No description provided for @chatStartConversation.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation with {name}'**
  String chatStartConversation(String name);

  /// No description provided for @chatTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get chatTypeMessage;

  /// No description provided for @chatSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSend;

  /// No description provided for @chatToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get chatToday;

  /// No description provided for @chatYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get chatYesterday;

  /// No description provided for @chatOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get chatOnline;

  /// No description provided for @chatLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen {time}'**
  String chatLastSeen(String time);

  /// No description provided for @chatTyping.
  ///
  /// In en, this message translates to:
  /// **'typing...'**
  String get chatTyping;

  /// No description provided for @chatDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get chatDelivered;

  /// No description provided for @chatRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get chatRead;

  /// No description provided for @chatDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete message'**
  String get chatDeleteMessage;

  /// No description provided for @chatDeleteForMe.
  ///
  /// In en, this message translates to:
  /// **'Delete for me'**
  String get chatDeleteForMe;

  /// No description provided for @chatDeleteForEveryone.
  ///
  /// In en, this message translates to:
  /// **'Delete for everyone'**
  String get chatDeleteForEveryone;

  /// No description provided for @chatCopyMessage.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get chatCopyMessage;

  /// No description provided for @chatReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get chatReply;

  /// No description provided for @chatNewMatch.
  ///
  /// In en, this message translates to:
  /// **'New match!'**
  String get chatNewMatch;

  /// No description provided for @chatMatchedWith.
  ///
  /// In en, this message translates to:
  /// **'You matched with {name}'**
  String chatMatchedWith(String name);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEdit;

  /// No description provided for @profileComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get profileComplete;

  /// No description provided for @profileBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get profileBasicInfo;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileName;

  /// No description provided for @profileAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get profileAge;

  /// No description provided for @profileBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get profileBirthday;

  /// No description provided for @profileGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get profileGender;

  /// No description provided for @profileSexualOrientation.
  ///
  /// In en, this message translates to:
  /// **'Sexual orientation'**
  String get profileSexualOrientation;

  /// No description provided for @profileBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get profileBio;

  /// No description provided for @profileBioHint.
  ///
  /// In en, this message translates to:
  /// **'Tell others about yourself...'**
  String get profileBioHint;

  /// No description provided for @profilePhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get profilePhotos;

  /// No description provided for @profileAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get profileAddPhoto;

  /// No description provided for @profileAddVideo.
  ///
  /// In en, this message translates to:
  /// **'Add video'**
  String get profileAddVideo;

  /// No description provided for @profileMakeMain.
  ///
  /// In en, this message translates to:
  /// **'Make main photo'**
  String get profileMakeMain;

  /// No description provided for @profileInterests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get profileInterests;

  /// No description provided for @profileAddInterests.
  ///
  /// In en, this message translates to:
  /// **'Add interests'**
  String get profileAddInterests;

  /// No description provided for @profileLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get profileLocation;

  /// No description provided for @profileCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get profileCity;

  /// No description provided for @profileCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get profileCountry;

  /// No description provided for @profileLivingIn.
  ///
  /// In en, this message translates to:
  /// **'Living in'**
  String get profileLivingIn;

  /// No description provided for @profileJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job title'**
  String get profileJobTitle;

  /// No description provided for @profileCompany.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get profileCompany;

  /// No description provided for @profileSchool.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get profileSchool;

  /// No description provided for @profileHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get profileHeight;

  /// No description provided for @profileHeightCm.
  ///
  /// In en, this message translates to:
  /// **'{height} cm'**
  String profileHeightCm(int height);

  /// No description provided for @profileLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get profileLanguages;

  /// No description provided for @profileZodiacSign.
  ///
  /// In en, this message translates to:
  /// **'Zodiac sign'**
  String get profileZodiacSign;

  /// No description provided for @profileEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get profileEducation;

  /// No description provided for @profileReligion.
  ///
  /// In en, this message translates to:
  /// **'Religion'**
  String get profileReligion;

  /// No description provided for @profileRelationshipGoals.
  ///
  /// In en, this message translates to:
  /// **'Relationship goals'**
  String get profileRelationshipGoals;

  /// No description provided for @profileFamilyPlans.
  ///
  /// In en, this message translates to:
  /// **'Family plans'**
  String get profileFamilyPlans;

  /// No description provided for @profilePersonalityType.
  ///
  /// In en, this message translates to:
  /// **'Personality type'**
  String get profilePersonalityType;

  /// No description provided for @profileWorkout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get profileWorkout;

  /// No description provided for @profileSmoking.
  ///
  /// In en, this message translates to:
  /// **'Smoking'**
  String get profileSmoking;

  /// No description provided for @profileDrinking.
  ///
  /// In en, this message translates to:
  /// **'Drinking'**
  String get profileDrinking;

  /// No description provided for @profilePets.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get profilePets;

  /// No description provided for @profileVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get profileVerified;

  /// No description provided for @profileGetVerified.
  ///
  /// In en, this message translates to:
  /// **'Get verified'**
  String get profileGetVerified;

  /// No description provided for @profileVerificationPending.
  ///
  /// In en, this message translates to:
  /// **'Verification pending'**
  String get profileVerificationPending;

  /// No description provided for @profilePreview.
  ///
  /// In en, this message translates to:
  /// **'Preview profile'**
  String get profilePreview;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved successfully!'**
  String get profileSaved;

  /// No description provided for @profilePrompts.
  ///
  /// In en, this message translates to:
  /// **'Prompts'**
  String get profilePrompts;

  /// No description provided for @profileAddPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add a prompt'**
  String get profileAddPrompt;

  /// No description provided for @profileAboutMe.
  ///
  /// In en, this message translates to:
  /// **'About Me'**
  String get profileAboutMe;

  /// No description provided for @profileMyDetails.
  ///
  /// In en, this message translates to:
  /// **'My Details'**
  String get profileMyDetails;

  /// No description provided for @profileLifestyle.
  ///
  /// In en, this message translates to:
  /// **'Lifestyle'**
  String get profileLifestyle;

  /// No description provided for @onboardingWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Crush'**
  String get onboardingWelcome;

  /// No description provided for @onboardingTagline.
  ///
  /// In en, this message translates to:
  /// **'Find your perfect match'**
  String get onboardingTagline;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingStep.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String onboardingStep(int current, int total);

  /// No description provided for @onboardingProgressNextStep.
  ///
  /// In en, this message translates to:
  /// **'Next: {step}'**
  String onboardingProgressNextStep(String step);

  /// No description provided for @onboardingProgressAlmostDone.
  ///
  /// In en, this message translates to:
  /// **'Almost done'**
  String get onboardingProgressAlmostDone;

  /// No description provided for @onboardingProgressSkipStep.
  ///
  /// In en, this message translates to:
  /// **'Skip this step'**
  String get onboardingProgressSkipStep;

  /// No description provided for @onboardingStepWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get onboardingStepWelcome;

  /// No description provided for @onboardingStepVerifyPhone.
  ///
  /// In en, this message translates to:
  /// **'Verify phone'**
  String get onboardingStepVerifyPhone;

  /// No description provided for @onboardingStepEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter code'**
  String get onboardingStepEnterCode;

  /// No description provided for @onboardingStepBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic info'**
  String get onboardingStepBasicInfo;

  /// No description provided for @onboardingStepVerifyId.
  ///
  /// In en, this message translates to:
  /// **'Verify ID'**
  String get onboardingStepVerifyId;

  /// No description provided for @onboardingStepProfileSetup.
  ///
  /// In en, this message translates to:
  /// **'Profile setup'**
  String get onboardingStepProfileSetup;

  /// No description provided for @commonPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get commonPrevious;

  /// No description provided for @onboardingWhatsYourName.
  ///
  /// In en, this message translates to:
  /// **'What\'s your name?'**
  String get onboardingWhatsYourName;

  /// No description provided for @onboardingWhenBirthday.
  ///
  /// In en, this message translates to:
  /// **'When\'s your birthday?'**
  String get onboardingWhenBirthday;

  /// No description provided for @onboardingSelectGender.
  ///
  /// In en, this message translates to:
  /// **'Select your gender'**
  String get onboardingSelectGender;

  /// No description provided for @onboardingBasicInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get onboardingBasicInfoTitle;

  /// No description provided for @onboardingBasicInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us about you'**
  String get onboardingBasicInfoSubtitle;

  /// No description provided for @onboardingBasicInfoUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get onboardingBasicInfoUsernameLabel;

  /// No description provided for @onboardingBasicInfoUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a unique username'**
  String get onboardingBasicInfoUsernameHint;

  /// No description provided for @onboardingBasicInfoFirstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your First Name'**
  String get onboardingBasicInfoFirstNameLabel;

  /// No description provided for @onboardingBasicInfoFirstNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your first name'**
  String get onboardingBasicInfoFirstNameHint;

  /// No description provided for @onboardingBasicInfoLastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get onboardingBasicInfoLastNameLabel;

  /// No description provided for @onboardingBasicInfoLastNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your last name (optional)'**
  String get onboardingBasicInfoLastNameHint;

  /// No description provided for @onboardingBasicInfoBirthdateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get onboardingBasicInfoBirthdateLabel;

  /// No description provided for @onboardingBasicInfoSelectBirthdate.
  ///
  /// In en, this message translates to:
  /// **'Select your birthdate'**
  String get onboardingBasicInfoSelectBirthdate;

  /// No description provided for @onboardingBasicInfoBirthdateHelpText.
  ///
  /// In en, this message translates to:
  /// **'Select your birthdate'**
  String get onboardingBasicInfoBirthdateHelpText;

  /// No description provided for @onboardingBasicInfoYearsOld.
  ///
  /// In en, this message translates to:
  /// **'{age} years old'**
  String onboardingBasicInfoYearsOld(int age);

  /// No description provided for @onboardingBasicInfoUsernameCheckingAvailability.
  ///
  /// In en, this message translates to:
  /// **'Checking username availability...'**
  String get onboardingBasicInfoUsernameCheckingAvailability;

  /// No description provided for @onboardingBasicInfoUsernameAvailable.
  ///
  /// In en, this message translates to:
  /// **'Username is available'**
  String get onboardingBasicInfoUsernameAvailable;

  /// No description provided for @onboardingBasicInfoUsernameRules.
  ///
  /// In en, this message translates to:
  /// **'3-20 characters, letters, numbers, or underscore'**
  String get onboardingBasicInfoUsernameRules;

  /// No description provided for @onboardingBasicInfoUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a username to continue'**
  String get onboardingBasicInfoUsernameRequired;

  /// No description provided for @onboardingBasicInfoUsernameFormatError.
  ///
  /// In en, this message translates to:
  /// **'Use 3-20 letters, numbers, or underscore'**
  String get onboardingBasicInfoUsernameFormatError;

  /// No description provided for @onboardingBasicInfoUsernameTaken.
  ///
  /// In en, this message translates to:
  /// **'This username is already taken'**
  String get onboardingBasicInfoUsernameTaken;

  /// No description provided for @onboardingBasicInfoBirthdateRequired.
  ///
  /// In en, this message translates to:
  /// **'Select your date of birth'**
  String get onboardingBasicInfoBirthdateRequired;

  /// No description provided for @onboardingBasicInfoBirthdateInvalid.
  ///
  /// In en, this message translates to:
  /// **'Select a valid date'**
  String get onboardingBasicInfoBirthdateInvalid;

  /// No description provided for @onboardingBasicInfoBirthdateTooYoung.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 18 years old'**
  String get onboardingBasicInfoBirthdateTooYoung;

  /// No description provided for @onboardingBasicInfoBirthdateTooOld.
  ///
  /// In en, this message translates to:
  /// **'Maximum age allowed is 75'**
  String get onboardingBasicInfoBirthdateTooOld;

  /// No description provided for @onboardingBasicInfoOrientationOptionalSemantics.
  ///
  /// In en, this message translates to:
  /// **'Orientation is optional. You can skip this for now.'**
  String get onboardingBasicInfoOrientationOptionalSemantics;

  /// No description provided for @onboardingBasicInfoOrientationOptionalHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional - skip for now, add later in Settings'**
  String get onboardingBasicInfoOrientationOptionalHelper;

  /// No description provided for @onboardingBasicInfoAgeWarningBody.
  ///
  /// In en, this message translates to:
  /// **'You\'re a bit too old to be using a dating app, don\'t you think?\n\nJust kidding! Love has no age limit. Are you sure you want to continue?'**
  String get onboardingBasicInfoAgeWarningBody;

  /// No description provided for @onboardingEmailVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get onboardingEmailVerificationTitle;

  /// No description provided for @onboardingEmailVerificationSentTo.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a verification link to:'**
  String get onboardingEmailVerificationSentTo;

  /// No description provided for @onboardingEmailVerificationFallbackEmail.
  ///
  /// In en, this message translates to:
  /// **'your email'**
  String get onboardingEmailVerificationFallbackEmail;

  /// No description provided for @onboardingEmailVerificationInstruction.
  ///
  /// In en, this message translates to:
  /// **'Click the link in the email to verify your account and continue.'**
  String get onboardingEmailVerificationInstruction;

  /// No description provided for @onboardingEmailVerificationSent.
  ///
  /// In en, this message translates to:
  /// **'Verification email sent! Check your inbox.'**
  String get onboardingEmailVerificationSent;

  /// No description provided for @onboardingEmailVerificationSuccessRedirecting.
  ///
  /// In en, this message translates to:
  /// **'Email verified successfully! Redirecting...'**
  String get onboardingEmailVerificationSuccessRedirecting;

  /// No description provided for @onboardingEmailVerificationTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait about a minute and try again.'**
  String get onboardingEmailVerificationTooManyAttempts;

  /// No description provided for @onboardingEmailVerificationSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send email. Please try again.'**
  String get onboardingEmailVerificationSendFailed;

  /// No description provided for @onboardingEmailVerificationCheckingStatus.
  ///
  /// In en, this message translates to:
  /// **'Checking verification status...'**
  String get onboardingEmailVerificationCheckingStatus;

  /// No description provided for @onboardingEmailVerificationResendSemantics.
  ///
  /// In en, this message translates to:
  /// **'Resend verification email'**
  String get onboardingEmailVerificationResendSemantics;

  /// No description provided for @onboardingEmailVerificationResendButton.
  ///
  /// In en, this message translates to:
  /// **'Resend Verification Email'**
  String get onboardingEmailVerificationResendButton;

  /// No description provided for @onboardingEmailVerificationResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String onboardingEmailVerificationResendIn(int seconds);

  /// No description provided for @onboardingEmailVerificationCheckNowSemantics.
  ///
  /// In en, this message translates to:
  /// **'I have verified, check now'**
  String get onboardingEmailVerificationCheckNowSemantics;

  /// No description provided for @onboardingEmailVerificationCheckNowButton.
  ///
  /// In en, this message translates to:
  /// **'I\'ve Verified - Check Now'**
  String get onboardingEmailVerificationCheckNowButton;

  /// No description provided for @onboardingEmailVerificationAutoCheckStopped.
  ///
  /// In en, this message translates to:
  /// **'Auto-check stopped after {minutes} minutes. Tap \"I\'ve Verified\" to check manually.'**
  String onboardingEmailVerificationAutoCheckStopped(int minutes);

  /// No description provided for @onboardingOrientationOptionalPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select orientation (optional)'**
  String get onboardingOrientationOptionalPrompt;

  /// No description provided for @onboardingAddPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add your best photos'**
  String get onboardingAddPhotos;

  /// No description provided for @onboardingPhotosHint.
  ///
  /// In en, this message translates to:
  /// **'Add at least 2 photos to continue'**
  String get onboardingPhotosHint;

  /// No description provided for @onboardingWriteBio.
  ///
  /// In en, this message translates to:
  /// **'Write something about yourself'**
  String get onboardingWriteBio;

  /// No description provided for @onboardingSelectInterests.
  ///
  /// In en, this message translates to:
  /// **'Select your interests'**
  String get onboardingSelectInterests;

  /// No description provided for @onboardingInterestsHint.
  ///
  /// In en, this message translates to:
  /// **'Choose at least 3 interests'**
  String get onboardingInterestsHint;

  /// No description provided for @onboardingAllSet.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set!'**
  String get onboardingAllSet;

  /// No description provided for @onboardingStartSwiping.
  ///
  /// In en, this message translates to:
  /// **'Start swiping'**
  String get onboardingStartSwiping;

  /// No description provided for @onboardingTermsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save. Please try again.'**
  String get onboardingTermsSaveFailed;

  /// No description provided for @onboardingTermsReadAndAccept.
  ///
  /// In en, this message translates to:
  /// **'Please read and accept'**
  String get onboardingTermsReadAndAccept;

  /// No description provided for @onboardingTermsScrollToContinue.
  ///
  /// In en, this message translates to:
  /// **'Scroll to continue'**
  String get onboardingTermsScrollToContinue;

  /// No description provided for @onboardingTermsWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Crush'**
  String get onboardingTermsWelcomeTitle;

  /// No description provided for @onboardingTermsWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'By using our dating app, you agree to these Terms and Conditions. Please read them carefully before proceeding.'**
  String get onboardingTermsWelcomeBody;

  /// No description provided for @onboardingTermsEligibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'1. Eligibility'**
  String get onboardingTermsEligibilityTitle;

  /// No description provided for @onboardingTermsEligibilityBody.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 18 years old to use Crush. By creating an account, you confirm that you are of legal age and have the right to enter into this agreement.'**
  String get onboardingTermsEligibilityBody;

  /// No description provided for @onboardingTermsAccountSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'2. Account Security'**
  String get onboardingTermsAccountSecurityTitle;

  /// No description provided for @onboardingTermsAccountSecurityBody.
  ///
  /// In en, this message translates to:
  /// **'You are responsible for maintaining the confidentiality of your account credentials. Notify us immediately if you suspect unauthorized access to your account.'**
  String get onboardingTermsAccountSecurityBody;

  /// No description provided for @onboardingTermsUserConductTitle.
  ///
  /// In en, this message translates to:
  /// **'3. User Conduct'**
  String get onboardingTermsUserConductTitle;

  /// No description provided for @onboardingTermsUserConductBody.
  ///
  /// In en, this message translates to:
  /// **'You agree to:\n• Provide accurate information\n• Treat other users with respect\n• Not engage in harassment, hate speech, or illegal activities\n• Not impersonate others or create fake profiles\n• Not share inappropriate or explicit content'**
  String get onboardingTermsUserConductBody;

  /// No description provided for @onboardingTermsPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'4. Privacy'**
  String get onboardingTermsPrivacyTitle;

  /// No description provided for @onboardingTermsPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'Your privacy is important to us. We collect and process your personal data in accordance with our Privacy Policy. By using Crush, you consent to our data practices as described in the Privacy Policy.'**
  String get onboardingTermsPrivacyBody;

  /// No description provided for @onboardingTermsContentOwnershipTitle.
  ///
  /// In en, this message translates to:
  /// **'5. Content Ownership'**
  String get onboardingTermsContentOwnershipTitle;

  /// No description provided for @onboardingTermsContentOwnershipBody.
  ///
  /// In en, this message translates to:
  /// **'You retain ownership of content you post. However, you grant Crush a non-exclusive license to use, display, and distribute your content within the app for the purpose of providing our services.'**
  String get onboardingTermsContentOwnershipBody;

  /// No description provided for @onboardingTermsSafetyTitle.
  ///
  /// In en, this message translates to:
  /// **'6. Safety'**
  String get onboardingTermsSafetyTitle;

  /// No description provided for @onboardingTermsSafetyBody.
  ///
  /// In en, this message translates to:
  /// **'While we implement safety measures, you are responsible for your own safety when meeting people from the app. We recommend meeting in public places and informing someone you trust about your plans.'**
  String get onboardingTermsSafetyBody;

  /// No description provided for @onboardingTermsTerminationTitle.
  ///
  /// In en, this message translates to:
  /// **'7. Termination'**
  String get onboardingTermsTerminationTitle;

  /// No description provided for @onboardingTermsTerminationBody.
  ///
  /// In en, this message translates to:
  /// **'We reserve the right to suspend or terminate your account if you violate these terms. You may also delete your account at any time through the app settings.'**
  String get onboardingTermsTerminationBody;

  /// No description provided for @onboardingTermsDisclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'8. Disclaimer'**
  String get onboardingTermsDisclaimerTitle;

  /// No description provided for @onboardingTermsDisclaimerBody.
  ///
  /// In en, this message translates to:
  /// **'Crush is provided \"as is\" without warranties. We do not guarantee that you will find a match or that other users\' information is accurate.'**
  String get onboardingTermsDisclaimerBody;

  /// No description provided for @onboardingTermsChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'9. Changes to Terms'**
  String get onboardingTermsChangesTitle;

  /// No description provided for @onboardingTermsChangesBody.
  ///
  /// In en, this message translates to:
  /// **'We may update these terms from time to time. Continued use of the app after changes constitutes acceptance of the new terms.'**
  String get onboardingTermsChangesBody;

  /// No description provided for @onboardingTermsContactTitle.
  ///
  /// In en, this message translates to:
  /// **'10. Contact'**
  String get onboardingTermsContactTitle;

  /// No description provided for @onboardingTermsContactBody.
  ///
  /// In en, this message translates to:
  /// **'If you have questions about these terms, please contact us through the app\'s support feature or email support@crushhour.app.'**
  String get onboardingTermsContactBody;

  /// No description provided for @onboardingTermsEndLabel.
  ///
  /// In en, this message translates to:
  /// **'End of Terms'**
  String get onboardingTermsEndLabel;

  /// No description provided for @onboardingTermsAgreementLabel.
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to the Terms and Conditions and Privacy Policy'**
  String get onboardingTermsAgreementLabel;

  /// No description provided for @onboardingTermsAgreementToggleHint.
  ///
  /// In en, this message translates to:
  /// **'Double tap to toggle agreement'**
  String get onboardingTermsAgreementToggleHint;

  /// No description provided for @onboardingTermsContinueSemantics.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingTermsContinueSemantics;

  /// No description provided for @onboardingTermsScrollHint.
  ///
  /// In en, this message translates to:
  /// **'Please scroll down to read all terms before agreeing'**
  String get onboardingTermsScrollHint;

  /// No description provided for @onboardingSignUpPhoneCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Code sent. Check your messages.'**
  String get onboardingSignUpPhoneCodeSent;

  /// No description provided for @onboardingSignUpContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get onboardingSignUpContinueWithGoogle;

  /// No description provided for @onboardingSignUpOrSignUpWithEmail.
  ///
  /// In en, this message translates to:
  /// **'or sign up with email'**
  String get onboardingSignUpOrSignUpWithEmail;

  /// No description provided for @onboardingSignUpOrSignUpWith.
  ///
  /// In en, this message translates to:
  /// **'or sign up with'**
  String get onboardingSignUpOrSignUpWith;

  /// No description provided for @onboardingSignUpPhoneErrorRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get onboardingSignUpPhoneErrorRequired;

  /// No description provided for @onboardingSignUpPhoneErrorMinDigits.
  ///
  /// In en, this message translates to:
  /// **'Add at least 6 digits'**
  String get onboardingSignUpPhoneErrorMinDigits;

  /// No description provided for @onboardingSignUpOtpErrorRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code'**
  String get onboardingSignUpOtpErrorRequired;

  /// No description provided for @onboardingSignUpOtpErrorInvalidLength.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get onboardingSignUpOtpErrorInvalidLength;

  /// No description provided for @onboardingSignUpWaitBeforeRequestingCode.
  ///
  /// In en, this message translates to:
  /// **'Please wait {seconds}s before requesting another code.'**
  String onboardingSignUpWaitBeforeRequestingCode(int seconds);

  /// No description provided for @onboardingSignUpPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number.'**
  String get onboardingSignUpPhoneInvalid;

  /// No description provided for @onboardingSignUpWaitBeforeResendingEmail.
  ///
  /// In en, this message translates to:
  /// **'Please wait {seconds}s before resending the verification email.'**
  String onboardingSignUpWaitBeforeResendingEmail(int seconds);

  /// No description provided for @onboardingSignUpUsernameRequired.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get onboardingSignUpUsernameRequired;

  /// No description provided for @onboardingSignUpEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get onboardingSignUpEmailRequired;

  /// No description provided for @onboardingSignUpGoogleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In failed. Please try again.'**
  String get onboardingSignUpGoogleSignInFailed;

  /// No description provided for @onboardingSignUpInvalidUsernameFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid username format'**
  String get onboardingSignUpInvalidUsernameFormat;

  /// No description provided for @onboardingSignUpInvalidEmailFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get onboardingSignUpInvalidEmailFormat;

  /// No description provided for @onboardingSignUpPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please create a password'**
  String get onboardingSignUpPasswordRequired;

  /// No description provided for @onboardingSignUpPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get onboardingSignUpPasswordMinLength;

  /// No description provided for @onboardingSignUpCompleteRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please complete all required fields: {fields}'**
  String onboardingSignUpCompleteRequiredFields(String fields);

  /// No description provided for @onboardingSignUpEmailAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists. Please sign in instead, or use a different email address.'**
  String get onboardingSignUpEmailAlreadyExists;

  /// No description provided for @onboardingSignUpAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created! Welcome to Crush.'**
  String get onboardingSignUpAccountCreated;

  /// No description provided for @onboardingSignUpSendVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send verification email. Please try again.'**
  String get onboardingSignUpSendVerificationFailed;

  /// No description provided for @onboardingSignUpRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Request failed.'**
  String get onboardingSignUpRequestFailed;

  /// No description provided for @onboardingSignUpVerificationEmailResent.
  ///
  /// In en, this message translates to:
  /// **'Verification email resent successfully.'**
  String get onboardingSignUpVerificationEmailResent;

  /// No description provided for @onboardingSignUpVerificationEmailSent.
  ///
  /// In en, this message translates to:
  /// **'A verification email has been sent to your inbox.'**
  String get onboardingSignUpVerificationEmailSent;

  /// No description provided for @onboardingSignUpOpenEmailAppFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open email app. Please check your email manually.'**
  String get onboardingSignUpOpenEmailAppFailed;

  /// No description provided for @onboardingSignUpCheckEmailStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not verify email status.'**
  String get onboardingSignUpCheckEmailStatusFailed;

  /// No description provided for @onboardingSignUpEmailVerifiedWelcome.
  ///
  /// In en, this message translates to:
  /// **'Email verified! Welcome to Crush.'**
  String get onboardingSignUpEmailVerifiedWelcome;

  /// No description provided for @onboardingSignUpEmailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Email not verified yet. Please click the link in your email, then try again.'**
  String get onboardingSignUpEmailNotVerified;

  /// No description provided for @onboardingSignUpPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String onboardingSignUpPercent(int percent);

  /// No description provided for @onboardingSignUpStepOne.
  ///
  /// In en, this message translates to:
  /// **'Step 1'**
  String get onboardingSignUpStepOne;

  /// No description provided for @onboardingSignUpChooseUsername.
  ///
  /// In en, this message translates to:
  /// **'Choose your username'**
  String get onboardingSignUpChooseUsername;

  /// No description provided for @onboardingSignUpUsernameDescription.
  ///
  /// In en, this message translates to:
  /// **'This is how others will find you on Crush.'**
  String get onboardingSignUpUsernameDescription;

  /// No description provided for @onboardingSignUpUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., john_doe123'**
  String get onboardingSignUpUsernameHint;

  /// No description provided for @onboardingSignUpUsernameRules.
  ///
  /// In en, this message translates to:
  /// **'3-20 characters, letters, numbers, and underscore only'**
  String get onboardingSignUpUsernameRules;

  /// No description provided for @onboardingSignUpEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your email?'**
  String get onboardingSignUpEmailTitle;

  /// No description provided for @onboardingSignUpBypassHint.
  ///
  /// In en, this message translates to:
  /// **'Test mode: verification is disabled.'**
  String get onboardingSignUpBypassHint;

  /// No description provided for @onboardingSignUpEmailHint.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send you a verification link to confirm your email.'**
  String get onboardingSignUpEmailHint;

  /// No description provided for @onboardingSignUpEmailAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get onboardingSignUpEmailAddressLabel;

  /// No description provided for @onboardingSignUpEmailAddressHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get onboardingSignUpEmailAddressHint;

  /// No description provided for @onboardingSignUpPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get onboardingSignUpPasswordTitle;

  /// No description provided for @onboardingSignUpPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'Make it strong with at least 8 characters.'**
  String get onboardingSignUpPasswordDescription;

  /// No description provided for @onboardingSignUpMissingRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Missing required fields: {fields}. Go back to fill them before creating your account.'**
  String onboardingSignUpMissingRequiredFields(String fields);

  /// No description provided for @onboardingSignUpEmailInstructionOpenInbox.
  ///
  /// In en, this message translates to:
  /// **'Open your email inbox'**
  String get onboardingSignUpEmailInstructionOpenInbox;

  /// No description provided for @onboardingSignUpEmailInstructionFindEmail.
  ///
  /// In en, this message translates to:
  /// **'Find the email from Crush'**
  String get onboardingSignUpEmailInstructionFindEmail;

  /// No description provided for @onboardingSignUpEmailInstructionClickLink.
  ///
  /// In en, this message translates to:
  /// **'Click the verification link'**
  String get onboardingSignUpEmailInstructionClickLink;

  /// No description provided for @onboardingSignUpEmailIgnoreNotice.
  ///
  /// In en, this message translates to:
  /// **'If you didn\'t request this, please ignore the email.'**
  String get onboardingSignUpEmailIgnoreNotice;

  /// No description provided for @onboardingSignUpDidntReceiveEmailResend.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive email? Resend'**
  String get onboardingSignUpDidntReceiveEmailResend;

  /// No description provided for @onboardingSignUpCheckSpam.
  ///
  /// In en, this message translates to:
  /// **'Check your spam folder if you don\'t see it'**
  String get onboardingSignUpCheckSpam;

  /// No description provided for @onboardingSignUpPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get onboardingSignUpPhoneTitle;

  /// No description provided for @onboardingSignUpPhoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send you a code to verify your account.'**
  String get onboardingSignUpPhoneSubtitle;

  /// No description provided for @onboardingSignUpCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get onboardingSignUpCodeLabel;

  /// No description provided for @onboardingSignUpPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'(555) 123-4567'**
  String get onboardingSignUpPhoneHint;

  /// No description provided for @onboardingSignUpSmsRates.
  ///
  /// In en, this message translates to:
  /// **'SMS rates may apply. We only use this to secure your account.'**
  String get onboardingSignUpSmsRates;

  /// No description provided for @onboardingSignUpOtpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter verification code'**
  String get onboardingSignUpOtpTitle;

  /// No description provided for @onboardingSignUpOtpSentTo.
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {phoneNumber}'**
  String onboardingSignUpOtpSentTo(String phoneNumber);

  /// No description provided for @onboardingSignUpVerificationCodeHint.
  ///
  /// In en, this message translates to:
  /// **'000000'**
  String get onboardingSignUpVerificationCodeHint;

  /// No description provided for @onboardingSignUpDidntReceiveCodeResend.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive code? Resend'**
  String get onboardingSignUpDidntReceiveCodeResend;

  /// No description provided for @onboardingSignUpPasswordStrengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get onboardingSignUpPasswordStrengthWeak;

  /// No description provided for @onboardingSignUpPasswordStrengthFair.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get onboardingSignUpPasswordStrengthFair;

  /// No description provided for @onboardingSignUpPasswordStrengthGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get onboardingSignUpPasswordStrengthGood;

  /// No description provided for @onboardingSignUpPasswordStrengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get onboardingSignUpPasswordStrengthStrong;

  /// No description provided for @onboardingProfileLocationRationaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Find matches near you'**
  String get onboardingProfileLocationRationaleTitle;

  /// No description provided for @onboardingProfileLocationRationaleDescription.
  ///
  /// In en, this message translates to:
  /// **'Crush uses your location to show you people nearby. Your exact location is never shared with other users.'**
  String get onboardingProfileLocationRationaleDescription;

  /// No description provided for @onboardingProfileSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'You need to be signed in to continue.'**
  String get onboardingProfileSignInRequired;

  /// No description provided for @onboardingProfileAllFieldsOptional.
  ///
  /// In en, this message translates to:
  /// **'All fields are optional. You can complete your profile later in Settings.'**
  String get onboardingProfileAllFieldsOptional;

  /// No description provided for @onboardingProfileYourPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Photos'**
  String get onboardingProfileYourPhotosTitle;

  /// No description provided for @onboardingProfileYourPhotosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional - helps you get more matches'**
  String get onboardingProfileYourPhotosSubtitle;

  /// No description provided for @onboardingProfileAboutYouSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell others about yourself'**
  String get onboardingProfileAboutYouSubtitle;

  /// No description provided for @onboardingProfileLookingForTitle.
  ///
  /// In en, this message translates to:
  /// **'I Am Looking For'**
  String get onboardingProfileLookingForTitle;

  /// No description provided for @onboardingProfileLookingForSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Who would you like to see?'**
  String get onboardingProfileLookingForSubtitle;

  /// No description provided for @onboardingProfileLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where are you based?'**
  String get onboardingProfileLocationSubtitle;

  /// No description provided for @onboardingProfileWorkEducationTitle.
  ///
  /// In en, this message translates to:
  /// **'Work & Education'**
  String get onboardingProfileWorkEducationTitle;

  /// No description provided for @onboardingProfileOptionalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get onboardingProfileOptionalSubtitle;

  /// No description provided for @onboardingProfileSchoolUniversity.
  ///
  /// In en, this message translates to:
  /// **'School / University'**
  String get onboardingProfileSchoolUniversity;

  /// No description provided for @onboardingProfileSelectUpToFive.
  ///
  /// In en, this message translates to:
  /// **'Select up to 5'**
  String get onboardingProfileSelectUpToFive;

  /// No description provided for @onboardingProfileFavouritesTitle.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get onboardingProfileFavouritesTitle;

  /// No description provided for @onboardingProfileFavouritesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share what you love'**
  String get onboardingProfileFavouritesSubtitle;

  /// No description provided for @onboardingProfileSettingUpProfile.
  ///
  /// In en, this message translates to:
  /// **'Setting up your profile...'**
  String get onboardingProfileSettingUpProfile;

  /// No description provided for @onboardingProfileCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Complete!'**
  String get onboardingProfileCompleteTitle;

  /// No description provided for @onboardingProfileBasicCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Basic Profile Complete'**
  String get onboardingProfileBasicCompleteTitle;

  /// No description provided for @onboardingProfileEligibleToStartMatching.
  ///
  /// In en, this message translates to:
  /// **'You\'re eligible to start matching!'**
  String get onboardingProfileEligibleToStartMatching;

  /// No description provided for @onboardingProfileRecommendCompleteAll.
  ///
  /// In en, this message translates to:
  /// **'We recommend completing all fields to get more matches and build trust with other users.'**
  String get onboardingProfileRecommendCompleteAll;

  /// No description provided for @onboardingProfileCompletionLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile Completion'**
  String get onboardingProfileCompletionLabel;

  /// No description provided for @onboardingProfileCompletionCount.
  ///
  /// In en, this message translates to:
  /// **'{filled}/{total} fields ({percent}%)'**
  String onboardingProfileCompletionCount(int filled, int total, int percent);

  /// No description provided for @onboardingProfileFromBasicInfoStep.
  ///
  /// In en, this message translates to:
  /// **'From your profile setup'**
  String get onboardingProfileFromBasicInfoStep;

  /// No description provided for @onboardingProfileYourUsernameTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Username'**
  String get onboardingProfileYourUsernameTitle;

  /// No description provided for @onboardingProfileUsernameChangeEvery28Days.
  ///
  /// In en, this message translates to:
  /// **'You can change this once every 28 days'**
  String get onboardingProfileUsernameChangeEvery28Days;

  /// No description provided for @onboardingProfileUsernameLockedForDays.
  ///
  /// In en, this message translates to:
  /// **'Locked for {days} more days'**
  String onboardingProfileUsernameLockedForDays(int days);

  /// No description provided for @onboardingProfileEnterUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter username'**
  String get onboardingProfileEnterUsername;

  /// No description provided for @onboardingProfileUsernameChangeAgainInDays.
  ///
  /// In en, this message translates to:
  /// **'You can change your username again in {days} days'**
  String onboardingProfileUsernameChangeAgainInDays(int days);

  /// No description provided for @onboardingProfileNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get onboardingProfileNotSet;

  /// No description provided for @onboardingProfileDaysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String onboardingProfileDaysRemaining(int days);

  /// No description provided for @onboardingProfileUsernameChangesLimited.
  ///
  /// In en, this message translates to:
  /// **'Username changes are limited to once every 28 days. You can change it again in {days} days.'**
  String onboardingProfileUsernameChangesLimited(int days);

  /// No description provided for @onboardingProfileFavouriteAthlete.
  ///
  /// In en, this message translates to:
  /// **'Favourite Athlete'**
  String get onboardingProfileFavouriteAthlete;

  /// No description provided for @onboardingProfileFavouriteFood.
  ///
  /// In en, this message translates to:
  /// **'Favourite Food'**
  String get onboardingProfileFavouriteFood;

  /// No description provided for @onboardingProfileFavouriteSport.
  ///
  /// In en, this message translates to:
  /// **'Favourite Sport'**
  String get onboardingProfileFavouriteSport;

  /// No description provided for @onboardingProfileFavouriteTvShow.
  ///
  /// In en, this message translates to:
  /// **'Favourite TV Show'**
  String get onboardingProfileFavouriteTvShow;

  /// No description provided for @onboardingProfileFavouriteActor.
  ///
  /// In en, this message translates to:
  /// **'Favourite Actor'**
  String get onboardingProfileFavouriteActor;

  /// No description provided for @onboardingProfileFavouriteSinger.
  ///
  /// In en, this message translates to:
  /// **'Favourite Singer'**
  String get onboardingProfileFavouriteSinger;

  /// No description provided for @onboardingProfileFavouriteMovie.
  ///
  /// In en, this message translates to:
  /// **'Favourite Movie'**
  String get onboardingProfileFavouriteMovie;

  /// No description provided for @onboardingProfileFavouriteHobby.
  ///
  /// In en, this message translates to:
  /// **'Favourite Hobby'**
  String get onboardingProfileFavouriteHobby;

  /// No description provided for @onboardingProfileSelectPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Select...'**
  String get onboardingProfileSelectPlaceholder;

  /// No description provided for @onboardingProfileOrTypeYourOwn.
  ///
  /// In en, this message translates to:
  /// **'Or type your own...'**
  String get onboardingProfileOrTypeYourOwn;

  /// No description provided for @onboardingProfileAddPhotoBeforeSkip.
  ///
  /// In en, this message translates to:
  /// **'Please add at least 1 photo before skipping. This is required for dating apps.'**
  String get onboardingProfileAddPhotoBeforeSkip;

  /// No description provided for @onboardingProfileStartMatching.
  ///
  /// In en, this message translates to:
  /// **'Start Matching'**
  String get onboardingProfileStartMatching;

  /// No description provided for @onboardingProfileStartMatchingWithPercent.
  ///
  /// In en, this message translates to:
  /// **'Start Matching ({percent}% complete)'**
  String onboardingProfileStartMatchingWithPercent(int percent);

  /// No description provided for @onboardingProfileCompleteLaterInSettings.
  ///
  /// In en, this message translates to:
  /// **'You can always complete your profile later in Settings'**
  String get onboardingProfileCompleteLaterInSettings;

  /// No description provided for @onboardingProfileSaveAndStartMatchingSemantics.
  ///
  /// In en, this message translates to:
  /// **'Save profile and start matching'**
  String get onboardingProfileSaveAndStartMatchingSemantics;

  /// No description provided for @onboardingProfileSkipSemantics.
  ///
  /// In en, this message translates to:
  /// **'Skip profile setup for now. Requires at least one photo.'**
  String get onboardingProfileSkipSemantics;

  /// No description provided for @subscriptionFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get subscriptionFree;

  /// No description provided for @subscriptionPlus.
  ///
  /// In en, this message translates to:
  /// **'Plus'**
  String get subscriptionPlus;

  /// No description provided for @subscriptionGetPlus.
  ///
  /// In en, this message translates to:
  /// **'Get Crush Plus'**
  String get subscriptionGetPlus;

  /// No description provided for @subscriptionUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get subscriptionUpgrade;

  /// No description provided for @subscriptionRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get subscriptionRestore;

  /// No description provided for @subscriptionUnlimitedLikes.
  ///
  /// In en, this message translates to:
  /// **'Unlimited likes'**
  String get subscriptionUnlimitedLikes;

  /// No description provided for @subscriptionUnlimitedRewinds.
  ///
  /// In en, this message translates to:
  /// **'Unlimited rewinds'**
  String get subscriptionUnlimitedRewinds;

  /// No description provided for @subscriptionSeeWhoLikesYou.
  ///
  /// In en, this message translates to:
  /// **'See who likes you'**
  String get subscriptionSeeWhoLikesYou;

  /// No description provided for @subscriptionBoostsPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{count} boosts per month'**
  String subscriptionBoostsPerMonth(int count);

  /// No description provided for @subscriptionSuperLikesPerDay.
  ///
  /// In en, this message translates to:
  /// **'{count} super likes per day'**
  String subscriptionSuperLikesPerDay(int count);

  /// No description provided for @subscriptionNoAds.
  ///
  /// In en, this message translates to:
  /// **'No ads'**
  String get subscriptionNoAds;

  /// No description provided for @subscriptionPrioritySupport.
  ///
  /// In en, this message translates to:
  /// **'Priority support'**
  String get subscriptionPrioritySupport;

  /// No description provided for @subscriptionPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{price}/month'**
  String subscriptionPerMonth(String price);

  /// No description provided for @subscriptionPerYear.
  ///
  /// In en, this message translates to:
  /// **'{price}/year'**
  String subscriptionPerYear(String price);

  /// No description provided for @subscriptionBestValue.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get subscriptionBestValue;

  /// No description provided for @subscriptionMostPopular.
  ///
  /// In en, this message translates to:
  /// **'Most popular'**
  String get subscriptionMostPopular;

  /// No description provided for @safetyReportUser.
  ///
  /// In en, this message translates to:
  /// **'Report user'**
  String get safetyReportUser;

  /// No description provided for @safetyBlockUser.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get safetyBlockUser;

  /// No description provided for @safetyUnblockUser.
  ///
  /// In en, this message translates to:
  /// **'Unblock user'**
  String get safetyUnblockUser;

  /// No description provided for @safetyReportReason.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting?'**
  String get safetyReportReason;

  /// No description provided for @safetyBlockConfirm.
  ///
  /// In en, this message translates to:
  /// **'Block {name}?'**
  String safetyBlockConfirm(String name);

  /// No description provided for @safetyBlockMessage.
  ///
  /// In en, this message translates to:
  /// **'They won\'t be able to see your profile or message you'**
  String get safetyBlockMessage;

  /// No description provided for @safetyReported.
  ///
  /// In en, this message translates to:
  /// **'Report submitted'**
  String get safetyReported;

  /// No description provided for @safetyTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety & blocking'**
  String get safetyTitle;

  /// No description provided for @safetyEmergencyAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Alert'**
  String get safetyEmergencyAlertTitle;

  /// No description provided for @safetyEmergencyAlertBody.
  ///
  /// In en, this message translates to:
  /// **'This will immediately notify all your emergency contacts with your location. Only use this if you feel unsafe.\n\nAre you sure you want to send an emergency alert?'**
  String get safetyEmergencyAlertBody;

  /// No description provided for @safetySendAlert.
  ///
  /// In en, this message translates to:
  /// **'Send Alert'**
  String get safetySendAlert;

  /// No description provided for @safetyEmergencyAlertSent.
  ///
  /// In en, this message translates to:
  /// **'Emergency alert sent to all contacts!'**
  String get safetyEmergencyAlertSent;

  /// No description provided for @safetyEmergencyAlertFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send alert. Please call emergency services directly.'**
  String get safetyEmergencyAlertFailed;

  /// No description provided for @safetyCheckedInSuccess.
  ///
  /// In en, this message translates to:
  /// **'Checked in safely! Your contacts have been notified.'**
  String get safetyCheckedInSuccess;

  /// No description provided for @safetyCheckInFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not check in. Please try again.'**
  String get safetyCheckInFailed;

  /// No description provided for @safetyDateStartedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Date started! Your contacts have been notified.'**
  String get safetyDateStartedSuccess;

  /// No description provided for @safetyDateStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start date. Please try again.'**
  String get safetyDateStartFailed;

  /// No description provided for @safetyDateEndedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Date ended safely! Your contacts have been notified.'**
  String get safetyDateEndedSuccess;

  /// No description provided for @safetyDateEndFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not end date. Please try again.'**
  String get safetyDateEndFailed;

  /// No description provided for @safetySignInToCreatePlan.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to create a date plan.'**
  String get safetySignInToCreatePlan;

  /// No description provided for @safetyDatePlanCreated.
  ///
  /// In en, this message translates to:
  /// **'Date plan created! We emailed your contact.'**
  String get safetyDatePlanCreated;

  /// No description provided for @safetySignInToManage.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to manage safety actions.'**
  String get safetySignInToManage;

  /// No description provided for @safetyBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get safetyBlockedUsers;

  /// No description provided for @safetyBlockedUsersEmpty.
  ///
  /// In en, this message translates to:
  /// **'People you block can\'t see your profile, message, or call you.'**
  String get safetyBlockedUsersEmpty;

  /// No description provided for @safetyUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get safetyUnblock;

  /// No description provided for @safetyMutedMessages.
  ///
  /// In en, this message translates to:
  /// **'Muted messages'**
  String get safetyMutedMessages;

  /// No description provided for @safetyMutedMessagesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Mute message alerts for someone without blocking them.'**
  String get safetyMutedMessagesEmpty;

  /// No description provided for @safetyUnmuteMessages.
  ///
  /// In en, this message translates to:
  /// **'Unmute messages'**
  String get safetyUnmuteMessages;

  /// No description provided for @safetyMutedCalls.
  ///
  /// In en, this message translates to:
  /// **'Muted calls'**
  String get safetyMutedCalls;

  /// No description provided for @safetyMutedCallsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Silence call alerts from selected people.'**
  String get safetyMutedCallsEmpty;

  /// No description provided for @safetyUnmuteCalls.
  ///
  /// In en, this message translates to:
  /// **'Unmute calls'**
  String get safetyUnmuteCalls;

  /// No description provided for @safetyNeedToReport.
  ///
  /// In en, this message translates to:
  /// **'Need to report someone?'**
  String get safetyNeedToReport;

  /// No description provided for @safetyReportInstructions.
  ///
  /// In en, this message translates to:
  /// **'Open their profile or chat, choose Report, and pick a reason. We review reports to keep the community safe.'**
  String get safetyReportInstructions;

  /// No description provided for @safetyReadCommunityGuidelines.
  ///
  /// In en, this message translates to:
  /// **'Read community guidelines'**
  String get safetyReadCommunityGuidelines;

  /// No description provided for @safetySubmitAppeal.
  ///
  /// In en, this message translates to:
  /// **'Submit an appeal'**
  String get safetySubmitAppeal;

  /// No description provided for @safetyAppealDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Appeal a safety action'**
  String get safetyAppealDialogTitle;

  /// No description provided for @safetyAppealHint.
  ///
  /// In en, this message translates to:
  /// **'Share why you are appealing'**
  String get safetyAppealHint;

  /// No description provided for @safetyAppealDetailsRequired.
  ///
  /// In en, this message translates to:
  /// **'Please add details for your appeal.'**
  String get safetyAppealDetailsRequired;

  /// No description provided for @safetyAppealSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Appeal submitted'**
  String get safetyAppealSubmitted;

  /// No description provided for @safetyReportHistory.
  ///
  /// In en, this message translates to:
  /// **'Report history'**
  String get safetyReportHistory;

  /// No description provided for @safetyReportHistoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Reports you submit stay private. Reported profiles are hidden from discovery for 10 days while our safety team reviews them.'**
  String get safetyReportHistoryDesc;

  /// No description provided for @safetyNoRecentReports.
  ///
  /// In en, this message translates to:
  /// **'No recent reports.'**
  String get safetyNoRecentReports;

  /// No description provided for @safetyReportedOn.
  ///
  /// In en, this message translates to:
  /// **'Reported {date}'**
  String safetyReportedOn(String date);

  /// No description provided for @safetyReviewReportingRules.
  ///
  /// In en, this message translates to:
  /// **'Review reporting rules'**
  String get safetyReviewReportingRules;

  /// No description provided for @safetyUnknownUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get safetyUnknownUser;

  /// No description provided for @safetyEducationTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay safe while you connect'**
  String get safetyEducationTitle;

  /// No description provided for @safetyTipMeetPublic.
  ///
  /// In en, this message translates to:
  /// **'Plan first meetups in busy public places and share details with a friend.'**
  String get safetyTipMeetPublic;

  /// No description provided for @safetyTipKeepInApp.
  ///
  /// In en, this message translates to:
  /// **'Keep chats in Crush until you trust someone. Never send money or codes.'**
  String get safetyTipKeepInApp;

  /// No description provided for @safetyTipVerify.
  ///
  /// In en, this message translates to:
  /// **'Look for verification badges and report profiles that feel fake or pushy.'**
  String get safetyTipVerify;

  /// No description provided for @safetyTipBlockReport.
  ///
  /// In en, this message translates to:
  /// **'Use block or report if anyone crosses a boundary. We act on reports to protect the community.'**
  String get safetyTipBlockReport;

  /// No description provided for @safetyReviewGuidelines.
  ///
  /// In en, this message translates to:
  /// **'Review safety & community guidelines'**
  String get safetyReviewGuidelines;

  /// No description provided for @safetyDatePlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Date Plans'**
  String get safetyDatePlansTitle;

  /// No description provided for @safetyDatePlansDesc.
  ///
  /// In en, this message translates to:
  /// **'Share your date details with trusted contacts who can check on you.'**
  String get safetyDatePlansDesc;

  /// No description provided for @safetyPlanAnotherDate.
  ///
  /// In en, this message translates to:
  /// **'Plan Another Date'**
  String get safetyPlanAnotherDate;

  /// No description provided for @safetyNoActiveDatePlans.
  ///
  /// In en, this message translates to:
  /// **'No active date plans'**
  String get safetyNoActiveDatePlans;

  /// No description provided for @safetyNoActiveDatePlansDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a plan before meeting someone and share it with a trusted friend or family member.'**
  String get safetyNoActiveDatePlansDesc;

  /// No description provided for @safetyCreateDatePlan.
  ///
  /// In en, this message translates to:
  /// **'Create Date Plan'**
  String get safetyCreateDatePlan;

  /// No description provided for @safetyDateWith.
  ///
  /// In en, this message translates to:
  /// **'Date with {name}'**
  String safetyDateWith(String name);

  /// No description provided for @safetySharedWithContacts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Shared with 1 contact} other{Shared with {count} contacts}}'**
  String safetySharedWithContacts(int count);

  /// No description provided for @safetyStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get safetyStartDate;

  /// No description provided for @safetyCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked In'**
  String get safetyCheckedIn;

  /// No description provided for @safetyCheckInSafe.
  ///
  /// In en, this message translates to:
  /// **'Check In Safe'**
  String get safetyCheckInSafe;

  /// No description provided for @safetyEndSafely.
  ///
  /// In en, this message translates to:
  /// **'End Safely'**
  String get safetyEndSafely;

  /// No description provided for @safetyStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get safetyStatusScheduled;

  /// No description provided for @safetyStatusOngoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get safetyStatusOngoing;

  /// No description provided for @safetyStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get safetyStatusCompleted;

  /// No description provided for @safetyStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get safetyStatusCancelled;

  /// No description provided for @safetyStatusEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get safetyStatusEmergency;

  /// No description provided for @safetyCreateDatePlanDesc.
  ///
  /// In en, this message translates to:
  /// **'Share your date details with someone you trust.'**
  String get safetyCreateDatePlanDesc;

  /// No description provided for @safetyWhoMeeting.
  ///
  /// In en, this message translates to:
  /// **'Who are you meeting?'**
  String get safetyWhoMeeting;

  /// No description provided for @safetyTheirNameHint.
  ///
  /// In en, this message translates to:
  /// **'Their name'**
  String get safetyTheirNameHint;

  /// No description provided for @safetyWhereLabel.
  ///
  /// In en, this message translates to:
  /// **'Where?'**
  String get safetyWhereLabel;

  /// No description provided for @safetyLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Location name or address'**
  String get safetyLocationHint;

  /// No description provided for @safetyEmergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact'**
  String get safetyEmergencyContact;

  /// No description provided for @safetyEmergencyContactDesc.
  ///
  /// In en, this message translates to:
  /// **'This person will be notified of your date details and can check on you.'**
  String get safetyEmergencyContactDesc;

  /// No description provided for @safetyContactName.
  ///
  /// In en, this message translates to:
  /// **'Contact name'**
  String get safetyContactName;

  /// No description provided for @safetyContactNameHint.
  ///
  /// In en, this message translates to:
  /// **'Mom, Best friend, etc.'**
  String get safetyContactNameHint;

  /// No description provided for @safetyContactEmail.
  ///
  /// In en, this message translates to:
  /// **'Contact email'**
  String get safetyContactEmail;

  /// No description provided for @safetyContactEmailHint.
  ///
  /// In en, this message translates to:
  /// **'example@email.com'**
  String get safetyContactEmailHint;

  /// No description provided for @safetyNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get safetyNotesLabel;

  /// No description provided for @safetyNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Any additional details...'**
  String get safetyNotesHint;

  /// No description provided for @safetyCreatePlan.
  ///
  /// In en, this message translates to:
  /// **'Create Plan'**
  String get safetyCreatePlan;

  /// No description provided for @safetyErrorEnterMatch.
  ///
  /// In en, this message translates to:
  /// **'Please enter who you are meeting'**
  String get safetyErrorEnterMatch;

  /// No description provided for @safetyErrorEnterLocation.
  ///
  /// In en, this message translates to:
  /// **'Please enter a location'**
  String get safetyErrorEnterLocation;

  /// No description provided for @safetyErrorAddContact.
  ///
  /// In en, this message translates to:
  /// **'Please add an emergency contact with email'**
  String get safetyErrorAddContact;

  /// No description provided for @safetyErrorValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid contact email'**
  String get safetyErrorValidEmail;

  /// No description provided for @safetyCreatePlanFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create plan. Please try again.'**
  String get safetyCreatePlanFailed;

  /// No description provided for @safetyBlocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked'**
  String get safetyBlocked;

  /// No description provided for @safetyUnblocked.
  ///
  /// In en, this message translates to:
  /// **'User unblocked'**
  String get safetyUnblocked;

  /// No description provided for @safetyFakeProfile.
  ///
  /// In en, this message translates to:
  /// **'Fake profile'**
  String get safetyFakeProfile;

  /// No description provided for @safetyInappropriateContent.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get safetyInappropriateContent;

  /// No description provided for @safetyHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get safetyHarassment;

  /// No description provided for @safetySpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get safetySpam;

  /// No description provided for @safetyScam.
  ///
  /// In en, this message translates to:
  /// **'Scam'**
  String get safetyScam;

  /// No description provided for @safetyOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get safetyOther;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String timeDaysAgo(int count);

  /// No description provided for @timeWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week ago} other{{count} weeks ago}}'**
  String timeWeeksAgo(int count);

  /// No description provided for @emptyNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get emptyNoResults;

  /// No description provided for @emptyTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters'**
  String get emptyTryAgain;

  /// No description provided for @emptyNoData.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get emptyNoData;

  /// No description provided for @emptyCheckBackLater.
  ///
  /// In en, this message translates to:
  /// **'Check back later'**
  String get emptyCheckBackLater;

  /// No description provided for @wordHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get wordHome;

  /// No description provided for @wordExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get wordExplore;

  /// No description provided for @wordHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get wordHelp;

  /// No description provided for @wordMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get wordMenu;

  /// No description provided for @wordFeed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get wordFeed;

  /// No description provided for @wordActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get wordActivity;

  /// No description provided for @wordNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get wordNotifications;

  /// No description provided for @wordInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get wordInbox;

  /// No description provided for @wordFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get wordFavorites;

  /// No description provided for @wordHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get wordHistory;

  /// No description provided for @wordCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get wordCopy;

  /// No description provided for @wordPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get wordPaste;

  /// No description provided for @wordUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get wordUndo;

  /// No description provided for @wordRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get wordRedo;

  /// No description provided for @wordDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get wordDownload;

  /// No description provided for @wordUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get wordUpload;

  /// No description provided for @wordSelect.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get wordSelect;

  /// No description provided for @wordDeselect.
  ///
  /// In en, this message translates to:
  /// **'Deselect'**
  String get wordDeselect;

  /// No description provided for @wordOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get wordOpen;

  /// No description provided for @wordCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get wordCreate;

  /// No description provided for @wordConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get wordConnect;

  /// No description provided for @wordDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get wordDisconnect;

  /// No description provided for @wordStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get wordStart;

  /// No description provided for @wordStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get wordStop;

  /// No description provided for @wordPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get wordPlay;

  /// No description provided for @wordPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get wordPause;

  /// No description provided for @wordRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get wordRecord;

  /// No description provided for @wordCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get wordCall;

  /// No description provided for @wordEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get wordEnd;

  /// No description provided for @wordAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get wordAnswer;

  /// No description provided for @wordDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get wordDecline;

  /// No description provided for @wordAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get wordAccept;

  /// No description provided for @wordReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get wordReject;

  /// No description provided for @wordApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get wordApprove;

  /// No description provided for @wordDeny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get wordDeny;

  /// No description provided for @wordAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get wordAllow;

  /// No description provided for @wordEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get wordEnable;

  /// No description provided for @wordDisable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get wordDisable;

  /// No description provided for @wordShow.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get wordShow;

  /// No description provided for @wordHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get wordHide;

  /// No description provided for @wordExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get wordExpand;

  /// No description provided for @wordCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get wordCollapse;

  /// No description provided for @wordSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get wordSort;

  /// No description provided for @wordFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get wordFilter;

  /// No description provided for @wordPin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get wordPin;

  /// No description provided for @wordUnpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get wordUnpin;

  /// No description provided for @wordArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get wordArchive;

  /// No description provided for @wordRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get wordRestore;

  /// No description provided for @wordForward.
  ///
  /// In en, this message translates to:
  /// **'Forward'**
  String get wordForward;

  /// No description provided for @wordFollow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get wordFollow;

  /// No description provided for @wordUnfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get wordUnfollow;

  /// No description provided for @wordSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get wordSubscribe;

  /// No description provided for @wordUnsubscribe.
  ///
  /// In en, this message translates to:
  /// **'Unsubscribe'**
  String get wordUnsubscribe;

  /// No description provided for @wordInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get wordInvite;

  /// No description provided for @wordJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get wordJoin;

  /// No description provided for @wordLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get wordLeave;

  /// No description provided for @wordLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get wordLogin;

  /// No description provided for @wordLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get wordLogout;

  /// No description provided for @wordSignup.
  ///
  /// In en, this message translates to:
  /// **'Signup'**
  String get wordSignup;

  /// No description provided for @wordRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get wordRegister;

  /// No description provided for @wordVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get wordVerify;

  /// No description provided for @wordConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get wordConfirmed;

  /// No description provided for @wordPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get wordPending;

  /// No description provided for @wordComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get wordComplete;

  /// No description provided for @wordFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get wordFinish;

  /// No description provided for @wordCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get wordCancel;

  /// No description provided for @wordTry.
  ///
  /// In en, this message translates to:
  /// **'Try'**
  String get wordTry;

  /// No description provided for @wordAgain.
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get wordAgain;

  /// No description provided for @wordGo.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get wordGo;

  /// No description provided for @wordSee.
  ///
  /// In en, this message translates to:
  /// **'See'**
  String get wordSee;

  /// No description provided for @wordLook.
  ///
  /// In en, this message translates to:
  /// **'Look'**
  String get wordLook;

  /// No description provided for @wordFind.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get wordFind;

  /// No description provided for @wordGet.
  ///
  /// In en, this message translates to:
  /// **'Get'**
  String get wordGet;

  /// No description provided for @wordSet.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get wordSet;

  /// No description provided for @wordPut.
  ///
  /// In en, this message translates to:
  /// **'Put'**
  String get wordPut;

  /// No description provided for @wordTake.
  ///
  /// In en, this message translates to:
  /// **'Take'**
  String get wordTake;

  /// No description provided for @wordGive.
  ///
  /// In en, this message translates to:
  /// **'Give'**
  String get wordGive;

  /// No description provided for @wordMake.
  ///
  /// In en, this message translates to:
  /// **'Make'**
  String get wordMake;

  /// No description provided for @wordKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get wordKeep;

  /// No description provided for @wordLet.
  ///
  /// In en, this message translates to:
  /// **'Let'**
  String get wordLet;

  /// No description provided for @wordKnow.
  ///
  /// In en, this message translates to:
  /// **'Know'**
  String get wordKnow;

  /// No description provided for @wordThink.
  ///
  /// In en, this message translates to:
  /// **'Think'**
  String get wordThink;

  /// No description provided for @wordFeel.
  ///
  /// In en, this message translates to:
  /// **'Feel'**
  String get wordFeel;

  /// No description provided for @wordWant.
  ///
  /// In en, this message translates to:
  /// **'Want'**
  String get wordWant;

  /// No description provided for @wordNeed.
  ///
  /// In en, this message translates to:
  /// **'Need'**
  String get wordNeed;

  /// No description provided for @wordLike.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get wordLike;

  /// No description provided for @wordLove.
  ///
  /// In en, this message translates to:
  /// **'Love'**
  String get wordLove;

  /// No description provided for @wordHate.
  ///
  /// In en, this message translates to:
  /// **'Hate'**
  String get wordHate;

  /// No description provided for @wordTalk.
  ///
  /// In en, this message translates to:
  /// **'Talk'**
  String get wordTalk;

  /// No description provided for @wordSay.
  ///
  /// In en, this message translates to:
  /// **'Say'**
  String get wordSay;

  /// No description provided for @wordTell.
  ///
  /// In en, this message translates to:
  /// **'Tell'**
  String get wordTell;

  /// No description provided for @wordAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask'**
  String get wordAsk;

  /// No description provided for @wordHelpVerb.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get wordHelpVerb;

  /// No description provided for @wordWait.
  ///
  /// In en, this message translates to:
  /// **'Wait'**
  String get wordWait;

  /// No description provided for @wordStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get wordStay;

  /// No description provided for @wordCome.
  ///
  /// In en, this message translates to:
  /// **'Come'**
  String get wordCome;

  /// No description provided for @wordMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get wordMove;

  /// No description provided for @wordRun.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get wordRun;

  /// No description provided for @wordWalk.
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get wordWalk;

  /// No description provided for @wordMeet.
  ///
  /// In en, this message translates to:
  /// **'Meet'**
  String get wordMeet;

  /// No description provided for @wordWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get wordWork;

  /// No description provided for @wordLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get wordLive;

  /// No description provided for @wordChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get wordChange;

  /// No description provided for @wordTurn.
  ///
  /// In en, this message translates to:
  /// **'Turn'**
  String get wordTurn;

  /// No description provided for @wordRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get wordRead;

  /// No description provided for @wordWrite.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get wordWrite;

  /// No description provided for @wordLearn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get wordLearn;

  /// No description provided for @wordStudy.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get wordStudy;

  /// No description provided for @wordWatch.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get wordWatch;

  /// No description provided for @wordListen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get wordListen;

  /// No description provided for @wordSpeak.
  ///
  /// In en, this message translates to:
  /// **'Speak'**
  String get wordSpeak;

  /// No description provided for @wordEat.
  ///
  /// In en, this message translates to:
  /// **'Eat'**
  String get wordEat;

  /// No description provided for @wordDrink.
  ///
  /// In en, this message translates to:
  /// **'Drink'**
  String get wordDrink;

  /// No description provided for @wordSleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get wordSleep;

  /// No description provided for @wordBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get wordBuy;

  /// No description provided for @wordSell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get wordSell;

  /// No description provided for @wordPay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get wordPay;

  /// No description provided for @wordSpend.
  ///
  /// In en, this message translates to:
  /// **'Spend'**
  String get wordSpend;

  /// No description provided for @wordSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get wordSave;

  /// No description provided for @wordWin.
  ///
  /// In en, this message translates to:
  /// **'Win'**
  String get wordWin;

  /// No description provided for @wordLose.
  ///
  /// In en, this message translates to:
  /// **'Lose'**
  String get wordLose;

  /// No description provided for @wordCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get wordCheck;

  /// No description provided for @wordPick.
  ///
  /// In en, this message translates to:
  /// **'Pick'**
  String get wordPick;

  /// No description provided for @wordChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get wordChoose;

  /// No description provided for @wordDecide.
  ///
  /// In en, this message translates to:
  /// **'Decide'**
  String get wordDecide;

  /// No description provided for @wordAgree.
  ///
  /// In en, this message translates to:
  /// **'Agree'**
  String get wordAgree;

  /// No description provided for @wordDisagree.
  ///
  /// In en, this message translates to:
  /// **'Disagree'**
  String get wordDisagree;

  /// No description provided for @wordActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get wordActive;

  /// No description provided for @wordInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get wordInactive;

  /// No description provided for @wordAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get wordAvailable;

  /// No description provided for @wordUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get wordUnavailable;

  /// No description provided for @wordBusy.
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get wordBusy;

  /// No description provided for @wordAway.
  ///
  /// In en, this message translates to:
  /// **'Away'**
  String get wordAway;

  /// No description provided for @wordInvisible.
  ///
  /// In en, this message translates to:
  /// **'Invisible'**
  String get wordInvisible;

  /// No description provided for @wordOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get wordOnline;

  /// No description provided for @wordOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get wordOffline;

  /// No description provided for @wordConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get wordConnected;

  /// No description provided for @wordDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get wordDisconnected;

  /// No description provided for @wordVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get wordVerified;

  /// No description provided for @wordUnverified.
  ///
  /// In en, this message translates to:
  /// **'Unverified'**
  String get wordUnverified;

  /// No description provided for @wordApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get wordApproved;

  /// No description provided for @wordDenied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get wordDenied;

  /// No description provided for @wordBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get wordBlocked;

  /// No description provided for @wordUnblocked.
  ///
  /// In en, this message translates to:
  /// **'Unblocked'**
  String get wordUnblocked;

  /// No description provided for @wordSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get wordSuspended;

  /// No description provided for @wordBanned.
  ///
  /// In en, this message translates to:
  /// **'Banned'**
  String get wordBanned;

  /// No description provided for @wordRestricted.
  ///
  /// In en, this message translates to:
  /// **'Restricted'**
  String get wordRestricted;

  /// No description provided for @wordPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get wordPremium;

  /// No description provided for @wordStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get wordStandard;

  /// No description provided for @wordBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get wordBasic;

  /// No description provided for @wordNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get wordNew;

  /// No description provided for @wordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get wordUpdated;

  /// No description provided for @wordRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get wordRecent;

  /// No description provided for @wordPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get wordPopular;

  /// No description provided for @wordTrending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get wordTrending;

  /// No description provided for @wordFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get wordFeatured;

  /// No description provided for @wordRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get wordRecommended;

  /// No description provided for @wordSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested'**
  String get wordSuggested;

  /// No description provided for @wordRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get wordRequired;

  /// No description provided for @wordOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get wordOptional;

  /// No description provided for @wordEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get wordEnabled;

  /// No description provided for @wordDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get wordDisabled;

  /// No description provided for @wordLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get wordLocked;

  /// No description provided for @wordUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get wordUnlocked;

  /// No description provided for @wordHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get wordHidden;

  /// No description provided for @wordVisible.
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get wordVisible;

  /// No description provided for @wordPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get wordPublic;

  /// No description provided for @wordPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get wordPrivate;

  /// No description provided for @wordSecure.
  ///
  /// In en, this message translates to:
  /// **'Secure'**
  String get wordSecure;

  /// No description provided for @wordSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe'**
  String get wordSafe;

  /// No description provided for @wordReal.
  ///
  /// In en, this message translates to:
  /// **'Real'**
  String get wordReal;

  /// No description provided for @wordFake.
  ///
  /// In en, this message translates to:
  /// **'Fake'**
  String get wordFake;

  /// No description provided for @wordTrue.
  ///
  /// In en, this message translates to:
  /// **'True'**
  String get wordTrue;

  /// No description provided for @wordFalse.
  ///
  /// In en, this message translates to:
  /// **'False'**
  String get wordFalse;

  /// No description provided for @wordValid.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get wordValid;

  /// No description provided for @wordInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get wordInvalid;

  /// No description provided for @wordCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get wordCorrect;

  /// No description provided for @wordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get wordIncorrect;

  /// No description provided for @wordEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get wordEmpty;

  /// No description provided for @wordFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get wordFull;

  /// No description provided for @wordReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get wordReady;

  /// No description provided for @wordNotReady.
  ///
  /// In en, this message translates to:
  /// **'Not Ready'**
  String get wordNotReady;

  /// No description provided for @wordDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get wordDone;

  /// No description provided for @wordNotDone.
  ///
  /// In en, this message translates to:
  /// **'Not Done'**
  String get wordNotDone;

  /// No description provided for @wordSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get wordSent;

  /// No description provided for @wordReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get wordReceived;

  /// No description provided for @wordReadStatus.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get wordReadStatus;

  /// No description provided for @wordUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get wordUnread;

  /// No description provided for @wordSeen.
  ///
  /// In en, this message translates to:
  /// **'Seen'**
  String get wordSeen;

  /// No description provided for @wordUnseen.
  ///
  /// In en, this message translates to:
  /// **'Unseen'**
  String get wordUnseen;

  /// No description provided for @wordOpenStatus.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get wordOpenStatus;

  /// No description provided for @wordClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get wordClosed;

  /// No description provided for @wordNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get wordNow;

  /// No description provided for @wordLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get wordLater;

  /// No description provided for @wordSoon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get wordSoon;

  /// No description provided for @wordToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get wordToday;

  /// No description provided for @wordTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get wordTomorrow;

  /// No description provided for @wordYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get wordYesterday;

  /// No description provided for @wordMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get wordMorning;

  /// No description provided for @wordAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get wordAfternoon;

  /// No description provided for @wordEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get wordEvening;

  /// No description provided for @wordNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get wordNight;

  /// No description provided for @wordWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get wordWeek;

  /// No description provided for @wordMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get wordMonth;

  /// No description provided for @wordYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get wordYear;

  /// No description provided for @wordDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get wordDaily;

  /// No description provided for @wordWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get wordWeekly;

  /// No description provided for @wordMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get wordMonthly;

  /// No description provided for @wordYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get wordYearly;

  /// No description provided for @wordAlways.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get wordAlways;

  /// No description provided for @wordNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get wordNever;

  /// No description provided for @wordSometimes.
  ///
  /// In en, this message translates to:
  /// **'Sometimes'**
  String get wordSometimes;

  /// No description provided for @wordOften.
  ///
  /// In en, this message translates to:
  /// **'Often'**
  String get wordOften;

  /// No description provided for @wordRarely.
  ///
  /// In en, this message translates to:
  /// **'Rarely'**
  String get wordRarely;

  /// No description provided for @wordRecently.
  ///
  /// In en, this message translates to:
  /// **'Recently'**
  String get wordRecently;

  /// No description provided for @wordBefore.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get wordBefore;

  /// No description provided for @wordAfter.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get wordAfter;

  /// No description provided for @wordDuring.
  ///
  /// In en, this message translates to:
  /// **'During'**
  String get wordDuring;

  /// No description provided for @wordUntil.
  ///
  /// In en, this message translates to:
  /// **'Until'**
  String get wordUntil;

  /// No description provided for @wordSince.
  ///
  /// In en, this message translates to:
  /// **'Since'**
  String get wordSince;

  /// No description provided for @wordAgo.
  ///
  /// In en, this message translates to:
  /// **'Ago'**
  String get wordAgo;

  /// No description provided for @wordMinute.
  ///
  /// In en, this message translates to:
  /// **'Minute'**
  String get wordMinute;

  /// No description provided for @wordMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get wordMinutes;

  /// No description provided for @wordHour.
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get wordHour;

  /// No description provided for @wordHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get wordHours;

  /// No description provided for @wordDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get wordDay;

  /// No description provided for @wordDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get wordDays;

  /// No description provided for @wordWeeks.
  ///
  /// In en, this message translates to:
  /// **'Weeks'**
  String get wordWeeks;

  /// No description provided for @wordMonths.
  ///
  /// In en, this message translates to:
  /// **'Months'**
  String get wordMonths;

  /// No description provided for @wordYears.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get wordYears;

  /// No description provided for @wordSecond.
  ///
  /// In en, this message translates to:
  /// **'Second'**
  String get wordSecond;

  /// No description provided for @wordSeconds.
  ///
  /// In en, this message translates to:
  /// **'Seconds'**
  String get wordSeconds;

  /// No description provided for @wordGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get wordGood;

  /// No description provided for @wordBad.
  ///
  /// In en, this message translates to:
  /// **'Bad'**
  String get wordBad;

  /// No description provided for @wordGreat.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get wordGreat;

  /// No description provided for @wordExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get wordExcellent;

  /// No description provided for @wordBest.
  ///
  /// In en, this message translates to:
  /// **'Best'**
  String get wordBest;

  /// No description provided for @wordWorst.
  ///
  /// In en, this message translates to:
  /// **'Worst'**
  String get wordWorst;

  /// No description provided for @wordOld.
  ///
  /// In en, this message translates to:
  /// **'Old'**
  String get wordOld;

  /// No description provided for @wordYoung.
  ///
  /// In en, this message translates to:
  /// **'Young'**
  String get wordYoung;

  /// No description provided for @wordHot.
  ///
  /// In en, this message translates to:
  /// **'Hot'**
  String get wordHot;

  /// No description provided for @wordCold.
  ///
  /// In en, this message translates to:
  /// **'Cold'**
  String get wordCold;

  /// No description provided for @wordFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get wordFast;

  /// No description provided for @wordSlow.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get wordSlow;

  /// No description provided for @wordEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get wordEasy;

  /// No description provided for @wordHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get wordHard;

  /// No description provided for @wordSimple.
  ///
  /// In en, this message translates to:
  /// **'Simple'**
  String get wordSimple;

  /// No description provided for @wordComplex.
  ///
  /// In en, this message translates to:
  /// **'Complex'**
  String get wordComplex;

  /// No description provided for @wordSmall.
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get wordSmall;

  /// No description provided for @wordBig.
  ///
  /// In en, this message translates to:
  /// **'Big'**
  String get wordBig;

  /// No description provided for @wordLarge.
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get wordLarge;

  /// No description provided for @wordTiny.
  ///
  /// In en, this message translates to:
  /// **'Tiny'**
  String get wordTiny;

  /// No description provided for @wordHuge.
  ///
  /// In en, this message translates to:
  /// **'Huge'**
  String get wordHuge;

  /// No description provided for @wordLong.
  ///
  /// In en, this message translates to:
  /// **'Long'**
  String get wordLong;

  /// No description provided for @wordShort.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get wordShort;

  /// No description provided for @wordHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get wordHigh;

  /// No description provided for @wordLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get wordLow;

  /// No description provided for @wordWide.
  ///
  /// In en, this message translates to:
  /// **'Wide'**
  String get wordWide;

  /// No description provided for @wordNarrow.
  ///
  /// In en, this message translates to:
  /// **'Narrow'**
  String get wordNarrow;

  /// No description provided for @wordThick.
  ///
  /// In en, this message translates to:
  /// **'Thick'**
  String get wordThick;

  /// No description provided for @wordThin.
  ///
  /// In en, this message translates to:
  /// **'Thin'**
  String get wordThin;

  /// No description provided for @wordDeep.
  ///
  /// In en, this message translates to:
  /// **'Deep'**
  String get wordDeep;

  /// No description provided for @wordShallow.
  ///
  /// In en, this message translates to:
  /// **'Shallow'**
  String get wordShallow;

  /// No description provided for @wordBright.
  ///
  /// In en, this message translates to:
  /// **'Bright'**
  String get wordBright;

  /// No description provided for @wordDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get wordDark;

  /// No description provided for @wordLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get wordLight;

  /// No description provided for @wordHeavy.
  ///
  /// In en, this message translates to:
  /// **'Heavy'**
  String get wordHeavy;

  /// No description provided for @wordSoft.
  ///
  /// In en, this message translates to:
  /// **'Soft'**
  String get wordSoft;

  /// No description provided for @wordLoud.
  ///
  /// In en, this message translates to:
  /// **'Loud'**
  String get wordLoud;

  /// No description provided for @wordQuiet.
  ///
  /// In en, this message translates to:
  /// **'Quiet'**
  String get wordQuiet;

  /// No description provided for @wordClean.
  ///
  /// In en, this message translates to:
  /// **'Clean'**
  String get wordClean;

  /// No description provided for @wordDirty.
  ///
  /// In en, this message translates to:
  /// **'Dirty'**
  String get wordDirty;

  /// No description provided for @wordRich.
  ///
  /// In en, this message translates to:
  /// **'Rich'**
  String get wordRich;

  /// No description provided for @wordPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get wordPoor;

  /// No description provided for @wordFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get wordFree;

  /// No description provided for @wordPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get wordPaid;

  /// No description provided for @wordCheap.
  ///
  /// In en, this message translates to:
  /// **'Cheap'**
  String get wordCheap;

  /// No description provided for @wordExpensive.
  ///
  /// In en, this message translates to:
  /// **'Expensive'**
  String get wordExpensive;

  /// No description provided for @wordBeautiful.
  ///
  /// In en, this message translates to:
  /// **'Beautiful'**
  String get wordBeautiful;

  /// No description provided for @wordUgly.
  ///
  /// In en, this message translates to:
  /// **'Ugly'**
  String get wordUgly;

  /// No description provided for @wordPretty.
  ///
  /// In en, this message translates to:
  /// **'Pretty'**
  String get wordPretty;

  /// No description provided for @wordHandsome.
  ///
  /// In en, this message translates to:
  /// **'Handsome'**
  String get wordHandsome;

  /// No description provided for @wordCute.
  ///
  /// In en, this message translates to:
  /// **'Cute'**
  String get wordCute;

  /// No description provided for @wordSexy.
  ///
  /// In en, this message translates to:
  /// **'Sexy'**
  String get wordSexy;

  /// No description provided for @wordAttractive.
  ///
  /// In en, this message translates to:
  /// **'Attractive'**
  String get wordAttractive;

  /// No description provided for @wordHappy.
  ///
  /// In en, this message translates to:
  /// **'Happy'**
  String get wordHappy;

  /// No description provided for @wordSad.
  ///
  /// In en, this message translates to:
  /// **'Sad'**
  String get wordSad;

  /// No description provided for @wordAngry.
  ///
  /// In en, this message translates to:
  /// **'Angry'**
  String get wordAngry;

  /// No description provided for @wordScared.
  ///
  /// In en, this message translates to:
  /// **'Scared'**
  String get wordScared;

  /// No description provided for @wordExcited.
  ///
  /// In en, this message translates to:
  /// **'Excited'**
  String get wordExcited;

  /// No description provided for @wordBored.
  ///
  /// In en, this message translates to:
  /// **'Bored'**
  String get wordBored;

  /// No description provided for @wordTired.
  ///
  /// In en, this message translates to:
  /// **'Tired'**
  String get wordTired;

  /// No description provided for @wordSick.
  ///
  /// In en, this message translates to:
  /// **'Sick'**
  String get wordSick;

  /// No description provided for @wordHealthy.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get wordHealthy;

  /// No description provided for @wordStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get wordStrong;

  /// No description provided for @wordWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get wordWeak;

  /// No description provided for @wordSmart.
  ///
  /// In en, this message translates to:
  /// **'Smart'**
  String get wordSmart;

  /// No description provided for @wordStupid.
  ///
  /// In en, this message translates to:
  /// **'Stupid'**
  String get wordStupid;

  /// No description provided for @wordFunny.
  ///
  /// In en, this message translates to:
  /// **'Funny'**
  String get wordFunny;

  /// No description provided for @wordSerious.
  ///
  /// In en, this message translates to:
  /// **'Serious'**
  String get wordSerious;

  /// No description provided for @wordNice.
  ///
  /// In en, this message translates to:
  /// **'Nice'**
  String get wordNice;

  /// No description provided for @wordMean.
  ///
  /// In en, this message translates to:
  /// **'Mean'**
  String get wordMean;

  /// No description provided for @wordKind.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get wordKind;

  /// No description provided for @wordCruel.
  ///
  /// In en, this message translates to:
  /// **'Cruel'**
  String get wordCruel;

  /// No description provided for @wordFriendly.
  ///
  /// In en, this message translates to:
  /// **'Friendly'**
  String get wordFriendly;

  /// No description provided for @wordRude.
  ///
  /// In en, this message translates to:
  /// **'Rude'**
  String get wordRude;

  /// No description provided for @wordPolite.
  ///
  /// In en, this message translates to:
  /// **'Polite'**
  String get wordPolite;

  /// No description provided for @wordHonest.
  ///
  /// In en, this message translates to:
  /// **'Honest'**
  String get wordHonest;

  /// No description provided for @wordLazy.
  ///
  /// In en, this message translates to:
  /// **'Lazy'**
  String get wordLazy;

  /// No description provided for @wordBrave.
  ///
  /// In en, this message translates to:
  /// **'Brave'**
  String get wordBrave;

  /// No description provided for @wordCurious.
  ///
  /// In en, this message translates to:
  /// **'Curious'**
  String get wordCurious;

  /// No description provided for @wordPatient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get wordPatient;

  /// No description provided for @wordImpatient.
  ///
  /// In en, this message translates to:
  /// **'Impatient'**
  String get wordImpatient;

  /// No description provided for @wordCareful.
  ///
  /// In en, this message translates to:
  /// **'Careful'**
  String get wordCareful;

  /// No description provided for @wordCareless.
  ///
  /// In en, this message translates to:
  /// **'Careless'**
  String get wordCareless;

  /// No description provided for @wordGenerous.
  ///
  /// In en, this message translates to:
  /// **'Generous'**
  String get wordGenerous;

  /// No description provided for @wordSelfish.
  ///
  /// In en, this message translates to:
  /// **'Selfish'**
  String get wordSelfish;

  /// No description provided for @wordRomantic.
  ///
  /// In en, this message translates to:
  /// **'Romantic'**
  String get wordRomantic;

  /// No description provided for @wordPassionate.
  ///
  /// In en, this message translates to:
  /// **'Passionate'**
  String get wordPassionate;

  /// No description provided for @wordLoyal.
  ///
  /// In en, this message translates to:
  /// **'Loyal'**
  String get wordLoyal;

  /// No description provided for @wordFaithful.
  ///
  /// In en, this message translates to:
  /// **'Faithful'**
  String get wordFaithful;

  /// No description provided for @wordTrustworthy.
  ///
  /// In en, this message translates to:
  /// **'Trustworthy'**
  String get wordTrustworthy;

  /// No description provided for @wordReliable.
  ///
  /// In en, this message translates to:
  /// **'Reliable'**
  String get wordReliable;

  /// No description provided for @wordResponsible.
  ///
  /// In en, this message translates to:
  /// **'Responsible'**
  String get wordResponsible;

  /// No description provided for @wordMature.
  ///
  /// In en, this message translates to:
  /// **'Mature'**
  String get wordMature;

  /// No description provided for @wordImmature.
  ///
  /// In en, this message translates to:
  /// **'Immature'**
  String get wordImmature;

  /// No description provided for @wordIndependent.
  ///
  /// In en, this message translates to:
  /// **'Independent'**
  String get wordIndependent;

  /// No description provided for @wordConfident.
  ///
  /// In en, this message translates to:
  /// **'Confident'**
  String get wordConfident;

  /// No description provided for @wordShy.
  ///
  /// In en, this message translates to:
  /// **'Shy'**
  String get wordShy;

  /// No description provided for @wordOutgoing.
  ///
  /// In en, this message translates to:
  /// **'Outgoing'**
  String get wordOutgoing;

  /// No description provided for @wordIntroverted.
  ///
  /// In en, this message translates to:
  /// **'Introverted'**
  String get wordIntroverted;

  /// No description provided for @wordExtroverted.
  ///
  /// In en, this message translates to:
  /// **'Extroverted'**
  String get wordExtroverted;

  /// No description provided for @wordAmbitious.
  ///
  /// In en, this message translates to:
  /// **'Ambitious'**
  String get wordAmbitious;

  /// No description provided for @wordCreative.
  ///
  /// In en, this message translates to:
  /// **'Creative'**
  String get wordCreative;

  /// No description provided for @wordIntelligent.
  ///
  /// In en, this message translates to:
  /// **'Intelligent'**
  String get wordIntelligent;

  /// No description provided for @wordWise.
  ///
  /// In en, this message translates to:
  /// **'Wise'**
  String get wordWise;

  /// No description provided for @wordTalented.
  ///
  /// In en, this message translates to:
  /// **'Talented'**
  String get wordTalented;

  /// No description provided for @wordSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Successful'**
  String get wordSuccessful;

  /// No description provided for @wordFamous.
  ///
  /// In en, this message translates to:
  /// **'Famous'**
  String get wordFamous;

  /// No description provided for @wordImportant.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get wordImportant;

  /// No description provided for @wordSpecial.
  ///
  /// In en, this message translates to:
  /// **'Special'**
  String get wordSpecial;

  /// No description provided for @wordPerfect.
  ///
  /// In en, this message translates to:
  /// **'Perfect'**
  String get wordPerfect;

  /// No description provided for @wordAmazing.
  ///
  /// In en, this message translates to:
  /// **'Amazing'**
  String get wordAmazing;

  /// No description provided for @wordWonderful.
  ///
  /// In en, this message translates to:
  /// **'Wonderful'**
  String get wordWonderful;

  /// No description provided for @wordFantastic.
  ///
  /// In en, this message translates to:
  /// **'Fantastic'**
  String get wordFantastic;

  /// No description provided for @wordIncredible.
  ///
  /// In en, this message translates to:
  /// **'Incredible'**
  String get wordIncredible;

  /// No description provided for @wordAwesome.
  ///
  /// In en, this message translates to:
  /// **'Awesome'**
  String get wordAwesome;

  /// No description provided for @wordTerrific.
  ///
  /// In en, this message translates to:
  /// **'Terrific'**
  String get wordTerrific;

  /// No description provided for @wordMarvelous.
  ///
  /// In en, this message translates to:
  /// **'Marvelous'**
  String get wordMarvelous;

  /// No description provided for @wordSuperb.
  ///
  /// In en, this message translates to:
  /// **'Superb'**
  String get wordSuperb;

  /// No description provided for @wordOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get wordOutstanding;

  /// No description provided for @wordBrilliant.
  ///
  /// In en, this message translates to:
  /// **'Brilliant'**
  String get wordBrilliant;

  /// No description provided for @wordFabulous.
  ///
  /// In en, this message translates to:
  /// **'Fabulous'**
  String get wordFabulous;

  /// No description provided for @wordMagnificent.
  ///
  /// In en, this message translates to:
  /// **'Magnificent'**
  String get wordMagnificent;

  /// No description provided for @wordSpectacular.
  ///
  /// In en, this message translates to:
  /// **'Spectacular'**
  String get wordSpectacular;

  /// No description provided for @wordPlease.
  ///
  /// In en, this message translates to:
  /// **'Please'**
  String get wordPlease;

  /// No description provided for @wordThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks'**
  String get wordThanks;

  /// No description provided for @wordThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you'**
  String get wordThankYou;

  /// No description provided for @wordSorry.
  ///
  /// In en, this message translates to:
  /// **'Sorry'**
  String get wordSorry;

  /// No description provided for @wordExcuseMe.
  ///
  /// In en, this message translates to:
  /// **'Excuse me'**
  String get wordExcuseMe;

  /// No description provided for @wordWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get wordWelcome;

  /// No description provided for @wordHello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get wordHello;

  /// No description provided for @wordHi.
  ///
  /// In en, this message translates to:
  /// **'Hi'**
  String get wordHi;

  /// No description provided for @wordHey.
  ///
  /// In en, this message translates to:
  /// **'Hey'**
  String get wordHey;

  /// No description provided for @wordGoodbye.
  ///
  /// In en, this message translates to:
  /// **'Goodbye'**
  String get wordGoodbye;

  /// No description provided for @wordBye.
  ///
  /// In en, this message translates to:
  /// **'Bye'**
  String get wordBye;

  /// No description provided for @wordCongratulations.
  ///
  /// In en, this message translates to:
  /// **'Congratulations'**
  String get wordCongratulations;

  /// No description provided for @wordCongrats.
  ///
  /// In en, this message translates to:
  /// **'Congrats'**
  String get wordCongrats;

  /// No description provided for @wordGoodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get wordGoodMorning;

  /// No description provided for @wordGoodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get wordGoodAfternoon;

  /// No description provided for @wordGoodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get wordGoodEvening;

  /// No description provided for @wordGoodNight.
  ///
  /// In en, this message translates to:
  /// **'Good night'**
  String get wordGoodNight;

  /// No description provided for @wordHowAreYou.
  ///
  /// In en, this message translates to:
  /// **'How are you?'**
  String get wordHowAreYou;

  /// No description provided for @wordImFine.
  ///
  /// In en, this message translates to:
  /// **'I\'m fine'**
  String get wordImFine;

  /// No description provided for @wordNiceMeetYou.
  ///
  /// In en, this message translates to:
  /// **'Nice to meet you'**
  String get wordNiceMeetYou;

  /// No description provided for @wordSeeLater.
  ///
  /// In en, this message translates to:
  /// **'See you later'**
  String get wordSeeLater;

  /// No description provided for @wordTakeCare.
  ///
  /// In en, this message translates to:
  /// **'Take care'**
  String get wordTakeCare;

  /// No description provided for @wordMissYou.
  ///
  /// In en, this message translates to:
  /// **'Miss you'**
  String get wordMissYou;

  /// No description provided for @wordLoveYou.
  ///
  /// In en, this message translates to:
  /// **'Love you'**
  String get wordLoveYou;

  /// No description provided for @wordThinkingOfYou.
  ///
  /// In en, this message translates to:
  /// **'Thinking of you'**
  String get wordThinkingOfYou;

  /// No description provided for @wordGoodLuck.
  ///
  /// In en, this message translates to:
  /// **'Good luck'**
  String get wordGoodLuck;

  /// No description provided for @wordHaveFun.
  ///
  /// In en, this message translates to:
  /// **'Have fun'**
  String get wordHaveFun;

  /// No description provided for @wordEnjoy.
  ///
  /// In en, this message translates to:
  /// **'Enjoy'**
  String get wordEnjoy;

  /// No description provided for @wordCheers.
  ///
  /// In en, this message translates to:
  /// **'Cheers'**
  String get wordCheers;

  /// No description provided for @wordWho.
  ///
  /// In en, this message translates to:
  /// **'Who'**
  String get wordWho;

  /// No description provided for @wordWhat.
  ///
  /// In en, this message translates to:
  /// **'What'**
  String get wordWhat;

  /// No description provided for @wordWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get wordWhen;

  /// No description provided for @wordWhere.
  ///
  /// In en, this message translates to:
  /// **'Where'**
  String get wordWhere;

  /// No description provided for @wordWhy.
  ///
  /// In en, this message translates to:
  /// **'Why'**
  String get wordWhy;

  /// No description provided for @wordHow.
  ///
  /// In en, this message translates to:
  /// **'How'**
  String get wordHow;

  /// No description provided for @wordWhich.
  ///
  /// In en, this message translates to:
  /// **'Which'**
  String get wordWhich;

  /// No description provided for @wordWhose.
  ///
  /// In en, this message translates to:
  /// **'Whose'**
  String get wordWhose;

  /// No description provided for @wordHowMany.
  ///
  /// In en, this message translates to:
  /// **'How many'**
  String get wordHowMany;

  /// No description provided for @wordHowMuch.
  ///
  /// In en, this message translates to:
  /// **'How much'**
  String get wordHowMuch;

  /// No description provided for @wordHowLong.
  ///
  /// In en, this message translates to:
  /// **'How long'**
  String get wordHowLong;

  /// No description provided for @wordHowFar.
  ///
  /// In en, this message translates to:
  /// **'How far'**
  String get wordHowFar;

  /// No description provided for @wordHowOld.
  ///
  /// In en, this message translates to:
  /// **'How old'**
  String get wordHowOld;

  /// No description provided for @wordHowOften.
  ///
  /// In en, this message translates to:
  /// **'How often'**
  String get wordHowOften;

  /// No description provided for @wordWith.
  ///
  /// In en, this message translates to:
  /// **'With'**
  String get wordWith;

  /// No description provided for @wordWithout.
  ///
  /// In en, this message translates to:
  /// **'Without'**
  String get wordWithout;

  /// No description provided for @wordIn.
  ///
  /// In en, this message translates to:
  /// **'In'**
  String get wordIn;

  /// No description provided for @wordOut.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get wordOut;

  /// No description provided for @wordUp.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get wordUp;

  /// No description provided for @wordDown.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get wordDown;

  /// No description provided for @wordLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get wordLeft;

  /// No description provided for @wordRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get wordRight;

  /// No description provided for @wordNear.
  ///
  /// In en, this message translates to:
  /// **'Near'**
  String get wordNear;

  /// No description provided for @wordFar.
  ///
  /// In en, this message translates to:
  /// **'Far'**
  String get wordFar;

  /// No description provided for @wordHere.
  ///
  /// In en, this message translates to:
  /// **'Here'**
  String get wordHere;

  /// No description provided for @wordThere.
  ///
  /// In en, this message translates to:
  /// **'There'**
  String get wordThere;

  /// No description provided for @wordInside.
  ///
  /// In en, this message translates to:
  /// **'Inside'**
  String get wordInside;

  /// No description provided for @wordOutside.
  ///
  /// In en, this message translates to:
  /// **'Outside'**
  String get wordOutside;

  /// No description provided for @wordAbove.
  ///
  /// In en, this message translates to:
  /// **'Above'**
  String get wordAbove;

  /// No description provided for @wordBelow.
  ///
  /// In en, this message translates to:
  /// **'Below'**
  String get wordBelow;

  /// No description provided for @wordBetween.
  ///
  /// In en, this message translates to:
  /// **'Between'**
  String get wordBetween;

  /// No description provided for @wordAround.
  ///
  /// In en, this message translates to:
  /// **'Around'**
  String get wordAround;

  /// No description provided for @wordAcross.
  ///
  /// In en, this message translates to:
  /// **'Across'**
  String get wordAcross;

  /// No description provided for @wordThrough.
  ///
  /// In en, this message translates to:
  /// **'Through'**
  String get wordThrough;

  /// No description provided for @wordAlong.
  ///
  /// In en, this message translates to:
  /// **'Along'**
  String get wordAlong;

  /// No description provided for @wordToward.
  ///
  /// In en, this message translates to:
  /// **'Toward'**
  String get wordToward;

  /// No description provided for @wordAwayFrom.
  ///
  /// In en, this message translates to:
  /// **'Away'**
  String get wordAwayFrom;

  /// No description provided for @wordBehind.
  ///
  /// In en, this message translates to:
  /// **'Behind'**
  String get wordBehind;

  /// No description provided for @wordAhead.
  ///
  /// In en, this message translates to:
  /// **'Ahead'**
  String get wordAhead;

  /// No description provided for @wordFront.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get wordFront;

  /// No description provided for @wordBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get wordBack;

  /// No description provided for @wordSide.
  ///
  /// In en, this message translates to:
  /// **'Side'**
  String get wordSide;

  /// No description provided for @wordTop.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get wordTop;

  /// No description provided for @wordBottom.
  ///
  /// In en, this message translates to:
  /// **'Bottom'**
  String get wordBottom;

  /// No description provided for @wordMiddle.
  ///
  /// In en, this message translates to:
  /// **'Middle'**
  String get wordMiddle;

  /// No description provided for @wordCenter.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get wordCenter;

  /// No description provided for @wordCorner.
  ///
  /// In en, this message translates to:
  /// **'Corner'**
  String get wordCorner;

  /// No description provided for @wordEdge.
  ///
  /// In en, this message translates to:
  /// **'Edge'**
  String get wordEdge;

  /// No description provided for @wordCrush.
  ///
  /// In en, this message translates to:
  /// **'Crush'**
  String get wordCrush;

  /// No description provided for @wordMatch.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get wordMatch;

  /// No description provided for @wordMatches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get wordMatches;

  /// No description provided for @wordMatched.
  ///
  /// In en, this message translates to:
  /// **'Matched'**
  String get wordMatched;

  /// No description provided for @wordMatching.
  ///
  /// In en, this message translates to:
  /// **'Matching'**
  String get wordMatching;

  /// No description provided for @wordUnmatched.
  ///
  /// In en, this message translates to:
  /// **'Unmatched'**
  String get wordUnmatched;

  /// No description provided for @wordConnection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get wordConnection;

  /// No description provided for @wordConnections.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get wordConnections;

  /// No description provided for @wordChemistry.
  ///
  /// In en, this message translates to:
  /// **'Chemistry'**
  String get wordChemistry;

  /// No description provided for @wordSpark.
  ///
  /// In en, this message translates to:
  /// **'Spark'**
  String get wordSpark;

  /// No description provided for @wordDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get wordDate;

  /// No description provided for @wordDates.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get wordDates;

  /// No description provided for @wordDating.
  ///
  /// In en, this message translates to:
  /// **'Dating'**
  String get wordDating;

  /// No description provided for @wordRomance.
  ///
  /// In en, this message translates to:
  /// **'Romance'**
  String get wordRomance;

  /// No description provided for @wordSingle.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get wordSingle;

  /// No description provided for @wordCouple.
  ///
  /// In en, this message translates to:
  /// **'Couple'**
  String get wordCouple;

  /// No description provided for @wordRelationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get wordRelationship;

  /// No description provided for @wordRelationships.
  ///
  /// In en, this message translates to:
  /// **'Relationships'**
  String get wordRelationships;

  /// No description provided for @wordPartner.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get wordPartner;

  /// No description provided for @wordSoulmate.
  ///
  /// In en, this message translates to:
  /// **'Soulmate'**
  String get wordSoulmate;

  /// No description provided for @wordInterested.
  ///
  /// In en, this message translates to:
  /// **'Interested'**
  String get wordInterested;

  /// No description provided for @wordInterest.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get wordInterest;

  /// No description provided for @wordInterests.
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get wordInterests;

  /// No description provided for @wordMutual.
  ///
  /// In en, this message translates to:
  /// **'Mutual'**
  String get wordMutual;

  /// No description provided for @wordCompatible.
  ///
  /// In en, this message translates to:
  /// **'Compatible'**
  String get wordCompatible;

  /// No description provided for @wordCompatibility.
  ///
  /// In en, this message translates to:
  /// **'Compatibility'**
  String get wordCompatibility;

  /// No description provided for @wordAttraction.
  ///
  /// In en, this message translates to:
  /// **'Attraction'**
  String get wordAttraction;

  /// No description provided for @wordFlirt.
  ///
  /// In en, this message translates to:
  /// **'Flirt'**
  String get wordFlirt;

  /// No description provided for @wordFlirting.
  ///
  /// In en, this message translates to:
  /// **'Flirting'**
  String get wordFlirting;

  /// No description provided for @wordFlirty.
  ///
  /// In en, this message translates to:
  /// **'Flirty'**
  String get wordFlirty;

  /// No description provided for @wordSwipe.
  ///
  /// In en, this message translates to:
  /// **'Swipe'**
  String get wordSwipe;

  /// No description provided for @wordSwiped.
  ///
  /// In en, this message translates to:
  /// **'Swiped'**
  String get wordSwiped;

  /// No description provided for @wordSwiping.
  ///
  /// In en, this message translates to:
  /// **'Swiping'**
  String get wordSwiping;

  /// No description provided for @wordLiked.
  ///
  /// In en, this message translates to:
  /// **'Liked'**
  String get wordLiked;

  /// No description provided for @wordLikes.
  ///
  /// In en, this message translates to:
  /// **'Likes'**
  String get wordLikes;

  /// No description provided for @wordLiking.
  ///
  /// In en, this message translates to:
  /// **'Liking'**
  String get wordLiking;

  /// No description provided for @wordPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get wordPassed;

  /// No description provided for @wordPassing.
  ///
  /// In en, this message translates to:
  /// **'Passing'**
  String get wordPassing;

  /// No description provided for @wordSuperLike.
  ///
  /// In en, this message translates to:
  /// **'Super Like'**
  String get wordSuperLike;

  /// No description provided for @wordSuperLiked.
  ///
  /// In en, this message translates to:
  /// **'Super Liked'**
  String get wordSuperLiked;

  /// No description provided for @wordBoost.
  ///
  /// In en, this message translates to:
  /// **'Boost'**
  String get wordBoost;

  /// No description provided for @wordBoosted.
  ///
  /// In en, this message translates to:
  /// **'Boosted'**
  String get wordBoosted;

  /// No description provided for @wordBoosting.
  ///
  /// In en, this message translates to:
  /// **'Boosting'**
  String get wordBoosting;

  /// No description provided for @wordRewind.
  ///
  /// In en, this message translates to:
  /// **'Rewind'**
  String get wordRewind;

  /// No description provided for @wordRewinded.
  ///
  /// In en, this message translates to:
  /// **'Rewinded'**
  String get wordRewinded;

  /// No description provided for @wordChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get wordChat;

  /// No description provided for @wordChats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get wordChats;

  /// No description provided for @wordChatting.
  ///
  /// In en, this message translates to:
  /// **'Chatting'**
  String get wordChatting;

  /// No description provided for @wordMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get wordMessage;

  /// No description provided for @wordMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get wordMessages;

  /// No description provided for @wordMessaging.
  ///
  /// In en, this message translates to:
  /// **'Messaging'**
  String get wordMessaging;

  /// No description provided for @wordConversation.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get wordConversation;

  /// No description provided for @wordConversations.
  ///
  /// In en, this message translates to:
  /// **'Conversations'**
  String get wordConversations;

  /// No description provided for @wordProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get wordProfile;

  /// No description provided for @wordProfiles.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get wordProfiles;

  /// No description provided for @wordBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get wordBio;

  /// No description provided for @wordPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get wordPhoto;

  /// No description provided for @wordPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get wordPhotos;

  /// No description provided for @wordVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get wordVideo;

  /// No description provided for @wordVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get wordVideos;

  /// No description provided for @wordGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get wordGallery;

  /// No description provided for @wordAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get wordAlbum;

  /// No description provided for @wordVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get wordVoice;

  /// No description provided for @wordAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get wordAudio;

  /// No description provided for @wordCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get wordCamera;

  /// No description provided for @wordImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get wordImage;

  /// No description provided for @wordImages.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get wordImages;

  /// No description provided for @wordPicture.
  ///
  /// In en, this message translates to:
  /// **'Picture'**
  String get wordPicture;

  /// No description provided for @wordPictures.
  ///
  /// In en, this message translates to:
  /// **'Pictures'**
  String get wordPictures;

  /// No description provided for @wordHeartbeat.
  ///
  /// In en, this message translates to:
  /// **'Heartbeat'**
  String get wordHeartbeat;

  /// No description provided for @wordHeart.
  ///
  /// In en, this message translates to:
  /// **'Heart'**
  String get wordHeart;

  /// No description provided for @wordHearts.
  ///
  /// In en, this message translates to:
  /// **'Hearts'**
  String get wordHearts;

  /// No description provided for @wordStar.
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get wordStar;

  /// No description provided for @wordStars.
  ///
  /// In en, this message translates to:
  /// **'Stars'**
  String get wordStars;

  /// No description provided for @wordDiamond.
  ///
  /// In en, this message translates to:
  /// **'Diamond'**
  String get wordDiamond;

  /// No description provided for @wordFlame.
  ///
  /// In en, this message translates to:
  /// **'Flame'**
  String get wordFlame;

  /// No description provided for @wordFire.
  ///
  /// In en, this message translates to:
  /// **'Fire'**
  String get wordFire;

  /// No description provided for @wordHotness.
  ///
  /// In en, this message translates to:
  /// **'Hotness'**
  String get wordHotness;

  /// No description provided for @wordVibes.
  ///
  /// In en, this message translates to:
  /// **'Vibes'**
  String get wordVibes;

  /// No description provided for @wordVibe.
  ///
  /// In en, this message translates to:
  /// **'Vibe'**
  String get wordVibe;

  /// No description provided for @wordMood.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get wordMood;

  /// No description provided for @wordEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get wordEnergy;

  /// No description provided for @wordAura.
  ///
  /// In en, this message translates to:
  /// **'Aura'**
  String get wordAura;

  /// No description provided for @wordPersonality.
  ///
  /// In en, this message translates to:
  /// **'Personality'**
  String get wordPersonality;

  /// No description provided for @wordCharacter.
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get wordCharacter;

  /// No description provided for @wordValues.
  ///
  /// In en, this message translates to:
  /// **'Values'**
  String get wordValues;

  /// No description provided for @wordGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get wordGoals;

  /// No description provided for @wordDreams.
  ///
  /// In en, this message translates to:
  /// **'Dreams'**
  String get wordDreams;

  /// No description provided for @wordHobbies.
  ///
  /// In en, this message translates to:
  /// **'Hobbies'**
  String get wordHobbies;

  /// No description provided for @wordPassion.
  ///
  /// In en, this message translates to:
  /// **'Passion'**
  String get wordPassion;

  /// No description provided for @wordAdventure.
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get wordAdventure;

  /// No description provided for @wordTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get wordTravel;

  /// No description provided for @wordTraveling.
  ///
  /// In en, this message translates to:
  /// **'Traveling'**
  String get wordTraveling;

  /// No description provided for @wordExploring.
  ///
  /// In en, this message translates to:
  /// **'Exploring'**
  String get wordExploring;

  /// No description provided for @wordFun.
  ///
  /// In en, this message translates to:
  /// **'Fun'**
  String get wordFun;

  /// No description provided for @wordLaughter.
  ///
  /// In en, this message translates to:
  /// **'Laughter'**
  String get wordLaughter;

  /// No description provided for @wordSmile.
  ///
  /// In en, this message translates to:
  /// **'Smile'**
  String get wordSmile;

  /// No description provided for @wordSmiles.
  ///
  /// In en, this message translates to:
  /// **'Smiles'**
  String get wordSmiles;

  /// No description provided for @wordSmiling.
  ///
  /// In en, this message translates to:
  /// **'Smiling'**
  String get wordSmiling;

  /// No description provided for @wordKiss.
  ///
  /// In en, this message translates to:
  /// **'Kiss'**
  String get wordKiss;

  /// No description provided for @wordKisses.
  ///
  /// In en, this message translates to:
  /// **'Kisses'**
  String get wordKisses;

  /// No description provided for @wordHug.
  ///
  /// In en, this message translates to:
  /// **'Hug'**
  String get wordHug;

  /// No description provided for @wordHugs.
  ///
  /// In en, this message translates to:
  /// **'Hugs'**
  String get wordHugs;

  /// No description provided for @wordCuddle.
  ///
  /// In en, this message translates to:
  /// **'Cuddle'**
  String get wordCuddle;

  /// No description provided for @wordCuddling.
  ///
  /// In en, this message translates to:
  /// **'Cuddling'**
  String get wordCuddling;

  /// No description provided for @wordIntimate.
  ///
  /// In en, this message translates to:
  /// **'Intimate'**
  String get wordIntimate;

  /// No description provided for @wordIntimacy.
  ///
  /// In en, this message translates to:
  /// **'Intimacy'**
  String get wordIntimacy;

  /// No description provided for @wordAffection.
  ///
  /// In en, this message translates to:
  /// **'Affection'**
  String get wordAffection;

  /// No description provided for @wordAffectionate.
  ///
  /// In en, this message translates to:
  /// **'Affectionate'**
  String get wordAffectionate;

  /// No description provided for @wordCaring.
  ///
  /// In en, this message translates to:
  /// **'Caring'**
  String get wordCaring;

  /// No description provided for @wordLoving.
  ///
  /// In en, this message translates to:
  /// **'Loving'**
  String get wordLoving;

  /// No description provided for @wordDevoted.
  ///
  /// In en, this message translates to:
  /// **'Devoted'**
  String get wordDevoted;

  /// No description provided for @wordCommitted.
  ///
  /// In en, this message translates to:
  /// **'Committed'**
  String get wordCommitted;

  /// No description provided for @wordCommitment.
  ///
  /// In en, this message translates to:
  /// **'Commitment'**
  String get wordCommitment;

  /// No description provided for @wordSeriousRel.
  ///
  /// In en, this message translates to:
  /// **'Serious'**
  String get wordSeriousRel;

  /// No description provided for @wordCasual.
  ///
  /// In en, this message translates to:
  /// **'Casual'**
  String get wordCasual;

  /// No description provided for @wordFriendship.
  ///
  /// In en, this message translates to:
  /// **'Friendship'**
  String get wordFriendship;

  /// No description provided for @wordFriend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get wordFriend;

  /// No description provided for @wordFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get wordFriends;

  /// No description provided for @wordBestFriend.
  ///
  /// In en, this message translates to:
  /// **'Best Friend'**
  String get wordBestFriend;

  /// No description provided for @wordSomethingSerious.
  ///
  /// In en, this message translates to:
  /// **'Something Serious'**
  String get wordSomethingSerious;

  /// No description provided for @wordLongTerm.
  ///
  /// In en, this message translates to:
  /// **'Long Term'**
  String get wordLongTerm;

  /// No description provided for @wordShortTerm.
  ///
  /// In en, this message translates to:
  /// **'Short Term'**
  String get wordShortTerm;

  /// No description provided for @wordOpenTo.
  ///
  /// In en, this message translates to:
  /// **'Open To'**
  String get wordOpenTo;

  /// No description provided for @wordLookingFor.
  ///
  /// In en, this message translates to:
  /// **'Looking For'**
  String get wordLookingFor;

  /// No description provided for @wordSeekingFor.
  ///
  /// In en, this message translates to:
  /// **'Seeking'**
  String get wordSeekingFor;

  /// No description provided for @wordWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get wordWaiting;

  /// No description provided for @wordSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching'**
  String get wordSearching;

  /// No description provided for @wordNotification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get wordNotification;

  /// No description provided for @wordAlert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get wordAlert;

  /// No description provided for @wordWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get wordWarning;

  /// No description provided for @wordInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get wordInfo;

  /// No description provided for @wordInformation.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get wordInformation;

  /// No description provided for @wordDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get wordDetails;

  /// No description provided for @wordData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get wordData;

  /// No description provided for @wordContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get wordContent;

  /// No description provided for @wordMedia.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get wordMedia;

  /// No description provided for @wordLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get wordLink;

  /// No description provided for @wordLinks.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get wordLinks;

  /// No description provided for @wordURL.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get wordURL;

  /// No description provided for @wordAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get wordAddress;

  /// No description provided for @wordName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get wordName;

  /// No description provided for @wordUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get wordUsername;

  /// No description provided for @wordNickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get wordNickname;

  /// No description provided for @wordAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get wordAccount;

  /// No description provided for @wordUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get wordUser;

  /// No description provided for @wordUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get wordUsers;

  /// No description provided for @wordPeople.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get wordPeople;

  /// No description provided for @wordPerson.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get wordPerson;

  /// No description provided for @wordGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get wordGroup;

  /// No description provided for @wordGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get wordGroups;

  /// No description provided for @wordTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get wordTeam;

  /// No description provided for @wordCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get wordCommunity;

  /// No description provided for @wordMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get wordMember;

  /// No description provided for @wordMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get wordMembers;

  /// No description provided for @wordAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get wordAdmin;

  /// No description provided for @wordModerator.
  ///
  /// In en, this message translates to:
  /// **'Moderator'**
  String get wordModerator;

  /// No description provided for @wordGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get wordGuest;

  /// No description provided for @wordVisitor.
  ///
  /// In en, this message translates to:
  /// **'Visitor'**
  String get wordVisitor;

  /// No description provided for @wordFollower.
  ///
  /// In en, this message translates to:
  /// **'Follower'**
  String get wordFollower;

  /// No description provided for @wordFollowers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get wordFollowers;

  /// No description provided for @wordFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get wordFollowing;

  /// No description provided for @wordFan.
  ///
  /// In en, this message translates to:
  /// **'Fan'**
  String get wordFan;

  /// No description provided for @wordFans.
  ///
  /// In en, this message translates to:
  /// **'Fans'**
  String get wordFans;

  /// No description provided for @wordSubscriber.
  ///
  /// In en, this message translates to:
  /// **'Subscriber'**
  String get wordSubscriber;

  /// No description provided for @wordSubscribers.
  ///
  /// In en, this message translates to:
  /// **'Subscribers'**
  String get wordSubscribers;

  /// No description provided for @wordFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get wordFile;

  /// No description provided for @wordFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get wordFiles;

  /// No description provided for @wordFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get wordFolder;

  /// No description provided for @wordFolders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get wordFolders;

  /// No description provided for @wordDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get wordDocument;

  /// No description provided for @wordDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get wordDocuments;

  /// No description provided for @wordText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get wordText;

  /// No description provided for @wordEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get wordEmail;

  /// No description provided for @wordPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get wordPhone;

  /// No description provided for @wordNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get wordNumber;

  /// No description provided for @wordCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get wordCode;

  /// No description provided for @wordPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get wordPassword;

  /// No description provided for @wordPasscode.
  ///
  /// In en, this message translates to:
  /// **'Passcode'**
  String get wordPasscode;

  /// No description provided for @wordPIN.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get wordPIN;

  /// No description provided for @wordKey.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get wordKey;

  /// No description provided for @wordToken.
  ///
  /// In en, this message translates to:
  /// **'Token'**
  String get wordToken;

  /// No description provided for @wordSession.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get wordSession;

  /// No description provided for @wordApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get wordApp;

  /// No description provided for @wordApplication.
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get wordApplication;

  /// No description provided for @wordWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get wordWebsite;

  /// No description provided for @wordPage.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get wordPage;

  /// No description provided for @wordPages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get wordPages;

  /// No description provided for @wordScreen.
  ///
  /// In en, this message translates to:
  /// **'Screen'**
  String get wordScreen;

  /// No description provided for @wordScreens.
  ///
  /// In en, this message translates to:
  /// **'Screens'**
  String get wordScreens;

  /// No description provided for @wordSection.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get wordSection;

  /// No description provided for @wordSections.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get wordSections;

  /// No description provided for @wordCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get wordCategory;

  /// No description provided for @wordCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get wordCategories;

  /// No description provided for @wordTag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get wordTag;

  /// No description provided for @wordTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get wordTags;

  /// No description provided for @wordLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get wordLabel;

  /// No description provided for @wordLabels.
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get wordLabels;

  /// No description provided for @wordTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get wordTitle;

  /// No description provided for @wordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Subtitle'**
  String get wordSubtitle;

  /// No description provided for @wordDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get wordDescription;

  /// No description provided for @wordSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get wordSummary;

  /// No description provided for @wordOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get wordOverview;

  /// No description provided for @wordPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get wordPreview;

  /// No description provided for @wordReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get wordReview;

  /// No description provided for @wordReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get wordReviews;

  /// No description provided for @wordRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get wordRating;

  /// No description provided for @wordRatings.
  ///
  /// In en, this message translates to:
  /// **'Ratings'**
  String get wordRatings;

  /// No description provided for @wordFeedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get wordFeedback;

  /// No description provided for @wordComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get wordComment;

  /// No description provided for @wordComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get wordComments;

  /// No description provided for @wordReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get wordReply;

  /// No description provided for @wordReplies.
  ///
  /// In en, this message translates to:
  /// **'Replies'**
  String get wordReplies;

  /// No description provided for @wordPost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get wordPost;

  /// No description provided for @wordPosts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get wordPosts;

  /// No description provided for @wordStory.
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get wordStory;

  /// No description provided for @wordStories.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get wordStories;

  /// No description provided for @wordEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get wordEvent;

  /// No description provided for @wordEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get wordEvents;

  /// No description provided for @wordNews.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get wordNews;

  /// No description provided for @wordUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get wordUpdate;

  /// No description provided for @wordUpdates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get wordUpdates;

  /// No description provided for @wordVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get wordVersion;

  /// No description provided for @wordRelease.
  ///
  /// In en, this message translates to:
  /// **'Release'**
  String get wordRelease;

  /// No description provided for @wordFeature.
  ///
  /// In en, this message translates to:
  /// **'Feature'**
  String get wordFeature;

  /// No description provided for @wordFeatures.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get wordFeatures;

  /// No description provided for @wordOption.
  ///
  /// In en, this message translates to:
  /// **'Option'**
  String get wordOption;

  /// No description provided for @wordOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get wordOptions;

  /// No description provided for @wordChoice.
  ///
  /// In en, this message translates to:
  /// **'Choice'**
  String get wordChoice;

  /// No description provided for @wordChoices.
  ///
  /// In en, this message translates to:
  /// **'Choices'**
  String get wordChoices;

  /// No description provided for @wordPreference.
  ///
  /// In en, this message translates to:
  /// **'Preference'**
  String get wordPreference;

  /// No description provided for @wordPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get wordPreferences;

  /// No description provided for @wordSetting.
  ///
  /// In en, this message translates to:
  /// **'Setting'**
  String get wordSetting;

  /// No description provided for @wordSettingsNoun.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get wordSettingsNoun;

  /// No description provided for @wordConfig.
  ///
  /// In en, this message translates to:
  /// **'Config'**
  String get wordConfig;

  /// No description provided for @wordConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get wordConfiguration;

  /// No description provided for @wordPermission.
  ///
  /// In en, this message translates to:
  /// **'Permission'**
  String get wordPermission;

  /// No description provided for @wordPermissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get wordPermissions;

  /// No description provided for @wordAccess.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get wordAccess;

  /// No description provided for @wordPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get wordPrivacy;

  /// No description provided for @wordSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get wordSecurity;

  /// No description provided for @wordSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get wordSupport;

  /// No description provided for @wordService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get wordService;

  /// No description provided for @wordServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get wordServices;

  /// No description provided for @wordTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get wordTerms;

  /// No description provided for @wordPolicy.
  ///
  /// In en, this message translates to:
  /// **'Policy'**
  String get wordPolicy;

  /// No description provided for @wordAgreement.
  ///
  /// In en, this message translates to:
  /// **'Agreement'**
  String get wordAgreement;

  /// No description provided for @wordContract.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get wordContract;

  /// No description provided for @wordPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get wordPlan;

  /// No description provided for @wordPlans.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get wordPlans;

  /// No description provided for @wordPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get wordPrice;

  /// No description provided for @wordPrices.
  ///
  /// In en, this message translates to:
  /// **'Prices'**
  String get wordPrices;

  /// No description provided for @wordCost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get wordCost;

  /// No description provided for @wordFee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get wordFee;

  /// No description provided for @wordFees.
  ///
  /// In en, this message translates to:
  /// **'Fees'**
  String get wordFees;

  /// No description provided for @wordDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get wordDiscount;

  /// No description provided for @wordOffer.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get wordOffer;

  /// No description provided for @wordOffers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get wordOffers;

  /// No description provided for @wordDeal.
  ///
  /// In en, this message translates to:
  /// **'Deal'**
  String get wordDeal;

  /// No description provided for @wordDeals.
  ///
  /// In en, this message translates to:
  /// **'Deals'**
  String get wordDeals;

  /// No description provided for @wordPromotion.
  ///
  /// In en, this message translates to:
  /// **'Promotion'**
  String get wordPromotion;

  /// No description provided for @wordPromotions.
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get wordPromotions;

  /// No description provided for @wordCoupon.
  ///
  /// In en, this message translates to:
  /// **'Coupon'**
  String get wordCoupon;

  /// No description provided for @wordGift.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get wordGift;

  /// No description provided for @wordGifts.
  ///
  /// In en, this message translates to:
  /// **'Gifts'**
  String get wordGifts;

  /// No description provided for @wordReward.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get wordReward;

  /// No description provided for @wordRewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get wordRewards;

  /// No description provided for @wordBonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get wordBonus;

  /// No description provided for @wordBonuses.
  ///
  /// In en, this message translates to:
  /// **'Bonuses'**
  String get wordBonuses;

  /// No description provided for @wordCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get wordCredit;

  /// No description provided for @wordCredits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get wordCredits;

  /// No description provided for @wordCoin.
  ///
  /// In en, this message translates to:
  /// **'Coin'**
  String get wordCoin;

  /// No description provided for @wordCoins.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get wordCoins;

  /// No description provided for @wordPoint.
  ///
  /// In en, this message translates to:
  /// **'Point'**
  String get wordPoint;

  /// No description provided for @wordPoints.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get wordPoints;

  /// No description provided for @wordLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get wordLevel;

  /// No description provided for @wordLevels.
  ///
  /// In en, this message translates to:
  /// **'Levels'**
  String get wordLevels;

  /// No description provided for @wordRank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get wordRank;

  /// No description provided for @wordBadge.
  ///
  /// In en, this message translates to:
  /// **'Badge'**
  String get wordBadge;

  /// No description provided for @wordBadges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get wordBadges;

  /// No description provided for @wordAchievement.
  ///
  /// In en, this message translates to:
  /// **'Achievement'**
  String get wordAchievement;

  /// No description provided for @wordAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get wordAchievements;

  /// No description provided for @wordMilestone.
  ///
  /// In en, this message translates to:
  /// **'Milestone'**
  String get wordMilestone;

  /// No description provided for @wordProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get wordProgress;

  /// No description provided for @wordGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get wordGoal;

  /// No description provided for @wordTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get wordTarget;

  /// No description provided for @wordResult.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get wordResult;

  /// No description provided for @wordResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get wordResults;

  /// No description provided for @wordStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get wordStats;

  /// No description provided for @wordStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get wordStatistics;

  /// No description provided for @wordAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get wordAnalytics;

  /// No description provided for @wordInsight.
  ///
  /// In en, this message translates to:
  /// **'Insight'**
  String get wordInsight;

  /// No description provided for @wordInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get wordInsights;

  /// No description provided for @wordReport.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get wordReport;

  /// No description provided for @wordReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get wordReports;

  /// No description provided for @wordDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get wordDashboard;

  /// No description provided for @wordWorld.
  ///
  /// In en, this message translates to:
  /// **'World'**
  String get wordWorld;

  /// No description provided for @wordCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get wordCountry;

  /// No description provided for @wordCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get wordCity;

  /// No description provided for @wordTown.
  ///
  /// In en, this message translates to:
  /// **'Town'**
  String get wordTown;

  /// No description provided for @wordState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get wordState;

  /// No description provided for @wordProvince.
  ///
  /// In en, this message translates to:
  /// **'Province'**
  String get wordProvince;

  /// No description provided for @wordRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get wordRegion;

  /// No description provided for @wordArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get wordArea;

  /// No description provided for @wordPlace.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get wordPlace;

  /// No description provided for @wordLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get wordLocation;

  /// No description provided for @wordDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get wordDistance;

  /// No description provided for @wordDirection.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get wordDirection;

  /// No description provided for @wordMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get wordMap;

  /// No description provided for @wordRoute.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get wordRoute;

  /// No description provided for @wordWay.
  ///
  /// In en, this message translates to:
  /// **'Way'**
  String get wordWay;

  /// No description provided for @wordPath.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get wordPath;

  /// No description provided for @wordRoad.
  ///
  /// In en, this message translates to:
  /// **'Road'**
  String get wordRoad;

  /// No description provided for @wordStreet.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get wordStreet;

  /// No description provided for @wordPark.
  ///
  /// In en, this message translates to:
  /// **'Park'**
  String get wordPark;

  /// No description provided for @wordBeach.
  ///
  /// In en, this message translates to:
  /// **'Beach'**
  String get wordBeach;

  /// No description provided for @wordMountain.
  ///
  /// In en, this message translates to:
  /// **'Mountain'**
  String get wordMountain;

  /// No description provided for @wordLake.
  ///
  /// In en, this message translates to:
  /// **'Lake'**
  String get wordLake;

  /// No description provided for @wordRiver.
  ///
  /// In en, this message translates to:
  /// **'River'**
  String get wordRiver;

  /// No description provided for @wordSea.
  ///
  /// In en, this message translates to:
  /// **'Sea'**
  String get wordSea;

  /// No description provided for @wordOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get wordOcean;

  /// No description provided for @wordSky.
  ///
  /// In en, this message translates to:
  /// **'Sky'**
  String get wordSky;

  /// No description provided for @wordSun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get wordSun;

  /// No description provided for @wordMoon.
  ///
  /// In en, this message translates to:
  /// **'Moon'**
  String get wordMoon;

  /// No description provided for @wordWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get wordWeather;

  /// No description provided for @wordSeason.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get wordSeason;

  /// No description provided for @wordSpring.
  ///
  /// In en, this message translates to:
  /// **'Spring'**
  String get wordSpring;

  /// No description provided for @wordSummer.
  ///
  /// In en, this message translates to:
  /// **'Summer'**
  String get wordSummer;

  /// No description provided for @wordAutumn.
  ///
  /// In en, this message translates to:
  /// **'Autumn'**
  String get wordAutumn;

  /// No description provided for @wordFall.
  ///
  /// In en, this message translates to:
  /// **'Fall'**
  String get wordFall;

  /// No description provided for @wordWinter.
  ///
  /// In en, this message translates to:
  /// **'Winter'**
  String get wordWinter;

  /// No description provided for @wordFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get wordFamily;

  /// No description provided for @wordParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get wordParent;

  /// No description provided for @wordParents.
  ///
  /// In en, this message translates to:
  /// **'Parents'**
  String get wordParents;

  /// No description provided for @wordMother.
  ///
  /// In en, this message translates to:
  /// **'Mother'**
  String get wordMother;

  /// No description provided for @wordFather.
  ///
  /// In en, this message translates to:
  /// **'Father'**
  String get wordFather;

  /// No description provided for @wordMom.
  ///
  /// In en, this message translates to:
  /// **'Mom'**
  String get wordMom;

  /// No description provided for @wordDad.
  ///
  /// In en, this message translates to:
  /// **'Dad'**
  String get wordDad;

  /// No description provided for @wordChild.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get wordChild;

  /// No description provided for @wordChildren.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get wordChildren;

  /// No description provided for @wordKid.
  ///
  /// In en, this message translates to:
  /// **'Kid'**
  String get wordKid;

  /// No description provided for @wordKids.
  ///
  /// In en, this message translates to:
  /// **'Kids'**
  String get wordKids;

  /// No description provided for @wordBaby.
  ///
  /// In en, this message translates to:
  /// **'Baby'**
  String get wordBaby;

  /// No description provided for @wordSon.
  ///
  /// In en, this message translates to:
  /// **'Son'**
  String get wordSon;

  /// No description provided for @wordDaughter.
  ///
  /// In en, this message translates to:
  /// **'Daughter'**
  String get wordDaughter;

  /// No description provided for @wordBrother.
  ///
  /// In en, this message translates to:
  /// **'Brother'**
  String get wordBrother;

  /// No description provided for @wordSister.
  ///
  /// In en, this message translates to:
  /// **'Sister'**
  String get wordSister;

  /// No description provided for @wordGrandparent.
  ///
  /// In en, this message translates to:
  /// **'Grandparent'**
  String get wordGrandparent;

  /// No description provided for @wordGrandparents.
  ///
  /// In en, this message translates to:
  /// **'Grandparents'**
  String get wordGrandparents;

  /// No description provided for @wordAunt.
  ///
  /// In en, this message translates to:
  /// **'Aunt'**
  String get wordAunt;

  /// No description provided for @wordUncle.
  ///
  /// In en, this message translates to:
  /// **'Uncle'**
  String get wordUncle;

  /// No description provided for @wordCousin.
  ///
  /// In en, this message translates to:
  /// **'Cousin'**
  String get wordCousin;

  /// No description provided for @wordPet.
  ///
  /// In en, this message translates to:
  /// **'Pet'**
  String get wordPet;

  /// No description provided for @wordPets.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get wordPets;

  /// No description provided for @wordDog.
  ///
  /// In en, this message translates to:
  /// **'Dog'**
  String get wordDog;

  /// No description provided for @wordCat.
  ///
  /// In en, this message translates to:
  /// **'Cat'**
  String get wordCat;

  /// No description provided for @wordAnimal.
  ///
  /// In en, this message translates to:
  /// **'Animal'**
  String get wordAnimal;

  /// No description provided for @wordAnimals.
  ///
  /// In en, this message translates to:
  /// **'Animals'**
  String get wordAnimals;

  /// No description provided for @wordFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get wordFood;

  /// No description provided for @wordDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get wordDinner;

  /// No description provided for @wordLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get wordLunch;

  /// No description provided for @wordBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get wordBreakfast;

  /// No description provided for @wordSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get wordSnack;

  /// No description provided for @wordDessert.
  ///
  /// In en, this message translates to:
  /// **'Dessert'**
  String get wordDessert;

  /// No description provided for @wordCoffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get wordCoffee;

  /// No description provided for @wordTea.
  ///
  /// In en, this message translates to:
  /// **'Tea'**
  String get wordTea;

  /// No description provided for @wordWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get wordWater;

  /// No description provided for @wordWine.
  ///
  /// In en, this message translates to:
  /// **'Wine'**
  String get wordWine;

  /// No description provided for @wordBeer.
  ///
  /// In en, this message translates to:
  /// **'Beer'**
  String get wordBeer;

  /// No description provided for @wordCocktail.
  ///
  /// In en, this message translates to:
  /// **'Cocktail'**
  String get wordCocktail;

  /// No description provided for @wordMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get wordMusic;

  /// No description provided for @wordSong.
  ///
  /// In en, this message translates to:
  /// **'Song'**
  String get wordSong;

  /// No description provided for @wordSongs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get wordSongs;

  /// No description provided for @wordMovie.
  ///
  /// In en, this message translates to:
  /// **'Movie'**
  String get wordMovie;

  /// No description provided for @wordMovies.
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get wordMovies;

  /// No description provided for @wordFilm.
  ///
  /// In en, this message translates to:
  /// **'Film'**
  String get wordFilm;

  /// No description provided for @wordFilms.
  ///
  /// In en, this message translates to:
  /// **'Films'**
  String get wordFilms;

  /// No description provided for @wordShowNoun.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get wordShowNoun;

  /// No description provided for @wordShows.
  ///
  /// In en, this message translates to:
  /// **'Shows'**
  String get wordShows;

  /// No description provided for @wordSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get wordSeries;

  /// No description provided for @wordBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get wordBook;

  /// No description provided for @wordBooks.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get wordBooks;

  /// No description provided for @wordGame.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get wordGame;

  /// No description provided for @wordGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get wordGames;

  /// No description provided for @wordSport.
  ///
  /// In en, this message translates to:
  /// **'Sport'**
  String get wordSport;

  /// No description provided for @wordSports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get wordSports;

  /// No description provided for @wordExercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get wordExercise;

  /// No description provided for @wordFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness'**
  String get wordFitness;

  /// No description provided for @wordGym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get wordGym;

  /// No description provided for @wordYoga.
  ///
  /// In en, this message translates to:
  /// **'Yoga'**
  String get wordYoga;

  /// No description provided for @wordRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get wordRunning;

  /// No description provided for @wordSwimming.
  ///
  /// In en, this message translates to:
  /// **'Swimming'**
  String get wordSwimming;

  /// No description provided for @wordDancing.
  ///
  /// In en, this message translates to:
  /// **'Dancing'**
  String get wordDancing;

  /// No description provided for @wordCooking.
  ///
  /// In en, this message translates to:
  /// **'Cooking'**
  String get wordCooking;

  /// No description provided for @wordReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get wordReading;

  /// No description provided for @wordWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get wordWriting;

  /// No description provided for @wordPainting.
  ///
  /// In en, this message translates to:
  /// **'Painting'**
  String get wordPainting;

  /// No description provided for @wordDrawing.
  ///
  /// In en, this message translates to:
  /// **'Drawing'**
  String get wordDrawing;

  /// No description provided for @wordPhotography.
  ///
  /// In en, this message translates to:
  /// **'Photography'**
  String get wordPhotography;

  /// No description provided for @wordArt.
  ///
  /// In en, this message translates to:
  /// **'Art'**
  String get wordArt;

  /// No description provided for @wordDesign.
  ///
  /// In en, this message translates to:
  /// **'Design'**
  String get wordDesign;

  /// No description provided for @wordFashion.
  ///
  /// In en, this message translates to:
  /// **'Fashion'**
  String get wordFashion;

  /// No description provided for @wordStyle.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get wordStyle;

  /// No description provided for @wordClothing.
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get wordClothing;

  /// No description provided for @wordClothes.
  ///
  /// In en, this message translates to:
  /// **'Clothes'**
  String get wordClothes;

  /// No description provided for @wordShoes.
  ///
  /// In en, this message translates to:
  /// **'Shoes'**
  String get wordShoes;

  /// No description provided for @wordAccessories.
  ///
  /// In en, this message translates to:
  /// **'Accessories'**
  String get wordAccessories;

  /// No description provided for @wordJewelry.
  ///
  /// In en, this message translates to:
  /// **'Jewelry'**
  String get wordJewelry;

  /// No description provided for @wordMakeup.
  ///
  /// In en, this message translates to:
  /// **'Makeup'**
  String get wordMakeup;

  /// No description provided for @wordBeauty.
  ///
  /// In en, this message translates to:
  /// **'Beauty'**
  String get wordBeauty;

  /// No description provided for @wordHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get wordHealth;

  /// No description provided for @wordWellness.
  ///
  /// In en, this message translates to:
  /// **'Wellness'**
  String get wordWellness;

  /// No description provided for @wordMind.
  ///
  /// In en, this message translates to:
  /// **'Mind'**
  String get wordMind;

  /// No description provided for @wordBody.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get wordBody;

  /// No description provided for @wordSoul.
  ///
  /// In en, this message translates to:
  /// **'Soul'**
  String get wordSoul;

  /// No description provided for @wordSpirit.
  ///
  /// In en, this message translates to:
  /// **'Spirit'**
  String get wordSpirit;

  /// No description provided for @wordLife.
  ///
  /// In en, this message translates to:
  /// **'Life'**
  String get wordLife;

  /// No description provided for @wordDeath.
  ///
  /// In en, this message translates to:
  /// **'Death'**
  String get wordDeath;

  /// No description provided for @wordBirth.
  ///
  /// In en, this message translates to:
  /// **'Birth'**
  String get wordBirth;

  /// No description provided for @wordAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get wordAge;

  /// No description provided for @wordGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get wordGender;

  /// No description provided for @wordMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get wordMale;

  /// No description provided for @wordFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get wordFemale;

  /// No description provided for @wordNonBinary.
  ///
  /// In en, this message translates to:
  /// **'Non-binary'**
  String get wordNonBinary;

  /// No description provided for @orientationStraight.
  ///
  /// In en, this message translates to:
  /// **'Straight'**
  String get orientationStraight;

  /// No description provided for @orientationGay.
  ///
  /// In en, this message translates to:
  /// **'Gay'**
  String get orientationGay;

  /// No description provided for @orientationLesbian.
  ///
  /// In en, this message translates to:
  /// **'Lesbian'**
  String get orientationLesbian;

  /// No description provided for @orientationBisexual.
  ///
  /// In en, this message translates to:
  /// **'Bisexual'**
  String get orientationBisexual;

  /// No description provided for @orientationPansexual.
  ///
  /// In en, this message translates to:
  /// **'Pansexual'**
  String get orientationPansexual;

  /// No description provided for @orientationAsexual.
  ///
  /// In en, this message translates to:
  /// **'Asexual'**
  String get orientationAsexual;

  /// No description provided for @orientationQueer.
  ///
  /// In en, this message translates to:
  /// **'Queer'**
  String get orientationQueer;

  /// No description provided for @orientationQuestioning.
  ///
  /// In en, this message translates to:
  /// **'Questioning'**
  String get orientationQuestioning;

  /// No description provided for @orientationPreferNotToSay.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get orientationPreferNotToSay;

  /// No description provided for @wordMan.
  ///
  /// In en, this message translates to:
  /// **'Man'**
  String get wordMan;

  /// No description provided for @wordWoman.
  ///
  /// In en, this message translates to:
  /// **'Woman'**
  String get wordWoman;

  /// No description provided for @wordBoy.
  ///
  /// In en, this message translates to:
  /// **'Boy'**
  String get wordBoy;

  /// No description provided for @wordGirl.
  ///
  /// In en, this message translates to:
  /// **'Girl'**
  String get wordGirl;

  /// No description provided for @wordGuy.
  ///
  /// In en, this message translates to:
  /// **'Guy'**
  String get wordGuy;

  /// No description provided for @wordLady.
  ///
  /// In en, this message translates to:
  /// **'Lady'**
  String get wordLady;

  /// No description provided for @wordGentleman.
  ///
  /// In en, this message translates to:
  /// **'Gentleman'**
  String get wordGentleman;

  /// No description provided for @wordHuman.
  ///
  /// In en, this message translates to:
  /// **'Human'**
  String get wordHuman;

  /// No description provided for @wordHumans.
  ///
  /// In en, this message translates to:
  /// **'Humans'**
  String get wordHumans;

  /// No description provided for @wordEveryone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get wordEveryone;

  /// No description provided for @wordEverybody.
  ///
  /// In en, this message translates to:
  /// **'Everybody'**
  String get wordEverybody;

  /// No description provided for @wordSomeone.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get wordSomeone;

  /// No description provided for @wordSomebody.
  ///
  /// In en, this message translates to:
  /// **'Somebody'**
  String get wordSomebody;

  /// No description provided for @wordNoone.
  ///
  /// In en, this message translates to:
  /// **'No one'**
  String get wordNoone;

  /// No description provided for @wordNobody.
  ///
  /// In en, this message translates to:
  /// **'Nobody'**
  String get wordNobody;

  /// No description provided for @wordAnyone.
  ///
  /// In en, this message translates to:
  /// **'Anyone'**
  String get wordAnyone;

  /// No description provided for @wordAnybody.
  ///
  /// In en, this message translates to:
  /// **'Anybody'**
  String get wordAnybody;

  /// No description provided for @wordEverything.
  ///
  /// In en, this message translates to:
  /// **'Everything'**
  String get wordEverything;

  /// No description provided for @wordSomething.
  ///
  /// In en, this message translates to:
  /// **'Something'**
  String get wordSomething;

  /// No description provided for @wordNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing'**
  String get wordNothing;

  /// No description provided for @wordAnything.
  ///
  /// In en, this message translates to:
  /// **'Anything'**
  String get wordAnything;

  /// No description provided for @notificationsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No notifications} =1{1 notification} other{{count} notifications}}'**
  String notificationsCount(int count);

  /// No description provided for @matchCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No matches} =1{1 match} other{{count} matches}}'**
  String matchCount(int count);

  /// No description provided for @likesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No likes} =1{1 like} other{{count} likes}}'**
  String likesCount(int count);

  /// No description provided for @photosCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No photos} =1{1 photo} other{{count} photos}}'**
  String photosCount(int count);

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Less than 1 km away} =1{1 km away} other{{count} km away}}'**
  String distanceKm(int count);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @callHistory.
  ///
  /// In en, this message translates to:
  /// **'Call History'**
  String get callHistory;

  /// No description provided for @callPipFloatingWindow.
  ///
  /// In en, this message translates to:
  /// **'Floating call window'**
  String get callPipFloatingWindow;

  /// No description provided for @callPipClose.
  ///
  /// In en, this message translates to:
  /// **'Close floating call window'**
  String get callPipClose;

  /// No description provided for @callPipTapToReturn.
  ///
  /// In en, this message translates to:
  /// **'Tap to return'**
  String get callPipTapToReturn;

  /// No description provided for @callPipActiveCall.
  ///
  /// In en, this message translates to:
  /// **'Active call'**
  String get callPipActiveCall;

  /// No description provided for @callIncomingUnknownCaller.
  ///
  /// In en, this message translates to:
  /// **'Unknown caller'**
  String get callIncomingUnknownCaller;

  /// No description provided for @callIncomingVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'Incoming video call'**
  String get callIncomingVideoTitle;

  /// No description provided for @callIncomingAudioTitle.
  ///
  /// In en, this message translates to:
  /// **'Incoming audio call'**
  String get callIncomingAudioTitle;

  /// No description provided for @callIncomingAutoDismiss.
  ///
  /// In en, this message translates to:
  /// **'Auto-dismisses in {seconds}s'**
  String callIncomingAutoDismiss(int seconds);

  /// No description provided for @callIncomingChooseAnswer.
  ///
  /// In en, this message translates to:
  /// **'Choose how to answer this call'**
  String get callIncomingChooseAnswer;

  /// No description provided for @callIncomingSwipeToAnswer.
  ///
  /// In en, this message translates to:
  /// **'Swipe to answer or use quick actions'**
  String get callIncomingSwipeToAnswer;

  /// No description provided for @callDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get callDecline;

  /// No description provided for @callAnswerAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get callAnswerAudio;

  /// No description provided for @callSlideToAnswer.
  ///
  /// In en, this message translates to:
  /// **'Slide to answer'**
  String get callSlideToAnswer;

  /// No description provided for @callPermissionVideoRequired.
  ///
  /// In en, this message translates to:
  /// **'Camera and microphone permission is required for video calls'**
  String get callPermissionVideoRequired;

  /// No description provided for @callPermissionAudioRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required for calls'**
  String get callPermissionAudioRequired;

  /// No description provided for @callCouldNotStart.
  ///
  /// In en, this message translates to:
  /// **'Could not start call'**
  String get callCouldNotStart;

  /// No description provided for @callError.
  ///
  /// In en, this message translates to:
  /// **'Call error'**
  String get callError;

  /// No description provided for @callMinimize.
  ///
  /// In en, this message translates to:
  /// **'Minimize call'**
  String get callMinimize;

  /// No description provided for @callUnknownName.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get callUnknownName;

  /// No description provided for @callSpeaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get callSpeaker;

  /// No description provided for @callFlipCamera.
  ///
  /// In en, this message translates to:
  /// **'Flip'**
  String get callFlipCamera;

  /// No description provided for @callEndCall.
  ///
  /// In en, this message translates to:
  /// **'End call'**
  String get callEndCall;

  /// No description provided for @callYouLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get callYouLabel;

  /// No description provided for @callReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting'**
  String get callReconnecting;

  /// No description provided for @callStatusReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get callStatusReconnecting;

  /// No description provided for @callStatusInitiating.
  ///
  /// In en, this message translates to:
  /// **'Initiating...'**
  String get callStatusInitiating;

  /// No description provided for @callStatusRinging.
  ///
  /// In en, this message translates to:
  /// **'Ringing...'**
  String get callStatusRinging;

  /// No description provided for @callStatusIncoming.
  ///
  /// In en, this message translates to:
  /// **'Incoming call...'**
  String get callStatusIncoming;

  /// No description provided for @callStatusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get callStatusConnecting;

  /// No description provided for @callVideoCall.
  ///
  /// In en, this message translates to:
  /// **'Video Call'**
  String get callVideoCall;

  /// No description provided for @callVoiceCall.
  ///
  /// In en, this message translates to:
  /// **'Voice Call'**
  String get callVoiceCall;

  /// No description provided for @callEnded.
  ///
  /// In en, this message translates to:
  /// **'Call ended'**
  String get callEnded;

  /// No description provided for @callHistoryLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to view call history.'**
  String get callHistoryLoginRequired;

  /// No description provided for @callHistoryLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load call history right now.'**
  String get callHistoryLoadError;

  /// No description provided for @callHistoryToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get callHistoryToday;

  /// No description provided for @callHistoryYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get callHistoryYesterday;

  /// No description provided for @callHistoryThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get callHistoryThisWeek;

  /// No description provided for @callHistoryEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get callHistoryEarlier;

  /// No description provided for @callHistoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No calls yet'**
  String get callHistoryEmptyTitle;

  /// No description provided for @callHistoryEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Your completed and missed calls will appear here.'**
  String get callHistoryEmptyDesc;

  /// No description provided for @callHistoryDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration {duration}'**
  String callHistoryDuration(String duration);

  /// No description provided for @callHistoryStatusRinging.
  ///
  /// In en, this message translates to:
  /// **'Ringing'**
  String get callHistoryStatusRinging;

  /// No description provided for @callHistoryStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get callHistoryStatusCompleted;

  /// No description provided for @callHistoryStatusMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed call'**
  String get callHistoryStatusMissed;

  /// No description provided for @callHistoryStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get callHistoryStatusDeclined;

  /// No description provided for @callHistoryStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get callHistoryStatusFailed;

  /// No description provided for @unableToLoadMoreCall.
  ///
  /// In en, this message translates to:
  /// **'Unable to load more call history.'**
  String get unableToLoadMoreCall;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @reportDetails.
  ///
  /// In en, this message translates to:
  /// **'Report details'**
  String get reportDetails;

  /// No description provided for @viewCommunityGuidelines.
  ///
  /// In en, this message translates to:
  /// **'View community guidelines'**
  String get viewCommunityGuidelines;

  /// No description provided for @reportsAreAnonymousAndReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reports are anonymous and reviewed by our team.'**
  String get reportsAreAnonymousAndReviewed;

  /// No description provided for @chatReportLastMatch.
  ///
  /// In en, this message translates to:
  /// **'Last match: {matchId}'**
  String chatReportLastMatch(String matchId);

  /// No description provided for @signInAgainToManage.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to manage safety actions.'**
  String get signInAgainToManage;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get blockUser;

  /// No description provided for @reportUser.
  ///
  /// In en, this message translates to:
  /// **'Report user'**
  String get reportUser;

  /// No description provided for @chatReportReasonSpamScams.
  ///
  /// In en, this message translates to:
  /// **'Spam or scams'**
  String get chatReportReasonSpamScams;

  /// No description provided for @chatReportReasonHarassmentHate.
  ///
  /// In en, this message translates to:
  /// **'Harassment or hate'**
  String get chatReportReasonHarassmentHate;

  /// No description provided for @chatReportReasonInappropriateContent.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get chatReportReasonInappropriateContent;

  /// No description provided for @chatReportReasonFakeProfile.
  ///
  /// In en, this message translates to:
  /// **'Fake profile'**
  String get chatReportReasonFakeProfile;

  /// No description provided for @chatReportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get chatReportReasonOther;

  /// No description provided for @chatReportSubmittedReason.
  ///
  /// In en, this message translates to:
  /// **'Report submitted: {reason}'**
  String chatReportSubmittedReason(String reason);

  /// No description provided for @chatReportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted'**
  String get chatReportSubmitted;

  /// No description provided for @chatReportDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us what happened'**
  String get chatReportDetailsHint;

  /// No description provided for @chatSafetyBlockedUser.
  ///
  /// In en, this message translates to:
  /// **'Blocked {name}.'**
  String chatSafetyBlockedUser(String name);

  /// No description provided for @chatSafetyUnblockedUser.
  ///
  /// In en, this message translates to:
  /// **'Unblocked {name}.'**
  String chatSafetyUnblockedUser(String name);

  /// No description provided for @iFeltSafe.
  ///
  /// In en, this message translates to:
  /// **'I felt safe'**
  String get iFeltSafe;

  /// No description provided for @connectionUnstableRecoveredWithReduced.
  ///
  /// In en, this message translates to:
  /// **'Connection unstable. Recovered with reduced quality.'**
  String get connectionUnstableRecoveredWithReduced;

  /// No description provided for @networkIsWeakSwitchedTo.
  ///
  /// In en, this message translates to:
  /// **'Network is weak. Switched to audio-only mode.'**
  String get networkIsWeakSwitchedTo;

  /// No description provided for @screenRecordingStopped.
  ///
  /// In en, this message translates to:
  /// **'Screen recording stopped.'**
  String get screenRecordingStopped;

  /// No description provided for @screenRecordingDetectedTheOther.
  ///
  /// In en, this message translates to:
  /// **'Screen recording detected. The other person was notified.'**
  String get screenRecordingDetectedTheOther;

  /// No description provided for @screenshotDetectedTheOtherPerson.
  ///
  /// In en, this message translates to:
  /// **'Screenshot detected. The other person was notified.'**
  String get screenshotDetectedTheOtherPerson;

  /// No description provided for @viewSafetyGuidelines.
  ///
  /// In en, this message translates to:
  /// **'View safety guidelines'**
  String get viewSafetyGuidelines;

  /// No description provided for @callSafetyTipFallbackPerson.
  ///
  /// In en, this message translates to:
  /// **'this person'**
  String get callSafetyTipFallbackPerson;

  /// No description provided for @callSafetyTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety reminder'**
  String get callSafetyTipTitle;

  /// No description provided for @callSafetyTipDismissTooltip.
  ///
  /// In en, this message translates to:
  /// **'Dismiss safety tip'**
  String get callSafetyTipDismissTooltip;

  /// No description provided for @callSafetyTipBody.
  ///
  /// In en, this message translates to:
  /// **'On your first call with {name}, avoid sharing private details. If anything feels unsafe, report or block immediately.'**
  String callSafetyTipBody(String name);

  /// No description provided for @callSafetyActionReported.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get callSafetyActionReported;

  /// No description provided for @callSafetyPostCallPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Did you feel safe on this call?'**
  String get callSafetyPostCallPromptTitle;

  /// No description provided for @callSafetyPostCallPromptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'If anything felt off, report or block now.'**
  String get callSafetyPostCallPromptSubtitle;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @resetPreview.
  ///
  /// In en, this message translates to:
  /// **'Reset preview'**
  String get resetPreview;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @appearanceThemes.
  ///
  /// In en, this message translates to:
  /// **'Appearance & Themes'**
  String get appearanceThemes;

  /// No description provided for @darkLuxuryThemesAreA.
  ///
  /// In en, this message translates to:
  /// **'Dark Luxury themes are a Plus feature. Upgrade to unlock them.'**
  String get darkLuxuryThemesAreA;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get endTime;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get startTime;

  /// No description provided for @unlink.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get unlink;

  /// No description provided for @cannotUnlinkTheLastRecovery.
  ///
  /// In en, this message translates to:
  /// **'Cannot unlink the last recovery method. Add another provider first.'**
  String get cannotUnlinkTheLastRecovery;

  /// No description provided for @accountSecurity.
  ///
  /// In en, this message translates to:
  /// **'Account Security'**
  String get accountSecurity;

  /// No description provided for @enableIncognito.
  ///
  /// In en, this message translates to:
  /// **'Enable Incognito'**
  String get enableIncognito;

  /// No description provided for @turnOffIncognito.
  ///
  /// In en, this message translates to:
  /// **'Turn off Incognito'**
  String get turnOffIncognito;

  /// No description provided for @pricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get pricing;

  /// No description provided for @features.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

  /// No description provided for @safety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get safety;

  /// No description provided for @communityGuidelines.
  ///
  /// In en, this message translates to:
  /// **'Community Guidelines'**
  String get communityGuidelines;

  /// No description provided for @promoCode.
  ///
  /// In en, this message translates to:
  /// **'Promo code'**
  String get promoCode;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @resetToDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults'**
  String get resetToDefaults;

  /// No description provided for @makeAllPrivate.
  ///
  /// In en, this message translates to:
  /// **'Make all private'**
  String get makeAllPrivate;

  /// No description provided for @makeAllPublic.
  ///
  /// In en, this message translates to:
  /// **'Make all public'**
  String get makeAllPublic;

  /// No description provided for @openEmail.
  ///
  /// In en, this message translates to:
  /// **'Open Email'**
  String get openEmail;

  /// No description provided for @ourRulesAndStandards.
  ///
  /// In en, this message translates to:
  /// **'Our rules and standards'**
  String get ourRulesAndStandards;

  /// No description provided for @browseArticlesAndGuides.
  ///
  /// In en, this message translates to:
  /// **'Browse articles and guides'**
  String get browseArticlesAndGuides;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @emailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get emailSupport;

  /// No description provided for @helpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupport;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @onlySeeVerifiedProfiles.
  ///
  /// In en, this message translates to:
  /// **'Only see verified profiles'**
  String get onlySeeVerifiedProfiles;

  /// No description provided for @verifiedProfilesOnly.
  ///
  /// In en, this message translates to:
  /// **'Verified profiles only'**
  String get verifiedProfilesOnly;

  /// No description provided for @upgradeToPlus.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Plus'**
  String get upgradeToPlus;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @editInterests.
  ///
  /// In en, this message translates to:
  /// **'Edit interests'**
  String get editInterests;

  /// No description provided for @turnOffToHideYour.
  ///
  /// In en, this message translates to:
  /// **'Turn off to hide your profile'**
  String get turnOffToHideYour;

  /// No description provided for @showMeInDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Show me in discovery'**
  String get showMeInDiscovery;

  /// No description provided for @displayHowFarAwayYou.
  ///
  /// In en, this message translates to:
  /// **'Display how far away you are'**
  String get displayHowFarAwayYou;

  /// No description provided for @showMyDistance.
  ///
  /// In en, this message translates to:
  /// **'Show my distance'**
  String get showMyDistance;

  /// No description provided for @myInterests.
  ///
  /// In en, this message translates to:
  /// **'My interests'**
  String get myInterests;

  /// No description provided for @discoveryFilters.
  ///
  /// In en, this message translates to:
  /// **'Discovery & Filters'**
  String get discoveryFilters;

  /// No description provided for @keepMessagesFor24Hours.
  ///
  /// In en, this message translates to:
  /// **'Keep messages for 24 hours'**
  String get keepMessagesFor24Hours;

  /// No description provided for @chatSettings.
  ///
  /// In en, this message translates to:
  /// **'Chat Settings'**
  String get chatSettings;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @finalConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Final confirmation'**
  String get finalConfirmation;

  /// No description provided for @requestExport.
  ///
  /// In en, this message translates to:
  /// **'Request Export'**
  String get requestExport;

  /// No description provided for @beforeDeletionYouCanRequest.
  ///
  /// In en, this message translates to:
  /// **'Before deletion, you can request a full data export for your records.'**
  String get beforeDeletionYouCanRequest;

  /// No description provided for @downloadYourDataFirst.
  ///
  /// In en, this message translates to:
  /// **'Download your data first?'**
  String get downloadYourDataFirst;

  /// No description provided for @youWillLose.
  ///
  /// In en, this message translates to:
  /// **'You will lose:'**
  String get youWillLose;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @whenYouDeactivateYourAccount.
  ///
  /// In en, this message translates to:
  /// **'When you deactivate your account:'**
  String get whenYouDeactivateYourAccount;

  /// No description provided for @deactivateAccount.
  ///
  /// In en, this message translates to:
  /// **'Deactivate Account'**
  String get deactivateAccount;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @shareExport.
  ///
  /// In en, this message translates to:
  /// **'Share Export'**
  String get shareExport;

  /// No description provided for @yourDataExportHasBeen.
  ///
  /// In en, this message translates to:
  /// **'Your data export has been generated successfully. Would you like to share/download it now?'**
  String get yourDataExportHasBeen;

  /// No description provided for @exportReady.
  ///
  /// In en, this message translates to:
  /// **'Export Ready'**
  String get exportReady;

  /// No description provided for @preparingYourExport.
  ///
  /// In en, this message translates to:
  /// **'Preparing your export'**
  String get preparingYourExport;

  /// No description provided for @yourExportIncludesProfilePhotos.
  ///
  /// In en, this message translates to:
  /// **'Your export includes profile, photos, likes, matches, messages, and preferences.'**
  String get yourExportIncludesProfilePhotos;

  /// No description provided for @requestDataExport.
  ///
  /// In en, this message translates to:
  /// **'Request Data Export'**
  String get requestDataExport;

  /// No description provided for @permanentlyRemoveYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove your account'**
  String get permanentlyRemoveYourAccount;

  /// No description provided for @accountActions.
  ///
  /// In en, this message translates to:
  /// **'Account Actions'**
  String get accountActions;

  /// No description provided for @setRegion.
  ///
  /// In en, this message translates to:
  /// **'Set region'**
  String get setRegion;

  /// No description provided for @detectYourRegionAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Detect your region automatically'**
  String get detectYourRegionAutomatically;

  /// No description provided for @useDeviceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Use device language'**
  String get useDeviceLanguage;

  /// No description provided for @regionUpdatedFromDeviceLocation.
  ///
  /// In en, this message translates to:
  /// **'Region updated from device location.'**
  String get regionUpdatedFromDeviceLocation;

  /// No description provided for @comparePlanBenefits.
  ///
  /// In en, this message translates to:
  /// **'Compare plan benefits'**
  String get comparePlanBenefits;

  /// No description provided for @planDetailsAndPricing.
  ///
  /// In en, this message translates to:
  /// **'Plan details and pricing'**
  String get planDetailsAndPricing;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @billingHelp.
  ///
  /// In en, this message translates to:
  /// **'Billing help'**
  String get billingHelp;

  /// No description provided for @refreshSubscriptionStatus.
  ///
  /// In en, this message translates to:
  /// **'Refresh subscription status'**
  String get refreshSubscriptionStatus;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @clearCacheNow.
  ///
  /// In en, this message translates to:
  /// **'Clear cache now'**
  String get clearCacheNow;

  /// No description provided for @cacheClearedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared successfully.'**
  String get cacheClearedSuccessfully;

  /// No description provided for @avoidUsingMobileDataFor.
  ///
  /// In en, this message translates to:
  /// **'Avoid using mobile data for media'**
  String get avoidUsingMobileDataFor;

  /// No description provided for @wifiOnly.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi only'**
  String get wifiOnly;

  /// No description provided for @autodownloadMedia.
  ///
  /// In en, this message translates to:
  /// **'Auto-download media'**
  String get autodownloadMedia;

  /// No description provided for @dataStorage.
  ///
  /// In en, this message translates to:
  /// **'Data & Storage'**
  String get dataStorage;

  /// No description provided for @unmatch.
  ///
  /// In en, this message translates to:
  /// **'Unmatch'**
  String get unmatch;

  /// No description provided for @unmatch1.
  ///
  /// In en, this message translates to:
  /// **'Unmatch?'**
  String get unmatch1;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @startAudioCall.
  ///
  /// In en, this message translates to:
  /// **'Start audio call'**
  String get startAudioCall;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @mediaSendingIsDisabledFor.
  ///
  /// In en, this message translates to:
  /// **'Media sending is disabled for this match. Enable it from the toolbar to share photos, videos, or audio.'**
  String get mediaSendingIsDisabledFor;

  /// No description provided for @unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @verifyYourIdToAdd.
  ///
  /// In en, this message translates to:
  /// **'Verify your ID to add a trust badge to your messages and matches.'**
  String get verifyYourIdToAdd;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @declineRequest.
  ///
  /// In en, this message translates to:
  /// **'Decline request?'**
  String get declineRequest;

  /// No description provided for @signInToViewMessage.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view message requests.'**
  String get signInToViewMessage;

  /// No description provided for @signInToViewYour.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your chats.'**
  String get signInToViewYour;

  /// No description provided for @tryPlusIntroOffer.
  ///
  /// In en, this message translates to:
  /// **'Try Plus intro offer'**
  String get tryPlusIntroOffer;

  /// No description provided for @backToDeck.
  ///
  /// In en, this message translates to:
  /// **'Back to deck'**
  String get backToDeck;

  /// No description provided for @maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe Later'**
  String get maybeLater;

  /// No description provided for @signInToViewYour1.
  ///
  /// In en, this message translates to:
  /// **'Sign in to view your matches.'**
  String get signInToViewYour1;

  /// No description provided for @imagePendingSafetyScan.
  ///
  /// In en, this message translates to:
  /// **'Image pending safety scan…'**
  String get imagePendingSafetyScan;

  /// No description provided for @openSafetyCenter.
  ///
  /// In en, this message translates to:
  /// **'Open Safety Center'**
  String get openSafetyCenter;

  /// No description provided for @viewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// No description provided for @showDifferentSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Show different suggestions'**
  String get showDifferentSuggestions;

  /// No description provided for @messageCopiedWillClearIn.
  ///
  /// In en, this message translates to:
  /// **'Message copied — will clear in 60 seconds'**
  String get messageCopiedWillClearIn;

  /// No description provided for @copyText.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get copyText;

  /// No description provided for @deleteForMe.
  ///
  /// In en, this message translates to:
  /// **'Delete for me'**
  String get deleteForMe;

  /// No description provided for @unsendPlus.
  ///
  /// In en, this message translates to:
  /// **'Unsend (Plus)'**
  String get unsendPlus;

  /// No description provided for @editPlus.
  ///
  /// In en, this message translates to:
  /// **'Edit (Plus)'**
  String get editPlus;

  /// No description provided for @removeMyReaction.
  ///
  /// In en, this message translates to:
  /// **'Remove my reaction'**
  String get removeMyReaction;

  /// No description provided for @editMessage.
  ///
  /// In en, this message translates to:
  /// **'Edit message'**
  String get editMessage;

  /// No description provided for @couldNotOpenAttachment.
  ///
  /// In en, this message translates to:
  /// **'Could not open attachment.'**
  String get couldNotOpenAttachment;

  /// No description provided for @mediaSavedLocallyOnYour.
  ///
  /// In en, this message translates to:
  /// **'Media saved locally on your device.'**
  String get mediaSavedLocallyOnYour;

  /// No description provided for @grant.
  ///
  /// In en, this message translates to:
  /// **'Grant'**
  String get grant;

  /// No description provided for @microphonePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission required'**
  String get microphonePermissionRequired;

  /// No description provided for @recordingTooShortMinimum1.
  ///
  /// In en, this message translates to:
  /// **'Recording too short (minimum 1 second)'**
  String get recordingTooShortMinimum1;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @useEmailInstead.
  ///
  /// In en, this message translates to:
  /// **'Use email instead'**
  String get useEmailInstead;

  /// No description provided for @signUpWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Sign up with phone'**
  String get signUpWithPhone;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @signUpWithEmailInstead.
  ///
  /// In en, this message translates to:
  /// **'Sign up with email instead'**
  String get signUpWithEmailInstead;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// No description provided for @openEmailApp.
  ///
  /// In en, this message translates to:
  /// **'Open Email App'**
  String get openEmailApp;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @yesIAm18.
  ///
  /// In en, this message translates to:
  /// **'Yes, I am 18+'**
  String get yesIAm18;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @usePhoneNumberInstead.
  ///
  /// In en, this message translates to:
  /// **'Use phone number instead'**
  String get usePhoneNumberInstead;

  /// No description provided for @signInWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign in with email'**
  String get signInWithEmail;

  /// No description provided for @useDifferentEmail.
  ///
  /// In en, this message translates to:
  /// **'Use Different Email'**
  String get useDifferentEmail;

  /// No description provided for @emptyString.
  ///
  /// In en, this message translates to:
  /// **' • '**
  String get emptyString;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @backToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Back to Sign In'**
  String get backToSignIn;

  /// No description provided for @selectExistingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Select existing photo'**
  String get selectExistingPhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @useCameraToCaptureId.
  ///
  /// In en, this message translates to:
  /// **'Use camera to capture ID'**
  String get useCameraToCaptureId;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removePhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Remove Phone Number?'**
  String get removePhoneNumber;

  /// No description provided for @removePhoneNumber1.
  ///
  /// In en, this message translates to:
  /// **'Remove Phone Number'**
  String get removePhoneNumber1;

  /// No description provided for @continueAnyway.
  ///
  /// In en, this message translates to:
  /// **'Continue Anyway'**
  String get continueAnyway;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @verifyOtp.
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// No description provided for @termsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsConditions;

  /// No description provided for @crush.
  ///
  /// In en, this message translates to:
  /// **'Crush'**
  String get crush;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @pass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get pass;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @weWillReviewAndMay.
  ///
  /// In en, this message translates to:
  /// **'We will review and may limit accounts that violate guidelines.'**
  String get weWillReviewAndMay;

  /// No description provided for @maybeLater1.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get maybeLater1;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete profile'**
  String get completeProfile;

  /// No description provided for @completeYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get completeYourProfile;

  /// No description provided for @verifyNow.
  ///
  /// In en, this message translates to:
  /// **'Verify now'**
  String get verifyNow;

  /// No description provided for @pleaseVerifyYourEmailOr.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email or phone number to start swiping and matching with others.'**
  String get pleaseVerifyYourEmailOr;

  /// No description provided for @verifyYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Verify your account'**
  String get verifyYourAccount;

  /// No description provided for @refreshDeck.
  ///
  /// In en, this message translates to:
  /// **'Refresh deck'**
  String get refreshDeck;

  /// No description provided for @tryPassportWithPlus.
  ///
  /// In en, this message translates to:
  /// **'Try Passport with Plus'**
  String get tryPassportWithPlus;

  /// No description provided for @blockHideProfile.
  ///
  /// In en, this message translates to:
  /// **'Block & hide profile'**
  String get blockHideProfile;

  /// No description provided for @reportProfile.
  ///
  /// In en, this message translates to:
  /// **'Report profile'**
  String get reportProfile;

  /// No description provided for @viewFullProfile.
  ///
  /// In en, this message translates to:
  /// **'View full profile'**
  String get viewFullProfile;

  /// No description provided for @likeBack.
  ///
  /// In en, this message translates to:
  /// **'Like Back'**
  String get likeBack;

  /// No description provided for @couldNotPassPleaseTry.
  ///
  /// In en, this message translates to:
  /// **'Could not pass. Please try again.'**
  String get couldNotPassPleaseTry;

  /// No description provided for @couldNotLikeBackPlease.
  ///
  /// In en, this message translates to:
  /// **'Could not like back. Please try again.'**
  String get couldNotLikeBackPlease;

  /// No description provided for @likesYou.
  ///
  /// In en, this message translates to:
  /// **'Likes You'**
  String get likesYou;

  /// No description provided for @boostNow.
  ///
  /// In en, this message translates to:
  /// **'Boost Now'**
  String get boostNow;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it!'**
  String get gotIt;

  /// No description provided for @ideaSent.
  ///
  /// In en, this message translates to:
  /// **'Idea sent!'**
  String get ideaSent;

  /// No description provided for @savedToYourIdeas.
  ///
  /// In en, this message translates to:
  /// **'Saved to your ideas!'**
  String get savedToYourIdeas;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @completeYourProfile1.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get completeYourProfile1;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @confirmDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Confirm Date of Birth'**
  String get confirmDateOfBirth;

  /// No description provided for @ageNotice.
  ///
  /// In en, this message translates to:
  /// **'Age Notice'**
  String get ageNotice;

  /// No description provided for @changeDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Change Date of Birth'**
  String get changeDateOfBirth;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @reportSubmittedThanksForKeeping.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Thanks for keeping Crush safe!'**
  String get reportSubmittedThanksForKeeping;

  /// No description provided for @shareFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Share feature coming soon'**
  String get shareFeatureComingSoon;

  /// No description provided for @shareProfile.
  ///
  /// In en, this message translates to:
  /// **'Share Profile'**
  String get shareProfile;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @profileReportSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this profile?'**
  String get profileReportSheetTitle;

  /// No description provided for @profileReportReasonInappropriatePhotos.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate photos'**
  String get profileReportReasonInappropriatePhotos;

  /// No description provided for @profileReportReasonScamOrSpam.
  ///
  /// In en, this message translates to:
  /// **'Scam or spam'**
  String get profileReportReasonScamOrSpam;

  /// No description provided for @profileReportReasonUnderageUser.
  ///
  /// In en, this message translates to:
  /// **'Underage user'**
  String get profileReportReasonUnderageUser;

  /// No description provided for @messageRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Message request sent.'**
  String get messageRequestSent;

  /// No description provided for @liked.
  ///
  /// In en, this message translates to:
  /// **'Liked!'**
  String get liked;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessage;

  /// No description provided for @couldNotLoadVideo.
  ///
  /// In en, this message translates to:
  /// **'Could not load video'**
  String get couldNotLoadVideo;

  /// No description provided for @noVideosYet.
  ///
  /// In en, this message translates to:
  /// **'No videos yet'**
  String get noVideosYet;

  /// No description provided for @photoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Photo unavailable'**
  String get photoUnavailable;

  /// No description provided for @noPhotosYet.
  ///
  /// In en, this message translates to:
  /// **'No photos yet'**
  String get noPhotosYet;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notificationsEmpty;

  /// No description provided for @notificationsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get notificationsToday;

  /// No description provided for @notificationsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get notificationsThisWeek;

  /// No description provided for @notificationsEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get notificationsEarlier;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @photosRejected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo rejected: {reason}} other{{count} photos rejected: {reason}}}'**
  String photosRejected(int count, String reason);

  /// No description provided for @photoSlotsAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Only 1 more photo slot available.} other{Only {count} more photo slots available.}}'**
  String photoSlotsAvailable(int count);

  /// No description provided for @photoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo} other{{count} photos}}'**
  String photoCount(int count);

  /// No description provided for @storyCountStr.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Story} other{{count}}}'**
  String storyCountStr(int count);

  /// No description provided for @personLikesYou.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person likes you} other{{count} people like you}}'**
  String personLikesYou(int count);

  /// No description provided for @blockedUserCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 blocked user} other{{count} blocked users}}'**
  String blockedUserCount(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'bn',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'id',
    'ja',
    'ko',
    'ne',
    'pt',
    'ru',
    'ta',
    'te',
    'tr',
    'ur',
    'vi',
    'yo',
    'yue',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'en':
      {
        switch (locale.countryCode) {
          case 'XA':
            return AppLocalizationsEnXa();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'ne':
      return AppLocalizationsNe();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
    case 'tr':
      return AppLocalizationsTr();
    case 'ur':
      return AppLocalizationsUr();
    case 'vi':
      return AppLocalizationsVi();
    case 'yo':
      return AppLocalizationsYo();
    case 'yue':
      return AppLocalizationsYue();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
