/// Mock implementation of ProfileMediaService.
/// For demo purposes, this returns local file paths as-is.
/// Replace with your actual media upload backend for production.
class ProfileMediaService {
  /// Upload a photo to storage and return the download URL.
  /// For demo: returns the local file path as-is.
  Future<String> uploadPhoto({
    required String userId,
    required String filePath,
  }) async {
    // Simulate upload delay
    await Future.delayed(const Duration(milliseconds: 300));

    // For demo: return local path as-is (works for displaying local images)
    return filePath;
  }

  /// Upload a video to storage and return the download URL.
  /// For demo: returns the local file path as-is.
  Future<String> uploadVideo({
    required String userId,
    required String filePath,
  }) async {
    // Simulate upload delay
    await Future.delayed(const Duration(milliseconds: 500));

    // For demo: return local path as-is (works for displaying local videos)
    return filePath;
  }

  /// Delete a media file from storage.
  Future<void> deleteMedia(String url) async {
    // For demo: no-op (files remain on device)
    // In production: delete from cloud storage
  }

  /// Check if a path is a local file (not a remote URL).
  bool isLocalFile(String path) {
    return !path.startsWith('http://') && !path.startsWith('https://');
  }

  /// Upload local files and return list of URLs (local files get uploaded, remote URLs pass through).
  Future<({List<String> photoUrls, List<String> videoUrls})> ensureRemoteUrls({
    required String userId,
    required List<String> photoPaths,
    required List<String> videoPaths,
  }) async {
    final photoUrls = <String>[];
    final videoUrls = <String>[];

    for (final path in photoPaths) {
      if (isLocalFile(path)) {
        final url = await uploadPhoto(userId: userId, filePath: path);
        photoUrls.add(url);
      } else {
        photoUrls.add(path);
      }
    }

    for (final path in videoPaths) {
      if (isLocalFile(path)) {
        final url = await uploadVideo(userId: userId, filePath: path);
        videoUrls.add(url);
      } else {
        videoUrls.add(path);
      }
    }

    return (photoUrls: photoUrls, videoUrls: videoUrls);
  }
}
