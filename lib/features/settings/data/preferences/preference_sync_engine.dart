enum PreferenceResolutionSource { local, remote, merged }

class PreferenceSyncSnapshot<T> {
  const PreferenceSyncSnapshot({required this.value, this.updatedAt});

  final T value;
  final DateTime? updatedAt;
}

class PreferenceSyncMergeResult<T> {
  const PreferenceSyncMergeResult({
    required this.value,
    required this.source,
    required this.hadConflict,
    this.updatedAt,
  });

  final T value;
  final PreferenceResolutionSource source;
  final bool hadConflict;
  final DateTime? updatedAt;
}

typedef PreferenceConflictResolver<T> = T Function(T localValue, T remoteValue);
typedef PreferenceEquality<T> = bool Function(T left, T right);

/// Resolves local cache and remote/server snapshots using timestamps first,
/// then a conflict resolver when both sides are equally fresh.
class PreferenceSyncEngine<T> {
  const PreferenceSyncEngine({
    required this.equals,
    required this.resolveConflict,
  });

  final PreferenceEquality<T> equals;
  final PreferenceConflictResolver<T> resolveConflict;

  PreferenceSyncMergeResult<T> resolve({
    required PreferenceSyncSnapshot<T> local,
    PreferenceSyncSnapshot<T>? remote,
  }) {
    if (remote == null) {
      return PreferenceSyncMergeResult<T>(
        value: local.value,
        source: PreferenceResolutionSource.local,
        hadConflict: false,
        updatedAt: local.updatedAt,
      );
    }

    final localUpdatedAt = local.updatedAt;
    final remoteUpdatedAt = remote.updatedAt;

    if (localUpdatedAt == null && remoteUpdatedAt != null) {
      return PreferenceSyncMergeResult<T>(
        value: remote.value,
        source: PreferenceResolutionSource.remote,
        hadConflict: false,
        updatedAt: remoteUpdatedAt,
      );
    }

    if (localUpdatedAt != null && remoteUpdatedAt == null) {
      return PreferenceSyncMergeResult<T>(
        value: local.value,
        source: PreferenceResolutionSource.local,
        hadConflict: false,
        updatedAt: localUpdatedAt,
      );
    }

    if (localUpdatedAt != null && remoteUpdatedAt != null) {
      if (localUpdatedAt.isAfter(remoteUpdatedAt)) {
        return PreferenceSyncMergeResult<T>(
          value: local.value,
          source: PreferenceResolutionSource.local,
          hadConflict: false,
          updatedAt: localUpdatedAt,
        );
      }
      if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
        return PreferenceSyncMergeResult<T>(
          value: remote.value,
          source: PreferenceResolutionSource.remote,
          hadConflict: false,
          updatedAt: remoteUpdatedAt,
        );
      }
    }

    final valuesEqual = equals(local.value, remote.value);
    if (valuesEqual) {
      return PreferenceSyncMergeResult<T>(
        value: local.value,
        source: PreferenceResolutionSource.local,
        hadConflict: false,
        updatedAt: localUpdatedAt ?? remoteUpdatedAt,
      );
    }

    final merged = resolveConflict(local.value, remote.value);
    return PreferenceSyncMergeResult<T>(
      value: merged,
      source: PreferenceResolutionSource.merged,
      hadConflict: true,
      updatedAt: localUpdatedAt ?? remoteUpdatedAt,
    );
  }
}
