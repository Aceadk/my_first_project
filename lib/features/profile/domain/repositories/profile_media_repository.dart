abstract class ProfileMediaRepository {
  Future<String> uploadPhoto({
    required String userId,
    required String filePath,
  });

  Future<String> uploadVideo({
    required String userId,
    required String filePath,
  });

  Future<void> deleteMedia(String url);

  bool isLocalFile(String path);

  Future<({List<String> photoUrls, List<String> videoUrls})> ensureRemoteUrls({
    required String userId,
    required List<String> photoPaths,
    required List<String> videoPaths,
  });
}
