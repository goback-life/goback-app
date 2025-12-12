import 'package:cloudless/core/features/post/data/dtos/feed_post_dto.dart';
import 'package:dedecube_core/dedecube_core.dart';

part 'feed_response_dto.freezed.dart';
part 'feed_response_dto.g.dart';

@freezed
sealed class FeedResponseDto with _$FeedResponseDto {
  const factory FeedResponseDto({
    required List<FeedPostDto> posts,
    required int totalCount,
    required bool hasNextPage,
  }) = _FeedResponseDto;

  factory FeedResponseDto.fromJson(Map<String, dynamic> json) =>
      _$FeedResponseDtoFromJson(json);
}
