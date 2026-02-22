// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upload_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UploadResponseDto _$UploadResponseDtoFromJson(Map<String, dynamic> json) =>
    UploadResponseDto(url: json['url'] as String);

Map<String, dynamic> _$UploadResponseDtoToJson(UploadResponseDto instance) =>
    <String, dynamic>{'url': instance.url};

UploadMultipleResponseDto _$UploadMultipleResponseDtoFromJson(
  Map<String, dynamic> json,
) => UploadMultipleResponseDto(
  urls: (json['urls'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$UploadMultipleResponseDtoToJson(
  UploadMultipleResponseDto instance,
) => <String, dynamic>{'urls': instance.urls};
