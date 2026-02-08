import 'package:cloudless/core/features/calendar/data/dtos/calendar_post_dto.dart';

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
}
