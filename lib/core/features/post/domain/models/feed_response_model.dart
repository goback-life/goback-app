import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:dedecube_core/dedecube_core.dart';

part 'feed_response_model.freezed.dart';

@freezed
sealed class FeedResponseModel with _$FeedResponseModel {
  const factory FeedResponseModel({
    required List<FeedPostModel> posts,
    required int totalCount,
    required bool hasNextPage,
  }) = _FeedResponseModel;
}
