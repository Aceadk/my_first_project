class AgoraConfig {
  // Replace with the APP ID you copied
  static const String appId = '3cb5440131af4513a46b6a8135afc7a7';
  
  // These will be set at runtime
  static String? token; // Will come from backend
  static String? channelName; // Unique for each call
  
  // Your backend URL for getting tokens
  // For development, you can use local emulator first
  static const String tokenServer = 'http://localhost:5001/your-app/us-central1';
}