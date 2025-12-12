import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/auth_repository.dart';
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
    try {
      final user = await profileRepository.getCurrentUser();
      emit(state.copyWith(
        user: user,
        profile: user?.profile,
        isLoading: false,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Could not load profile. Please try again.',
      ));
    }
  }

  Future<void> _onBasicInfoSubmitted(
      ProfileBasicInfoSubmitted event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(isSaving: true, errorMessage: null));
    try {
      final user = await profileRepository.saveBasicInfo(
        name: event.name,
        age: event.age,
        gender: event.gender,
        sexualOrientation: event.sexualOrientation,
      );
      emit(state.copyWith(
        user: user,
        profile: user.profile,
        isSaving: false,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        errorMessage: 'Could not save basic info. Please try again.',
      ));
    }
  }

  Future<void> _onDetailsSubmitted(
      ProfileDetailsSubmitted event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(isSaving: true, errorMessage: null));
    try {
      final user = await profileRepository.saveProfileDetails(
        bio: event.bio,
        photoUrls: event.photoUrls,
        jobTitle: event.jobTitle,
        company: event.company,
        school: event.school,
        interests: event.interests,
      );
      emit(state.copyWith(
        user: user,
        profile: user.profile,
        isSaving: false,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        errorMessage: 'Could not save profile. Please try again.',
      ));
    }
  }

  Future<void> _onIdDocumentUploaded(
      ProfileIdDocumentUploaded event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(isSaving: true, errorMessage: null));
    try {
      await profileRepository.uploadIdDocument();
      // Wait for manual or automatic verification – for demo we mark verified.
      final user = await profileRepository.markIdVerified();
      emit(state.copyWith(
        user: user,
        profile: user.profile,
        isSaving: false,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        errorMessage: 'Could not upload ID. Please try again.',
      ));
    }
  }

  Future<void> _onIdVerifiedMarked(
      ProfileIdVerifiedMarked event, Emitter<ProfileState> emit) async {
    try {
      final user = await profileRepository.markIdVerified();
      emit(state.copyWith(
        user: user,
        profile: user.profile,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Could not mark ID verified. Please try again.',
      ));
    }
  }

  Future<void> _onSaveRequested(
      ProfileSaveRequested event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(isSaving: true, errorMessage: null));
    try {
      final updatedUser = await profileRepository.updateProfile(event.profile);
      emit(state.copyWith(
        user: updatedUser,
        profile: updatedUser.profile,
        isSaving: false,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        errorMessage: 'Could not save profile. Please try again.',
      ));
    }
  }
}
