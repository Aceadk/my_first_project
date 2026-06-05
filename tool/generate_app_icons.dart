import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const _appIconPath = 'assets/icons/app_icon.png';
const _launchWordmarkPath = 'assets/icons/launch_wordmark.png';

const _nativeLaunchBaseWidth = 280;
const _webIconSizes = <String, int>{
  'web/favicon.png': 32,
  'web/icons/Icon-192.png': 192,
  'web/icons/Icon-512.png': 512,
  'web/icons/Icon-maskable-192.png': 192,
  'web/icons/Icon-maskable-512.png': 512,
};
const _macIconSizes = <String, int>{
  'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png': 16,
  'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png': 32,
  'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png': 64,
  'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png': 128,
  'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png': 256,
  'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png': 512,
  'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png': 1024,
};
const _windowsIconSizes = <int>[16, 32, 48, 64, 128, 256];

void main() {
  final appIcon = _loadImage(_appIconPath);
  final launchWordmark = _removePaleBackground(_loadImage(_launchWordmarkPath));

  for (final entry in _webIconSizes.entries) {
    _writeSquarePng(entry.key, appIcon, entry.value);
  }

  for (final entry in _macIconSizes.entries) {
    _writeSquarePng(entry.key, appIcon, entry.value);
  }

  _writePng(_launchWordmarkPath, launchWordmark);
  _writeWindowsIco(appIcon);
  _writeNativeLaunchImages(launchWordmark);

  stdout.writeln('Generated web, desktop, and native launch assets.');
}

img.Image _loadImage(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw StateError('Missing image source: $path');
  }

  final image = img.decodeImage(file.readAsBytesSync());
  if (image == null) {
    throw StateError('Could not decode image source: $path');
  }

  return img.bakeOrientation(image);
}

img.Image _removePaleBackground(img.Image source) {
  final transparent = source.convert(numChannels: 4);

  for (final pixel in transparent) {
    final r = pixel.r.toInt();
    final g = pixel.g.toInt();
    final b = pixel.b.toInt();
    final isPaleNeutral = r >= 232 && g >= 232 && b >= 232;

    if (isPaleNeutral) {
      pixel.setRgba(r, g, b, 0);
    }
  }

  return transparent;
}

void _writeSquarePng(String path, img.Image source, int size) {
  final square = img.copyResizeCropSquare(
    source,
    size: size,
    interpolation: img.Interpolation.cubic,
  );
  _writePng(path, square);
}

void _writeWindowsIco(img.Image source) {
  final icons = _windowsIconSizes
      .map(
        (size) => img.copyResizeCropSquare(
          source,
          size: size,
          interpolation: img.Interpolation.cubic,
        ),
      )
      .toList(growable: false);

  final file = File('windows/runner/resources/app_icon.ico');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(img.IcoEncoder().encodeImages(icons));
}

void _writeNativeLaunchImages(img.Image source) {
  final scale3x = _resizeByWidth(source, _nativeLaunchBaseWidth * 3);
  final scale2x = _resizeByWidth(source, _nativeLaunchBaseWidth * 2);
  final scale1x = _resizeByWidth(source, _nativeLaunchBaseWidth);

  _writePng(
    'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png',
    scale3x,
  );
  _writePng(
    'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png',
    scale2x,
  );
  _writePng(
    'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png',
    scale1x,
  );
  _writePng('android/app/src/main/res/drawable/launch_wordmark.png', scale1x);
}

img.Image _resizeByWidth(img.Image source, int width) {
  final height = math.max(1, (width * source.height / source.width).round());
  return img.copyResize(
    source,
    width: width,
    height: height,
    interpolation: img.Interpolation.cubic,
  );
}

void _writePng(String path, img.Image image) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(image));
}
