import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crushhour/features/profile/data/services/profile_media_service.dart';
import 'package:crushhour/features/profile/domain/repositories/profile_media_repository.dart';
import 'core/services/firebase_mocks.dart';

const _firebaseTestOptions = FirebaseOptions(
  apiKey: 'test-api-key',
  appId: '1:1234567890:ios:test-app-id',
  messagingSenderId: '1234567890',
  projectId: 'test-project-id',
  storageBucket: 'test-project-id.appspot.com',
);

void main() {
  group('ProfileMediaService', () {
    late ProfileMediaService service;
    late Directory tempDir;

    setUpAll(() async {
      setupFirebaseCoreMocks();
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: _firebaseTestOptions);
      }
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('profile_media_test_');
      service = ProfileMediaService();
      ProfileMediaService.useFallbackInDebug = true;
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      ProfileMediaService.useFallbackInDebug = true;
    });

    test('isLocalFile detects local and remote paths', () {
      expect(service.isLocalFile('/tmp/photo.jpg'), isTrue);
      expect(service.isLocalFile('file:///tmp/photo.jpg'), isTrue);
      expect(service.isLocalFile('https://example.com/photo.jpg'), isFalse);
      expect(service.isLocalFile('http://example.com/photo.jpg'), isFalse);
    });

    test('uploadPhoto returns failure when file does not exist', () async {
      final result = await service.uploadPhoto(
        userId: 'user-1',
        filePath: '${tempDir.path}/missing.jpg',
      );
      expect(result.isSuccess, isFalse);
      expect(result.error?.code, ProfileMediaErrorCode.fileNotFound);
      expect(result.error?.message, contains('Photo file not found'));
    });

    test('uploadVideo returns failure when file does not exist', () async {
      final result = await service.uploadVideo(
        userId: 'user-1',
        filePath: '${tempDir.path}/missing.mp4',
      );
      expect(result.isSuccess, isFalse);
      expect(result.error?.code, ProfileMediaErrorCode.fileNotFound);
      expect(result.error?.message, contains('Video file not found'));
    });

    test(
      'uploadPhoto falls back to local path in debug on upload error',
      () async {
        final file = File('${tempDir.path}/photo.jpg');
        await file.writeAsString('fake-photo-bytes');

        final result = await service.uploadPhoto(
          userId: 'user-1',
          filePath: file.path,
        );

        expect(result.isSuccess, isTrue);
        expect(result.url, file.path);
        expect(result.usedLocalFallback, isTrue);
        expect(result.error?.code, ProfileMediaErrorCode.uploadFailed);
      },
    );

    test(
      'uploadVideo falls back to local path in debug on upload error',
      () async {
        final file = File('${tempDir.path}/video.mp4');
        await file.writeAsString('fake-video-bytes');

        final result = await service.uploadVideo(
          userId: 'user-1',
          filePath: file.path,
        );

        expect(result.isSuccess, isTrue);
        expect(result.url, file.path);
        expect(result.usedLocalFallback, isTrue);
        expect(result.error?.code, ProfileMediaErrorCode.uploadFailed);
      },
    );

    test('deleteMedia skips non-firebase URLs and does not throw', () async {
      final nonFirebase = await service.deleteMedia(
        'https://example.com/not-firebase.jpg',
      );
      final localPath = await service.deleteMedia('/local/path/photo.jpg');
      expect(nonFirebase.skipped, isTrue);
      expect(localPath.skipped, isTrue);
    });

    test('deleteMedia swallows errors for firebase URLs', () async {
      final result = await service.deleteMedia(
        'https://firebasestorage.googleapis.com/v0/b/demo/o/users%2Fuser-1%2Fphotos%2F1.jpg',
      );
      expect(result.isSuccess, isFalse);
      expect(result.error?.code, ProfileMediaErrorCode.deleteFailed);
    });

    test(
      'ensureRemoteUrls uploads local files, keeps remote, skips missing',
      () async {
        final localPhoto = File('${tempDir.path}/photo.png');
        final localVideo = File('${tempDir.path}/video.mp4');
        await localPhoto.writeAsString('p');
        await localVideo.writeAsString('v');

        final result = await service.ensureRemoteUrls(
          userId: 'user-42',
          photoPaths: [
            localPhoto.path,
            'https://cdn.example.com/photo.jpg',
            '${tempDir.path}/missing_photo.jpg',
          ],
          videoPaths: [
            localVideo.path,
            'https://cdn.example.com/video.mp4',
            '${tempDir.path}/missing_video.mp4',
          ],
        );

        expect(result.photoUrls, contains(localPhoto.path));
        expect(result.photoUrls, contains('https://cdn.example.com/photo.jpg'));
        expect(
          result.photoUrls,
          isNot(contains('${tempDir.path}/missing_photo.jpg')),
        );
        expect(
          result.issues.where((i) => i.mediaType == ProfileMediaType.photo),
          isNotEmpty,
        );

        expect(result.videoUrls, contains(localVideo.path));
        expect(result.videoUrls, contains('https://cdn.example.com/video.mp4'));
        expect(
          result.videoUrls,
          isNot(contains('${tempDir.path}/missing_video.mp4')),
        );
        expect(
          result.issues.where((i) => i.mediaType == ProfileMediaType.video),
          isNotEmpty,
        );
      },
    );

    test(
      'ensureRemoteUrls can return empty lists when all local files missing',
      () async {
        final result = await service.ensureRemoteUrls(
          userId: 'user-42',
          photoPaths: ['${tempDir.path}/missing_photo.jpg'],
          videoPaths: ['${tempDir.path}/missing_video.mp4'],
        );

        expect(result.photoUrls, isEmpty);
        expect(result.videoUrls, isEmpty);
        expect(result.hasIssues, isTrue);
      },
    );
  });
}
