import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/config/agora_config.dart';

class TestVideoScreen extends StatefulWidget {
  const TestVideoScreen({super.key});

  @override
  State<TestVideoScreen> createState() => _TestVideoScreenState();
}

class _TestVideoScreenState extends State<TestVideoScreen> {
  bool _isJoined = false;
  bool _isLoading = false;
  String _logText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agora Test')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isJoined ? Icons.check_circle : Icons.error,
                          color: _isJoined ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _isJoined ? 'Connected to Agora' : 'Not connected',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isJoined ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'App ID: ${AgoraConfig.appId.substring(0, 10)}...',
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Test Button
            ElevatedButton(
              onPressed: _isLoading ? null : _testConnection,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Test Agora Connection'),
            ),
            
            const SizedBox(height: 20),
            
            // Log
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _logText.isEmpty ? 'Logs will appear here...' : _logText,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addLog(String log) {
    setState(() {
      _logText = '${DateTime.now()}: $log\n$_logText';
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _logText = '';
    });

    try {
      _addLog('1. Requesting permissions...');
      
      // Request camera and microphone permissions
      await Permission.camera.request();
      await Permission.microphone.request();
      
      _addLog('2. Creating Agora engine...');
      
      // Create engine instance
      final engine = createAgoraRtcEngine();
      
      _addLog('3. Initializing with App ID...');
      
      // Initialize with your App ID
      await engine.initialize(
        const RtcEngineContext(
          appId: AgoraConfig.appId,
        ),
      );
      
      _addLog('4. Enabling video...');
      
      // Enable video module
      await engine.enableVideo();
      
      _addLog('✅ SUCCESS! Agora is properly configured.');
      _addLog('App ID: ${AgoraConfig.appId}');
      
      setState(() {
        _isJoined = true;
      });
      
    } catch (e) {
      _addLog('❌ ERROR: $e');
      _addLog('Check:');
      _addLog('1. Is your App ID correct?');
      _addLog('2. Did you add Android/iOS permissions?');
      _addLog('3. Is agora_rtc_engine in pubspec.yaml?');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
