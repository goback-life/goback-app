// Verification test: Content Editor + Publish + Visibility Selection pages
//
// Documents the public API contracts that must be preserved during refactoring.
// Run: flutter test test/refactor_verification/content_editor_test.dart

// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

// Content Editor
import 'package:cloudless/presentation/pages/content_editor/content_editor_page.dart';
import 'package:cloudless/presentation/pages/content_editor/content_editor_layout.dart';
import 'package:cloudless/presentation/pages/content_editor/content_editor_routable.dart';
import 'package:cloudless/presentation/pages/content_editor/views/content_editor_view.dart';
import 'package:cloudless/presentation/pages/content_editor/views/lockout_post_editor_view.dart';
import 'package:cloudless/presentation/pages/content_editor/components/content_editor_selected_media.dart';
import 'package:cloudless/presentation/pages/content_editor/components/content_editor_text_post.dart';
import 'package:cloudless/presentation/pages/content_editor/components/content_editor_post_description.dart';
import 'package:cloudless/presentation/pages/content_editor/components/content_editor_post_tag_user_section.dart';
import 'package:cloudless/presentation/pages/content_editor/components/content_editor_button.dart';
import 'package:cloudless/presentation/pages/content_editor/components/content_editor_user_chip.dart';
import 'package:cloudless/presentation/pages/content_editor/components/markdown_link_formatter.dart';

// Publish Content
import 'package:cloudless/presentation/pages/publish_content/publish_content_page.dart';
import 'package:cloudless/presentation/pages/publish_content/publish_content_layout.dart';
import 'package:cloudless/presentation/pages/publish_content/publish_content_routable.dart';
import 'package:cloudless/presentation/pages/publish_content/views/publish_content_view.dart';
import 'package:cloudless/presentation/pages/publish_content/components/publish_content_button.dart';

// Visibility Selection
import 'package:cloudless/presentation/pages/visibility_selection/visibility_selection_page.dart';
import 'package:cloudless/presentation/pages/visibility_selection/visibility_selection_layout.dart';
import 'package:cloudless/presentation/pages/visibility_selection/visibility_selection_routable.dart';
import 'package:cloudless/presentation/pages/visibility_selection/views/visibility_selection_view.dart';

void main() {
  group('Content Editor - Public API Contracts', () {
    test('ContentEditorPage exists as a const widget', () {
      expect(const ContentEditorPage(), isA<Widget>());
    });

    test('ContentEditorRoutable has correct path', () {
      expect(const ContentEditorRoutable().path, '/content_editor');
    });

    test('ContentEditorLayout mixin provides expected spacing values', () {
      final layout = _TestContentEditorLayout();
      expect(layout.horizontalPadding, 16.0);
      expect(layout.topMargin, 60.0);
      expect(layout.verticalSpacing, 32.0);
      expect(layout.bottomMargin, 10.0);
      expect(layout.titleToImage, 20.0);
      expect(layout.imageHeight, 278.0);
      expect(layout.borderRadius, 4.0);
      expect(layout.imageToEdit, 16.0);
      expect(layout.mediaToDescription, 30.0);
      expect(layout.thumbnailPreviewWidth, 62.0);
      expect(layout.thumbnailPreviewHeight, 47.0);
    });

    test('ContentEditorButton is a const widget', () {
      expect(const ContentEditorButton(), isA<Widget>());
    });

    test('ContentEditorUserChip accepts username and onRemove', () {
      final chip = ContentEditorUserChip(username: 'testUser', onRemove: () {});
      expect(chip.username, 'testUser');
    });

    test('MarkdownLinkFormatter handles full markdown link deletion', () {
      final formatter = MarkdownLinkFormatter();

      // Simulate backspace inside a markdown link: "Hello [google](https://google.com) world"
      const oldText = 'Hello [google](https://google.com) world';
      const newText = 'Hello [google](https://google.co) world'; // deleted 'm'

      final result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: oldText,
          selection: TextSelection.collapsed(offset: 33), // after 'm'
        ),
        const TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: 32), // after 'o'
        ),
      );

      // Should delete the entire markdown link
      expect(result.text, 'Hello  world');
      expect(result.selection.baseOffset, 6); // right after 'Hello '
    });

    test('MarkdownLinkFormatter passes through non-link deletions', () {
      final formatter = MarkdownLinkFormatter();

      final result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: 'Hello world',
          selection: TextSelection.collapsed(offset: 11),
        ),
        const TextEditingValue(
          text: 'Hello worl',
          selection: TextSelection.collapsed(offset: 10),
        ),
      );

      expect(result.text, 'Hello worl');
    });
  });

  group('Publish Content - Public API Contracts', () {
    test('PublishContentPage exists as a const widget', () {
      expect(const PublishContentPage(), isA<Widget>());
    });

    test('PublishContentRoutable has correct path', () {
      expect(const PublishContentRoutable().path, '/publish_content');
    });

    test('PublishContentLayout mixin provides expected spacing values', () {
      final layout = _TestPublishContentLayout();
      expect(layout.horizontalPadding, 16.0);
      expect(layout.topMargin, 60.0);
      expect(layout.bottomMargin, 10.0);
      expect(layout.membersListSearchToList, 32.0);
    });

    test('PublishContentView is a const widget', () {
      expect(const PublishContentView(), isA<Widget>());
    });
  });

  group('Visibility Selection - Public API Contracts', () {
    test('VisibilitySelectionPage exists as a const widget', () {
      expect(const VisibilitySelectionPage(), isA<Widget>());
    });

    test('VisibilitySelectionRoutable has correct path', () {
      expect(const VisibilitySelectionRoutable().path, '/visibility_selection');
    });

    test('VisibilitySelectionLayout provides expected spacing values', () {
      final layout = _TestVisibilitySelectionLayout();
      expect(layout.horizontalPadding, 16.0);
      expect(layout.topMargin, 60.0);
      expect(layout.searchToList, 16.0);
      expect(layout.pillsSpacing, 8.0);
      expect(layout.pillHeight, 40.0);
      expect(layout.pillRadius, 20.0);
      expect(layout.bottomBarPadding, 16.0);
    });
  });
}

// Test helpers to access layout mixin values
class _TestContentEditorLayout with MainLayout, ContentEditorLayout {}

class _TestPublishContentLayout with MainLayout, PublishContentLayout {}

class _TestVisibilitySelectionLayout
    with MainLayout, VisibilitySelectionLayout {}
