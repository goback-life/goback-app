import 'package:cloudless/core/features/calendar/data/dtos/calendar_post_dto.dart';
import 'package:dedecube_core/dedecube_core.dart';

abstract class CalendarServiceContract {
  /// Retrieves lockout calendar posts for a specific user for a given month.
  ///
  /// [userId] - The ID of the user whose calendar to query.
  /// [year] - The year to query.
  /// [month] - The month to query (1-12).
  ///
  /// Returns a list of lockout posts for that month.
  Future<List<CalendarPostDto>> getCalendarPosts({
    required String userId,
    required int year,
    required int month,
  });

  /// Retrieves lockout calendar posts for a friend for a given month.
  ///
  /// [friendId] - The ID of the friend whose calendar to view.
  /// [year] - The year to query.
  /// [month] - The month to query (1-12).
  ///
  /// Returns a list of lockout posts for that month.
  Future<List<CalendarPostDto>> getFriendCalendarPosts({
    required String friendId,
    required int year,
    required int month,
  });

  /// Saves a post to the calendar (marks it as "most memorable").
  ///
  /// Returns success/failure with error message.
  FutureResult<void> savePostToCalendar(String postId);

  /// Removes a post from the calendar.
  FutureResult<void> unsavePostFromCalendar(String postId);

  /// Gets pending posts for selection (yesterday's unsaved lockout posts).
  Future<List<CalendarPostDto>> getPendingSelectionPosts({DateTime? date});

  /// Checks if user has pending posts for selection.
  Future<bool> hasPendingSelection({DateTime? date});
}
