import 'dart:io';
import 'package:image/image.dart' as img;

const _size = 1024;
const _text = 'Crush';
const _launchWordmarkWidth = 840;
const _launchWordmarkHeight = 270;

// Brand colors from DsColors
final _brandPrimary = img.ColorRgba8(0xFF, 0x3F, 0x7F, 0xFF); // #FF3F7F
final _backgroundDark = img.ColorRgba8(0x0D, 0x0E, 0x12, 0xFF); // #0D0E12
final _transparent = img.ColorRgba8(0x00, 0x00, 0x00, 0x00);

void main() {
  _ensureIconDir();

  final base =
      _renderIcon(background: _backgroundDark, textColor: _brandPrimary);
  File('assets/icons/app_icon.png').writeAsBytesSync(img.encodePng(base));

  final foreground = _renderIcon(
    background: _transparent,
    textColor: _brandPrimary,
  );
  File('assets/icons/app_icon_foreground.png')
      .writeAsBytesSync(img.encodePng(foreground));

  final wordmark3x = _renderWordmark(
    width: _launchWordmarkWidth,
    height: _launchWordmarkHeight,
    textColor: _brandPrimary,
  );
  File('assets/icons/launch_wordmark.png')
      .writeAsBytesSync(img.encodePng(wordmark3x));

  final wordmark2x = img.copyResize(
    wordmark3x,
    width: (_launchWordmarkWidth * 2 / 3).round(),
    height: (_launchWordmarkHeight * 2 / 3).round(),
    interpolation: img.Interpolation.linear,
  );
  final wordmark1x = img.copyResize(
    wordmark3x,
    width: (_launchWordmarkWidth / 3).round(),
    height: (_launchWordmarkHeight / 3).round(),
    interpolation: img.Interpolation.linear,
  );

  _writePng(
    'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png',
    wordmark3x,
  );
  _writePng(
    'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png',
    wordmark2x,
  );
  _writePng(
    'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png',
    wordmark1x,
  );

  _writePng(
    'android/app/src/main/res/drawable/launch_wordmark.png',
    wordmark1x,
  );
}

img.Image _renderIcon({
  required img.Color background,
  required img.Color textColor,
}) {
  final font = img.arial48;
  final metrics = _measureText(font, _text);
  final targetWidth = (_size * 0.7).round();
  final scale = targetWidth / metrics.width;
  final baseSize = (_size / scale).round();

  final canvas = img.Image(width: baseSize, height: baseSize, numChannels: 4);
  img.fill(canvas, color: background);

  _drawCenteredText(canvas, _text, textColor, font);

  return img.copyResize(
    canvas,
    width: _size,
    height: _size,
    interpolation: img.Interpolation.linear,
  );
}

img.Image _renderWordmark({
  required int width,
  required int height,
  required img.Color textColor,
}) {
  final font = img.arial48;
  final metrics = _measureText(font, _text);
  final targetWidth = (width * 0.8).round();
  final scale = targetWidth / metrics.width;
  final baseWidth = (width / scale).round();
  final baseHeight = (height / scale).round();

  final canvas =
      img.Image(width: baseWidth, height: baseHeight, numChannels: 4);
  img.fill(canvas, color: _transparent);

  _drawCenteredText(canvas, _text, textColor, font);

  return img.copyResize(
    canvas,
    width: width,
    height: height,
    interpolation: img.Interpolation.linear,
  );
}

void _drawCenteredText(
  img.Image image,
  String text,
  img.Color color,
  img.BitmapFont font,
) {
  final metrics = _measureText(font, text);
  final x = ((image.width - metrics.width) / 2).round();
  final y = ((image.height - metrics.height) / 2).round();

  img.drawString(
    image,
    text,
    font: font,
    x: x,
    y: y,
    color: color,
  );
}

_TextMetrics _measureText(img.BitmapFont font, String text) {
  var width = 0;
  var height = 0;
  for (final code in text.codeUnits) {
    final ch = font.characters[code];
    if (ch == null) {
      width += font.base ~/ 2;
      continue;
    }
    width += ch.xAdvance;
    final charHeight = ch.height + ch.yOffset;
    if (charHeight > height) {
      height = charHeight;
    }
  }
  return _TextMetrics(width: width, height: height);
}

void _ensureIconDir() {
  final dir = Directory('assets/icons');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
}

void _writePng(String path, img.Image image) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(image));
}

class _TextMetrics {
  final int width;
  final int height;

  const _TextMetrics({required this.width, required this.height});
}
