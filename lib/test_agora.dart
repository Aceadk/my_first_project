// ignore_for_file: avoid_print
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:my_first_project/core/config/agora_config.dart';

Future<void> testAgoraSetup() async {
  print('Testing Agora configuration...');

  try {
    final engine = createAgoraRtcEngine();
    await engine.initialize(
      const RtcEngineContext(appId: AgoraConfig.appId),
    );

    print('✓ Agora SDK initialized successfully');
    print('✓ App ID: ${AgoraConfig.appId}');

    if (AgoraConfig.appId.length > 10) {
      print('✓ App ID format looks correct');
    } else {
      print('✗ App ID seems too short. Check your App ID!');
    }

    final version = await engine.getVersion();
    print('✓ Agora SDK version: ${version.version}');

    await engine.release();
    print('✓ Engine released');
  } catch (e) {
    print('✗ Error initializing Agora: $e');
  }
}
