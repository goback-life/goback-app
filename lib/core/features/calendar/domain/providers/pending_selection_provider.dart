import 'package:cloudless/core/features/calendar/data/providers/calendar_service_provider.dart';
import 'package:cloudless/core/features/calendar/data/storables/last_selection_date_storable.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_selection_provider.g.dart';

/// Provider that checks if the user needs to select a memorable post.
///
/// Returns true if:
/// 1. User hasn't been prompted today
/// 2. User has unsaved lockout posts from yesterday
/// 3. User is not returning from a lockout (handled elsewhere)
@riverpod
Future<bool> shouldShowMemorableSelection(Ref ref) async {
  final storable = LastSelectionDateStorable();

  // Check if already prompted today
  final wasPromptedToday = await storable.wasPromptedToday();
  if (wasPromptedToday) {
    return false;
  }

  // Check if user has pending posts from yesterday
  final service = ref.read(calendarServiceProvider);
  final hasPending = await service.hasPendingSelection();

  return hasPending;
}

/// Provider for saving the last selection prompt date.
@riverpod
class MarkSelectionPrompted extends _$MarkSelectionPrompted {
  @override
  Future<void> build() async {}

  /// Marks that the user was prompted today.
  Future<void> markPrompted() async {
    final storable = LastSelectionDateStorable();
    await storable.setPromptedToday();

    // Invalidate the check provider
    ref.invalidate(shouldShowMemorableSelectionProvider);
  }
}
