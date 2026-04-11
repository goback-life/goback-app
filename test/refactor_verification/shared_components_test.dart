// Verification test for shared UI components refactoring.
//
// Validates structural invariants after refactoring without requiring
// a full Flutter test environment.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final componentsDir = Directory('lib/presentation/components');

  group('Shared UI Components - structural verification', () {
    test('components directory exists', () {
      expect(componentsDir.existsSync(), isTrue);
    });

    test('full_screen_image.dart exists and is within 500 lines', () {
      final file = File('${componentsDir.path}/full_screen_image.dart');
      expect(file.existsSync(), isTrue);
      final lines = file.readAsLinesSync();
      expect(
        lines.length,
        lessThanOrEqualTo(500),
        reason:
            'full_screen_image.dart should be <= 500 lines, '
            'was ${lines.length}',
      );
    });

    test('full_screen_image_geometry.dart exists as part file', () {
      final file = File(
        '${componentsDir.path}/full_screen_image_geometry.dart',
      );
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(
        content,
        contains(
          "part of 'package:cloudless/presentation/components/"
          "full_screen_image.dart'",
        ),
      );
    });

    test('full_screen_image_painter.dart exists as part file', () {
      final file = File('${componentsDir.path}/full_screen_image_painter.dart');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(
        content,
        contains(
          "part of 'package:cloudless/presentation/components/"
          "full_screen_image.dart'",
        ),
      );
    });

    test('full_screen_image.dart declares part directives', () {
      final file = File('${componentsDir.path}/full_screen_image.dart');
      final content = file.readAsStringSync();
      expect(content, contains("part 'full_screen_image_geometry.dart'"));
      expect(content, contains("part 'full_screen_image_painter.dart'"));
    });

    test('full_screen_image.dart retains public API', () {
      final file = File('${componentsDir.path}/full_screen_image.dart');
      final content = file.readAsStringSync();
      expect(content, contains('class FullScreenImage extends StatefulWidget'));
      expect(content, contains('static Future<T?> show<T>'));
      expect(content, contains('final ImageProvider image'));
      expect(content, contains('final bool showFlipMenu'));
      expect(content, contains('final void Function(Uint8List'));
    });

    test('geometry part file contains extracted math utilities', () {
      final file = File(
        '${componentsDir.path}/full_screen_image_geometry.dart',
      );
      final content = file.readAsStringSync();
      expect(content, contains('_getAxisAlignedBoundingBoxWithRotation'));
      expect(content, contains('_getMatrixTranslation'));
      expect(content, contains('_exceedsBy'));
      expect(content, contains('_transformViewport'));
      expect(content, contains('_round'));
      expect(content, contains('_getNearestPointInside'));
      expect(content, contains('_pointIsInside'));
      expect(content, contains('_getNearestPointOnLine'));
      expect(content, contains('_getAxisAlignedBoundingBox'));
      expect(content, contains('_fixMatrixForBounds'));
    });

    test('painter part file contains _UiImagePainter', () {
      final file = File('${componentsDir.path}/full_screen_image_painter.dart');
      final content = file.readAsStringSync();
      expect(content, contains('class _UiImagePainter extends CustomPainter'));
      expect(content, contains('void paint(Canvas canvas, Size size)'));
      expect(content, contains('bool shouldRepaint'));
    });

    test('full_screen_image_flip_menu.dart unchanged', () {
      final file = File(
        '${componentsDir.path}/full_screen_image_flip_menu.dart',
      );
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(content, contains('class FullScreenImageFlipMenu'));
      expect(content, contains('onFlipHorizontal'));
      expect(content, contains('onFlipVertical'));
    });

    test('glass system files intact', () {
      final glassContainer = File(
        '${componentsDir.path}/glass/app_glass_container.dart',
      );
      final glassConfig = File('${componentsDir.path}/glass/glass_config.dart');
      expect(glassContainer.existsSync(), isTrue);
      expect(glassConfig.existsSync(), isTrue);
      final containerContent = glassContainer.readAsStringSync();
      expect(containerContent, contains('class AppGlassContainer'));
      expect(containerContent, contains('class AppGlassLayer'));
      expect(containerContent, contains('kNativeGlassAvailable'));
    });

    test('CTA button system files intact', () {
      final ctaFile = File(
        '${componentsDir.path}/buttons/call_to_action/call_to_action.dart',
      );
      expect(ctaFile.existsSync(), isTrue);
      final content = ctaFile.readAsStringSync();
      expect(content, contains('class CallToAction extends StatelessWidget'));
      expect(content, contains("part 'theming/call_to_action_theme.dart'"));
      expect(content, contains("part 'theming/call_to_action_mode.dart'"));
    });

    test('no file in components/ exceeds 500 lines', () {
      final dartFiles = componentsDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      for (final file in dartFiles) {
        final lines = file.readAsLinesSync();
        final relativePath = file.path.replaceFirst(
          componentsDir.path,
          'components',
        );
        expect(
          lines.length,
          lessThanOrEqualTo(500),
          reason: '$relativePath has ${lines.length} lines (max 500)',
        );
      }
    });

    test('profile_image files intact', () {
      final profileImage = File(
        '${componentsDir.path}/profile_image/profile_image.dart',
      );
      expect(profileImage.existsSync(), isTrue);
      final content = profileImage.readAsStringSync();
      expect(content, contains('class ProfileImage'));
      expect(content, contains('FullScreenImage.show'));
    });

    test('alert files intact', () {
      final mainAlert = File('${componentsDir.path}/alerts/main_alert.dart');
      expect(mainAlert.existsSync(), isTrue);
      final content = mainAlert.readAsStringSync();
      expect(content, contains('class MainAlert'));
      expect(content, contains('AppGlassContainer'));
    });

    test('share card files intact', () {
      final lockoutCard = File(
        '${componentsDir.path}/share_card/lockout_share_card.dart',
      );
      final statsCard = File(
        '${componentsDir.path}/share_card/stats_share_card.dart',
      );
      expect(lockoutCard.existsSync(), isTrue);
      expect(statsCard.existsSync(), isTrue);
    });

    test('video player files intact', () {
      final dialog = File(
        '${componentsDir.path}/video_player/video_player_dialog.dart',
      );
      final progressBar = File(
        '${componentsDir.path}/video_player/video_progress_bar.dart',
      );
      expect(dialog.existsSync(), isTrue);
      expect(progressBar.existsSync(), isTrue);
    });
  });
}
