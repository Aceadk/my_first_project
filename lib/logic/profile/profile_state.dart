import 'package:equatable/equatable.dart';
import '../../data/models/profile.dart';
import '../../data/models/user.dart';

class ProfileState extends Equatable {
  final CrushUser? user;
  final Profile? profile;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const ProfileState({
    this.user,
    this.profile,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  ProfileState copyWith({
    CrushUser? user,
    Profile? profile,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
  }) {
    return ProfileState(
      user: user ?? this.user,
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        user,
        profile,
        isLoading,
        isSaving,
        errorMessage,
      ];
}
