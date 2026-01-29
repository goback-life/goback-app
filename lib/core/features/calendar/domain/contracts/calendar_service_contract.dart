import 'package:cloudless/core/features/calendar/data/dtos/calendar_operation_response_dto.dart';
import 'package:cloudless/core/features/calendar/data/dtos/calendar_post_dto.dart';

abstract class CalendarServiceContract {
  /// Retrieves calendar posts for a specific user for a given month.
  ///
  /// [userId] - The ID of the user whose calendar to query.
  /// [year] - The year to query.
  /// [month] - The month to query (1-12).
  ///
  /// Returns a list of posts saved to calendar for that month.
  Future<List<CalendarPostDto>> getCalendarPosts({
    required String userId,
    required int year,
    required int month,
  });

  /// Retrieves calendar posts for a friend for a given month.
  ///
  /// [friendId] - The ID of the friend whose calendar to view.
  /// [year] - The year to query.
  /// [month] - The month to query (1-12).
  ///
  /// Returns a list of posts saved to calendar for that month.
  Future<List<CalendarPostDto>> getFriendCalendarPosts({
    required String friendId,
    required int year,
    required int month,
  });

  /// Saves a post to the user's calendar.
  ///
  /// Sets the calendar_saved_at timestamp on the post.
  /// Only the post author can save their own posts.
  Future<CalendarOperationResponseDto> addPostToCalendar({
    required String postId,
  });

  /// Removes a post from the user's calendar.
  ///
  /// Clears the calendar_saved_at timestamp on the post.
  Future<CalendarOperationResponseDto> removePostFromCalendar({
    required String postId,
  });
}
