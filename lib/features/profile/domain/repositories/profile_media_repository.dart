enum ProfileMediaType { photo, video }

enum ProfileMediaErrorCode {
  fileNotFound,
  uploadFailed,
  deleteFailed,
  missingLocalFile,
  nonFirebaseUrl,
}

class ProfileMediaError {
  const ProfileMediaError({
    required this.code,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  final ProfileMediaErrorCode code;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;
}

class ProfileMediaUploadResult {
  const ProfileMediaUploadResult._({
    required this.url,
    required this.error,
    required this.usedLocalFallback,
  });

  final String? url;
  final ProfileMediaError? error;
  final bool usedLocalFallback;

  bool get isSuccess => url != null;

  factory ProfileMediaUploadResult.success({
    required String url,
    bool usedLocalFallback = false,
    ProfileMediaError? error,
  }) {
    return ProfileMediaUploadResult._(
      url: url,
      error: error,
      usedLocalFallback: usedLocalFallback,
    );
  }

  factory ProfileMediaUploadResult.failure({required ProfileMediaError error}) {
    return ProfileMediaUploadResult._(
      url: null,
      error: error,
      usedLocalFallback: false,
    );
  }
}

class ProfileMediaDeleteResult {
  const ProfileMediaDeleteResult._({
    required this.deleted,
    required this.skipped,
    this.error,
  });

  final bool deleted;
  final bool skipped;
  final ProfileMediaError? error;

  bool get isSuccess => error == null;

  factory ProfileMediaDeleteResult.deleted() {
    return const ProfileMediaDeleteResult._(deleted: true, skipped: false);
  }

  factory ProfileMediaDeleteResult.skipped() {
    return const ProfileMediaDeleteResult._(deleted: false, skipped: true);
  }

  factory ProfileMediaDeleteResult.failure({required ProfileMediaError error}) {
    return ProfileMediaDeleteResult._(
      deleted: false,
      skipped: false,
      error: error,
    );
  }
}

enum ProfileMediaMigrationIssueKind { uploadFailed, missingLocalFile }

class ProfileMediaMigrationIssue {
  const ProfileMediaMigrationIssue({
    required this.mediaType,
    required this.path,
    required this.kind,
    required this.error,
    required this.recoveredWithFallback,
  });

  final ProfileMediaType mediaType;
  final String path;
  final ProfileMediaMigrationIssueKind kind;
  final ProfileMediaError error;
  final bool recoveredWithFallback;
}

class ProfileMediaEnsureResult {
  ProfileMediaEnsureResult({
    required List<String> photoUrls,
    required List<String> videoUrls,
    List<ProfileMediaMigrationIssue> issues =
        const <ProfileMediaMigrationIssue>[],
  }) : photoUrls = List.unmodifiable(photoUrls),
       videoUrls = List.unmodifiable(videoUrls),
       issues = List.unmodifiable(issues);

  final List<String> photoUrls;
  final List<String> videoUrls;
  final List<ProfileMediaMigrationIssue> issues;

  bool get hasIssues => issues.isNotEmpty;
  bool get hasBlockingFailures =>
      issues.any((issue) => !issue.recoveredWithFallback);
}

abstract class ProfileMediaRepository {
  Future<ProfileMediaUploadResult> uploadPhoto({
    required String userId,
    required String filePath,
  });

  Future<ProfileMediaUploadResult> uploadVideo({
    required String userId,
    required String filePath,
  });

  Future<ProfileMediaDeleteResult> deleteMedia(String url);

  bool isLocalFile(String path);

  Future<ProfileMediaEnsureResult> ensureRemoteUrls({
    required String userId,
    required List<String> photoPaths,
    required List<String> videoPaths,
  });
}
