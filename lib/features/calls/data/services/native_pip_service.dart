import 'package:flutter/services.dart';

/// Native OS Picture-in-Picture bridge.
///
/// Android path is backed by a MethodChannel handler in MainActivity.
/// iOS currently returns false until native PiP is wired.
class NativePiPService {
  NativePiPService._();

  static final NativePiPService instance = NativePiPService._();
  static const MethodChannel _channel = MethodChannel('crushhour/native_pip');

  Future<bool> enterPictureInPicture() async {
    try {
      final result = await _channel.invokeMethod<bool>('enterPictureInPicture');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
