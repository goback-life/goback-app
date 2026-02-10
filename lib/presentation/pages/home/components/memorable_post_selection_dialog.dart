import 'package:cloudless/core/features/calendar/data/dtos/calendar_post_dto.dart';
import 'package:cloudless/core/features/calendar/data/providers/calendar_service_provider.dart';
import 'package:cloudless/core/features/calendar/domain/providers/pending_selection_provider.dart';
import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

/// Dialog shown on new day to select a memorable post from yesterday's posts.
class MemorablePostSelectionDialog extends HookConsumerWidget with MainLayout {
  const MemorablePostSelectionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const MemorablePostSelectionDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final posts = useState<List<CalendarPostDto>>([]);
    final selectedPostId = useState<String?>(null);
    final isLoading = useState(true);
    final isSaving = useState(false);
    final error = useState<String?>(null);

    // Load pending posts
    useEffect(() {
      Future<void> loadPosts() async {
        try {
          final service = ref.read(calendarServiceProvider);
          final pendingPosts = await service.getPendingSelectionPosts();
          posts.value = pendingPosts;

          // Auto-select if only one post
          if (posts.value.length == 1) {
            selectedPostId.value = posts.value.first.postId;
          }
        } catch (e) {
          error.value = 'Failed to load posts';
        } finally {
          isLoading.value = false;
        }
      }

      loadPosts();
      return null;
    }, []);

    Future<void> handleSave() async {
      final postId = selectedPostId.value;
      if (postId == null) return;

      isSaving.value = true;
      try {
        final service = ref.read(calendarServiceProvider);
        final result = await service.savePostToCalendar(postId);

        result.fold(
          (_) {
            // Mark as prompted and close
            ref.read(markSelectionPromptedProvider.notifier).markPrompted();
            Navigator.of(context).pop();
          },
          (err) {
            error.value = 'Failed to save post';
            isSaving.value = false;
          },
        );
      } catch (e) {
        error.value = 'Failed to save post';
        isSaving.value = false;
      }
    }

    Future<void> handleSkip() async {
      // Mark as prompted so we don't show again today
      await ref.read(markSelectionPromptedProvider.notifier).markPrompted();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              translator.translate('pages.memorable_selection.title'),
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              translator.translate('pages.memorable_selection.description'),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isLoading.value)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              )
            else if (posts.value.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  translator.translate('pages.memorable_selection.no_posts'),
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: posts.value.length,
                  itemBuilder: (context, index) {
                    final post = posts.value[index];
                    final isSelected = selectedPostId.value == post.postId;
                    final publishedAt = DateTime.tryParse(post.publishedAt);

                    return GestureDetector(
                      onTap: () => selectedPostId.value = post.postId,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.outline.withValues(alpha: 0.2),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Row(
                            children: [
                              // Thumbnail
                              SizedBox(
                                width: 80,
                                height: 80,
                                child: post.thumbnailUrl != null
                                    ? Image.network(
                                        post.thumbnailUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: colorScheme.primaryContainer,
                                          child: Icon(
                                            Icons.image,
                                            color: colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        color: colorScheme.primaryContainer,
                                        child: Icon(
                                          Icons.image,
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              // Description
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (post.description?.isNotEmpty ?? false)
                                        Text(
                                          post.description!,
                                          style: textTheme.bodyMedium,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      else
                                        Text(
                                          'No description',
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      if (publishedAt != null)
                                        Text(
                                          _formatTime(publishedAt),
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              // Selection indicator
                              if (isSelected)
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: colorScheme.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (error.value != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: Text(
                  error.value!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),
            // Buttons
            if (!isLoading.value && posts.value.isNotEmpty) ...[
              CallToAction.primary.filled(
                action: selectedPostId.value != null && !isSaving.value
                    ? handleSave
                    : null,
                label: isSaving.value
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.primary,
                          ),
                        ),
                      )
                    : Text(
                        translator.translate('pages.memorable_selection.save'),
                        style: textTheme.titleMedium?.copyWith(
                          color: selectedPostId.value != null
                              ? colorScheme.primary
                              : colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
            ],
            TextButton(
              onPressed: isSaving.value ? null : handleSkip,
              child: Text(
                translator.translate('pages.memorable_selection.skip'),
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$hour12:$minute $period';
  }
}
