import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:crushhour/core/app_logger.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

/// ProfileMediaService handles uploading profile photos and videos to Firebase Storage.
///
/// In debug mode, if Firebase Storage upload fails (e.g., due to security rules),
/// it will fall back to using local file paths. This allows development to continue
/// while Firebase Storage rules are being configured.
class ProfileMediaService {
  FirebaseStorage? _storage;
  FirebaseStorage get _storageInstance => _storage ??= FirebaseStorage.instance;
  final _uuid = const Uuid();

  /// Whether to use local file fallback when Firebase Storage fails (debug only)
  static bool useFallbackInDebug = true;

  /// Upload a photo to Firebase Storage and return the download URL.
  /// In debug mode with fallback enabled, returns local path if upload fails.
  Future<String> uploadPhoto({
    required String userId,
    required String filePath,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Photo file not found: $filePath');
    }

    try {
      // Generate unique filename
      final extension = path.extension(filePath).toLowerCase();
      final filename = '${_uuid.v4()}$extension';
      final storagePath = 'users/$userId/photos/$filename';

      // Upload to Firebase Storage
      final ref = _storageInstance.ref().child(storagePath);
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: _getContentType(extension),
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'userId': userId,
          },
        ),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      AppLogger.debug('ProfileMediaService: Photo uploaded - $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
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

      // In debug mode, fall back to local path
      if (kDebugMode && useFallbackInDebug) {
        AppLogger.debug(
          'ProfileMediaService: Using local file fallback for development',
        );
        return filePath;
      }
      rethrow;
    } catch (e) {
      AppLogger.error('ProfileMediaService: Photo upload failed - $e');

      // In debug mode, fall back to local path
      if (kDebugMode && useFallbackInDebug) {
        AppLogger.debug(
          'ProfileMediaService: Using local file fallback for development',
        );
        return filePath;
      }
      rethrow;
    }
  }

  /// Upload a video to Firebase Storage and return the download URL.
  /// In debug mode with fallback enabled, returns local path if upload fails.
  Future<String> uploadVideo({
    required String userId,
    required String filePath,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Video file not found: $filePath');
    }

    try {
      // Generate unique filename
      final extension = path.extension(filePath).toLowerCase();
      final filename = '${_uuid.v4()}$extension';
      final storagePath = 'users/$userId/videos/$filename';

      // Upload to Firebase Storage
      final ref = _storageInstance.ref().child(storagePath);
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: _getVideoContentType(extension),
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'userId': userId,
          },
        ),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      AppLogger.debug('ProfileMediaService: Video uploaded - $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      AppLogger.debug(
        'ProfileMediaService: Firebase Storage error - ${e.code}: ${e.message}',
      );

      // In debug mode, fall back to local path
      if (kDebugMode && useFallbackInDebug) {
        AppLogger.debug(
          'ProfileMediaService: Using local file fallback for development',
        );
        return filePath;
      }
      rethrow;
    } catch (e) {
      AppLogger.error('ProfileMediaService: Video upload failed - $e');

      // In debug mode, fall back to local path
      if (kDebugMode && useFallbackInDebug) {
        AppLogger.debug(
          'ProfileMediaService: Using local file fallback for development',
        );
        return filePath;
      }
      rethrow;
    }
  }

  /// Delete a media file from Firebase Storage.
  Future<void> deleteMedia(String url) async {
    try {
      if (!url.startsWith('https://firebasestorage.googleapis.com')) {
        // Not a Firebase Storage URL, skip
        return;
      }

      final ref = _storageInstance.refFromURL(url);
      await ref.delete();
      AppLogger.debug('ProfileMediaService: Media deleted - $url');
    } catch (e) {
      AppLogger.error('ProfileMediaService: Media delete failed - $e');
      // Don't rethrow - deletion failures shouldn't block user operations
    }
  }

  /// Check if a path is a local file (not a remote URL).
  bool isLocalFile(String path) {
    return !path.startsWith('http://') && !path.startsWith('https://');
  }

  /// Upload local files and return list of URLs (local files get uploaded, remote URLs pass through).
  /// Skips local files that no longer exist (e.g., temp files that were cleaned up).
  Future<({List<String> photoUrls, List<String> videoUrls})> ensureRemoteUrls({
    required String userId,
    required List<String> photoPaths,
    required List<String> videoPaths,
  }) async {
    final photoUrls = <String>[];
    final videoUrls = <String>[];

    for (final filePath in photoPaths) {
      if (isLocalFile(filePath)) {
        // Check if local file still exists
        final file = File(filePath);
        if (!await file.exists()) {
          AppLogger.debug(
            'ProfileMediaService: Skipping missing local photo: $filePath',
          );
          continue; // Skip missing files instead of failing
        }
        try {
          final url = await uploadPhoto(userId: userId, filePath: filePath);
          photoUrls.add(url);
        } catch (e) {
          AppLogger.debug(
            'ProfileMediaService: Failed to upload photo, skipping: $e',
          );
          // In debug mode with fallback, still add the local path
          if (kDebugMode && useFallbackInDebug) {
            photoUrls.add(filePath);
          }
          // In release mode, skip the failed photo rather than failing entire save
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
          continue; // Skip missing files instead of failing
        }
        try {
          final url = await uploadVideo(userId: userId, filePath: filePath);
          videoUrls.add(url);
        } catch (e) {
          AppLogger.debug(
            'ProfileMediaService: Failed to upload video, skipping: $e',
          );
          // In debug mode with fallback, still add the local path
          if (kDebugMode && useFallbackInDebug) {
            videoUrls.add(filePath);
          }
          // In release mode, skip the failed video rather than failing entire save
        }
      } else {
        videoUrls.add(filePath);
      }
    }

    return (photoUrls: photoUrls, videoUrls: videoUrls);
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
}
