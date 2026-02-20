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
