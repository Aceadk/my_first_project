import 'package:flutter/foundation.dart';

/// Base class for all Data Transfer Objects.
///
/// DTOs are used to:
/// - Serialize/deserialize API responses
/// - Decouple domain models from API contracts
/// - Handle API versioning gracefully
/// - Validate incoming data
abstract class BaseDto {
  const BaseDto();

  /// Convert DTO to JSON map.
  Map<String, dynamic> toJson();

  /// Validate the DTO data.
  /// Returns null if valid, error message if invalid.
  String? validate() => null;

  /// Check if DTO is valid.
  bool get isValid => validate() == null;
}

/// Mixin for DTOs that track metadata.
mixin DtoMetadata {
  /// When this data was created on the server.
  DateTime? get createdAt;

  /// When this data was last updated on the server.
  DateTime? get updatedAt;

  /// Server-assigned unique identifier.
  String? get serverId;
}

/// Mixin for DTOs that support pagination.
mixin PaginatedResponse<T> {
  /// List of items in this page.
  List<T> get items;

  /// Total number of items across all pages.
  int? get totalCount;

  /// Current page number (0-indexed).
  int get page;

  /// Number of items per page.
  int get pageSize;

  /// Whether there are more pages available.
  bool get hasMore;

  /// Cursor for the next page (if cursor-based pagination).
  String? get nextCursor;
}

/// Generic paginated response DTO.
class PaginatedDto<T extends BaseDto> extends BaseDto
    with PaginatedResponse<T> {
  const PaginatedDto({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    this.totalCount,
    this.nextCursor,
  });

  @override
  final List<T> items;

  @override
  final int? totalCount;

  @override
  final int page;

  @override
  final int pageSize;

  @override
  final bool hasMore;

  @override
  final String? nextCursor;

  @override
  Map<String, dynamic> toJson() => {
        'items': items.map((e) => e.toJson()).toList(),
        'page': page,
        'page_size': pageSize,
        'has_more': hasMore,
        if (totalCount != null) 'total_count': totalCount,
        if (nextCursor != null) 'next_cursor': nextCursor,
      };

  /// Create from JSON with item parser.
  static PaginatedDto<T> fromJson<T extends BaseDto>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemParser,
  ) {
    final itemsList = (json['items'] as List<dynamic>?)
            ?.map((e) => itemParser(e as Map<String, dynamic>))
            .toList() ??
        [];

    return PaginatedDto<T>(
      items: itemsList,
      page: json['page'] as int? ?? 0,
      pageSize: json['page_size'] as int? ?? 20,
      hasMore: json['has_more'] as bool? ?? false,
      totalCount: json['total_count'] as int?,
      nextCursor: json['next_cursor'] as String?,
    );
  }
}

/// Generic API response wrapper.
class ApiResponseDto<T> extends BaseDto {
  const ApiResponseDto({
    required this.success,
    this.data,
    this.error,
    this.errorCode,
    this.message,
    this.timestamp,
  });

  /// Whether the request was successful.
  final bool success;

  /// Response data (if successful).
  final T? data;

  /// Error message (if failed).
  final String? error;

  /// Error code for programmatic handling.
  final String? errorCode;

  /// Human-readable message.
  final String? message;

  /// Server timestamp.
  final DateTime? timestamp;

  @override
  Map<String, dynamic> toJson() => {
        'success': success,
        if (data != null)
          'data': data is BaseDto ? (data as BaseDto).toJson() : data,
        if (error != null) 'error': error,
        if (errorCode != null) 'error_code': errorCode,
        if (message != null) 'message': message,
        if (timestamp != null) 'timestamp': timestamp!.toIso8601String(),
      };

  /// Create from JSON with data parser.
  static ApiResponseDto<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(dynamic)? dataParser,
  ) {
    return ApiResponseDto<T>(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null && dataParser != null
          ? dataParser(json['data'])
          : null,
      error: json['error'] as String?,
      errorCode: json['error_code'] as String?,
      message: json['message'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String)
          : null,
    );
  }

  /// Create a success response.
  factory ApiResponseDto.success(T data, {String? message}) {
    return ApiResponseDto(
      success: true,
      data: data,
      message: message,
      timestamp: DateTime.now(),
    );
  }

  /// Create an error response.
  factory ApiResponseDto.error(String error,
      {String? errorCode, String? message}) {
    return ApiResponseDto(
      success: false,
      error: error,
      errorCode: errorCode,
      message: message,
      timestamp: DateTime.now(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// JSON SERIALIZATION UTILITIES
// ═══════════════════════════════════════════════════════════════════════════

/// Utilities for JSON serialization/deserialization.
class JsonUtils {
  JsonUtils._();

  /// Parse a DateTime from various formats.
  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  /// Parse an int from various formats.
  static int? parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Parse a double from various formats.
  static double? parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Parse a bool from various formats.
  static bool? parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    return null;
  }

  /// Parse a list with type conversion.
  static List<T>? parseList<T>(
    dynamic value,
    T Function(dynamic) parser,
  ) {
    if (value == null) return null;
    if (value is! List) return null;
    return value.map((e) => parser(e)).toList();
  }

  /// Parse a map with type conversion.
  static Map<String, T>? parseMap<T>(
    dynamic value,
    T Function(dynamic) parser,
  ) {
    if (value == null) return null;
    if (value is! Map) return null;
    return value.map((k, v) => MapEntry(k.toString(), parser(v)));
  }

  /// Safely get a nested value from JSON.
  static T? getNestedValue<T>(
    Map<String, dynamic> json,
    List<String> path, [
    T Function(dynamic)? parser,
  ]) {
    dynamic current = json;
    for (final key in path) {
      if (current is! Map<String, dynamic>) return null;
      current = current[key];
      if (current == null) return null;
    }
    if (parser != null) return parser(current);
    return current as T?;
  }
}

/// Extension for safe JSON access.
extension SafeJsonAccess on Map<String, dynamic> {
  /// Get a string value safely.
  String? getString(String key) => this[key]?.toString();

  /// Get an int value safely.
  int? getInt(String key) => JsonUtils.parseInt(this[key]);

  /// Get a double value safely.
  double? getDouble(String key) => JsonUtils.parseDouble(this[key]);

  /// Get a bool value safely.
  bool? getBool(String key) => JsonUtils.parseBool(this[key]);

  /// Get a DateTime value safely.
  DateTime? getDateTime(String key) => JsonUtils.parseDateTime(this[key]);

  /// Get a list value safely.
  List<T>? getList<T>(String key, T Function(dynamic) parser) {
    return JsonUtils.parseList(this[key], parser);
  }

  /// Get a nested map value safely.
  Map<String, dynamic>? getMap(String key) {
    final value = this[key];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
    return null;
  }

  /// Get a nested value by path.
  T? getNested<T>(List<String> path, [T Function(dynamic)? parser]) {
    return JsonUtils.getNestedValue(this, path, parser);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// VALIDATION UTILITIES
// ═══════════════════════════════════════════════════════════════════════════

/// Validation result for DTOs.
class ValidationResult {
  const ValidationResult({
    this.isValid = true,
    this.errors = const [],
  });

  final bool isValid;
  final List<ValidationError> errors;

  factory ValidationResult.valid() => const ValidationResult();

  factory ValidationResult.invalid(List<ValidationError> errors) {
    return ValidationResult(isValid: false, errors: errors);
  }

  factory ValidationResult.single(String field, String message) {
    return ValidationResult(
      isValid: false,
      errors: [ValidationError(field: field, message: message)],
    );
  }

  String? get firstError => errors.isNotEmpty ? errors.first.message : null;

  @override
  String toString() {
    if (isValid) return 'ValidationResult: Valid';
    return 'ValidationResult: Invalid - ${errors.map((e) => e.toString()).join(', ')}';
  }
}

/// Single validation error.
class ValidationError {
  const ValidationError({
    required this.field,
    required this.message,
    this.code,
  });

  final String field;
  final String message;
  final String? code;

  @override
  String toString() => '$field: $message';
}

/// Validator builder for DTOs.
class DtoValidator {
  DtoValidator();

  final List<ValidationError> _errors = [];

  /// Add an error if condition is false.
  DtoValidator require(bool condition, String field, String message) {
    if (!condition) {
      _errors.add(ValidationError(field: field, message: message));
    }
    return this;
  }

  /// Require a non-null value.
  DtoValidator requireNotNull(dynamic value, String field, {String? message}) {
    if (value == null) {
      _errors.add(ValidationError(
        field: field,
        message: message ?? '$field is required',
      ));
    }
    return this;
  }

  /// Require a non-empty string.
  DtoValidator requireNotEmpty(String? value, String field, {String? message}) {
    if (value == null || value.isEmpty) {
      _errors.add(ValidationError(
        field: field,
        message: message ?? '$field cannot be empty',
      ));
    }
    return this;
  }

  /// Require a minimum length.
  DtoValidator requireMinLength(String? value, int minLength, String field) {
    if (value != null && value.length < minLength) {
      _errors.add(ValidationError(
        field: field,
        message: '$field must be at least $minLength characters',
      ));
    }
    return this;
  }

  /// Require a value within range.
  DtoValidator requireRange(num? value, num min, num max, String field) {
    if (value != null && (value < min || value > max)) {
      _errors.add(ValidationError(
        field: field,
        message: '$field must be between $min and $max',
      ));
    }
    return this;
  }

  /// Require a valid email.
  DtoValidator requireEmail(String? value, String field) {
    if (value != null &&
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      _errors.add(ValidationError(
        field: field,
        message: '$field must be a valid email',
      ));
    }
    return this;
  }

  /// Build the validation result.
  ValidationResult build() {
    if (_errors.isEmpty) return ValidationResult.valid();
    return ValidationResult.invalid(List.unmodifiable(_errors));
  }

  /// Get the first error message or null if valid.
  String? get firstError => _errors.isNotEmpty ? _errors.first.message : null;
}

// ═══════════════════════════════════════════════════════════════════════════
// DTO MAPPER
// ═══════════════════════════════════════════════════════════════════════════

/// Base class for mapping between DTOs and domain models.
abstract class DtoMapper<D extends BaseDto, M> {
  const DtoMapper();

  /// Convert DTO to domain model.
  M toDomain(D dto);

  /// Convert domain model to DTO.
  D toDto(M model);

  /// Convert a list of DTOs to domain models.
  List<M> toDomainList(List<D> dtos) => dtos.map(toDomain).toList();

  /// Convert a list of domain models to DTOs.
  List<D> toDtoList(List<M> models) => models.map(toDto).toList();
}

/// Debug helper for DTO inspection.
void debugDto(String tag, BaseDto dto) {
  if (kDebugMode) {
    debugPrint('[$tag] ${dto.runtimeType}: ${dto.toJson()}');
  }
}
