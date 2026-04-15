import 'dart:ui' as ui;

import 'package:cloudless/core/models/profile_model.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/components/mention_text_field/mention_text_field.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:flutter/material.dart';

/// Arrow SVG path data for the glass send button (viewBox 36x30).
const kArrowPathData = GlassPathData(
  commands: [
    ['M', 0, 15.0259],
    ['C', 0.0002096, 13.0214, 1.62535, 11.3962, 3.62988, 11.396],
    ['L', 23.5752, 11.396],
    ['L', 18.4834, 6.30422],
    ['C', 17.0415, 4.86214, 17.0416, 2.52371, 18.4834, 1.08156],
    ['C', 19.9255, -0.360582, 22.264, -0.360588, 23.7061, 1.08156],
    ['L', 34.8467, 12.2232],
    ['C', 36.0309, 13.4077, 36.2417, 15.1958, 35.4805, 16.5962],
    ['C', 35.3004, 17.0256, 35.0361, 17.4283, 34.6865, 17.7779],
    ['L', 23.5459, 28.9195],
    ['C', 22.1039, 30.3612, 19.7662, 30.3611, 18.3242, 28.9195],
    ['C', 16.8821, 27.4773, 16.8821, 25.139, 18.3242, 23.6968],
    ['L', 23.3623, 18.6568],
    ['L', 3.62988, 18.6568],
    ['C', 1.62522, 18.6565, 0, 17.0306, 0, 15.0259],
    ['Z'],
  ],
  viewBoxWidth: 36,
  viewBoxHeight: 30,
);

/// Max characters per comment.
const kCommentMaxLength = 250;

/// Compact comment input pill with @mention autocomplete and send arrow.
///
/// Starts as a single-line pill and expands up to 5 lines as the user
/// types. Shows a character counter under the arrow at 75%+ usage.
class PostDetailOverlayInput extends StatelessWidget {
  const PostDetailOverlayInput({
    required this.scale,
    required this.textController,
    required this.allUsers,
    required this.onMentionsChanged,
    required this.onSubmit,
    super.key,
  });

  final double scale;
  final TextEditingController textController;
  final List<ProfileModel> allUsers;
  final ValueChanged<List<String>> onMentionsChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final minH = 30.0 * scale;
    final pillRadius = minH / 2;
    final arrowW = 36.0 * scale;
    final arrowH = 30.0 * scale;
    final gap = 8.0 * scale;
    final fs = 13.0 * scale;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: textController,
      builder: (context, value, _) {
        final len = value.text.length;
        final showCounter = len > (kCommentMaxLength * 0.75).round();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: AppGlassContainer(
                config: GlassConfig(
                  variant: GlassVariant.clear,
                  cornerRadius: pillRadius,
                  tint: MainColors.accent,
                ),
                child: Container(
                  constraints: BoxConstraints(minHeight: minH),
                  color: MainColors.accent.withValues(alpha: 0.08),
                  padding: EdgeInsets.symmetric(
                    horizontal: 12 * scale,
                    vertical: 6 * scale,
                  ),
                  child: MentionTextField(
                    controller: textController,
                    allUsers: allUsers,
                    onMentionsChanged: onMentionsChanged,
                    maxLines: null,
                    maxLength: kCommentMaxLength,
                    style: TextStyle(
                      fontFamily: MainFontFamilies.quicksand,
                      fontWeight: FontWeight.w400,
                      fontSize: fs,
                      color: MainColors.white,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Add a thought...',
                      hintStyle: TextStyle(
                        fontFamily: MainFontFamilies.quicksand,
                        fontWeight: FontWeight.w400,
                        fontSize: fs,
                        color: MainColors.white.withValues(alpha: 0.5),
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      counter: const SizedBox.shrink(),
                    ),
                    onSubmitted: (_) => onSubmit(),
                  ),
                ),
              ),
            ),
            SizedBox(width: gap),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: onSubmit,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: arrowW < 44 ? 44 : arrowW,
                    height: arrowH < 44 ? 44 : arrowH,
                    child: Center(
                      child: CustomPaint(
                        size: Size(arrowW, arrowH),
                        painter: _GlassArrowPainter(
                          accent: MainColors.accent.withValues(alpha: 0.10),
                        ),
                      ),
                    ),
                  ),
                ),
                if (showCounter)
                  Padding(
                    padding: EdgeInsets.only(top: 3 * scale),
                    child: Text(
                      '$len/$kCommentMaxLength',
                      style: TextStyle(
                        fontFamily: MainFontFamilies.quicksand,
                        fontSize: 9.0 * scale,
                        fontWeight: FontWeight.w400,
                        color: len >= kCommentMaxLength
                            ? MainColors.accent
                            : MainColors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Paints the send arrow with liquid-glass styling: accent tint, white
/// overlay, NW→SE body gradient, and directional edge highlight.
class _GlassArrowPainter extends CustomPainter {
  const _GlassArrowPainter({required this.accent});
  final Color accent;

  Path _buildPath(Size size) {
    final sx = size.width / kArrowPathData.viewBoxWidth;
    final sy = size.height / kArrowPathData.viewBoxHeight;
    final path = Path();
    for (final cmd in kArrowPathData.commands) {
      if (cmd.isEmpty) continue;
      switch (cmd[0] as String) {
        case 'M':
          path.moveTo(
            (cmd[1] as num).toDouble() * sx,
            (cmd[2] as num).toDouble() * sy,
          );
        case 'L':
          path.lineTo(
            (cmd[1] as num).toDouble() * sx,
            (cmd[2] as num).toDouble() * sy,
          );
        case 'C':
          path.cubicTo(
            (cmd[1] as num).toDouble() * sx,
            (cmd[2] as num).toDouble() * sy,
            (cmd[3] as num).toDouble() * sx,
            (cmd[4] as num).toDouble() * sy,
            (cmd[5] as num).toDouble() * sx,
            (cmd[6] as num).toDouble() * sy,
          );
        case 'Z':
          path.close();
      }
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);
    final bounds = Offset.zero & size;

    // 1. Accent tint base
    canvas.drawPath(path, Paint()..color = accent);

    // 2. Light white tint
    canvas.drawPath(
      path,
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );

    // 3. Body gradient: NW bright → SE subtle
    canvas.save();
    canvas.clipPath(path);
    canvas.drawPaint(
      Paint()
        ..shader = ui.Gradient.linear(bounds.topLeft, bounds.bottomRight, [
          Colors.white.withValues(alpha: 0.10),
          Colors.white.withValues(alpha: 0.03),
        ]),
    );
    canvas.restore();

    // 4. Edge highlight — NW directional light
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..shader = ui.Gradient.linear(
          bounds.topLeft,
          bounds.bottomRight,
          [
            Colors.white.withValues(alpha: 0.70),
            Colors.white.withValues(alpha: 0.15),
            Colors.transparent,
          ],
          [0.0, 0.45, 0.75],
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _GlassArrowPainter old) => old.accent != accent;
}
