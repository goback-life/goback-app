import 'package:cloudless/core/features/calendar/data/dtos/calendar_operation_response_dto.dart';
import 'package:cloudless/core/features/calendar/data/dtos/calendar_post_dto.dart';
import 'package:cloudless/core/features/calendar/domain/enums/calendar_load_direction.dart';

abstract class CalendarServiceContract {
  /// Retrieves calendar posts for a specific user relative to a reference date.
  ///
  /// [userId] - The ID of the user whose calendar to query.
  /// [referenceDate] - The date to use as reference point.
  /// [direction] - Whether to load posts before or after the reference date.
  /// [limit] - Maximum number of posts to return (default: 42 for grid view).
  ///
  /// Returns a list of posts ordered by calendar date.
  /// - If direction is 'before': posts are returned in descending order (newest first).
  /// - If direction is 'after': posts are returned in ascending order (oldest first).
  Future<List<CalendarPostDto>> getCalendarPosts({
    required String userId,
    required DateTime referenceDate,
    required CalendarLoadDirection direction,
    int limit = 42,
  });

  /// Adds a post to the calendar for a specific date.
  ///
  /// Only the post author can add their own posts to their calendar.
  /// Maximum one post per day.
  Future<CalendarOperationResponseDto> addPostToCalendar({
    required String postId,
    required DateTime calendarDate,
  });

  /// Removes a post from the calendar for a specific date.
  ///
  /// Only the calendar owner can remove posts from their calendar.
  Future<CalendarOperationResponseDto> removePostFromCalendar({
    required DateTime calendarDate,
  });
}
