// Structural verification test for tutorial + profile pages refactoring.
// Validates that all public widget classes, their constructors, and
// exported symbols remain intact after refactoring.
//
// This is a compile-time + structural test, not a widget test,
// because these pages depend on Riverpod providers, Supabase,
// router, translator, and other runtime infrastructure that cannot
// be trivially mocked in a unit test.

// -- Tutorial page imports --
import 'package:cloudless/presentation/pages/tutorial/tutorial_page.dart';
import 'package:cloudless/presentation/pages/tutorial/tutorial_layout.dart';
import 'package:cloudless/presentation/pages/tutorial/tutorial_routable.dart';
import 'package:cloudless/presentation/pages/tutorial/views/tutorial_view.dart';
import 'package:cloudless/presentation/pages/tutorial/views/tutorial_feed_phase.dart';
import 'package:cloudless/presentation/pages/tutorial/views/tutorial_lockout_phase.dart';
import 'package:cloudless/presentation/pages/tutorial/components/tutorial_post_card.dart';
import 'package:cloudless/presentation/pages/tutorial/components/tutorial_cutout_painter.dart';
import 'package:cloudless/presentation/pages/tutorial/components/tutorial_nav_overlay.dart';
import 'package:cloudless/presentation/pages/tutorial/components/tutorial_tooltip.dart';
import 'package:cloudless/presentation/pages/tutorial/components/tutorial_friend_adder.dart';
import 'package:cloudless/presentation/pages/tutorial/components/tutorial_invite_tab.dart';
import 'package:cloudless/presentation/pages/tutorial/components/tutorial_search_tab.dart';
import 'package:cloudless/presentation/pages/tutorial/components/tutorial_search_field.dart';

// -- Profile page imports --
import 'package:cloudless/presentation/pages/profile/profile_page.dart';
import 'package:cloudless/presentation/pages/profile/profile_layout.dart';
import 'package:cloudless/presentation/pages/profile/profile_routable.dart';
import 'package:cloudless/presentation/pages/profile/views/profile_view.dart';
import 'package:cloudless/presentation/pages/profile/components/edit_profile_button.dart';
import 'package:cloudless/presentation/pages/profile/components/profile_hamburger_menu.dart';
import 'package:cloudless/presentation/pages/profile/components/profile_weekly_stats.dart';
import 'package:cloudless/presentation/pages/profile/components/profile_tab_toggle.dart';
import 'package:cloudless/presentation/pages/profile/components/calendar_section/profile_calendar.dart';
import 'package:cloudless/presentation/pages/profile/components/calendar_section/calendar_grid.dart';
import 'package:cloudless/presentation/pages/profile/components/calendar_section/calendar_header.dart';
import 'package:cloudless/presentation/pages/profile/components/calendar_section/calendar_day.dart';
import 'package:cloudless/presentation/pages/profile/components/calendar_section/models/calendar_day_model.dart';
import 'package:cloudless/presentation/pages/profile/components/stats_section/profile_stats_view.dart';
import 'package:cloudless/presentation/pages/profile/components/stats_section/stats_card.dart';
import 'package:cloudless/presentation/pages/profile/components/stats_section/lockout_bar_chart.dart';
import 'package:cloudless/presentation/pages/profile/components/stats_section/lockout_bar_chart_painter.dart';
import 'package:cloudless/presentation/pages/profile/components/stats_section/lockout_monthly_cards.dart';
import 'package:cloudless/presentation/pages/profile/components/stats_section/activity_bubble_cloud.dart';
import 'package:cloudless/presentation/pages/profile/components/stats_section/activity_bubble_cloud_painter.dart';

// -- External profile imports --
import 'package:cloudless/presentation/pages/external_profile/external_profile_page.dart';
import 'package:cloudless/presentation/pages/external_profile/external_profile_layout.dart';
import 'package:cloudless/presentation/pages/external_profile/external_profile_routable.dart';
import 'package:cloudless/presentation/pages/external_profile/views/external_profile_view.dart';

// -- Circle profile imports --
import 'package:cloudless/presentation/pages/circle_profile/circle_profile_page.dart';
import 'package:cloudless/presentation/pages/circle_profile/circle_profile_layout.dart';
import 'package:cloudless/presentation/pages/circle_profile/circle_profile_routable.dart';
import 'package:cloudless/presentation/pages/circle_profile/views/circle_profile_view.dart';

// -- Profile shared imports --
import 'package:cloudless/presentation/pages/profile_shared/profile_actions_layout.dart';
import 'package:cloudless/presentation/pages/profile_shared/components/profile_actions_menu.dart';
import 'package:cloudless/presentation/pages/profile_shared/components/profile_block_action.dart';
import 'package:cloudless/presentation/pages/profile_shared/components/profile_report_action.dart';
import 'package:cloudless/presentation/pages/profile_shared/components/profile_report_reason_button.dart';
import 'package:cloudless/presentation/pages/profile_shared/components/profile_remove_action.dart';
import 'package:cloudless/presentation/pages/profile_shared/components/profile_report_reason_modal.dart';

import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tutorial page structural verification', () {
    test('All tutorial widget classes exist and are const-constructible', () {
      const tutorialPage = TutorialPage();
      const tutorialView = TutorialView();
      const tutorialFeedPhase = TutorialFeedPhase(onStartLockout: _noop);
      const tutorialNavOverlay = TutorialNavOverlay(onDismiss: _noop);
      const tutorialPostCard = TutorialPostCard(
        assetPath: 'test',
        username: 'test',
        isRight: false,
      );
      const tutorialTooltip = TutorialTooltip(message: 'test');
      const tutorialFriendAdder = TutorialFriendAdder(
        friendsAdded: 0,
        onFriendAdded: _noop,
      );

      expect(tutorialPage, isA<TutorialPage>());
      expect(tutorialView, isA<TutorialView>());
      expect(tutorialFeedPhase, isA<TutorialFeedPhase>());
      expect(tutorialNavOverlay, isA<TutorialNavOverlay>());
      expect(tutorialPostCard, isA<TutorialPostCard>());
      expect(tutorialTooltip, isA<TutorialTooltip>());
      expect(tutorialFriendAdder, isA<TutorialFriendAdder>());
    });

    test('TutorialLayout mixin provides expected constants', () {
      expect(TutorialLayout.tooltipHPadding, 32.0);
      expect(TutorialLayout.tooltipCornerRadius, 24.0);
      expect(TutorialLayout.friendAdderTopFraction, 0.45);
      expect(TutorialLayout.progressDotSize, 10.0);
      expect(TutorialLayout.progressDotSpacing, 8.0);
    });

    test('TutorialRoutable path is /tutorial', () {
      const routable = TutorialRoutable();
      expect(routable.path, '/tutorial');
    });

    test('TutorialPhase enum has expected values', () {
      expect(TutorialPhase.values.length, 2);
      expect(TutorialPhase.values, contains(TutorialPhase.feed));
      expect(TutorialPhase.values, contains(TutorialPhase.lockout));
    });

    test('TutorialCutoutPainter is a CustomPainter', () {
      final painter = TutorialCutoutPainter(
        bgColor: Colors.black,
        countdown: '1:30',
      );
      expect(painter, isA<CustomPainter>());
    });

    test('TutorialTooltip supports secondary button', () {
      const tooltip = TutorialTooltip(
        message: 'test',
        buttonLabel: 'Share',
        secondaryButtonLabel: 'Skip',
        onTap: _noop,
        onSecondaryTap: _noop,
      );
      expect(tooltip, isA<TutorialTooltip>());
    });

    test('TutorialLockoutPhase exists with onComplete', () {
      expect(TutorialLockoutPhase, isNotNull);
    });

    test('Extracted TutorialInviteTab is const-constructible', () {
      const tab = TutorialInviteTab(onFriendAdded: _noop);
      expect(tab, isA<TutorialInviteTab>());
    });

    test('Extracted TutorialSearchTab is const-constructible', () {
      const tab = TutorialSearchTab(onFriendAdded: _noop);
      expect(tab, isA<TutorialSearchTab>());
    });

    test('Extracted TutorialSearchField is const-constructible', () {
      const field = TutorialSearchField(
        hintText: 'Search',
        onChanged: _noopString,
      );
      expect(field, isA<TutorialSearchField>());
    });
  });

  group('Profile page structural verification', () {
    test('All profile widget classes exist and are const-constructible', () {
      const profilePage = ProfilePage();
      const editProfileButton = EditProfileButton();
      const profileWeeklyStats = ProfileWeeklyStats();

      expect(profilePage, isA<ProfilePage>());
      expect(editProfileButton, isA<EditProfileButton>());
      expect(profileWeeklyStats, isA<ProfileWeeklyStats>());
    });

    test('ProfileLayout mixin provides expected layout constants', () {
      final layout = _TestProfileLayout();
      expect(layout.designWidth, 402.0);
      expect(layout.avatarSize, 132.0);
      expect(layout.avatarTopOffset, 55.0);
      expect(layout.usernameFontSize, 40.0);
      expect(layout.usernameTracking, -2.4);
      expect(layout.usernameTopGap, 11.0);
      expect(layout.bioFontSize, 24.0);
      expect(layout.bioTracking, -1.44);
      expect(layout.bioTopGap, 11.0);
      expect(layout.bioMaxWidth, 288.0);
      expect(layout.dayCellWidth, 39.0);
      expect(layout.dayCellHeight, 48.0);
      expect(layout.calendarGridTop, 360.0);
      expect(layout.calendarGridWidth, 340.0);
      expect(layout.calendarRowSpacing, 59.0);
      expect(layout.dayFontSize, 24.0);
      expect(layout.dayTracking, -1.44);
      expect(layout.dayCellRadius, 10.0);
      expect(layout.monthFontSize, 40.0);
      expect(layout.monthTracking, -2.4);
      expect(layout.monthNavTop, 714.0);
      expect(layout.arrowWidth, 41.0);
      expect(layout.arrowHeight, 34.0);
      expect(layout.hamburgerBarWidth, 31.0);
      expect(layout.hamburgerBarHeight, 5.0);
      expect(layout.hamburgerBarRadius, 47.0);
      expect(layout.hamburgerBarSpacing, 4.0);
      expect(layout.hamburgerTopOffset, 55.0);
      expect(layout.hamburgerRightOffset, 20.0);
    });

    test('ProfileView requires scale parameter', () {
      const view = ProfileView(scale: 1.0);
      expect(view, isA<ProfileView>());
    });

    test('ProfileTabToggle requires selectedIndex and onChanged', () {
      const toggle = ProfileTabToggle(selectedIndex: 0, onChanged: _noopInt);
      expect(toggle, isA<ProfileTabToggle>());
    });

    test('ProfileHamburgerMenu requires scale and onTap', () {
      const menu = ProfileHamburgerMenu(scale: 1.0, onTap: _noop);
      expect(menu, isA<ProfileHamburgerMenu>());
    });

    test('CalendarDayModel has expected fields', () {
      final model = CalendarDayModel(
        date: DateTime(2026, 3, 15),
        isCurrentMonth: true,
        isFuture: false,
        hasContent: true,
        thumbnailUrl: 'https://example.com/img.jpg',
      );
      expect(model.day, 15);
      expect(model.isCurrentMonth, true);
      expect(model.isFuture, false);
      expect(model.hasContent, true);
      expect(model.thumbnailUrl, isNotNull);
    });

    test('ProfileCalendar accepts optional userId and scale', () {
      const cal = ProfileCalendar();
      const calWithUser = ProfileCalendar(userId: 'test-user', scale: 0.8);
      expect(cal, isA<ProfileCalendar>());
      expect(calWithUser, isA<ProfileCalendar>());
    });

    test('preloadCalendarCache is a top-level function', () {
      expect(preloadCalendarCache, isA<Function>());
    });

    test('StatsCard requires label, value, scale', () {
      const card = StatsCard(label: 'Total', value: '5h', scale: 1.0);
      expect(card, isA<StatsCard>());
    });

    test('LockoutLineChartPainter is a CustomPainter', () {
      final painter = LockoutLineChartPainter(
        dailyMinutes: [0, 0, 0, 0, 0, 0, 0],
      );
      expect(painter, isA<CustomPainter>());
    });

    test('ActivityBubbleCloudPainter is a CustomPainter', () {
      final painter = ActivityBubbleCloudPainter(bubbles: []);
      expect(painter, isA<CustomPainter>());
    });

    test('ActivityBubble data class has expected fields', () {
      const bubble = ActivityBubble(
        label: 'Sport',
        emoji: '\u{1F3C3}',
        totalMinutes: 120,
      );
      expect(bubble.label, 'Sport');
      expect(bubble.totalMinutes, 120);
    });
  });

  group('External profile structural verification', () {
    test('ExternalProfileRoutable path is /external_profile', () {
      const routable = ExternalProfileRoutable();
      expect(routable.path, '/external_profile');
    });

    test('ExternalProfilePage requires userId', () {
      const page = ExternalProfilePage(userId: 'test');
      expect(page, isA<ExternalProfilePage>());
    });

    test('ExternalProfileView requires userId', () {
      const view = ExternalProfileView(userId: 'test');
      expect(view, isA<ExternalProfileView>());
    });

    test('ExternalProfileLayout mixin provides expected values', () {
      final layout = _TestExternalProfileLayout();
      expect(layout.topMargin, 66.0);
      expect(layout.verticalSpacing, 16.0);
      expect(layout.titleToImage, 60.0);
    });
  });

  group('Circle profile structural verification', () {
    test('CircleProfileRoutable path is /circle_profile', () {
      const routable = CircleProfileRoutable();
      expect(routable.path, '/circle_profile');
    });

    test('CircleProfilePage requires userId', () {
      const page = CircleProfilePage(userId: 'test');
      expect(page, isA<CircleProfilePage>());
    });

    test('CircleProfileView requires userId and scale', () {
      const view = CircleProfileView(userId: 'test', scale: 1.0);
      expect(view, isA<CircleProfileView>());
    });

    test('CircleProfileLayout mixin provides expected values', () {
      final layout = _TestCircleProfileLayout();
      expect(layout.horizontalPadding, 16.0);
      expect(layout.topMargin, 60.0);
      expect(layout.verticalSpacing, 20.0);
      expect(layout.titleToImage, 50.0);
      expect(layout.buttonToCalendar, 30.0);
    });
  });

  group('Profile shared structural verification', () {
    test('ProfileActionsLayout mixin provides expected values', () {
      final layout = _TestProfileActionsLayout();
      expect(layout.menuVerticalSpacing, 8.0);
      expect(layout.menuBorderRadius, 8.0);
      expect(layout.menuIconSize, 20.0);
      expect(layout.menuIconSpacing, 10.0);
      expect(layout.menuItemHorizontalPadding, 32.0);
      expect(layout.menuItemVerticalPadding, 10.0);
      expect(layout.modalBorderRadius, 20.0);
      expect(layout.modalButtonHeight, 40.0);
    });

    test('ProfileRemoveAction requires onTap', () {
      const action = ProfileRemoveAction(onTap: _noop);
      expect(action, isA<ProfileRemoveAction>());
    });

    test(
      'ProfileActionsMenu, ProfileBlockAction, ProfileReportAction exist',
      () {
        expect(ProfileActionsMenu, isNotNull);
        expect(ProfileBlockAction, isNotNull);
        expect(ProfileReportAction, isNotNull);
      },
    );

    test('ProfileReportReasonModal exists', () {
      expect(ProfileReportReasonModal, isNotNull);
    });

    test('ProfileReportReasonButton exists', () {
      expect(ProfileReportReasonButton, isNotNull);
    });
  });
}

void _noop() {}
void _noopInt(int _) {}
void _noopString(String _) {}

class _TestProfileLayout with MainLayout, ProfileLayout {}

class _TestExternalProfileLayout with MainLayout, ExternalProfileLayout {}

class _TestCircleProfileLayout with MainLayout, CircleProfileLayout {}

class _TestProfileActionsLayout with MainLayout, ProfileActionsLayout {}
