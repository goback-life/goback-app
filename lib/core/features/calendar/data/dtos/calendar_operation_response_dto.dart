// ignore_for_file: invalid_annotation_target

import 'package:dedecube_core/dedecube_core.dart';

part 'calendar_operation_response_dto.freezed.dart';
part 'calendar_operation_response_dto.g.dart';

@freezed
sealed class CalendarOperationResponseDto with _$CalendarOperationResponseDto {
  const factory CalendarOperationResponseDto({
    required bool success,
    String? message,
    String? error,
  }) = _CalendarOperationResponseDto;

  factory CalendarOperationResponseDto.fromJson(Map<String, dynamic> json) =>
      _$CalendarOperationResponseDtoFromJson(json);
}
