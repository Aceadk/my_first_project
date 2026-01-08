/// Stub implementation of ProfileMediaService.
/// Replace with your actual media upload backend.
class ProfileMediaService {
  /// Upload a photo to storage and return the download URL.
  Future<String> uploadPhoto({
    required String userId,
    required String filePath,
  }) async {
    // TODO: Implement photo upload to your storage backend
    throw UnimplementedError('Photo upload not implemented. Connect your storage backend.');
  }

  /// Upload a video to storage and return the download URL.
  Future<String> uploadVideo({
    required String userId,
    required String filePath,
  }) async {
    // TODO: Implement video upload to your storage backend
    throw UnimplementedError('Video upload not implemented. Connect your storage backend.');
  }

  /// Delete a media file from storage.
  Future<void> deleteMedia(String url) async {
    // TODO: Implement media deletion from your storage backend
  }

  /// Check if a path is a local file (not a remote URL).
  bool isLocalFile(String path) {
    return !path.startsWith('http://') && !path.startsWith('https://');
  }

  /// Upload local files and return list of URLs (local files get uploaded, remote URLs pass through).
  Future<({List<String> photos, List<String> videos})> ensureRemoteUrls({
    required String userId,
    required List<String> photoPaths,
    required List<String> videoPaths,
  }) async {
    // TODO: Implement batch upload to your storage backend
    // For now, just return the paths as-is (assuming they're already URLs)
    final photos = <String>[];
    final videos = <String>[];

    for (final path in photoPaths) {
      if (isLocalFile(path)) {
        // Would upload here
        throw UnimplementedError('Photo upload not implemented. Connect your storage backend.');
      } else {
        photos.add(path);
      }
    }

    for (final path in videoPaths) {
      if (isLocalFile(path)) {
        // Would upload here
        throw UnimplementedError('Video upload not implemented. Connect your storage backend.');
      } else {
        videos.add(path);
      }
    }

    return (photos: photos, videos: videos);
  }
}
