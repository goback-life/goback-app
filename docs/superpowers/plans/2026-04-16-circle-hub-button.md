# Circle Hub Button Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a glass circle button to FeedView that opens a 3-tab CircleHubPage (Lockouts, Circle, Notifications), with unified search in the Circle tab.

**Architecture:** New `CircleHubPage` with `IndexedStack` of 3 views and a glass tab toggle, following the existing `YourCirclePage` pattern. The Circle tab's search bar is modified to query both circle members and external users. A small `FeedCircleHubButton` is added as a `Positioned` widget in `FeedView._buildStack()`.

**Tech Stack:** Flutter, Riverpod, Freezed (routable), AppGlassContainer, existing hooks (`useSearchUsers`, `useCircleMembers`, `useConnectionRequests`)

**Spec:** `docs/superpowers/specs/2026-04-16-circle-hub-button-design.md`

---

### Task 1: Create CircleHubRoutable

**Files:**
- Create: `lib/presentation/pages/circle_hub/circle_hub_routable.dart`
- Modify: `lib/presentation/routes.dart`

- [ ] **Step 1: Create the routable file**

```dart
// lib/presentation/pages/circle_hub/circle_hub_routable.dart
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:cloudless/presentation/pages/circle_hub/circle_hub_page.dart';

part 'circle_hub_routable.freezed.dart';
part 'circle_hub_routable.g.dart';

@freezed
sealed class CircleHubRoutable extends Routable<CircleHubRoutable>
    with _$CircleHubRoutable {
  factory CircleHubRoutable.fromJson(Map<String, dynamic> json) =>
      _$CircleHubRoutableFromJson(json);

  const CircleHubRoutable._();

  const factory CircleHubRoutable() = _CircleHubRoutable;

  @override
  String get path => '/circle_hub';

  @override
  Map<String, dynamic> get toMap => toJson();

  @override
  CircleHubRoutable Function(Map<String, dynamic>) get fromMap =>
      CircleHubRoutable.fromJson;

  @override
  Widget buildPage(BuildContext context, CircleHubRoutable routeData) {
    return const CircleHubPage();
  }
}
```

- [ ] **Step 2: Register the route**

In `lib/presentation/routes.dart`, add the import and route entry:

```dart
// Add import at top:
import 'package:cloudless/presentation/pages/circle_hub/circle_hub_routable.dart';

// Add to routes list (after YourCircleRoutable):
const CircleHubRoutable(),
```

- [ ] **Step 3: Create a stub CircleHubPage so codegen succeeds**

```dart
// lib/presentation/pages/circle_hub/circle_hub_page.dart
import 'package:flutter/material.dart';

class CircleHubPage extends StatelessWidget {
  const CircleHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Circle Hub')));
  }
}
```

- [ ] **Step 4: Run build_runner**

Run: `fvm dart run build_runner build --delete-conflicting-outputs`

Expected: Generates `circle_hub_routable.freezed.dart` and `circle_hub_routable.g.dart` without errors.

- [ ] **Step 5: Verify analyze passes**

Run: `fvm flutter analyze lib/presentation/pages/circle_hub/ lib/presentation/routes.dart`

Expected: No new errors (existing warnings from `--no-fatal-warnings` are OK).

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/pages/circle_hub/ lib/presentation/routes.dart
git commit -m "feat: add CircleHubRoutable and stub page"
```

---

### Task 2: Build CircleHubPage with 3-Tab Toggle

**Files:**
- Modify: `lib/presentation/pages/circle_hub/circle_hub_page.dart`

**Context:** The tab toggle follows the exact pattern from `lib/presentation/pages/your_circle/your_circle_page.dart` (lines 46-122), extended from 2 pills to 3. The `IndexedStack` holds the 3 views. For now, use placeholder widgets — real views are wired in later tasks.

- [ ] **Step 1: Replace the stub with the full implementation**

```dart
// lib/presentation/pages/circle_hub/circle_hub_page.dart
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

class CircleHubPage extends HookConsumerWidget {
  const CircleHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = useState<int>(0);
    final topPad = MediaQuery.of(context).padding.top;

    return AppGlassLayer(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            IndexedStack(
              index: tabIndex.value,
              children: const [
                Center(child: Text('Lockouts')),
                Center(child: Text('Circle')),
                Center(child: Text('Notifications')),
              ],
            ),
            Positioned(
              top: topPad + 8,
              left: 0,
              right: 0,
              child: Center(
                child: _TabToggle(
                  selectedIndex: tabIndex.value,
                  onChanged: (i) => tabIndex.value = i,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabToggle extends StatelessWidget {
  const _TabToggle({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppGlassContainer(
      config: const GlassConfig(
        variant: GlassVariant.clear,
        tint: MainColors.accent,
        cornerRadius: 20,
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TabPill(
              label: 'Lockouts',
              isSelected: selectedIndex == 0,
              onTap: () => onChanged(0),
            ),
            _TabPill(
              label: 'Circle',
              isSelected: selectedIndex == 1,
              onTap: () => onChanged(1),
            ),
            _TabPill(
              label: 'Notifications',
              isSelected: selectedIndex == 2,
              onTap: () => onChanged(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? MainColors.accent.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
            color: isSelected
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify analyze passes**

Run: `fvm flutter analyze lib/presentation/pages/circle_hub/circle_hub_page.dart`

Expected: No new errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/pages/circle_hub/circle_hub_page.dart
git commit -m "feat: CircleHubPage with 3-tab glass toggle"
```

---

### Task 3: Wire Existing Views into CircleHubPage

**Files:**
- Modify: `lib/presentation/pages/circle_hub/circle_hub_page.dart`

**Context:** Replace the 3 placeholder `Center(child: Text(...))` widgets in the `IndexedStack` with the real views:
- Index 0: `FriendsLockedOutView` from `lib/presentation/pages/friends_locked_out/views/friends_locked_out_view.dart` — wrap in `SafeArea` as the original `FriendsLockedOutPage` does.
- Index 1: `YourCircleView` from `lib/presentation/pages/your_circle/views/your_circle_view.dart`
- Index 2: `NotificationsView` from `lib/presentation/pages/notifications/views/notifications_view.dart`

- [ ] **Step 1: Add imports and replace IndexedStack children**

Add these imports to `circle_hub_page.dart`:

```dart
import 'package:cloudless/presentation/pages/friends_locked_out/views/friends_locked_out_view.dart';
import 'package:cloudless/presentation/pages/your_circle/views/your_circle_view.dart';
import 'package:cloudless/presentation/pages/notifications/views/notifications_view.dart';
```

Replace the `IndexedStack` children:

```dart
IndexedStack(
  index: tabIndex.value,
  children: const [
    SafeArea(child: FriendsLockedOutView()),
    YourCircleView(),
    NotificationsView(),
  ],
),
```

- [ ] **Step 2: Verify analyze passes**

Run: `fvm flutter analyze lib/presentation/pages/circle_hub/circle_hub_page.dart`

Expected: No new errors.

- [ ] **Step 3: Commit**

```bash
git add lib/presentation/pages/circle_hub/circle_hub_page.dart
git commit -m "feat: wire FriendsLockedOutView, YourCircleView, NotificationsView into CircleHubPage"
```

---

### Task 4: Add FeedCircleHubButton to FeedView

**Files:**
- Create: `lib/presentation/pages/feed/components/feed_circle_hub_button.dart`
- Modify: `lib/presentation/pages/feed/views/feed_view.dart`
- Modify: `lib/presentation/pages/feed/feed_layout.dart`

**Context:** The button is a plain glass circle positioned top-right of the feed, vertically aligned with `FeedDateOverlay` (at `safeTop + 8 * s`). It uses the same glass style as the lockout button (clear variant, accent tint). When unread notifications or incoming friend requests exist, the tint switches to red — same approach as `FeedDateOverlay` (line 39: `MainColors.red500.withValues(alpha: 0.35)`).

- [ ] **Step 1: Add layout constants to FeedLayout**

In `lib/presentation/pages/feed/feed_layout.dart`, add after the date overlay constants (after line 42):

```dart
  // -- Circle hub button --
  static const double circleHubButtonSize = 32.0;
  static const double circleHubButtonRight = 16.0;
```

- [ ] **Step 2: Create FeedCircleHubButton widget**

```dart
// lib/presentation/pages/feed/components/feed_circle_hub_button.dart
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/circle_hub/circle_hub_routable.dart';
import 'package:cloudless/presentation/pages/feed/feed_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class FeedCircleHubButton extends StatelessWidget {
  const FeedCircleHubButton({
    super.key,
    this.hasUnread = false,
  });

  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final s = screenWidth / 402.0;
    final size = FeedLayout.circleHubButtonSize * s;

    return GestureDetector(
      onTap: () => router.push(const CircleHubRoutable()),
      child: SizedBox(
        width: size,
        height: size,
        child: AppGlassContainer(
          config: GlassConfig(
            variant: GlassVariant.clear,
            cornerRadius: size / 2,
            tint: hasUnread
                ? MainColors.red500.withValues(alpha: 0.35)
                : MainColors.accent,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Add the button to FeedView._buildStack()**

In `lib/presentation/pages/feed/views/feed_view.dart`, add the import:

```dart
import 'package:cloudless/core/features/connection/domain/providers/get_outgoing_requests_provider.dart';
import 'package:cloudless/presentation/pages/feed/components/feed_circle_hub_button.dart';
```

In `_buildStack()`, after the existing `hasUnread` variable (line 409-414), add a check for incoming friend requests:

```dart
    final hasIncomingRequests = ref
        .watch(getIncomingRequestsProvider)
        .maybeWhen(
          data: (r) => r.fold((list) => list.isNotEmpty, (_) => false),
          orElse: () => false,
        );
```

Then add a new `Positioned` widget in the Stack children, after the date overlay `Positioned` (after line 462) and before the new posts banner:

```dart
        // Circle hub button — top right, aligned with date overlay
        Positioned(
          top: safeTop + 8 * s,
          right: FeedLayout.circleHubButtonRight * s,
          child: FeedCircleHubButton(
            hasUnread: hasUnread || hasIncomingRequests,
          ),
        ),
```

- [ ] **Step 4: Verify analyze passes**

Run: `fvm flutter analyze lib/presentation/pages/feed/`

Expected: No new errors.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/pages/feed/
git commit -m "feat: add glass circle hub button to FeedView top-right"
```

---

### Task 5: Unify Circle Search to Include External Users

**Files:**
- Modify: `lib/presentation/pages/your_circle/views/your_circle_view.dart`

**Context:** Currently `YourCircleView` has a `YourCircleSearchPill` at the bottom that filters circle members locally via `circleMembersData.updateSearchQuery()`. The goal is to make this search ALSO query external users (via `useSearchUsers`) when text is entered, and show both sets of results — circle members with rank/stats, external users with a "Send request" button.

The circle member filtering uses `circleMembersData.searchQuery` applied to the leaderboard entries (lines 87-96). The external user search uses `useSearchUsers(ref)` from `lib/core/features/connection/domain/hooks/use_search_users.dart`.

The `SearchResultTile` and `ConnectionRequestsData` are from `connection_requests_view.dart` — we reuse those widgets.

- [ ] **Step 1: Add imports for search and request hooks/widgets**

Add to the imports in `your_circle_view.dart`:

```dart
import 'package:cloudless/core/features/connection/domain/hooks/use_search_users.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_connection_requests.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_outgoing_requests_provider.dart';
import 'package:cloudless/core/features/connection/domain/providers/search_users_provider.dart';
import 'package:cloudless/presentation/pages/your_circle/components/connection_request_tiles.dart';
```

- [ ] **Step 2: Add search hooks to the build method**

In `YourCircleView.build()`, after `final searchController = useTextEditingController();` (line 39), add:

```dart
    final externalSearch = useSearchUsers(ref);
    final requestsData = useConnectionRequests(ref);
```

- [ ] **Step 3: Modify the search pill onSearchChanged to update both searches**

Replace the `YourCircleSearchPill` in the bottom bar (lines 175-179) — change `onSearchChanged` to update both the local circle filter and the external search:

```dart
                        YourCircleSearchPill(
                          searchQuery: circleMembersData.searchQuery,
                          onSearchChanged: (query) {
                            circleMembersData.updateSearchQuery(query);
                            externalSearch.updateQuery(query);
                          },
                          controller: searchController,
                        ),
```

- [ ] **Step 4: Add external search results below the leaderboard when searching**

In the Stack children, after the `ListView.builder` for the leaderboard (after line 150), add a widget that shows external search results when the search query is non-empty. Insert this before the `// Layer 1: Fixed bottom bar` comment (before line 152):

```dart
            // Layer 0b: External search results (shown when searching)
            if (searchQuery.isNotEmpty && externalSearch.results.isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: (removeMode.value
                        ? removeButtonHeight
                        : searchPillHeight) +
                    bottomBarBottomPadding +
                    bottomPad +
                    24,
                top: topPad + 16,
                child: Column(
                  children: [
                    // Leaderboard results are handled by the existing ListView above.
                    // External (non-circle) results below:
                    if (filtered.isEmpty && externalSearch.results.isEmpty)
                      const SizedBox.shrink()
                    else if (externalSearch.results.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: externalSearch.results.length,
                          itemBuilder: (context, index) {
                            final (profile, status) =
                                externalSearch.results[index];
                            return SearchResultTile(
                              profile: profile,
                              status: status,
                              isCircleFull: isFull,
                              onConnect: () {
                                requestsData.send(profile.id).then((result) {
                                  result.fold((value) {
                                    ref.invalidate(
                                      searchUsersProvider(
                                        externalSearch.query,
                                      ),
                                    );
                                    ref.invalidate(getOutgoingRequestsProvider);
                                    if (value == 'auto_accepted') {
                                      ref.invalidate(getCircleMembersProvider);
                                      ref.invalidate(
                                        getCircleLeaderboardProvider,
                                      );
                                    }
                                  }, (_) {});
                                });
                              },
                              onAccept: () {},
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
```

**Note:** This approach overlays external results on top of the filtered leaderboard. A cleaner approach may be to combine both result sets into a single list. The implementer should evaluate whether the overlay or a merged list works better visually — if the leaderboard already shows filtered circle members AND external results should appear below them, consider replacing the `ListView.builder` entirely with a combined list when `searchQuery.isNotEmpty`. The key requirement is: circle members show `LeaderboardTile`, external users show `SearchResultTile`.

- [ ] **Step 5: Verify analyze passes**

Run: `fvm flutter analyze lib/presentation/pages/your_circle/views/your_circle_view.dart`

Expected: No new errors.

- [ ] **Step 6: Commit**

```bash
git add lib/presentation/pages/your_circle/views/your_circle_view.dart
git commit -m "feat: unify circle search to query both members and external users"
```

---

### Task 6: Remove Circle and Notifications Icons from HomeNavigationBar

**Files:**
- Modify: `lib/presentation/pages/home/components/home_navigation_bar.dart`

**Context:** The `HomeNavigationBar` (used in `HomePage`) currently has 5 items in a `Row`: logo, profile, friends-locked-out, circle, and notifications. Remove the circle icon (lines 72-86) and the notifications icon (lines 88-167). Keep logo, profile, and friends-locked-out.

- [ ] **Step 1: Remove the Circle GestureDetector**

Remove the Circle icon block (lines 72-86 in `home_navigation_bar.dart`):

```dart
              // Circle — REMOVE THIS BLOCK
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => router.push(const YourCircleRoutable()),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: SizedBox(
                      width: navCircleButtonSize,
                      height: navCircleButtonSize,
                      child: Assets.svg.yourCircle.render(),
                    ),
                  ),
                ),
              ),
```

- [ ] **Step 2: Remove the Notifications GestureDetector**

Remove the entire `currentUserAsync.when(...)` block (lines 88-167) that renders the notifications bell icon.

- [ ] **Step 3: Remove unused imports**

Remove these imports that are no longer needed:

```dart
import 'package:cloudless/core/features/notification/domain/hooks/use_unread_notification_count.dart';
import 'package:cloudless/presentation/pages/notifications/notifications_routable.dart';
import 'package:cloudless/presentation/pages/your_circle/your_circle_routable.dart';
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
```

Check which imports are still used by the remaining code (logo, profile, friends-locked-out) before removing. The `Assets` import may still be needed if the logo uses it. The `MainColors` import may still be needed.

- [ ] **Step 4: Verify analyze passes**

Run: `fvm flutter analyze lib/presentation/pages/home/components/home_navigation_bar.dart`

Expected: No new errors.

- [ ] **Step 5: Commit**

```bash
git add lib/presentation/pages/home/components/home_navigation_bar.dart
git commit -m "feat: remove Circle and Notifications icons from HomeNavigationBar"
```

---

### Task 7: Manual Smoke Test

**Files:** None (testing only)

- [ ] **Step 1: Run the app**

Run: `fvm flutter run --flavor production`

- [ ] **Step 2: Verify FeedView**

- The glass circle button appears top-right, vertically aligned with the date pill
- Button is a plain glass circle with accent tint
- If you have unread notifications or pending friend requests, it tints red

- [ ] **Step 3: Verify CircleHubPage**

- Tap the glass circle → CircleHubPage opens
- 3-tab toggle shows: Lockouts | Circle | Notifications
- Default tab is Lockouts (index 0)
- Switching tabs works, content renders correctly
- Lockouts tab shows friends locked out list
- Circle tab shows leaderboard with bottom search bar
- Notifications tab shows notification list

- [ ] **Step 4: Verify unified search**

- In Circle tab, type a username in the search bar
- Circle members matching the query appear as `LeaderboardTile`
- Non-circle users appear as `SearchResultTile` with "Send request" button
- Clear search → leaderboard reappears

- [ ] **Step 5: Verify HomeNavigationBar**

- If `HomePage` is reachable, verify Circle and Notifications icons are gone
- Profile, logo, friends-locked-out still work

- [ ] **Step 6: Final commit if any fixes needed**

```bash
git add -A
git commit -m "fix: smoke test adjustments for circle hub"
```
