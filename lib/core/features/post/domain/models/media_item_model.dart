import 'package:dedecube_core/dedecube_core.dart';

part 'media_item_model.freezed.dart';

@freezed
sealed class MediaItemModel with _$MediaItemModel {
  const factory MediaItemModel({
    required String id,
    required String mediaType,
    required String mediaUrl,
    required int sortOrder,
  }) = _MediaItemModel;
}
