import 'package:cloudless/core/features/post/data/dtos/feed_response_dto.dart';
import 'package:cloudless/core/features/post/data/mappers/feed_post_dto_to_model_mapper.dart';
import 'package:cloudless/core/features/post/domain/models/feed_response_model.dart';

class FeedResponseDtoToModelMapper {
  const FeedResponseDtoToModelMapper({required this.feedPostMapper});

  final FeedPostDtoToModelMapper feedPostMapper;

  FeedResponseModel mapDto(FeedResponseDto dto) {
    return FeedResponseModel(
      posts: feedPostMapper.mapDtoList(dto.posts),
      totalCount: dto.totalCount,
      hasNextPage: dto.hasNextPage,
    );
  }
}
