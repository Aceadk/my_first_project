import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/features/profile/data/repositories/profile_repository.dart';
import 'package:crushhour/features/auth/data/repositories/auth_repository.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/core/utils/error_messages.dart';
import 'package:crushhour/core/services/analytics_service.dart';
import 'package:crushhour/core/app_logger.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository profileRepository;
  final AuthRepository authRepository;

  Timer? _retryTimer;
  int _retryDelayMs = 1000;
  int _retryCount = 0;
  static const int _maxAutoRetries = 2;
  bool _isManualRefresh = false;

  ProfileBloc({
    required this.profileRepository,
    required this.authRepository,
  }) : super(const ProfileState()) {
    on<ProfileLoadRequested>(_onLoadRequested);
    on<ProfileSaveRequested>(_onSaveRequested);
    on<ProfileBasicInfoSubmitted>(_onBasicInfoSubmitted);
    on<ProfileDetailsSubmitted>(_onDetailsSubmitted);
    on<ProfileIdDocumentUploaded>(_onIdDocumentUploaded);
    on<ProfileIdVerifiedMarked>(_onIdVerifiedMarked);
    on<ProfileLocationUpdateRequested>(_onLocationUpdateRequested);
  }

  Future<void> _onLoadRequested(
      ProfileLoadRequested event, Emitter<ProfileState> emit) async {
    AppLogger.logInfo('[ProfileBloc] _onLoadRequested called');

    // Track if this is a manual refresh (user-triggered) vs auto-retry
    final isManualRefresh =
        _isManualRefresh || state.status != ProfileStatus.error;

    AppLogger.logInfo('[ProfileBloc] isManualRefresh: $isManualRefresh, retryCount: $_retryCount');

    if (isManualRefresh) {
      _retryCount = 0;
      _retryDelayMs = 1000;
    }
    _isManualRefresh = false;
    _retryTimer?.cancel();

    emit(state.copyWith(
      isLoading: true,
      status: ProfileStatus.loading,
      errorMessage: null,
      nextRetrySeconds: null,
    ));

    AppLogger.logInfo('[ProfileBloc] Calling profileRepository.getCurrentUser()...');

    final result = await Result.guard(
      () => profileRepository.getCurrentUser(),
      logLabel: 'ProfileRepository.getCurrentUser',
      fallbackError: ErrorMessages.loadProfileFailed,
    );

    AppLogger.logInfo('[ProfileBloc] Result: isSuccess=${result.isSuccess}, data=${result.data}, error=${result.errorMessage}');

    if (!result.isSuccess) {
      _retryCount++;
      final errorMsg = result.errorMessage;

      AppLogger.logInfo('[ProfileBloc] Load failed: $errorMsg (retryCount: $_retryCount)');

      // Check if error indicates "no profile" rather than actual failure
      final isNoProfileError = _isNoProfileError(errorMsg);

      AppLogger.logInfo('[ProfileBloc] isNoProfileError: $isNoProfileError');

      // If we've retried enough times or error indicates no profile, show empty state
      if (_retryCount > _maxAutoRetries || isNoProfileError) {
        AppLogger.logInfo('[ProfileBloc] Emitting ProfileStatus.empty');
        emit(state.copyWith(
          isLoading: false,
          status: ProfileStatus.empty,
          errorMessage: null,
          nextRetrySeconds: null,
        ));
        return;
      }

      // Otherwise show error and schedule retry
      AppLogger.logInfo('[ProfileBloc] Emitting ProfileStatus.error, scheduling retry');
      emit(state.copyWith(
        isLoading: false,
        status: ProfileStatus.error,
        errorMessage: errorMsg,
        nextRetrySeconds: (_retryDelayMs / 1000).ceil(),
      ));
      _scheduleRetry();
      return;
    }

    // Success - reset retry state
    _retryCount = 0;
    _retryDelayMs = 1000;

    final user = result.data;

    AppLogger.logInfo('[ProfileBloc] User loaded: id=${user?.id}, hasProfile=${user?.profile != null}');
    final profile = user?.profile;
    if (profile != null) {
      AppLogger.logInfo('[ProfileBloc] Profile: name=${profile.name}, age=${profile.age}');
    }

    // Track profile viewed
    if (user != null) {
      AnalyticsService.instance.logProfileViewed();
    }

    // If user is null or has no profile, they need to create one
    final hasProfile = user?.profile != null;

    AppLogger.logInfo('[ProfileBloc] Emitting status: ${hasProfile ? 'loaded' : 'empty'}');

    emit(state.copyWith(
      user: user,
      profile: user?.profile,
      isLoading: false,
      status: hasProfile ? ProfileStatus.loaded : ProfileStatus.empty,
      errorMessage: null,
      nextRetrySeconds: null,
    ));
  }

  /// Check if error message indicates no profile available vs actual error.
  bool _isNoProfileError(String? errorMsg) {
    if (errorMsg == null) return false;
    final lower = errorMsg.toLowerCase();
    return lower.contains('no profile') ||
        lower.contains('not found') ||
        lower.contains('does not exist') ||
        lower.contains('no user') ||
        lower.contains('empty');
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    final delay = Duration(milliseconds: _retryDelayMs);
    _retryDelayMs = (_retryDelayMs * 2).clamp(1000, 8000);
    _retryTimer = Timer(delay, () {
      if (!isClosed) add(ProfileLoadRequested());
    });
  }

  /// Trigger a manual refresh (resets retry count).
  void manualRefresh() {
    _isManualRefresh = true;
    add(ProfileLoadRequested());
  }

  Future<void> _onBasicInfoSubmitted(
      ProfileBasicInfoSubmitted event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(isSaving: true, errorMessage: null));
    final result = await Result.guard(
      () => profileRepository.saveBasicInfo(
        username: event.username,
        name: event.name,
        age: event.age,
        gender: event.gender,
        sexualOrientation: event.sexualOrientation,
      ),
      logLabel: 'ProfileRepository.saveBasicInfo',
      fallbackError: 'Could not save basic info. Please try again.',
    );

    // Track profile update
    if (result.isSuccess) {
      AnalyticsService.instance.logProfileUpdated(
        fieldsUpdated: ['name', 'age', 'gender', 'sexualOrientation'],
      );
    }

    final user = result.data;
    emit(state.copyWith(
      user: user ?? state.user,
      profile: user?.profile ?? state.profile,
      isSaving: false,
      errorMessage: result.errorMessage,
    ));
  }

  Future<void> _onDetailsSubmitted(
      ProfileDetailsSubmitted event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(isSaving: true, errorMessage: null));

    final oldPhotoCount = state.profile?.photoUrls.length ?? 0;

    final result = await Result.guard(
      () => profileRepository.saveProfileDetails(
        bio: event.bio,
        photoUrls: event.photoUrls,
        videoUrls: event.videoUrls,
        jobTitle: event.jobTitle,
        company: event.company,
        school: event.school,
        interests: event.interests,
      ),
      logLabel: 'ProfileRepository.saveProfileDetails',
      fallbackError: ErrorMessages.saveProfileFailed,
    );

    // Track profile updates
    if (result.isSuccess) {
      final fieldsUpdated = <String>['bio', 'interests'];
      if (event.jobTitle != null) fieldsUpdated.add('jobTitle');
      if (event.company != null) fieldsUpdated.add('company');
      if (event.school != null) fieldsUpdated.add('school');

      AnalyticsService.instance.logProfileUpdated(fieldsUpdated: fieldsUpdated);
      AnalyticsService.instance.logBioUpdated(charCount: event.bio.length);

      // Track photo changes
      if (event.photoUrls.length > oldPhotoCount) {
        AnalyticsService.instance.logPhotoAdded(
          totalPhotos: event.photoUrls.length,
        );
      } else if (event.photoUrls.length < oldPhotoCount) {
        AnalyticsService.instance.logPhotoRemoved(
          totalPhotos: event.photoUrls.length,
        );
      }
    }

    final user = result.data;
    emit(state.copyWith(
      user: user ?? state.user,
      profile: user?.profile ?? state.profile,
      isSaving: false,
      errorMessage: result.errorMessage,
    ));
  }

  Future<void> _onIdDocumentUploaded(
      ProfileIdDocumentUploaded event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(isSaving: true, errorMessage: null));
    final uploadResult = await Result.guard(
      () => profileRepository.uploadIdDocument(),
      logLabel: 'ProfileRepository.uploadIdDocument',
      fallbackError: ErrorMessages.uploadIdFailed,
    );
    if (!uploadResult.isSuccess) {
      emit(state.copyWith(
        isSaving: false,
        errorMessage: uploadResult.errorMessage,
      ));
      return;
    }

    final userResult = await Result.guard(
      () => profileRepository.markIdVerified(),
      logLabel: 'ProfileRepository.markIdVerified',
      fallbackError: ErrorMessages.uploadIdFailed,
    );
    final user = userResult.data;
    emit(state.copyWith(
      user: user ?? state.user,
      profile: user?.profile ?? state.profile,
      isSaving: false,
      errorMessage: userResult.errorMessage,
    ));
  }

  Future<void> _onIdVerifiedMarked(
      ProfileIdVerifiedMarked event, Emitter<ProfileState> emit) async {
    final result = await Result.guard(
      () => profileRepository.markIdVerified(),
      logLabel: 'ProfileRepository.markIdVerified',
      fallbackError: 'Could not mark ID verified. Please try again.',
    );
    final user = result.data;
    emit(state.copyWith(
      user: user ?? state.user,
      profile: user?.profile ?? state.profile,
      errorMessage: result.errorMessage,
    ));
  }

  Future<void> _onSaveRequested(
      ProfileSaveRequested event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(isSaving: true, errorMessage: null));
    final result = await Result.guard(
      () => profileRepository.updateProfile(event.profile),
      logLabel: 'ProfileRepository.updateProfile',
      fallbackError: ErrorMessages.saveProfileFailed,
    );
    final updatedUser = result.data;
    emit(state.copyWith(
      user: updatedUser ?? state.user,
      profile: updatedUser?.profile ?? state.profile,
      isSaving: false,
      status: ProfileStatus.loaded,
      errorMessage: result.errorMessage,
    ));
  }

  Future<void> _onLocationUpdateRequested(
      ProfileLocationUpdateRequested event, Emitter<ProfileState> emit) async {
    // Only update if we have a profile
    final currentProfile = state.profile;
    if (currentProfile == null) return;

    AppLogger.logInfo(
        '[ProfileBloc] Updating location: ${event.latitude}, ${event.longitude}');

    // Update profile with new location
    final updatedProfile = currentProfile.copyWith(
      latitude: event.latitude,
      longitude: event.longitude,
      city: event.city ?? currentProfile.city,
      country: event.country ?? currentProfile.country,
    );

    // Save to backend
    final result = await Result.guard(
      () => profileRepository.updateProfile(updatedProfile),
      logLabel: 'ProfileRepository.updateProfile (location)',
      fallbackError: 'Could not update location.',
    );

    if (result.isSuccess) {
      final updatedUser = result.data;
      emit(state.copyWith(
        user: updatedUser ?? state.user,
        profile: updatedUser?.profile ?? updatedProfile,
      ));

      AnalyticsService.instance.logProfileUpdated(
        fieldsUpdated: ['latitude', 'longitude', 'city', 'country'],
      );
    }
  }

  @override
  Future<void> close() {
    _retryTimer?.cancel();
    return super.close();
  }
}
