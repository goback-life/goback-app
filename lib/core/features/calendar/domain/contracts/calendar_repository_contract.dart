import 'package:cloudless/core/features/calendar/domain/enums/calendar_load_direction.dart';
import 'package:cloudless/core/features/calendar/domain/models/calendar_post_model.dart';
import 'package:dedecube_core/dedecube_core.dart';

abstract class CalendarRepositoryContract {
  /// Retrieves calendar posts for a specific user relative to a reference date.
  ///
  /// [userId] - The ID of the user whose calendar to query.
  /// [referenceDate] - The date to use as reference point.
  /// [direction] - Whether to load posts before or after the reference date.
  /// [limit] - Maximum number of posts to return.
  FutureResult<List<CalendarPostModel>> getCalendarPosts({
    required String userId,
    required DateTime referenceDate,
    required CalendarLoadDirection direction,
    int limit = 42,
  });

  /// Saves a post to the user's calendar.
  ///
  /// Sets the calendar_saved_at timestamp on the post.
  /// Returns true if the operation was successful, false otherwise.
  FutureResult<bool> addPostToCalendar({required String postId});

  /// Removes a post from the user's calendar.
  ///
  /// Clears the calendar_saved_at timestamp on the post.
  /// Returns true if the operation was successful, false otherwise.
  FutureResult<bool> removePostFromCalendar({required String postId});
}
