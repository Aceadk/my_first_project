import 'dart:io';
import 'dart:ui' as ui;

import 'package:crushhour/core/media/image_optimizer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('image_optimizer_test_');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          if (call.method == 'getTemporaryDirectory') {
            return tempDir.path;
          }
          return null;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ImageOptimizer', () {
    test('optimize writes optimized image and thumbnail by default', () async {
      final input = File('${tempDir.path}/input.png');
      await input.writeAsBytes(await _createPngBytes(40, 30));

      final result = await ImageOptimizer.instance.optimize(input);

      expect(await result.optimizedFile.exists(), isTrue);
      expect(result.thumbnailFile, isNotNull);
      expect(await result.thumbnailFile!.exists(), isTrue);
      expect(result.originalWidth, 40);
      expect(result.originalHeight, 30);
      expect(result.optimizedWidth, 40);
      expect(result.optimizedHeight, 30);
      expect(result.originalSizeBytes, greaterThan(0));
      expect(result.optimizedSizeBytes, greaterThan(0));
      expect(result.thumbnailSizeBytes, isNotNull);
      expect(result.compressionRatio, greaterThan(0));
    });

    test('optimize without thumbnail leaves thumbnail fields null', () async {
      final input = File('${tempDir.path}/input_no_thumb.png');
      await input.writeAsBytes(await _createPngBytes(32, 32));

      final result = await ImageOptimizer.instance.optimize(
        input,
        config: const ImageOptimizeConfig(generateThumbnail: false),
      );

      expect(await result.optimizedFile.exists(), isTrue);
      expect(result.thumbnailFile, isNull);
      expect(result.thumbnailSizeBytes, isNull);
    });

    test(
      'optimize resizes wide image when width exceeds max dimension',
      () async {
        final input = File('${tempDir.path}/wide.png');
        await input.writeAsBytes(await _createPngBytes(400, 200));

        final result = await ImageOptimizer.instance.optimize(
          input,
          config: const ImageOptimizeConfig(maxDimension: 100),
        );

        expect(result.optimizedWidth, 100);
        expect(result.optimizedHeight, 50);
      },
    );

    test(
      'optimize resizes tall image when height exceeds max dimension',
      () async {
        final input = File('${tempDir.path}/tall.png');
        await input.writeAsBytes(await _createPngBytes(200, 400));

        final result = await ImageOptimizer.instance.optimize(
          input,
          config: const ImageOptimizeConfig(maxDimension: 100),
        );

        expect(result.optimizedWidth, 50);
        expect(result.optimizedHeight, 100);
      },
    );

    test('optimize throws when input bytes are not a valid image', () async {
      final bad = File('${tempDir.path}/bad.bin');
      await bad.writeAsBytes(const [1, 2, 3, 4, 5, 6, 7, 8]);

      await expectLater(
        () => ImageOptimizer.instance.optimize(bad),
        throwsA(isA<Exception>()),
      );
    });

    test('cleanupTempFiles deletes only opt_ and thumb_ files', () async {
      final opt = File('${tempDir.path}/opt_old.jpg')..writeAsStringSync('opt');
      final thumb = File('${tempDir.path}/thumb_old.jpg')
        ..writeAsStringSync('thumb');
      final keep = File('${tempDir.path}/keep.txt')..writeAsStringSync('keep');

      await ImageOptimizer.instance.cleanupTempFiles();

      expect(await opt.exists(), isFalse);
      expect(await thumb.exists(), isFalse);
      expect(await keep.exists(), isTrue);
    });

    test('cleanupTempFiles swallows path provider failures', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pathProviderChannel, (call) async {
            throw PlatformException(
              code: 'path-provider-error',
              message: 'simulated failure',
            );
          });

      await expectLater(ImageOptimizer.instance.cleanupTempFiles(), completes);
    });

    test(
      'OptimizedImage savedBytes can be negative for larger optimized output',
      () {
        final model = OptimizedImage(
          optimizedFile: File('${tempDir.path}/fake.jpg'),
          originalSizeBytes: 100,
          optimizedSizeBytes: 120,
          originalWidth: 10,
          originalHeight: 10,
          optimizedWidth: 10,
          optimizedHeight: 10,
        );

        expect(model.savedBytes, -20);
      },
    );
  });
}

Future<Uint8List> _createPngBytes(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  final rect = ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
  final paint = ui.Paint()..color = const ui.Color(0xFF42A5F5);
  canvas.drawRect(rect, paint);

  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();

  if (bytes == null) {
    throw Exception('Failed to create PNG bytes for test image');
  }

  return bytes.buffer.asUint8List();
}
