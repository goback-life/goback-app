// ignore_for_file: invalid_annotation_target

import 'dart:io';

import 'package:cloudless/core/features/post/domain/constants/text_post_constants.dart';
import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:dedecube_core/dedecube_core.dart';

part 'post_creation_dto.freezed.dart';

@freezed
sealed class PostCreationDto with _$PostCreationDto {
  const factory PostCreationDto({
    required String publishedTimezone,
    String? postId,
    String? mainImagePath,
    String? thumbnailPath,
    String? firstFramePath,
    String? existingImageUrl,
    String? existingVideoUrl,
    String? existingThumbnailUrl,
    @Default(ContentType.image) ContentType contentType,
    @Default('') String description,
    @Default([]) List<String> taggedUserIds,
    @Default([]) List<String> excludedUserIds,
    DateTime? createdAt,
  }) = _PostCreationDto;

  const PostCreationDto._();

  File? get mainImage => mainImagePath != null ? File(mainImagePath!) : null;

  File? get thumbnail => thumbnailPath != null ? File(thumbnailPath!) : null;

  File? get firstFrame => firstFramePath != null ? File(firstFramePath!) : null;

  bool get hasMainImage =>
      mainImagePath != null ||
      existingImageUrl != null ||
      existingVideoUrl != null;
  bool get hasLocalImage => mainImagePath != null;

  bool get hasThumbnail =>
      thumbnailPath != null || existingThumbnailUrl != null;
  bool get hasFirstFrame => firstFramePath != null;
  bool get isVideo => contentType == ContentType.video;

  bool get isText => contentType == ContentType.text;

  File? get thumbnailForUpload => thumbnail ?? firstFrame;

  bool get isValid {
    if (isEditing) {
      if (isText) {
        return description.isNotEmpty &&
            description.length <= TextPostConstants.maxTextPostLength &&
            !hasMainImage;
      }
      return hasMainImage;
    } else {
      if (isText) {
        return description.isNotEmpty &&
            description.length <= TextPostConstants.maxTextPostLength &&
            !hasMainImage;
      }
      return hasMainImage;
    }
  }

  bool get isEditing => postId != null;

  DateTime get effectiveCreatedAt => createdAt ?? DateTime.now();
}
