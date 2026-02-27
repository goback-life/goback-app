import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloudless/core/features/post/domain/hooks/use_post_detail.dart';
import 'package:cloudless/core/features/post/domain/models/feed_post_model.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/components/squircle_clipper.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_overlay_content.dart';
import 'package:cloudless/presentation/pages/post_detail/components/post_detail_overlay_reactions.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:dedecube_core/dedecube_core.dart';
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
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
          ),
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
class PostDetailOverlay extends HookConsumerWidget {
  const PostDetailOverlay({
    required this.post,
    this.readOnly = false,
    super.key,
  });

  final FeedPostModel post;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final s = screenW / 402.0;

    // Card dimensions
    final cardW = 371.0 * s;
    final cardH = screenH * (600.0 / 874.0);
    final cardMarginH = 15.0 * s;
    final cardTop = 93.0 * s;
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
        scrollFraction.value =
            (pos.pixels / pos.maxScrollExtent).clamp(0.0, 1.0);
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController]);

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
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
                child: _GlassCard(
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
              ),
            ),
          ),
        ),
      ),
    );
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
    final indicatorW = 8.0 * scale;
    final indicatorH = 35.0 * scale;
    final indicatorRight = 6.0 * scale;

    // Indicator travels between squircle bottom and reaction bar top
    final visibleTop = squircleTop + squircleSize;
    final visibleH = cardH - visibleTop - contentBottom;
    final indicatorPad = 10 * scale;
    final travel =
        (visibleH - indicatorH - indicatorPad * 2).clamp(0.0, visibleH);
    // Reversed list: fraction=0 at rest (bottom), fraction=1 scrolled up (top)
    final indicatorTop =
        visibleTop + indicatorPad + (1 - scrollFraction) * travel;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40191919),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: AppGlassContainer(
        config: GlassConfig(
          variant: GlassVariant.regular,
          cornerRadius: cardRadius,
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
                    child: ClipSquircle(
                      child: _squircleImage(),
                    ),
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

  Widget _squircleImage() {
    final url = post.imageUrl ?? '';
    if (url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        width: squircleSize,
        height: squircleSize,
        memCacheWidth: (squircleSize * 2).toInt(),
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 100),
        placeholder: (_, __) => Container(color: MainColors.dark),
        errorWidget: (_, __, ___) => Container(color: MainColors.dark),
      );
    }
    return Container(color: MainColors.dark);
  }
}

/// Clips content to the bottom portion of the card, starting at [clipTop].
class _ContentClipper extends CustomClipper<Rect> {
  _ContentClipper({required this.clipTop});

  final double clipTop;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, clipTop, size.width, size.height);

  @override
  bool shouldReclip(covariant _ContentClipper old) => old.clipTop != clipTop;
}
