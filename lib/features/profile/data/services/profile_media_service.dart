import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:crushhour/core/app_logger.dart';
import 'package:crushhour/core/media/image_optimizer.dart';
import 'package:crushhour/core/performance/performance_monitor.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:crushhour/features/profile/domain/repositories/profile_media_repository.dart';

typedef MediaUploadHandler =
    Future<String> Function({
      required String storagePath,
      required File file,
      required SettableMetadata metadata,
    });

typedef MediaDeleteHandler = Future<void> Function(String url);

/// ProfileMediaService handles uploading profile photos and videos to Firebase Storage.
///
/// Optionally (opt-in via [useFallbackInDebug]), if a Firebase Storage upload
/// fails in debug mode it can fall back to the local file path so the picked
/// media still renders on-device. This is OFF by default: the local path is
/// later discarded by the repository (only remote URLs are persisted), so a
/// silent fallback makes uploads *look* successful while the photo is never
/// actually saved. Failing loudly surfaces the real cause (e.g. Storage rules
/// not deployed, or App Check rejecting the request).

class ProfileMediaService implements ProfileMediaRepository {
  ProfileMediaService({
    MediaUploadHandler? uploadHandler,
    MediaDeleteHandler? deleteHandler,
    bool Function()? isDebugMode,
    String Function()? uuidGenerator,
  }) : _isDebugMode = isDebugMode ?? _defaultIsDebugMode,
       _uuidGenerator = uuidGenerator ?? const Uuid().v4 {
    _uploadHandler = uploadHandler ?? _uploadWithFirebase;
    _deleteHandler = deleteHandler ?? _deleteWithFirebase;
  }

  static bool _defaultIsDebugMode() => kDebugMode;

  FirebaseStorage? _storage;
  FirebaseStorage get _storageInstance => _storage ??= FirebaseStorage.instance;
  late final MediaUploadHandler _uploadHandler;
  late final MediaDeleteHandler _deleteHandler;
  final bool Function() _isDebugMode;
  final String Function() _uuidGenerator;

  /// Whether to use local file fallback when Firebase Storage fails (debug only).
  ///
  /// Defaults to false so failed uploads surface a real error instead of
  /// silently substituting a local path that the repository will later drop.
  /// Opt in per-session if you need offline/local-only development.
  static bool useFallbackInDebug = false;

  /// Upload a photo to Firebase Storage.
  /// Returns an explicit typed result for success/failure/fallback paths.
  @override
  Future<ProfileMediaUploadResult> uploadPhoto({
    required String userId,
    required String filePath,
  }) async {
    var file = File(filePath);
    if (!await file.exists()) {
      return ProfileMediaUploadResult.failure(
        error: ProfileMediaError(
          code: ProfileMediaErrorCode.fileNotFound,
          message: 'Photo file not found: $filePath',
        ),
      );
    }

    try {
      // Optimize image before upload: resize, compress, strip EXIF
      try {
        final optimized = await ImageOptimizer.instance.optimize(file);
        file = optimized.optimizedFile;
        AppLogger.debug(
          'ProfileMediaService: Optimized photo — '
          'saved ${(optimized.savedBytes / 1024).toStringAsFixed(0)} KB',
        );
      } catch (e) {
        // Optimization failure is non-fatal — upload the original
        AppLogger.warning(
          'ProfileMediaService: Image optimization failed, uploading original',
          error: e,
        );
      }

      // Generate unique filename (always .jpg after optimization)
      final extension = path.extension(file.path).toLowerCase();
      final filename = '${_uuidGenerator()}$extension';
      final storagePath = 'users/$userId/photos/$filename';

      // Upload to Firebase Storage
      await PerformanceMonitor.instance.startTrace('image_upload');
      final downloadUrl = await _uploadHandler(
        storagePath: storagePath,
        file: file,
        metadata: SettableMetadata(
          contentType: _getContentType(extension),
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'userId': userId,
          },
        ),
      );
      await PerformanceMonitor.instance.stopTrace(
        'image_upload',
        metrics: {'size_bytes': await file.length()},
      );

      AppLogger.debug('ProfileMediaService: Photo uploaded - $downloadUrl');
      return ProfileMediaUploadResult.success(url: downloadUrl);
    } on FirebaseException catch (e, st) {
      AppLogger.debug(
        'ProfileMediaService: Firebase Storage error - ${e.code}: ${e.message}',
      );
      AppLogger.debug(
        'ProfileMediaService: Make sure Firebase Storage rules allow uploads for authenticated users.',
      );
      AppLogger.debug('ProfileMediaService: Example rules:');
      AppLogger.debug('  rules_version = "2";');
      AppLogger.debug('  service firebase.storage {');
      AppLogger.debug('    match /b/{bucket}/o {');
      AppLogger.debug('      match /users/{userId}/{allPaths=**} {');
      AppLogger.debug(
        '        allow read, write: if request.auth != null && request.auth.uid == userId;',
      );
      AppLogger.debug('      }');
      AppLogger.debug('    }');
      AppLogger.debug('  }');

      return _uploadFailureWithOptionalFallback(
        localPath: filePath,
        error: ProfileMediaError(
          code: ProfileMediaErrorCode.uploadFailed,
          message: 'Photo upload failed: ${e.message ?? e.code}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      AppLogger.error('ProfileMediaService: Photo upload failed - $e');

      return _uploadFailureWithOptionalFallback(
        localPath: filePath,
        error: ProfileMediaError(
          code: ProfileMediaErrorCode.uploadFailed,
          message: 'Photo upload failed: $e',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Upload a video to Firebase Storage.
  /// Returns an explicit typed result for success/failure/fallback paths.
  @override
  Future<ProfileMediaUploadResult> uploadVideo({
    required String userId,
    required String filePath,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return ProfileMediaUploadResult.failure(
        error: ProfileMediaError(
          code: ProfileMediaErrorCode.fileNotFound,
          message: 'Video file not found: $filePath',
        ),
      );
    }

    try {
      // Generate unique filename
      final extension = path.extension(filePath).toLowerCase();
      final filename = '${_uuidGenerator()}$extension';
      final storagePath = 'users/$userId/videos/$filename';

      // Upload to Firebase Storage
      final downloadUrl = await _uploadHandler(
        storagePath: storagePath,
        file: file,
        metadata: SettableMetadata(
          contentType: _getVideoContentType(extension),
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'userId': userId,
          },
        ),
      );

      AppLogger.debug('ProfileMediaService: Video uploaded - $downloadUrl');
      return ProfileMediaUploadResult.success(url: downloadUrl);
    } on FirebaseException catch (e, st) {
      AppLogger.debug(
        'ProfileMediaService: Firebase Storage error - ${e.code}: ${e.message}',
      );

      return _uploadFailureWithOptionalFallback(
        localPath: filePath,
        error: ProfileMediaError(
          code: ProfileMediaErrorCode.uploadFailed,
          message: 'Video upload failed: ${e.message ?? e.code}',
          cause: e,
          stackTrace: st,
        ),
      );
    } catch (e, st) {
      AppLogger.error('ProfileMediaService: Video upload failed - $e');

      return _uploadFailureWithOptionalFallback(
        localPath: filePath,
        error: ProfileMediaError(
          code: ProfileMediaErrorCode.uploadFailed,
          message: 'Video upload failed: $e',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Delete a media file from Firebase Storage.
  @override
  Future<ProfileMediaDeleteResult> deleteMedia(String url) async {
    try {
      if (!url.startsWith('https://firebasestorage.googleapis.com')) {
        return ProfileMediaDeleteResult.skipped();
      }

      await _deleteHandler(url);
      AppLogger.debug('ProfileMediaService: Media deleted - $url');
      return ProfileMediaDeleteResult.deleted();
    } catch (e, st) {
      AppLogger.error('ProfileMediaService: Media delete failed - $e');
      return ProfileMediaDeleteResult.failure(
        error: ProfileMediaError(
          code: ProfileMediaErrorCode.deleteFailed,
          message: 'Media delete failed: $e',
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Check if a path is a local file (not a remote URL).
  @override
  bool isLocalFile(String path) {
    return !path.startsWith('http://') && !path.startsWith('https://');
  }

  /// Upload local files and normalize all media paths to remote/local-usable URLs.
  /// Returns explicit issue details for all recoverable/non-recoverable branches.
  @override
  Future<ProfileMediaEnsureResult> ensureRemoteUrls({
    required String userId,
    required List<String> photoPaths,
    required List<String> videoPaths,
  }) async {
    final photoUrls = <String>[];
    final videoUrls = <String>[];
    final issues = <ProfileMediaMigrationIssue>[];

    for (final filePath in photoPaths) {
      if (isLocalFile(filePath)) {
        // Check if local file still exists
        final file = File(filePath);
        if (!await file.exists()) {
          AppLogger.debug(
            'ProfileMediaService: Skipping missing local photo: $filePath',
          );
          issues.add(
            ProfileMediaMigrationIssue(
              mediaType: ProfileMediaType.photo,
              path: filePath,
              kind: ProfileMediaMigrationIssueKind.missingLocalFile,
              error: ProfileMediaError(
                code: ProfileMediaErrorCode.missingLocalFile,
                message: 'Missing local photo file: $filePath',
              ),
              recoveredWithFallback: false,
            ),
          );
          continue;
        }

        final result = await uploadPhoto(userId: userId, filePath: filePath);
        if (result.isSuccess && result.url != null) {
          photoUrls.add(result.url!);
        }
        if (result.error != null) {
          issues.add(
            ProfileMediaMigrationIssue(
              mediaType: ProfileMediaType.photo,
              path: filePath,
              kind: ProfileMediaMigrationIssueKind.uploadFailed,
              error: result.error!,
              recoveredWithFallback: result.usedLocalFallback,
            ),
          );
        }
      } else {
        photoUrls.add(filePath);
      }
    }

    for (final filePath in videoPaths) {
      if (isLocalFile(filePath)) {
        // Check if local file still exists
        final file = File(filePath);
        if (!await file.exists()) {
          AppLogger.debug(
            'ProfileMediaService: Skipping missing local video: $filePath',
          );
          issues.add(
            ProfileMediaMigrationIssue(
              mediaType: ProfileMediaType.video,
              path: filePath,
              kind: ProfileMediaMigrationIssueKind.missingLocalFile,
              error: ProfileMediaError(
                code: ProfileMediaErrorCode.missingLocalFile,
                message: 'Missing local video file: $filePath',
              ),
              recoveredWithFallback: false,
            ),
          );
          continue;
        }

        final result = await uploadVideo(userId: userId, filePath: filePath);
        if (result.isSuccess && result.url != null) {
          videoUrls.add(result.url!);
        }
        if (result.error != null) {
          issues.add(
            ProfileMediaMigrationIssue(
              mediaType: ProfileMediaType.video,
              path: filePath,
              kind: ProfileMediaMigrationIssueKind.uploadFailed,
              error: result.error!,
              recoveredWithFallback: result.usedLocalFallback,
            ),
          );
        }
      } else {
        videoUrls.add(filePath);
      }
    }

    return ProfileMediaEnsureResult(
      photoUrls: photoUrls,
      videoUrls: videoUrls,
      issues: issues,
    );
  }

  String _getContentType(String extension) {
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.heic':
      case '.heif':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  String _getVideoContentType(String extension) {
    switch (extension) {
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.avi':
        return 'video/x-msvideo';
      case '.webm':
        return 'video/webm';
      default:
        return 'video/mp4';
    }
  }

  Future<String> _uploadWithFirebase({
    required String storagePath,
    required File file,
    required SettableMetadata metadata,
  }) async {
    final ref = _storageInstance.ref().child(storagePath);
    final snapshot = await ref.putFile(file, metadata);
    return snapshot.ref.getDownloadURL();
  }

  Future<void> _deleteWithFirebase(String url) async {
    final ref = _storageInstance.refFromURL(url);
    await ref.delete();
  }

  ProfileMediaUploadResult _uploadFailureWithOptionalFallback({
    required String localPath,
    required ProfileMediaError error,
  }) {
    if (_isDebugMode() && useFallbackInDebug) {
      AppLogger.debug(
        'ProfileMediaService: Using local file fallback for development',
      );
      return ProfileMediaUploadResult.success(
        url: localPath,
        usedLocalFallback: true,
        error: error,
      );
    }
    return ProfileMediaUploadResult.failure(error: error);
  }
}
