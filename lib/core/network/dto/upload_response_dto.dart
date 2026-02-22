import 'package:json_annotation/json_annotation.dart';

part 'upload_response_dto.g.dart';

/// DTO for a single file upload response.
@JsonSerializable()
class UploadResponseDto {
  UploadResponseDto({required this.url});

  /// The URL of the uploaded file.
  final String url;

  factory UploadResponseDto.fromJson(Map<String, dynamic> json) =>
      _$UploadResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UploadResponseDtoToJson(this);
}

/// DTO for multiple file upload response.
@JsonSerializable()
class UploadMultipleResponseDto {
  UploadMultipleResponseDto({required this.urls});

  /// The URLs of the uploaded files.
  final List<String> urls;

  factory UploadMultipleResponseDto.fromJson(Map<String, dynamic> json) =>
      _$UploadMultipleResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UploadMultipleResponseDtoToJson(this);
}
