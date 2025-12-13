import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class ProfileMediaUploadResult {
  final List<String> photoUrls;
  final List<String> videoUrls;

  const ProfileMediaUploadResult({
    required this.photoUrls,
    required this.videoUrls,
  });
}

/// Uploads local profile media to Firebase Storage while leaving remote URLs untouched.
class ProfileMediaService {
  ProfileMediaService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<ProfileMediaUploadResult> ensureRemoteUrls({
    required String userId,
    required List<String> photoPaths,
    required List<String> videoPaths,
  }) async {
    final uploadedPhotos = <String>[];
    final uploadedVideos = <String>[];

    for (final path in photoPaths) {
      uploadedPhotos.add(await _maybeUpload(path, userId, 'photos'));
    }
    for (final path in videoPaths) {
      uploadedVideos.add(await _maybeUpload(path, userId, 'videos'));
    }

    return ProfileMediaUploadResult(
      photoUrls: uploadedPhotos,
      videoUrls: uploadedVideos,
    );
  }

  Future<String> _maybeUpload(
    String path,
    String userId,
    String folder,
  ) async {
    if (_isRemote(path)) return path;

    final ext = _safeExtension(path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = path.split('/').last;
    final objectPath =
        'profile_media/$userId/$folder/${timestamp}_$fileName';
    final ref = _storage.ref().child(objectPath);
    final file = File(path);

    final metadata = SettableMetadata(contentType: _contentType(ext, folder));
    final uploadTask = ref.putFile(file, metadata);
    final snapshot = await uploadTask.whenComplete(() {});
    return snapshot.ref.getDownloadURL();
  }

  bool _isRemote(String path) {
    final uri = Uri.tryParse(path);
    return uri != null && uri.hasScheme && (uri.isScheme('http') || uri.isScheme('https'));
  }

  String _safeExtension(String path) {
    final parts = path.split('.');
    if (parts.length < 2) return '';
    return parts.last.toLowerCase();
  }

  String _contentType(String ext, String folder) {
    if (folder == 'videos') {
      switch (ext) {
        case 'mp4':
          return 'video/mp4';
        case 'mov':
          return 'video/quicktime';
        case 'webm':
          return 'video/webm';
        default:
          return 'video/*';
      }
    }

    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/*';
    }
  }
}
