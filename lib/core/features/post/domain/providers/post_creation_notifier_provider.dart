import 'dart:io';

import 'package:cloudless/core/features/post/data/dtos/post_creation_dto.dart';
import 'package:cloudless/core/features/post/domain/enums/content_type.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'post_creation_notifier_provider.g.dart';

@riverpod
class PostCreationNotifier extends _$PostCreationNotifier {
  @override
  PostCreationDto build() => PostCreationDto(
    createdAt: DateTime.now(),
    publishedTimezone: DateTime.now().timeZoneName,
  );

  void loadExistingPost({
    required String postId,
    required String description,
    required List<String> taggedUserIds,
    required List<String> excludedUserIds,
    required DateTime createdAt,
    required ContentType contentType,
    String? parentId,
    String? imageUrl,
    String? videoUrl,
    String? thumbnailUrl,
  }) {
    state = PostCreationDto(
      postId: postId,
      parentId: parentId,
      existingImageUrl: contentType == ContentType.image ? imageUrl : null,
      existingVideoUrl: contentType == ContentType.video ? videoUrl : null,
      existingThumbnailUrl: contentType == ContentType.video
          ? thumbnailUrl
          : null,
      contentType: contentType,
      description: description,
      taggedUserIds: taggedUserIds,
      excludedUserIds: excludedUserIds,
      createdAt: createdAt,
      publishedTimezone: DateTime.now().timeZoneName,
    );
  }

  void loadReplyMode({required String parentId}) {
    state = PostCreationDto(
      parentId: parentId,
      createdAt: DateTime.now(),
      publishedTimezone: DateTime.now().timeZoneName,
    );
  }

  Future<void> updateImage(File? image) async {
    if (image == null) {
      state = state.copyWith(
        mainImagePath: null,
        existingImageUrl: null,
        thumbnailPath: null,
        firstFramePath: null,
        contentType: ContentType.image,
      );
      return;
    }

    final contentType = _detectPostType(image);

    state = state.copyWith(
      mainImagePath: image.path,
      existingImageUrl: null,
      existingVideoUrl: null,
      existingThumbnailUrl: null,
      thumbnailPath: null,
      firstFramePath: null,
      contentType: contentType,
    );
  }

  void updateFirstFrame(File? firstFrame) {
    if (state.contentType != ContentType.video) {
      return;
    }

    final hasCustomPreview =
        state.thumbnailPath != null || state.existingThumbnailUrl != null;

    state = state.copyWith(
      firstFramePath: firstFrame?.path,
      thumbnailPath: hasCustomPreview ? state.thumbnailPath : firstFrame?.path,
    );
  }

  void updateThumbnail(File? thumbnail) {
    if (state.contentType != ContentType.video) {
      return;
    }

    state = state.copyWith(thumbnailPath: thumbnail?.path);
  }

  void updatePostType(ContentType postType) {
    state = state.copyWith(contentType: postType);
  }

  void updateContentType(ContentType contentType) {
    state = state.copyWith(contentType: contentType);
  }

  void updateDescription(String description) {
    state = state.copyWith(description: description);
  }

  void updateTaggedUsers(List<String> taggedUserIds) {
    state = state.copyWith(taggedUserIds: taggedUserIds);
  }

  void updateExcludedUsers(List<String> excludedUserIds) {
    state = state.copyWith(excludedUserIds: excludedUserIds);
  }

  void reset() {
    state = PostCreationDto(
      createdAt: DateTime.now(),
      publishedTimezone: DateTime.now().timeZoneName,
    );
  }

  ContentType _detectPostType(File file) {
    final extension = file.path.toLowerCase();

    if (extension.endsWith('.mp4') ||
        extension.endsWith('.mov') ||
        extension.endsWith('.avi')) {
      return ContentType.video;
    }
    if (extension.endsWith('.mp3') ||
        extension.endsWith('.wav') ||
        extension.endsWith('.m4a')) {
      return ContentType.audio;
    }

    return ContentType.image;
  }
}
