import 'dart:io';

import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:dedecube_core/dedecube_core.dart';

part 'post_data_model.freezed.dart';

@freezed
sealed class PostDataModel with _$PostDataModel {
  const factory PostDataModel({
    required String authorId,
    required ContentType contentType,
    required List<File> mediaFiles,
    required DateTime contentDate,
    required String publishedTimezone,
    String? postId,
    String? parentId,
    String? description,
    File? thumbnailFile,
    @Default([]) List<String> taggedUserIds,
    @Default([]) List<String> excludedUserIds,
    @Default(false) bool isLockoutPost,
  }) = _PostDataModel;
}
