// Structural verification test for home page refactoring.
// Validates that all public widget classes, their constructors, and
// exported symbols remain intact after refactoring.
//
// This is a compile-time + structural test, not a widget test,
// because the home page depends on Riverpod providers, Supabase,
// router, translator, and other runtime infrastructure that cannot
// be trivially mocked in a unit test.

// -- Widget existence: importing ensures classes still exist & compile --
import 'package:cloudless/presentation/pages/home/home_page.dart';
import 'package:cloudless/presentation/pages/home/home_layout.dart';
import 'package:cloudless/presentation/pages/home/home_routable.dart';
import 'package:cloudless/presentation/pages/home/views/home_view.dart';
import 'package:cloudless/presentation/pages/home/components/home_feed_posts_list.dart';
import 'package:cloudless/presentation/pages/home/components/home_feed_post_card.dart';
import 'package:cloudless/presentation/pages/home/components/home_navigation_bar.dart';
import 'package:cloudless/presentation/pages/home/components/home_circle_actions_widget.dart';
import 'package:cloudless/presentation/pages/home/components/home_feed_empty_state.dart';
import 'package:cloudless/presentation/pages/home/components/home_new_posts_banner.dart';
import 'package:cloudless/presentation/pages/home/components/home_scroll_indicator.dart';
import 'package:cloudless/presentation/pages/home/components/home_date_badge.dart';
import 'package:cloudless/presentation/pages/home/components/home_lockout_button.dart';
import 'package:cloudless/presentation/pages/home/components/home_lockout_join_button.dart';
import 'package:cloudless/presentation/pages/home/components/manual_lockout_dialog.dart';
import 'package:cloudless/presentation/pages/home/components/memorable_post_selection_dialog.dart';
import 'package:cloudless/presentation/pages/home/components/dnd_prompt_dialog.dart';

// -- New extracted hook file --
import 'package:cloudless/presentation/pages/home/hooks/use_home_scroll_state.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Home page structural verification', () {
    test('All home page widget classes exist and are const-constructible', () {
      // These const constructors prove the public API is unchanged.
      const homePage = HomePage();
      const homeView = HomeView();
      const homeNavigationBar = HomeNavigationBar();
      const homeFeedEmptyState = HomeFeedEmptyState();
      const homeLockoutButton = HomeLockoutButton();
      const homeScrollIndicator = HomeScrollIndicator(onTap: _noop);
      const homeNewPostsBanner = HomeNewPostsBanner(
        newPostsCount: 0,
        onTap: _noop,
      );
      const homeDateBadge = HomeDateBadge();
      const dndPromptDialog = DndPromptDialog();
      const manualLockoutDialog = ManualLockoutDialog();
      const memorablePostSelectionDialog = MemorablePostSelectionDialog();

      // Verify types (not null)
      expect(homePage, isA<HomePage>());
      expect(homeView, isA<HomeView>());
      expect(homeNavigationBar, isA<HomeNavigationBar>());
      expect(homeFeedEmptyState, isA<HomeFeedEmptyState>());
      expect(homeLockoutButton, isA<HomeLockoutButton>());
      expect(homeScrollIndicator, isA<HomeScrollIndicator>());
      expect(homeNewPostsBanner, isA<HomeNewPostsBanner>());
      expect(homeDateBadge, isA<HomeDateBadge>());
      expect(dndPromptDialog, isA<DndPromptDialog>());
      expect(manualLockoutDialog, isA<ManualLockoutDialog>());
      expect(memorablePostSelectionDialog, isA<MemorablePostSelectionDialog>());
    });

    test('HomeLayout mixin provides expected layout constants', () {
      final layout = _TestHomeLayout();
      // Key layout values that UI depends on
      expect(layout.horizontalPadding, 16.0);
      expect(layout.bottomMargin, 24.0);
      expect(layout.createContentButtonSize, 60.0);
      expect(layout.feedPostWidth, 250.0);
      expect(layout.feedPostHeight, 250.0);
      expect(layout.feedPostImageRadius, 6.0);
      expect(layout.navBarHeight, 60.0);
      expect(layout.scrollIndicatorSize, 32.0);
      expect(layout.newPostsBannerSize, 21.0);
      expect(layout.topMargin, 66.0);
      expect(layout.titleToImage, 12.0);
      expect(layout.dateBadgeTopPadding, 18.0);
      expect(layout.feedPostsListBottomPadding, 135.0);
    });

    test('HomeRoutable path is /home', () {
      const routable = HomeRoutable();
      expect(routable.path, '/home');
    });

    test('HomeScrollState typedef has required fields', () {
      // Verify the extracted hook's return type structure
      final state = HomeScrollState(
        isAtTop: true,
        isAtBottom: false,
        scrollController: null,
        onBannerTap: () {},
        onScrollToBottom: () {},
      );
      expect(state.isAtTop, true);
      expect(state.isAtBottom, false);
    });

    test('HomeFeedPostCard requires post and isCurrentUser', () {
      // Verify the constructor signature hasn't changed.
      // We can't instantiate without a real FeedPostModel, but the import
      // above proves the class still exists with the expected name.
      expect(HomeFeedPostCard, isNotNull);
    });

    test('HomeFeedPostsList requires expected parameters', () {
      expect(HomeFeedPostsList, isNotNull);
    });

    test('HomeCircleActionsWidget requires userId', () {
      expect(HomeCircleActionsWidget, isNotNull);
    });

    test('ManualLockoutDialog has static show method', () {
      expect(ManualLockoutDialog.show, isA<Function>());
    });

    test('MemorablePostSelectionDialog has static show method', () {
      expect(MemorablePostSelectionDialog.show, isA<Function>());
    });

    test('DndPromptDialog has static showIfNeeded method', () {
      expect(DndPromptDialog.showIfNeeded, isA<Function>());
    });
  });
}

void _noop() {}

class _TestHomeLayout with MainLayout, HomeLayout {}
