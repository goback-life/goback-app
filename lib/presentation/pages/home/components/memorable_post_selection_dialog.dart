import 'package:cloudless/core/features/calendar/data/dtos/pending_selection_post_dto.dart';
import 'package:cloudless/core/features/calendar/data/providers/calendar_service_provider.dart';
import 'package:cloudless/core/features/calendar/domain/providers/pending_selection_provider.dart';
import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

/// Dialog shown on new day to select a memorable post from recent lockout posts.
/// Tap a post to save it directly; tap Skip to dismiss.
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

    final posts = useState<List<PendingSelectionPostDto>>([]);
    final isLoading = useState(true);
    final savingPostId = useState<String?>(null);
    final error = useState<String?>(null);

    // Load pending posts
    useEffect(() {
      Future<void> loadPosts() async {
        try {
          final service = ref.read(calendarServiceProvider);
          final pendingPosts = await service.getPendingSelectionPosts();
          posts.value = pendingPosts;
        } catch (e) {
          error.value = 'Failed to load posts';
        } finally {
          isLoading.value = false;
        }
      }

      loadPosts();
      return null;
    }, []);

    Future<void> handleTapPost(String postId) async {
      if (savingPostId.value != null) return;
      savingPostId.value = postId;
      try {
        final service = ref.read(calendarServiceProvider);
        final result = await service.savePostToCalendar(postId);
        result.fold(
          (_) {
            ref.read(markSelectionPromptedProvider.notifier).markPrompted();
            Navigator.of(context).pop();
          },
          (err) {
            error.value = 'Failed to save post';
            savingPostId.value = null;
          },
        );
      } catch (e) {
        error.value = 'Failed to save post';
        savingPostId.value = null;
      }
    }

    Future<void> handleSkip() async {
      await ref.read(markSelectionPromptedProvider.notifier).markPrompted();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: AppGlassContainer(
        config: const GlassConfig(
          variant: GlassVariant.regular,
          cornerRadius: 16,
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
                      final isSaving = savingPostId.value == post.id;
                      final publishedAt = DateTime.tryParse(post.publishedAt);

                      return GestureDetector(
                        onTap: () => handleTapPost(post.id),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Row(
                              children: [
                                // Thumbnail or saving indicator
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: isSaving
                                      ? Container(
                                          color: colorScheme.primaryContainer,
                                          child: const Center(
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                        )
                                      : post.thumbnailUrl != null
                                      ? Image.network(
                                          post.thumbnailUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                                color: colorScheme
                                                    .primaryContainer,
                                                child: Icon(
                                                  Icons.image,
                                                  color: colorScheme
                                                      .onPrimaryContainer,
                                                ),
                                              ),
                                        )
                                      : Container(
                                          color: colorScheme.primaryContainer,
                                          child: Icon(
                                            Icons.image,
                                            color:
                                                colorScheme.onPrimaryContainer,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (post.description?.isNotEmpty ??
                                            false)
                                          Text(
                                            post.description!,
                                            style: textTheme.bodyMedium,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          )
                                        else
                                          Text(
                                            'No description',
                                            style: textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: colorScheme.onSurface
                                                      .withValues(alpha: 0.5),
                                                  fontStyle: FontStyle.italic,
                                                ),
                                          ),
                                        const SizedBox(height: 4),
                                        if (publishedAt != null)
                                          Text(
                                            _formatTime(publishedAt),
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                                  color: colorScheme.onSurface
                                                      .withValues(alpha: 0.5),
                                                ),
                                          ),
                                      ],
                                    ),
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
              CallToAction.secondary.outlined(
                action: savingPostId.value != null ? null : handleSkip,
                label: Text(
                  translator.translate('pages.memorable_selection.skip'),
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
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
