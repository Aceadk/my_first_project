import 'package:flutter/services.dart';

enum NativePermission {
  camera('camera'),
  microphone('microphone');

  const NativePermission(this.channelName);

  final String channelName;
}

class NativePermissionService {
  const NativePermissionService();

  static const MethodChannel _channel = MethodChannel(
    'crushhour/native_permissions',
  );

  Future<bool> hasPermission(NativePermission permission) {
    return _invokePermissionMethod('hasPermission', permission);
  }

  Future<bool> requestPermission(NativePermission permission) {
    return _invokePermissionMethod('requestPermission', permission);
  }

  Future<bool> _invokePermissionMethod(
    String method,
    NativePermission permission,
  ) async {
    final result = await _channel.invokeMethod<bool>(method, {
      'permission': permission.channelName,
    });
    return result ?? false;
  }
}
