import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudless/core/features/auth/domain/providers/get_current_user_provider.dart';
import 'package:cloudless/core/features/calendar/domain/providers/calendar_posts_cache_provider.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_post_detail.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/core/features/post/domain/providers/delete_post_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/feed_posts_cache_provider.dart';
import 'package:cloudless/core/features/post/domain/providers/post_action_notifier_provider.dart';
import 'package:cloudless/presentation/components/alerts/main_alert.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/components/squircle_clipper.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_overlay_content.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_overlay_reactions.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

/// Shows a full-screen image overlay that dismisses on tap.
void _showFullScreenImage(BuildContext context, String? imageUrl) {
  if (imageUrl == null || imageUrl.isEmpty) return;
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      pageBuilder: (_, __, ___) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.contain),
        ),
      ),
    ),
  );
}

/// Glass card overlay for post detail, opened from the feed.
///
/// Features a pinned squircle image with Hero transition, scrollable
/// comments/content, a glass scroll indicator, and dismiss gestures
/// (swipe-down or tap-outside).
class PostDetailOverlay extends HookConsumerWidget with MainLayout {
  const PostDetailOverlay({
    required this.post,
    this.readOnly = false,
    this.showDeleteButton = false,
    super.key,
  });

  final FeedPostModel post;
  final bool readOnly;
  final bool showDeleteButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final keyboardH = MediaQuery.of(context).viewInsets.bottom;
    final s = screenW / 402.0;

    // Card dimensions
    final cardW = 371.0 * s;
    final cardTop = 93.0 * s;
    // Shrink card when keyboard is open so its bottom stays above the keyboard.
    // Mention overlay (44pt) floats independently in the global Overlay stack,
    // so no extra buffer is needed here.
    final cardH = (screenH * (600.0 / 874.0)).clamp(
      0.0,
      screenH - cardTop - keyboardH,
    );
    final cardMarginH = 15.0 * s;
    final cardRadius = 47.0 * s;

    // Squircle layout — equidistant from sides and top
    final squircleSize = 296.0 * s;
    final squircleInset = (cardW - squircleSize) / 2;
    final squircleLeft = squircleInset;
    final squircleTop = squircleInset; // equidistant from top too

    // Content layout — inset from squircle edges to clear card corners
    final contentHPad = squircleInset + 12 * s;
    final contentWidth = cardW - contentHPad * 2;

    // Post detail (may refresh from server)
    final postDetail = usePostDetail(
      ref: ref,
      postId: post.id,
      fallbackPost: post,
    );
    final currentPost = postDetail.post ?? post;

    // Check if current user owns this post
    final isOwnPost = useMemoized(() {
      return ref
              .read(getCurrentUserProvider)
              .whenOrNull(
                data: (r) =>
                    r.fold((u) => u.id == currentPost.authorId, (_) => false),
              ) ??
          false;
    }, [currentPost.authorId]);

    // Scroll tracking for indicator
    final scrollController = useScrollController();
    final scrollFraction = useState(0.0);

    useEffect(() {
      void onScroll() {
        if (!scrollController.hasClients) {
          return;
        }
        final pos = scrollController.position;
        if (pos.maxScrollExtent <= 0) {
          scrollFraction.value = 0;
          return;
        }
        scrollFraction.value = (pos.pixels / pos.maxScrollExtent).clamp(
          0.0,
          1.0,
        );
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController]);

    // Peek scroll: when comments exist, briefly scroll up to reveal
    // the "Thoughts" header after the card's Hero animation settles.
    useEffect(() {
      if (currentPost.commentCount <= 0) return null;

      bool cancelled = false;

      void onUserScroll() {
        cancelled = true;
        scrollController.removeListener(onUserScroll);
      }

      scrollController.addListener(onUserScroll);

      Future<void> peek() async {
        await Future.delayed(const Duration(milliseconds: 700));
        if (cancelled ||
            !scrollController.hasClients ||
            scrollController.position.maxScrollExtent <= 0) {
          return;
        }
        final peekDistance = (160.0 * s).clamp(
          0.0,
          scrollController.position.maxScrollExtent,
        );
        scrollController.animateTo(
          peekDistance,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      peek();
      return () {
        cancelled = true;
        scrollController.removeListener(onUserScroll);
      };
    }, [currentPost.commentCount]);

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(), // dismiss overlay
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () {}, // absorb taps on card
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(
                left: cardMarginH,
                right: cardMarginH,
                top: cardTop,
              ),
              child: SizedBox(
                width: cardW,
                height: cardH,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _GlassCard(
                      cardRadius: cardRadius,
                      cardH: cardH,
                      squircleSize: squircleSize,
                      squircleLeft: squircleLeft,
                      squircleTop: squircleTop,
                      contentHPad: contentHPad,
                      contentWidth: contentWidth,
                      scale: s,
                      post: currentPost,
                      scrollController: scrollController,
                      scrollFraction: scrollFraction.value,
                      readOnly: readOnly,
                    ),
                    if (showDeleteButton && isOwnPost)
                      Positioned(
                        top: -14 * s,
                        right: -4 * s,
                        child: GestureDetector(
                          onTap: () => _confirmAndDeletePost(
                            context,
                            ref,
                            post: currentPost,
                          ),
                          child: Container(
                            width: 30 * s,
                            height: 30 * s,
                            decoration: BoxDecoration(
                              color: MainColors.dark.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Theme.of(context).colorScheme.onSurface,
                              size: 16 * s,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndDeletePost(
    BuildContext context,
    WidgetRef ref, {
    required FeedPostModel post,
  }) async {
    final confirmed = Completer<bool>();

    await MainAlert.showFull(
      context: context,
      title: translator.translate('components.delete_post.title'),
      content: Text(
        translator.translate('components.delete_post.content'),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        textAlign: TextAlign.center,
      ),
      primaryButtonText: translator.translate('components.delete_post.confirm'),
      secondaryButtonText: translator.translate(
        'components.delete_post.cancel',
      ),
      primaryButtonType: CallToActionType.danger,
      onPrimaryPressed: () {
        router.pop();
        confirmed.complete(true);
      },
      onSecondaryPressed: () {
        router.pop();
        confirmed.complete(false);
      },
    );

    if (!await confirmed.future) return;

    try {
      final result = await ref.read(
        deletePostProvider(postId: post.id, authorId: post.authorId).future,
      );

      result.fold(
        (_) {
          // Remove from both caches
          ref.read(feedPostsCacheProvider.notifier).removePost(post.id);
          ref
              .read(calendarPostsCacheProvider.notifier)
              .removePostOptimistically(post.id);
          ref
              .read(postActionNotifierProvider.notifier)
              .notifyPostDeleted(postId: post.id);
          if (context.mounted) {
            Navigator.of(context).pop(); // close overlay
          }
        },
        (error) {
          debugPrint('[PostDelete] FAILURE: $error');
          if (context.mounted) {
            MainAlert.showError(
              context: context,
              title: translator.translate('components.delete_post.error_title'),
              content: translator.translate(
                'components.delete_post.error_content',
              ),
            );
          }
        },
      );
    } catch (e, stackTrace) {
      debugPrint('[PostDelete] EXCEPTION: $e\n$stackTrace');
      if (context.mounted) {
        await MainAlert.showError(
          context: context,
          title: translator.translate('components.delete_post.error_title'),
          content: translator.translate('components.delete_post.error_content'),
        );
      }
    }
  }
}

/// The glass card surface with pinned squircle, scrollable content,
/// and scroll indicator.
class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.cardRadius,
    required this.cardH,
    required this.squircleSize,
    required this.squircleLeft,
    required this.squircleTop,
    required this.contentHPad,
    required this.contentWidth,
    required this.scale,
    required this.post,
    required this.scrollController,
    required this.scrollFraction,
    this.readOnly = false,
  });

  final double cardRadius;
  final double cardH;
  final double squircleSize;
  final double squircleLeft;
  final double squircleTop;
  final double contentHPad;
  final double contentWidth;
  final double scale;
  final FeedPostModel post;
  final ScrollController scrollController;
  final double scrollFraction;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    // Reactions bar dimensions
    final reactionBarH = 32.0 * scale;
    final reactionBarPad = 12.0 * scale;
    final contentBottom = reactionBarH + reactionBarPad * 2;

    // Scroll indicator dimensions
    final indicatorW = 24.0 * scale;
    final indicatorH = 35.0 * scale;
    final indicatorRight = 6.0 * scale;

    // Indicator travels between squircle bottom and reaction bar top
    final visibleTop = squircleTop + squircleSize;
    final visibleH = cardH - visibleTop - contentBottom;
    final indicatorPad = 10 * scale;
    final travel = (visibleH - indicatorH - indicatorPad * 2).clamp(
      0.0,
      visibleH,
    );
    // Reversed list: fraction=0 at rest (bottom), fraction=1 scrolled up (top)
    final indicatorTop =
        visibleTop + indicatorPad + (1 - scrollFraction) * travel;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AppGlassContainer(
        config: GlassConfig(
          variant: GlassVariant.regular,
          cornerRadius: cardRadius,
          tint: MainColors.accent,
          opacity: 0.15,
        ),
        child: Stack(
          children: [
            // Scrollable content — clipped at squircle midpoint, stops
            // above reaction bar
            Positioned.fill(
              child: ClipRect(
                clipper: _ContentClipper(
                  clipTop: squircleTop + squircleSize / 2,
                ),
                child: PostDetailOverlayContent(
                  post: post,
                  scale: scale,
                  scrollController: scrollController,
                  squircleTop: squircleTop,
                  squircleSize: squircleSize,
                  contentHPad: contentHPad,
                  contentWidth: contentWidth,
                  bottomInset: contentBottom,
                  readOnly: readOnly,
                ),
              ),
            ),

            // Fixed score label above squircle for lockout posts
            if (post.isLockoutPost && post.lockoutScore != null)
              Positioned(
                left: squircleLeft,
                right: squircleLeft,
                top: squircleTop - 24 * scale,
                child: Text(
                  '${post.lockoutScore}'
                  '${post.lockoutDurationFormatted != null ? ' | ${post.lockoutDurationFormatted}' : ''}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: MainFontFamilies.quicksand,
                    fontWeight: FontWeight.w500,
                    fontSize: 15.0 * scale,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.5 * scale,
                  ),
                ),
              ),

            // Pinned squircle image
            Positioned(
              left: squircleLeft,
              top: squircleTop,
              child: GestureDetector(
                onTap: () => _showFullScreenImage(context, post.imageUrl),
                child: Hero(
                  tag: 'post_${post.id}',
                  child: SizedBox(
                    width: squircleSize,
                    height: squircleSize,
                    child: ClipSquircle(child: _squircleImage(context)),
                  ),
                ),
              ),
            ),

            // Scroll indicator (right edge, draggable)
            Positioned(
              right: indicatorRight - 10 * scale,
              top: indicatorTop - 5 * scale,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  if (travel <= 0 || !scrollController.hasClients) return;
                  final pos = scrollController.position;
                  final delta =
                      (-details.delta.dy / travel) * pos.maxScrollExtent;
                  scrollController.jumpTo(
                    (pos.pixels + delta).clamp(0.0, pos.maxScrollExtent),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10 * scale,
                    vertical: 5 * scale,
                  ),
                  child: SizedBox(
                    width: indicatorW,
                    height: indicatorH,
                    child: AppGlassContainer(
                      config: GlassConfig(
                        variant: GlassVariant.clear,
                        cornerRadius: indicatorW / 2,
                        tint: MainColors.accent,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),

            // Reaction bar (anchored to bottom)
            Positioned(
              left: 0,
              right: 0,
              bottom: reactionBarPad,
              child: PostDetailOverlayReactions(
                postId: post.id,
                scale: scale,
                readOnly: readOnly,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _squircleImage(BuildContext context) {
    final url = post.imageUrl ?? '';
    final placeholderColor = Theme.of(context).colorScheme.surfaceContainerHigh;
    if (url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: squircleSize,
        height: squircleSize,
        memCacheWidth: (squircleSize * 2).toInt(),
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 100),
        placeholder: (_, __) => Container(color: placeholderColor),
        errorWidget: (_, __, ___) => Container(color: placeholderColor),
      );
    }
    return Container(color: placeholderColor);
  }
}

/// Clips content to the bottom portion of the card, starting at [clipTop].
class _ContentClipper extends CustomClipper<Rect> {
  _ContentClipper({required this.clipTop});

  final double clipTop;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, clipTop, size.width, size.height);

  @override
  bool shouldReclip(covariant _ContentClipper old) => old.clipTop != clipTop;
}
