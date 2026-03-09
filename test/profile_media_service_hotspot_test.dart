import 'dart:io';

import 'package:crushhour/features/profile/data/services/profile_media_service.dart';
import 'package:crushhour/features/profile/domain/repositories/profile_media_repository.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

const _pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProfileMediaService hotspot branches', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'profile_media_hotspot_test_',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_pathProviderChannel, (call) async {
            if (call.method == 'getTemporaryDirectory') {
              return tempDir.path;
            }
            return null;
          });
      ProfileMediaService.useFallbackInDebug = true;
    });

    tearDown(() async {
      ProfileMediaService.useFallbackInDebug = true;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_pathProviderChannel, null);
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
        final result = await service.uploadPhoto(
          userId: 'user-1',
          filePath: file.path,
        );
        expect(result.isSuccess, isTrue);
        expect(result.url, contains(file.path.split('/').last));
      }

      expect(capturedTypes, matrix.values.toList());
      expect(
        capturedPaths.every(
          (p) => p.startsWith('users/user-1/photos/fixed-id.'),
        ),
        isTrue,
      );
    });

    test('uploadPhoto strips EXIF metadata before upload', () async {
      final sourceBytes = _createJpegWithExif();
      final sourceExif = img.decodeJpgExif(sourceBytes);
      expect(sourceExif, isNotNull);
      expect(sourceExif!.gpsIfd.hasGPSLatitude, isTrue);
      expect(sourceExif.gpsIfd.hasGPSLongitude, isTrue);
      expect(sourceExif.imageIfd.hasMake, isTrue);
      expect(_containsExifSignature(sourceBytes), isTrue);

      final sourceFile = File('${tempDir.path}/source_with_exif.jpg');
      await sourceFile.writeAsBytes(sourceBytes);

      Uint8List? uploadedBytes;
      final service = ProfileMediaService(
        uploadHandler:
            ({required storagePath, required file, required metadata}) async {
              uploadedBytes = await file.readAsBytes();
              expect(metadata.contentType, 'image/jpeg');
              expect(storagePath, 'users/user-1/photos/fixed-id.jpg');
              return 'https://cdn.example.com/uploaded.jpg';
            },
        uuidGenerator: () => 'fixed-id',
      );

      final result = await service.uploadPhoto(
        userId: 'user-1',
        filePath: sourceFile.path,
      );

      expect(result.isSuccess, isTrue);
      expect(result.url, 'https://cdn.example.com/uploaded.jpg');
      expect(uploadedBytes, isNotNull);
      expect(_containsExifSignature(uploadedBytes!), isFalse);
      expect(img.decodeJpgExif(uploadedBytes!), isNull);
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
        final result = await service.uploadVideo(
          userId: 'user-1',
          filePath: file.path,
        );
        expect(result.isSuccess, isTrue);
        expect(result.url, contains(file.path.split('/').last));
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
      expect(result.isSuccess, isTrue);
      expect(result.url, file.path);
      expect(result.usedLocalFallback, isTrue);
      expect(result.error?.code, ProfileMediaErrorCode.uploadFailed);
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
      expect(result.isSuccess, isTrue);
      expect(result.url, file.path);
      expect(result.usedLocalFallback, isTrue);
      expect(result.error?.code, ProfileMediaErrorCode.uploadFailed);
    });

    test(
      'upload methods return explicit failure when fallback is disabled or non-debug',
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

        final photoResult = await debugService.uploadPhoto(
          userId: 'user-1',
          filePath: photo.path,
        );
        expect(photoResult.isSuccess, isFalse);
        expect(photoResult.error?.code, ProfileMediaErrorCode.uploadFailed);

        final releaseService = ProfileMediaService(
          isDebugMode: () => false,
          uploadHandler:
              ({required storagePath, required file, required metadata}) {
                throw Exception('upload failed');
              },
        );

        final videoResult = await releaseService.uploadVideo(
          userId: 'user-1',
          filePath: video.path,
        );
        expect(videoResult.isSuccess, isFalse);
        expect(videoResult.error?.code, ProfileMediaErrorCode.uploadFailed);
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

        final nonFirebase = await service.deleteMedia(
          'https://example.com/not-firebase',
        );
        final localPath = await service.deleteMedia('/local/path.jpg');
        final firebaseUrl = await service.deleteMedia(
          'https://firebasestorage.googleapis.com/v0/b/demo/o/users%2F1%2Fphoto.jpg',
        );

        expect(deleteCalls, 1);
        expect(nonFirebase.skipped, isTrue);
        expect(localPath.skipped, isTrue);
        expect(firebaseUrl.isSuccess, isFalse);
        expect(firebaseUrl.error?.code, ProfileMediaErrorCode.deleteFailed);
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
        expect(
          debugResult.issues.any(
            (i) => i.path == failPhoto.path && i.recoveredWithFallback == true,
          ),
          isTrue,
        );
        expect(
          debugResult.issues.any(
            (i) => i.path == failVideo.path && i.recoveredWithFallback == true,
          ),
          isTrue,
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
        expect(releaseResult.hasBlockingFailures, isTrue);
      },
    );
  });
}

Future<File> _createFile(Directory dir, String name) async {
  final file = File('${dir.path}/$name');
  await file.writeAsString('bytes:$name');
  return file;
}

Uint8List _createJpegWithExif() {
  final image = img.Image(width: 32, height: 32);
  img.fill(image, color: img.ColorRgb8(64, 128, 200));
  image.exif.imageIfd
    ..make = 'TestCam'
    ..model = 'TestModel'
    ..software = 'profile-media-test';
  image.exif.gpsIfd.setGpsLocation(latitude: 37.7749, longitude: -122.4194);

  final bytes = img.encodeJpg(image, quality: 92);
  return Uint8List.fromList(bytes);
}

bool _containsExifSignature(Uint8List bytes) {
  const signature = [0x45, 0x78, 0x69, 0x66]; // "Exif"
  for (var i = 0; i <= bytes.length - signature.length; i++) {
    if (bytes[i] == signature[0] &&
        bytes[i + 1] == signature[1] &&
        bytes[i + 2] == signature[2] &&
        bytes[i + 3] == signature[3]) {
      return true;
    }
  }
  return false;
}
