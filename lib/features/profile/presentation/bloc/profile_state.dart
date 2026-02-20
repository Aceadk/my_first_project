import 'package:equatable/equatable.dart';
import 'package:crushhour/data/models/profile.dart';
import 'package:crushhour/data/models/user.dart';

/// Profile loading status.
enum ProfileStatus {
  /// Initial state, no load attempted yet.
  initial,

  /// Loading profile from server.
  loading,

  /// Profile loaded successfully.
  loaded,

  /// No profile exists yet (new user), ready to create.
  empty,

  /// Error loading profile (after retries exhausted).
  error,
}

class ProfileState extends Equatable {
  final CrushUser? user;
  final Profile? profile;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final ProfileStatus status;
  final int? nextRetrySeconds;
  static const _unset = Object();

  const ProfileState({
    this.user,
    this.profile,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.status = ProfileStatus.initial,
    this.nextRetrySeconds,
  });

  ProfileState copyWith({
    CrushUser? user,
    Profile? profile,
    bool? isLoading,
    bool? isSaving,
    Object? errorMessage = _unset,
    ProfileStatus? status,
    Object? nextRetrySeconds = _unset,
  }) {
    return ProfileState(
      user: user ?? this.user,
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      status: status ?? this.status,
      nextRetrySeconds: identical(nextRetrySeconds, _unset)
          ? this.nextRetrySeconds
          : nextRetrySeconds as int?,
    );
  }

  @override
  List<Object?> get props => [
    user,
    profile,
    isLoading,
    isSaving,
    errorMessage,
    status,
    nextRetrySeconds,
  ];
}
