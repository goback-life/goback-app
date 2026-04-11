import 'package:flutter_test/flutter_test.dart';

/// Structural verification tests for the your_circle page refactoring.
///
/// These tests document the public API contracts for all your_circle widgets.
/// They verify that:
/// 1. All public classes/functions exist and are importable.
/// 2. Widget constructors accept the correct parameters.
/// 3. File organization matches expected structure after refactoring.
///
/// Purpose: catch accidental public API breakage during refactoring.
/// These are compile-time + instantiation tests, NOT rendering tests
/// (rendering requires full Riverpod/Supabase setup).

// -- Public widget & function imports (must remain stable) --
import 'package:cloudless/presentation/pages/your_circle/your_circle_page.dart';
import 'package:cloudless/presentation/pages/your_circle/your_circle_layout.dart';
import 'package:cloudless/presentation/pages/your_circle/your_circle_routable.dart';
import 'package:cloudless/presentation/pages/your_circle/views/your_circle_view.dart';
import 'package:cloudless/presentation/pages/your_circle/views/connection_requests_view.dart';
import 'package:cloudless/presentation/pages/your_circle/components/your_circle_add_menu.dart';
import 'package:cloudless/presentation/pages/your_circle/components/your_circle_friend_tile.dart';
import 'package:cloudless/presentation/pages/your_circle/components/your_circle_search_pill.dart';
import 'package:cloudless/presentation/pages/your_circle/components/your_circle_remove_dialog.dart';
import 'package:cloudless/presentation/pages/your_circle/components/your_circle_invite_button.dart';
import 'package:cloudless/presentation/pages/your_circle/components/your_circle_join_button.dart';
import 'package:cloudless/presentation/pages/your_circle/components/invite_card_popup.dart';
import 'package:cloudless/presentation/pages/your_circle/components/receive_code_card_popup.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';

void main() {
  group('your_circle - public API contracts', () {
    // -----------------------------------------------------------------------
    // Page & routing
    // -----------------------------------------------------------------------
    test('YourCirclePage can be instantiated', () {
      const page = YourCirclePage();
      expect(page, isA<YourCirclePage>());
    });

    test('YourCircleRoutable exposes /your_circle path', () {
      const routable = YourCircleRoutable();
      expect(routable.path, equals('/your_circle'));
    });

    // -----------------------------------------------------------------------
    // Views
    // -----------------------------------------------------------------------
    test('YourCircleView can be instantiated', () {
      const view = YourCircleView();
      expect(view, isA<YourCircleView>());
    });

    test('ConnectionRequestsView can be instantiated', () {
      const view = ConnectionRequestsView();
      expect(view, isA<ConnectionRequestsView>());
    });

    // -----------------------------------------------------------------------
    // Components - constructor contracts
    // -----------------------------------------------------------------------
    test('YourCircleAddMenu can be instantiated', () {
      const menu = YourCircleAddMenu();
      expect(menu, isA<YourCircleAddMenu>());
    });

    test('YourCircleInviteButton can be instantiated', () {
      const btn = YourCircleInviteButton();
      expect(btn, isA<YourCircleInviteButton>());
    });

    test('YourCircleJoinButton can be instantiated', () {
      const btn = YourCircleJoinButton();
      expect(btn, isA<YourCircleJoinButton>());
    });

    // -----------------------------------------------------------------------
    // Top-level popup functions remain importable
    // -----------------------------------------------------------------------
    test('showInviteCardPopup is a function', () {
      expect(showInviteCardPopup, isA<Function>());
    });

    test('showReceiveCodeCardPopup is a function', () {
      expect(showReceiveCodeCardPopup, isA<Function>());
    });

    test('showRemoveFriendDialog is a function', () {
      expect(showRemoveFriendDialog, isA<Function>());
    });

    // -----------------------------------------------------------------------
    // Layout mixin constants
    // -----------------------------------------------------------------------
    test('YourCircleLayout mixin exposes expected dimension getters', () {
      // Create a concrete class to test the mixin.
      final layout = _TestLayout();
      expect(layout.friendTileHeight, equals(59.0));
      expect(layout.searchPillWidth, equals(231.0));
      expect(layout.searchPillHeight, equals(51.0));
      expect(layout.addButtonSize, equals(51.0));
      expect(layout.arrowWidth, equals(48.0));
      expect(layout.removeButtonWidth, equals(318.0));
      expect(layout.removeButtonHeight, equals(51.0));
      expect(layout.swipeDeleteThreshold, equals(0.3));
    });
  });
}

/// Concrete class to test [YourCircleLayout] mixin values.
class _TestLayout with MainLayout, YourCircleLayout {}
