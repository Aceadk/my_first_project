/// Core network infrastructure for CrushHour.
///
/// This module provides:
/// - [ApiClient] - HTTP client with versioning, retry, and interceptors
/// - [ApiVersion] - API version management and negotiation
/// - [ApiConfig] - API configuration (dev, staging, prod)
/// - DTOs - Data Transfer Objects for API communication
/// - Real-time - WebSocket and Firebase real-time sync
library;

// API Client
export 'api_client.dart';
export 'api_version.dart';

// DTOs
export 'dto/base_dto.dart';
export 'dto/auth_dto.dart';
export 'dto/profile_dto.dart';
export 'dto/discovery_dto.dart';
export 'dto/chat_dto.dart';

// Real-time
export 'realtime/realtime_connection.dart';
export 'realtime/firebase_realtime_service.dart';
