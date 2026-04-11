// Verification test for calendar, comment, media, media_picker refactoring.
// Ensures public API surface is preserved after refactoring.
//
// Run: flutter test test/refactor_verification/cal_comment_media_test.dart

// ignore_for_file: unused_import

// ============================================================================
// CALENDAR FEATURE - Public API Surface
// ============================================================================
// Data layer
import 'package:cloudless/core/features/calendar/data/dtos/calendar_post_dto.dart';
import 'package:cloudless/core/features/calendar/data/dtos/pending_selection_post_dto.dart';
import 'package:cloudless/core/features/calendar/data/exceptions/calendar_operation_exception.dart';
import 'package:cloudless/core/features/calendar/data/mappers/calendar_exception_mapper.dart';
import 'package:cloudless/core/features/calendar/data/mappers/calendar_post_dto_to_model_mapper.dart';
import 'package:cloudless/core/features/calendar/data/providers/calendar_repository_provider.dart';
import 'package:cloudless/core/features/calendar/data/providers/calendar_service_provider.dart';
import 'package:cloudless/core/features/calendar/data/repositories/calendar_repository.dart';
import 'package:cloudless/core/features/calendar/data/services/calendar_service.dart';
import 'package:cloudless/core/features/calendar/data/storables/last_selection_date_storable.dart';
// Domain layer
import 'package:cloudless/core/features/calendar/domain/contracts/calendar_repository_contract.dart';
import 'package:cloudless/core/features/calendar/domain/contracts/calendar_service_contract.dart';
import 'package:cloudless/core/features/calendar/domain/enums/calendar_load_direction.dart';
import 'package:cloudless/core/features/calendar/domain/models/calendar_post_model.dart';
import 'package:cloudless/core/features/calendar/domain/providers/calendar_month_notifier_provider.dart';
import 'package:cloudless/core/features/calendar/domain/providers/calendar_posts_cache_provider.dart';
import 'package:cloudless/core/features/calendar/domain/providers/get_calendar_posts_provider.dart';
import 'package:cloudless/core/features/calendar/domain/providers/pending_selection_provider.dart';
import 'package:cloudless/core/features/calendar/domain/use_cases/get_calendar_posts_use_case.dart';

// ============================================================================
// COMMENT FEATURE - Public API Surface
// ============================================================================
// Data layer
import 'package:cloudless/core/features/comment/data/dtos/post_comment_dto.dart';
import 'package:cloudless/core/features/comment/data/exceptions/comment_exceptions.dart';
import 'package:cloudless/core/features/comment/data/mappers/comment_dto_to_model_mapper.dart';
import 'package:cloudless/core/features/comment/data/providers/comment_service_provider.dart';
import 'package:cloudless/core/features/comment/data/services/comment_service.dart';
// Domain layer
import 'package:cloudless/core/features/comment/domain/contracts/comment_service_contract.dart';
import 'package:cloudless/core/features/comment/domain/hooks/use_post_comments.dart';
import 'package:cloudless/core/features/comment/domain/models/post_comment_model.dart';
import 'package:cloudless/core/features/comment/domain/providers/create_comment_provider.dart';
import 'package:cloudless/core/features/comment/domain/providers/delete_comment_provider.dart';
import 'package:cloudless/core/features/comment/domain/providers/get_post_comments_provider.dart';

// ============================================================================
// MEDIA FEATURE - Public API Surface
// ============================================================================
import 'package:cloudless/core/features/media/domain/enums/media_type.dart';
import 'package:cloudless/core/features/media/domain/enums/pick_image_type.dart';
import 'package:cloudless/core/features/media/domain/exceptions/invalid_media_exception.dart';
import 'package:cloudless/core/features/media/domain/hooks/use_image_cropper.dart';
import 'package:cloudless/core/features/media/domain/hooks/use_image_picker.dart';
import 'package:cloudless/core/features/media/domain/hooks/use_media_picker.dart';
import 'package:cloudless/core/features/media/domain/hooks/use_pick_and_compress_image_with_permission.dart';
import 'package:cloudless/core/features/media/domain/hooks/use_thumbnail_picker.dart';
import 'package:cloudless/core/features/media/domain/models/media_selection.dart';
import 'package:cloudless/core/features/media/domain/use_cases/pick_and_compress_image_with_permission_use_case.dart';

// ============================================================================
// MEDIA PICKER FEATURE - Public API Surface
// ============================================================================
// Data layer
import 'package:cloudless/core/features/media_picker/data/exceptions/image_picker_camera_exception.dart';
import 'package:cloudless/core/features/media_picker/data/exceptions/image_picker_exception.dart';
import 'package:cloudless/core/features/media_picker/data/exceptions/image_picker_gallery_exception.dart';
import 'package:cloudless/core/features/media_picker/data/exceptions/unsupported_image_format_exception.dart';
import 'package:cloudless/core/features/media_picker/data/providers/image_compress_service_provider.dart';
import 'package:cloudless/core/features/media_picker/data/providers/image_picker_repository_provider.dart';
import 'package:cloudless/core/features/media_picker/data/providers/image_picker_service_provider.dart';
import 'package:cloudless/core/features/media_picker/data/repositories/image_picker_repository.dart';
import 'package:cloudless/core/features/media_picker/data/services/image_compress_service.dart';
import 'package:cloudless/core/features/media_picker/data/services/image_picker_service.dart';
import 'package:cloudless/core/features/media_picker/data/utils/image_format_validator.dart';
// Domain layer
import 'package:cloudless/core/features/media_picker/domain/contracts/image_compress_service_contract.dart';
import 'package:cloudless/core/features/media_picker/domain/contracts/image_picker_repository_contract.dart';
import 'package:cloudless/core/features/media_picker/domain/contracts/image_picker_service_contract.dart';
import 'package:cloudless/core/features/media_picker/domain/providers/pick_image_from_camera_provider.dart';
import 'package:cloudless/core/features/media_picker/domain/providers/pick_image_from_gallery_provider.dart';
import 'package:cloudless/core/features/media_picker/domain/use_cases/pick_image_from_camera_use_case.dart';
import 'package:cloudless/core/features/media_picker/domain/use_cases/pick_image_from_gallery_use_case.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Calendar feature - public API surface', () {
    test('CalendarPostDto exists and has fromJson factory', () {
      expect(CalendarPostDto.fromJson, isA<Function>());
    });

    test('PendingSelectionPostDto has expected fields', () {
      final dto = PendingSelectionPostDto(
        id: 'id',
        contentType: 'image',
        publishedAt: '2024-01-01',
      );
      expect(dto.id, 'id');
      expect(dto.contentType, 'image');
      expect(dto.publishedAt, '2024-01-01');
    });

    test('CalendarOperationException extends properly', () {
      const e = CalendarOperationException('test', 'CODE');
      expect(e, isA<Exception>());
    });

    test('CalendarExceptionMapper.fromSupabaseException returns exception', () {
      final result = CalendarExceptionMapper.fromSupabaseException(
        Exception('test'),
      );
      expect(result, isA<CalendarOperationException>());
    });

    test('CalendarPostDtoToModelMapper has mapDto and mapDtoList', () {
      final mapper = CalendarPostDtoToModelMapper();
      expect(mapper.mapDto, isA<Function>());
      expect(mapper.mapDtoList, isA<Function>());
    });

    test('CalendarLoadDirection enum has expected values', () {
      expect(CalendarLoadDirection.values.length, 2);
      expect(CalendarLoadDirection.before.value, 'before');
      expect(CalendarLoadDirection.after.value, 'after');
    });

    test('GetCalendarPostsUseCase accepts repository contract', () {
      // Type check only - we can't instantiate abstract contracts
      expect(GetCalendarPostsUseCase, isA<Type>());
    });

    test('LastSelectionDateStorable has expected API', () {
      final storable = LastSelectionDateStorable();
      expect(storable.key, 'last_selection_prompt_date');
    });
  });

  group('Comment feature - public API surface', () {
    test('PostCommentDto exists and has fromJson factory', () {
      expect(PostCommentDto.fromJson, isA<Function>());
    });

    test('Comment exceptions hierarchy', () {
      const base = CommentException('msg', 'code');
      const notFound = CommentNotFoundException();
      const unauth = CommentUnauthorizedException();
      const invalid = InvalidCommentContentException();
      expect(base, isA<Exception>());
      expect(notFound, isA<CommentException>());
      expect(unauth, isA<CommentException>());
      expect(invalid, isA<CommentException>());
    });

    test('CommentDtoToModelMapper has mapDto and mapDtoList', () {
      final mapper = CommentDtoToModelMapper();
      expect(mapper.mapDto, isA<Function>());
      expect(mapper.mapDtoList, isA<Function>());
    });

    test('kMaxCommentsPerUserPerPost constant exists', () {
      expect(kMaxCommentsPerUserPerPost, 10);
    });
  });

  group('Media feature - public API surface', () {
    test('MediaType enum has expected values', () {
      expect(MediaType.values.length, 2);
      expect(MediaType.photo, isNotNull);
      expect(MediaType.video, isNotNull);
    });

    test('PickImageType enum has expected values', () {
      expect(PickImageType.values.length, 2);
      expect(PickImageType.camera, isNotNull);
      expect(PickImageType.gallery, isNotNull);
    });

    test('InvalidMediaException extends properly', () {
      const e = InvalidMediaException('test', 'CODE');
      expect(e, isA<Exception>());
    });

    test('CropType enum has expected values', () {
      expect(CropType.values.length, 2);
      expect(CropType.circle, isNotNull);
      expect(CropType.content, isNotNull);
    });

    test('MediaSelection has expected constructor', () {
      // Just verify the class exists and can be referenced
      expect(MediaSelection, isA<Type>());
    });
  });

  group('Media picker feature - public API surface', () {
    test('Exception hierarchy', () {
      final camera = ImagePickerCameraException();
      final gallery = ImagePickerGalleryException();
      final unsupported = UnsupportedImageFormatException();
      expect(camera, isA<ImagePickerException>());
      expect(gallery, isA<ImagePickerException>());
      expect(unsupported, isA<ImagePickerException>());
    });

    test('ImageFormatValidator supports jpg, jpeg, png', () {
      expect(
        ImageFormatValidator.supportedFormats,
        containsAll(['jpg', 'jpeg', 'png']),
      );
    });

    test('ImageCompressService implements contract', () {
      const service = ImageCompressService();
      expect(service, isA<ImageCompressServiceContract>());
    });

    test('ImagePickerService implements contract', () {
      final service = ImagePickerService();
      expect(service, isA<ImagePickerServiceContract>());
    });
  });
}
