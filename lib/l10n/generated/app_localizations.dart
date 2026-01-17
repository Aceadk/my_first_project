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
    Locale('zh')
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
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
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
      'that was used.');
}
