import 'dart:io';

import 'package:crushhour/features/profile/data/services/profile_media_service.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileMediaService hotspot branches', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'profile_media_hotspot_test_',
      );
      ProfileMediaService.useFallbackInDebug = true;
    });

    tearDown(() async {
      ProfileMediaService.useFallbackInDebug = true;
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('uploadPhoto maps all supported photo content types', () async {
      final capturedTypes = <String>[];
      final capturedPaths = <String>[];
      final service = ProfileMediaService(
        uploadHandler:
            ({required storagePath, required file, required metadata}) async {
              capturedTypes.add(metadata.contentType ?? '');
              capturedPaths.add(storagePath);
              return 'https://cdn.example.com/${file.path.split('/').last}';
            },
        uuidGenerator: () => 'fixed-id',
      );

      final matrix = <String, String>{
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.png': 'image/png',
        '.gif': 'image/gif',
        '.webp': 'image/webp',
        '.heic': 'image/heic',
        '.heif': 'image/heic',
        '.unknown': 'image/jpeg',
      };

      for (final entry in matrix.entries) {
        final file = await _createFile(tempDir, 'photo${entry.key}');
        final url = await service.uploadPhoto(
          userId: 'user-1',
          filePath: file.path,
        );
        expect(url, contains(file.path.split('/').last));
      }

      expect(capturedTypes, matrix.values.toList());
      expect(
        capturedPaths.every(
          (p) => p.startsWith('users/user-1/photos/fixed-id.'),
        ),
        isTrue,
      );
    });

    test('uploadVideo maps all supported video content types', () async {
      final capturedTypes = <String>[];
      final capturedPaths = <String>[];
      final service = ProfileMediaService(
        uploadHandler:
            ({required storagePath, required file, required metadata}) async {
              capturedTypes.add(metadata.contentType ?? '');
              capturedPaths.add(storagePath);
              return 'https://cdn.example.com/${file.path.split('/').last}';
            },
        uuidGenerator: () => 'fixed-video-id',
      );

      final matrix = <String, String>{
        '.mp4': 'video/mp4',
        '.mov': 'video/quicktime',
        '.avi': 'video/x-msvideo',
        '.webm': 'video/webm',
        '.unknown': 'video/mp4',
      };

      for (final entry in matrix.entries) {
        final file = await _createFile(tempDir, 'video${entry.key}');
        final url = await service.uploadVideo(
          userId: 'user-1',
          filePath: file.path,
        );
        expect(url, contains(file.path.split('/').last));
      }

      expect(capturedTypes, matrix.values.toList());
      expect(
        capturedPaths.every(
          (p) => p.startsWith('users/user-1/videos/fixed-video-id.'),
        ),
        isTrue,
      );
    });

    test('uploadPhoto falls back on FirebaseException in debug', () async {
      final file = await _createFile(tempDir, 'photo.jpg');
      final service = ProfileMediaService(
        isDebugMode: () => true,
        uploadHandler:
            ({required storagePath, required file, required metadata}) {
              throw FirebaseException(
                plugin: 'firebase_storage',
                code: 'permission-denied',
                message: 'denied',
              );
            },
      );

      final result = await service.uploadPhoto(
        userId: 'user-1',
        filePath: file.path,
      );
      expect(result, file.path);
    });

    test('uploadVideo falls back on generic exception in debug', () async {
      final file = await _createFile(tempDir, 'video.mp4');
      final service = ProfileMediaService(
        isDebugMode: () => true,
        uploadHandler:
            ({required storagePath, required file, required metadata}) {
              throw Exception('upload failed');
            },
      );

      final result = await service.uploadVideo(
        userId: 'user-1',
        filePath: file.path,
      );
      expect(result, file.path);
    });

    test(
      'upload methods rethrow when fallback is disabled or non-debug',
      () async {
        final photo = await _createFile(tempDir, 'photo.jpg');
        final video = await _createFile(tempDir, 'video.mp4');

        ProfileMediaService.useFallbackInDebug = false;
        final debugService = ProfileMediaService(
          isDebugMode: () => true,
          uploadHandler:
              ({required storagePath, required file, required metadata}) {
                throw FirebaseException(
                  plugin: 'firebase_storage',
                  code: 'permission-denied',
                );
              },
        );

        await expectLater(
          () =>
              debugService.uploadPhoto(userId: 'user-1', filePath: photo.path),
          throwsA(isA<FirebaseException>()),
        );

        final releaseService = ProfileMediaService(
          isDebugMode: () => false,
          uploadHandler:
              ({required storagePath, required file, required metadata}) {
                throw Exception('upload failed');
              },
        );

        await expectLater(
          () => releaseService.uploadVideo(
            userId: 'user-1',
            filePath: video.path,
          ),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'deleteMedia skips non-firebase URLs and swallows delete errors',
      () async {
        var deleteCalls = 0;
        final service = ProfileMediaService(
          deleteHandler: (url) async {
            deleteCalls++;
            throw Exception('delete failed');
          },
        );

        await service.deleteMedia('https://example.com/not-firebase');
        await service.deleteMedia('/local/path.jpg');
        await service.deleteMedia(
          'https://firebasestorage.googleapis.com/v0/b/demo/o/users%2F1%2Fphoto.jpg',
        );

        expect(deleteCalls, 1);
      },
    );

    test(
      'ensureRemoteUrls handles success, missing files, and fallback paths',
      () async {
        final okPhoto = await _createFile(tempDir, 'ok_photo.jpg');
        final failPhoto = await _createFile(tempDir, 'fail_photo.jpg');
        final okVideo = await _createFile(tempDir, 'ok_video.mp4');
        final failVideo = await _createFile(tempDir, 'fail_video.mp4');

        final debugService = ProfileMediaService(
          isDebugMode: () => true,
          uploadHandler:
              ({required storagePath, required file, required metadata}) async {
                if (file.path.contains('fail_')) {
                  throw Exception('upload failed');
                }
                return 'https://cdn.example.com/${file.path.split('/').last}';
              },
        );

        final debugResult = await debugService.ensureRemoteUrls(
          userId: 'user-1',
          photoPaths: [
            okPhoto.path,
            failPhoto.path,
            '${tempDir.path}/missing_photo.jpg',
            'https://cdn.example.com/already_remote.jpg',
          ],
          videoPaths: [
            okVideo.path,
            failVideo.path,
            '${tempDir.path}/missing_video.mp4',
            'https://cdn.example.com/already_remote.mp4',
          ],
        );

        expect(
          debugResult.photoUrls,
          contains('https://cdn.example.com/ok_photo.jpg'),
        );
        expect(debugResult.photoUrls, contains(failPhoto.path));
        expect(
          debugResult.photoUrls,
          isNot(contains('${tempDir.path}/missing_photo.jpg')),
        );
        expect(
          debugResult.photoUrls,
          contains('https://cdn.example.com/already_remote.jpg'),
        );

        expect(
          debugResult.videoUrls,
          contains('https://cdn.example.com/ok_video.mp4'),
        );
        expect(debugResult.videoUrls, contains(failVideo.path));
        expect(
          debugResult.videoUrls,
          isNot(contains('${tempDir.path}/missing_video.mp4')),
        );
        expect(
          debugResult.videoUrls,
          contains('https://cdn.example.com/already_remote.mp4'),
        );

        final releaseService = ProfileMediaService(
          isDebugMode: () => false,
          uploadHandler:
              ({required storagePath, required file, required metadata}) async {
                throw Exception('upload failed');
              },
        );

        final releaseResult = await releaseService.ensureRemoteUrls(
          userId: 'user-1',
          photoPaths: [failPhoto.path],
          videoPaths: [failVideo.path],
        );

        expect(releaseResult.photoUrls, isEmpty);
        expect(releaseResult.videoUrls, isEmpty);
      },
    );
  });
}

Future<File> _createFile(Directory dir, String name) async {
  final file = File('${dir.path}/$name');
  await file.writeAsString('bytes:$name');
  return file;
}
