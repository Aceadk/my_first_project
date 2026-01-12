import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crushhour/features/profile/data/repositories/profile_repository.dart';
import 'package:crushhour/features/auth/data/repositories/auth_repository.dart';
import 'package:crushhour/core/utils/result.dart';
import 'package:crushhour/core/services/analytics_service.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository profileRepository;
  final AuthRepository authRepository;

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
  }

  Future<void> _onLoadRequested(
      ProfileLoadRequested event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    final result = await Result.guard(
      () => profileRepository.getCurrentUser(),
      logLabel: 'ProfileRepository.getCurrentUser',
      fallbackError: 'Could not load profile. Please try again.',
    );
    if (!result.isSuccess) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: result.errorMessage,
      ));
      return;
    }

    final user = result.data;

    // Track profile viewed
    if (user != null) {
      AnalyticsService.instance.logProfileViewed();
    }

    emit(state.copyWith(
      user: user,
      profile: user?.profile,
      isLoading: false,
      errorMessage: null,
    ));
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
      fallbackError: 'Could not save profile. Please try again.',
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
      fallbackError: 'Could not upload ID. Please try again.',
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
      fallbackError: 'Could not upload ID. Please try again.',
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
      fallbackError: 'Could not save profile. Please try again.',
    );
    final updatedUser = result.data;
    emit(state.copyWith(
      user: updatedUser ?? state.user,
      profile: updatedUser?.profile ?? state.profile,
      isSaving: false,
      errorMessage: result.errorMessage,
    ));
  }
}
