# UX Flow Analysis: Emotional Touchpoints & Opportunities

## Executive Summary

goback is philosophically ambitious -- a social app that treats disconnection as a feature, not a bug. The codebase reveals a product that has nailed the core mechanic (lockout + share) with a genuinely novel cutout-effect lockout screen, but leaves significant emotional potential unrealized in nearly every other flow. The app currently reads as functional rather than evocative. The biggest gaps are: (1) transitions between emotional states lack ceremony, (2) empty states are utilitarian rather than warm, (3) the 24h content lifecycle is invisible to users (no countdown, no farewell), and (4) the circle/connection system treats relationships as binary (connected/not) rather than layered.

Key findings:
- The lockout flow is the strongest emotional moment in the app, with the sky-cutout timer, goback score, and friends overlay. This is the product's signature experience.
- Onboarding is informational rather than experiential -- it tells users what the app does instead of making them feel why it matters.
- Content disappearance (the 24h expiry) happens silently -- the most philosophically important feature has zero user-facing ceremony.
- Circle management is transactional (list + invite code) rather than ceremonial -- joining someone's circle should feel like being welcomed into a home, not submitting a form.
- The "memorable post selection" dialog is a brilliant concept (choosing one post to save to your calendar) but its current presentation undersells its emotional weight.

---

## Flow-by-Flow Analysis

### 1. Onboarding / First Launch

**Current Steps:**
1. Objective page shows mission text ("Your brain evolved for tribes, not timelines...") with "Continue" button
2. Sign-in page with phone number input + privacy checkbox
3. OTP verification page with 6-digit code
4. Create profile page (avatar, username, bio)
5. Home page with 4-step onboarding overlay (glass cards with dot pagination)

**Emotional Journey:**
- User arrives curious (probably invited by a friend)
- Objective page is the first emotional contact -- reads as a manifesto
- Sign-in is standard/clinical -- phone number entry
- OTP is standard friction
- Profile creation is generic (identical to any social app)
- Onboarding overlay is educational but not inspiring

**Friction Points:**
- The objective page text ("goback is the network built around your neurochemistry") is intellectual, not visceral. Users arriving via friend invite want to understand what they'll *experience*, not what neurochemistry means.
- No visual illustration of the 24h content concept, lockout concept, or circle concept during onboarding.
- The 4-step onboarding overlay (steps 1-4) is text-heavy. Step 2 says "Press and hold anywhere to open the menu" -- this is navigational instruction, not emotional onboarding.
- Profile creation has no warmth -- "Create your profile" is procedural. No sense of "you're about to enter someone's circle."

**Moments of Delight:**
- The glass card overlay with step dots has pleasant visual treatment.
- The `GobackLogo` is used consistently as a brand anchor.

**Missed Opportunities:**
- No mention during onboarding of *who invited them* (the friend who shared the invite code). This is the strongest emotional hook available -- "Sarah invited you to her circle" would create immediate belonging.
- No preview of what the lockout experience feels like. The signature feature is invisible until the user discovers it.
- The transition from "objective" to "sign in" is abrupt. The philosophical statement about meaningful connection leads directly into a phone number form.
- No "first circle" celebration when the user joins their first friend's circle.

**Key File References:**
- `lib/presentation/pages/objective/views/objective_view.dart`
- `lib/presentation/pages/sign_in/views/sign_in_view.dart`
- `lib/presentation/pages/otp/views/otp_view.dart`
- `lib/presentation/pages/create_profile/views/create_profile_view.dart`
- `lib/presentation/components/onboarding/onboarding_overlay.dart`
- `assets/translations/en.json` (pages.objective, pages.onboarding)

---

### 2. Authentication (Sign-in + OTP)

**Current Steps:**
1. Phone number input with country selector
2. Privacy policy checkbox
3. Submit -> loading overlay
4. OTP page with formatted phone number display
5. 6-digit code entry
6. "Resend code" option
7. Submit -> loading overlay -> navigate to profile creation or home

**Emotional Journey:**
- Standard authentication friction. User is task-focused (get past this to see what my friend shared).
- OTP wait creates anxiety/impatience.

**Friction Points:**
- The `useLoadingOverlay` shows a generic loading indicator during submission. No reassuring copy.
- OTP resend has no countdown timer visible -- user doesn't know when they can resend.
- Error states are alert dialogs (`MainAlert.showError`) which are jarring and feel like failures rather than gentle guidance.

**Moments of Delight:**
- Phone number is formatted in the OTP description, showing the user their number for confirmation.

**Missed Opportunities:**
- No "almost there" micro-copy during OTP verification.
- Paste detection works (`Code Detected` dialog) but the dialog is utilitarian.
- No gentle animation or reassurance during the wait between SMS send and code entry.

**Key File References:**
- `lib/presentation/pages/sign_in/views/sign_in_view.dart`
- `lib/presentation/pages/otp/views/otp_view.dart`
- `lib/core/features/auth/domain/hooks/use_sign_in_form.dart`
- `lib/core/features/auth/domain/hooks/use_otp_form.dart`

---

### 3. Home / Feed

**Current Steps:**
1. Home page loads with navigation bar (logo, profile avatar, lockouts, circle, notifications)
2. If no circle members -> "Hi @username, Invite your close friends and goback. to life" with Invite/Join buttons
3. If circle members but no posts -> loading state, then empty feed with background image
4. If posts exist -> scrollable feed with squircle post cards, date badge overlay
5. Lockout button always visible at bottom-left
6. New posts banner appears when scrolled away and new content arrives
7. Scroll indicator on right side when not at top

**Emotional Journey:**
- First-time user with no circle: loneliness/anticipation (empty state with call to action)
- User with circle but no posts: quiet/waiting
- Active feed: connection/curiosity (seeing friends' content)
- New posts arriving: anticipation/FOMO (but healthy FOMO -- it's from their actual friends)

**Friction Points:**
- The empty state when user has a circle but no one has posted is a plain `CircularProgressIndicator` followed by nothing. There's no "all quiet" message or encouragement to start a lockout.
- The `HomeCircleActionsWidget` is functional but emotionally flat -- "Hi @username" followed by invite buttons is procedural.
- The `HomeDateBadge` shows dates but has no context for temporal meaning (this is today's feed, these posts expire at midnight, etc.).
- Loading states throughout use generic `CircularProgressIndicator` with no personality.

**Moments of Delight:**
- The background image behind the feed creates atmosphere.
- The new posts banner with count creates gentle pull without being aggressive.
- Auto-scroll to top on post creation (300ms easeOut) gives satisfying feedback.
- The `AppGlassContainer` glass effects throughout give a premium feel.

**Missed Opportunities:**
- No countdown or visual indication that posts will disappear. The 24h expiry is the product's defining feature but is completely invisible in the feed.
- No "last moments" or "fading away" effect on posts approaching their 24h expiry.
- The feed empty state with a circle present could acknowledge the time of day: "Morning quiet" vs "Evening peace" to normalize having no content.
- The date badge could become a meaningful anchor: "Today" vs "Yesterday" rather than just a date.
- No visual differentiation for lockout posts vs regular posts in the feed.

**Key File References:**
- `lib/presentation/pages/home/home_page.dart`
- `lib/presentation/pages/home/views/home_view.dart`
- `lib/presentation/pages/feed/views/feed_view.dart`
- `lib/presentation/pages/home/components/home_navigation_bar.dart`
- `lib/presentation/pages/home/components/home_circle_actions_widget.dart`
- `lib/presentation/pages/home/components/home_lockout_button.dart`

---

### 4. Content Creation (Post Flow)

**Current Steps:**
1. From lockout completion: media picker opens -> content editor with glass card overlay
2. From regular flow: content type picker (Photo/Video/Text) -> media picker -> content editor
3. Content editor: media preview, description field with @mentions, date display
4. "Continue" button -> Publish page with member selection (select all/deselect all, search, per-user toggle)
5. "Publish" button -> loading overlay -> success snackbar -> navigate home
6. Lockout post variant: glass card editor with squircle preview, Share button, restrict visibility link -> direct publish

**Emotional Journey:**
- Post-lockout: user just spent time offline, feeling present/accomplished. They want to share their real-world experience. Emotional peak moment.
- Regular post: more casual/intentional. User has something to share with their circle.
- Member selection: forced moment of intentionality (who should see this?). This aligns with the product philosophy.

**Friction Points:**
- The distinction between lockout posts and regular posts is architectural (different view: `LockoutPostEditorView` vs `ContentEditorView`) but not emotionally communicated. The user doesn't understand why the experience is different.
- The publish page with individual member selection is powerful philosophically (conscious sharing) but slow in practice. Selecting 50+ friends individually is tedious. The select all/deselect all helps but still requires scrolling through the entire list.
- Video thumbnail extraction (`isExtractingThumbnail`) shows no user-facing feedback about what's happening.
- Error messages on publish failure are generic: "Error publishing post. Please try again."

**Moments of Delight:**
- The lockout glass card editor is visually distinctive and premium-feeling.
- The "restrict visibility" link with dynamic count ("restricted to X people") gives real-time feedback.
- The description hint "Tell about this moment..." is emotionally warmer than standard placeholder text.
- Success snackbar confirms publication.

**Missed Opportunities:**
- No preview of how the post will look in the feed before publishing.
- No reminder that this post will disappear in 24h -- this could be reframed positively: "This moment will live for 24 hours."
- The description field could suggest prompts based on lockout context (e.g., "What did you do while you were away?").
- No celebration animation on successful publish -- just a snackbar. Creating content is the primary value exchange; it deserves more ceremony.
- The member selection could default to "Everyone" with the option to exclude, rather than requiring explicit selection (which it seems to do via `memberExclusionData`). This is actually correct but the UX framing could be clearer.

**Key File References:**
- `lib/presentation/pages/content_editor/content_editor_page.dart`
- `lib/presentation/pages/content_editor/views/content_editor_view.dart`
- `lib/presentation/pages/content_editor/views/lockout_post_editor_view.dart`
- `lib/presentation/pages/publish_content/views/publish_content_view.dart`
- `lib/presentation/pages/visibility_selection/visibility_selection_page.dart`

---

### 5. Content Viewing (Post Detail)

**Current Steps:**
1. Tap post in feed -> `PostDetailPage.show()` with `FadeTransition` (350ms in, 250ms out)
2. Post detail overlay appears on transparent background (tap outside to dismiss)
3. From calendar: post detail as modal bottom sheet with navigation arrows (previous/next post)
4. Post includes reactions, comments, edit/delete/hide/report options via action menu

**Emotional Journey:**
- Curiosity -> engagement (viewing friend's post)
- Calendar context: nostalgia/reflection (viewing past memories)

**Friction Points:**
- Tap-outside-to-dismiss on the feed overlay means accidental dismissal is easy. Users engaged with a post can lose it with a misplaced tap.
- Calendar navigation arrows (previous/next post) have loading states but no skeleton or placeholder -- the post just disappears while the next one loads.

**Moments of Delight:**
- The `FadeTransition` is smooth (350ms in, 250ms out).
- Calendar integration gives posts a second life beyond the 24h window (for posts the user chose to save).
- Post navigation in calendar view (prev/next arrows) allows browsing memories chronologically.

**Missed Opportunities:**
- No visual indicator of post age ("posted 3 hours ago" vs "disappears in 2 hours").
- No "last chance to save" prompt for posts approaching their 24h expiry.
- The reaction system exists but there's no visible emotional response to receiving reactions (no push notification moment, no animation on the post).
- Comments could show read receipts or typing indicators to create real-time connection feeling.

**Key File References:**
- `lib/presentation/pages/post_detail/post_detail_page.dart`
- `lib/presentation/pages/post_detail/views/post_detail_view.dart`
- `lib/presentation/pages/post_detail/views/post_detail_overlay.dart`

---

### 6. Lockout Flow (The Signature Experience)

**Current Steps:**
1. Tap lockout button (bottom-left of home, or triangle in feed) -> `ManualLockoutDialog` (time picker + optional activity text)
2. Select duration (1-9 hours, in 15-minute increments) + optional activity description (20 char max)
3. Confirm -> navigate to `ManualLockoutPage` (full-screen, cannot go back via `PopScope(canPop: false)`)
4. Lockout screen: solid color background with transparent cutout holes revealing sky image. Timer text is cut out of the solid layer showing sky through the numbers. Triangle shape also cut out.
5. Long-press anywhere reveals `LockoutFriendsOverlay` (blur + list of friends also locked out with their remaining time, activity text, and "same lockout" accent border)
6. Timer counts down. When complete:
   - Triangle fades out (300ms)
   - "Share your goback" + "Skip" text fades in (400ms) through cutout effect
   - Goback score displayed (score/100 | duration) via cutout
7. Share -> opens media picker -> `LockoutPostEditorView` (glass card with squircle)
8. Skip -> completes session without post, clears storage, navigates home
9. Alternative: if app was backgrounded during lockout and timer ended, user returns to `ManualLockoutPage` which detects completion and shows the same share/skip prompt

**Emotional Journey:**
- Pre-lockout: intentionality/commitment (choosing to disconnect)
- During lockout: calm/present (the app is literally locked, showing only a beautiful countdown)
- Friends overlay (long-press): solidarity/belonging ("others are doing this too")
- Lockout complete: accomplishment/return (the score quantifies the quality of disconnection)
- Share prompt: reflection/expression ("what did you do while away?")

**Friction Points:**
- The `ManualLockoutDialog` is a standard Material dialog with Cupertino pickers. This is the moment of commitment to disconnect -- it should feel more ceremonial.
- The activity text field ("What are you doing?") is limited to 20 characters and is optional. Its purpose isn't clearly communicated.
- The minimum duration of 1 hour with 15-minute granularity is rigid. Users might want 30 or 45 minutes for a quick break.
- The goback score calculation (battery drain as proxy for phone-down time) is clever but unexplained to the user. The score label "score / 100 | time" appears on completion but users don't know what it means or how to improve it.
- If no friends are locked out, the friends overlay shows "No friends locked out" which is deflating.

**Moments of Delight:**
- The cutout effect is genuinely novel and beautiful. The timer text is see-through, revealing a sky/landscape image beneath. This is the app's strongest visual moment.
- The friends overlay (long-press discovery) creates a sense of secret/discovery.
- The accent border on friends in the same lockout session creates belonging.
- The completion transition (triangle fades, text appears) is elegant.
- The battery-based score gamifies real disconnection without being manipulative.

**Missed Opportunities:**
- No sound or haptic feedback at lockout completion. This is a significant life moment (returning from intentional disconnection) that deserves tactile celebration.
- The score is displayed but not contextualized. "Your score: 87" means nothing without benchmarks, personal history, or explanation.
- No historical view of past lockout scores/durations to track personal growth.
- The friends overlay could show what activity each friend chose (already shows `actionText`) but doesn't explain what the accent border means.
- No ability to "join" a friend's lockout from the lockout screen itself (only from `FriendsLockedOutPage` before starting).
- The skip option ("Skip") after lockout feels dismissive of the experience. Reframing as "Keep it private" or "Just for me" would honor the offline time even without sharing.

**Key File References:**
- `lib/presentation/pages/home/components/home_lockout_button.dart`
- `lib/presentation/pages/home/components/manual_lockout_dialog.dart`
- `lib/presentation/pages/manual_lockout/views/manual_lockout_view.dart` (cutout painter, completion logic)
- `lib/presentation/pages/manual_lockout/components/lockout_friends_overlay.dart`
- `lib/presentation/pages/lockout_complete/views/lockout_complete_view.dart`
- `lib/core/features/lockout/domain/utilities/goback_score_calculator.dart`
- `lib/presentation/components/lockout_listener_widget.dart`

---

### 7. Friends Locked Out / Join Lockout

**Current Steps:**
1. Navigate from home nav bar (people icon) -> `FriendsLockedOutPage`
2. List of friends currently in lockout sessions (avatar, username, activity, remaining time)
3. "Join" button appears for sessions with >30 minutes remaining
4. Tap Join -> joins the same lockout session -> navigates to lockout screen

**Emotional Journey:**
- Discovery: "who's offline right now?" -- creates connection through shared absence
- Decision: "should I join them?" -- social motivation to disconnect together
- Post-join: solidarity (same lockout session, accent border in overlay)

**Friction Points:**
- The "Join" button has a 30-minute minimum requirement (`_minJoinableMinutes = 30`). This is a UX cliff -- the button simply disappears without explanation when time is too short.
- The empty state ("No friends locked out") is a single line of text. When no friends are offline, this page offers nothing.
- Navigating to this page requires going through the nav bar, which means it's not easily discoverable.

**Moments of Delight:**
- Real-time countdown updates (polling every minute).
- The "Join" interaction creates a sense of joining someone's decision.
- Activity text ("hiking", "reading") adds personal context.

**Missed Opportunities:**
- No notification when a friend starts a lockout. The push notification types include `lockoutStarted` and `lockoutJoined` but these are filtered OUT of the notifications view (`n.type != NotificationType.lockoutStarted`).
- No history of past joint lockouts. "You and Sarah have locked out together 5 times" would build relationship narrative.
- No ability to send a message/encouragement to a friend currently locked out.
- Could show a subtle indicator in the nav bar when friends are locked out (similar to the notification badge).

**Key File References:**
- `lib/presentation/pages/friends_locked_out/friends_locked_out_page.dart`
- `lib/presentation/pages/friends_locked_out/views/friends_locked_out_view.dart`

---

### 8. Circle Management

**Current Steps:**
1. Navigate from home nav bar (circle icon) -> `YourCirclePage`
2. Two tabs: "Circle" (member list) and "Requests" (connection requests)
3. Circle tab: reverse-scrolling list of members with swipe-to-delete
4. Add menu (+ button) with options to invite or join
5. When circle reaches 150: "Your circle is full!" alert (one-time), + button replaced by minus pill for remove mode
6. Invite flow: phone number input with live account checking, contacts list with SMS invite
7. Join flow: code input -> confirmation dialog -> connection created

**Emotional Journey:**
- Circle browsing: belonging/warmth (seeing your people)
- Inviting: sharing/generosity ("come join my space")
- Joining: acceptance/excitement ("I'm being included")
- Removing: sadness/necessity (the remove confirmation copy is actually good: "True bonds deserve attention...")

**Friction Points:**
- The invite flow goes through SMS, which is a high-friction channel. Users must leave the app, open Messages, and send.
- The join flow requires manually entering a code received via SMS. No deep linking or QR code option.
- The "Requests" tab concept exists as `ConnectionRequestsView` but its content and flow aren't obvious from the page-level code.
- The 150-member limit feels arbitrary without explanation. The one-time alert says "You've reached the maximum of 150 connections" but doesn't explain the Dunbar's number reasoning.
- Member list is a flat reverse-scrolling list with no organization or context (when did they join? how active are they?).

**Moments of Delight:**
- The glass tab toggle at the top (Circle/Requests) with animated container is polished.
- Remove confirmation copy ("True bonds deserve attention. If you remove them, you will no longer see your moments here... but you can always create new ones.") is emotionally aware.
- Phone number live-check shows whether the number has a goback account (green accent dot).
- The circle-full alert uses glass container with accent tint -- premium feel.

**Missed Opportunities:**
- No celebration when a new member joins the circle. This is a relationship-defining moment.
- No visual representation of circle health/activity. A "circle pulse" showing how active the group is would reinforce belonging.
- Join by code is functional but not warm. "Sarah wants to connect with you" would be better than entering a 6-digit code.
- No history of who invited whom (the relationship origin story).
- The 150-member limit should be explained in the context of Dunbar's number and the app's philosophy, not as a technical constraint.

**Key File References:**
- `lib/presentation/pages/your_circle/your_circle_page.dart`
- `lib/presentation/pages/your_circle/views/your_circle_view.dart`
- `lib/presentation/pages/invite_to_circle/views/invite_to_circle_view.dart`
- `lib/presentation/pages/join_circle/views/join_circle_view.dart`
- `lib/presentation/pages/review_circle/review_circle_page.dart`

---

### 9. Profile

**Current Steps:**
1. Own profile: avatar, username, bio, weekly lockout stats, calendar grid with month navigation
2. Circle member profile (`CircleProfilePage`): same layout + back button + hamburger menu with remove/report/block options
3. External profile (`ExternalProfilePage`): avatar, username, bio only -- no calendar, no actions

**Emotional Journey:**
- Own profile: self-reflection (seeing your offline time stats, calendar of saved memories)
- Friend's profile: appreciation/curiosity (their history, their offline commitment)
- External profile: neutral assessment (deciding whether to connect)

**Friction Points:**
- The weekly stats ("X hours offline this week") are plain text. No visualization, no trend, no comparison.
- The calendar grid exists but its emotional weight isn't communicated -- these are the moments the user chose to preserve from the ephemeral feed.
- Profile editing (hamburger menu -> dropdown) is hidden behind a small icon. The dropdown is a simple Column of GestureDetectors.

**Moments of Delight:**
- Weekly lockout stats make offline time visible and valued.
- The calendar preserves chosen memories beyond the 24h window -- this is a beautiful concept.
- The scale-aware layout (`screenWidth / designWidth`) ensures visual consistency across devices.

**Missed Opportunities:**
- The calendar could show the *type* of offline activity (from lockout action text) alongside saved posts.
- No streak tracking for consistent lockout practice.
- Friend profiles could show mutual lockout history ("You've gone offline together X times").
- The "hours offline this week" could be visualized as a ring or progress bar with a weekly goal.
- No bio character count feedback during editing.

**Key File References:**
- `lib/presentation/pages/profile/profile_page.dart`
- `lib/presentation/pages/profile/views/profile_view.dart`
- `lib/presentation/pages/circle_profile/circle_profile_page.dart`
- `lib/presentation/pages/external_profile/external_profile_page.dart`
- `lib/presentation/pages/profile/components/calendar_section/profile_calendar.dart`
- `lib/presentation/pages/profile/components/profile_weekly_stats.dart`

---

### 10. Notifications

**Current Steps:**
1. Navigate from home nav bar (bell icon) -> `NotificationsPage`
2. List of aggregated notifications (reactions, tags, comments, connection requests, friend joins)
3. Auto-mark all as read after 1.5 seconds
4. Connection request notifications have Accept/Deny buttons (Accept disabled when circle is full)
5. Tap notification -> navigate to relevant content (post detail, profile, etc.)
6. Badge (red dot) on nav bar icon when unread notifications exist

**Emotional Journey:**
- Arriving at notifications: anticipation ("who engaged with my content?")
- Seeing reactions: validation/warmth
- Connection requests: excitement/consideration
- Empty notifications: quiet/acceptance

**Friction Points:**
- Lockout-related notifications (`lockoutStarted`, `lockoutJoined`) are explicitly filtered out of the view. These are arguably the most unique and emotionally relevant notifications in the app.
- The 1.5-second auto-mark-as-read means users can't distinguish which specific notifications are new. The unread state is effectively meaningless.
- Error states show raw error messages: `Error loading notifications: ${error.toString()}` -- this is developer-facing text.
- The notification empty state uses `NotificationEmptyState` but the translation suggests only two options: "No notifications yet" or "Nothing new -- enjoy the quiet." The second one is better but they seem to be separate keys.

**Moments of Delight:**
- "Nothing new -- enjoy the quiet." as the empty state is philosophically aligned and emotionally warm.
- Aggregated notifications (e.g., "Sarah and 3 others reacted to your post") reduce noise.
- The notification badge is a subtle 8x8 dot rather than an aggressive count badge.

**Missed Opportunities:**
- Lockout notifications should be celebrated, not hidden. "Sarah went offline for 3 hours" is exactly the kind of notification this app should amplify.
- No notification grouping by time (today vs yesterday).
- No rich preview of the post that received a reaction/comment.
- The Accept/Deny buttons for connection requests are functional but could include the requester's context (mutual friends, how they found you).

**Key File References:**
- `lib/presentation/pages/notifications/notifications_page.dart`
- `lib/presentation/pages/notifications/views/notifications_view.dart`
- `lib/presentation/pages/notifications/components/notification_item.dart`
- `lib/presentation/pages/notifications/components/notification_empty_state.dart`

---

### 11. Memorable Post Selection (Calendar Save)

**Current Steps:**
1. On new day, if user has unsaved lockout posts from yesterday -> `MemorablePostSelectionDialog` appears
2. Dialog shows "Save to Calendar" title, "Choose one post from yesterday to save to your calendar"
3. List of eligible posts with thumbnails and descriptions
4. Tap a post to save it directly
5. "Skip for today" to dismiss

**Emotional Journey:**
- Surprise: user doesn't expect this prompt
- Reflection: reviewing yesterday's moments, deciding which one to preserve
- Commitment: choosing one post means declaring it "memorable"

**Friction Points:**
- The dialog is `barrierDismissible: false` -- user is forced to interact. This is correct philosophically (force the reflection) but may feel intrusive.
- Posts without descriptions show "No description" in italic -- this looks like an error rather than an opportunity ("This moment speaks for itself").
- Only shows posts from lockout sessions, not all posts from yesterday. Users may want to save a non-lockout post.

**Moments of Delight:**
- The concept itself is the delight -- forcing a daily reflection on what's worth keeping.
- Single selection (not multi-select) forces prioritization.

**Missed Opportunities:**
- No context for *why* this matters -- "Your posts from yesterday have disappeared. Choose one to keep forever." would add emotional weight.
- No animation or celebration when a post is saved to the calendar.
- The dialog could show a mini-calendar visualization showing where this post will appear.
- Could include a short text prompt: "Why is this one worth remembering?"

**Key File References:**
- `lib/presentation/pages/home/components/memorable_post_selection_dialog.dart`
- `lib/core/features/calendar/domain/providers/pending_selection_provider.dart`

---

### 12. Time Limit (Daily Usage)

**Current Steps:**
The time limit feature exists in `lib/core/features/time_limit/` but the presentation layer has only generated routable files (`time_limit_reached_routable.freezed.dart`, `.g.dart`) with no actual page implementation found. The feature appears to be architecturally present but not yet implemented in the UI.

**Emotional Journey:**
N/A -- feature appears incomplete.

**Missed Opportunities:**
- This is a significant philosophical opportunity. Daily usage limits are core to the product thesis. When implemented, the time-limit-reached experience should feel like a gentle nudge ("You've been here long enough today. Time to goback.") rather than a hard block.
- Could show what the user's circle is doing offline to encourage disconnection.

**Key File References:**
- `lib/core/features/time_limit/` (data + domain layers)
- `lib/presentation/pages/time_limit_reached/` (only generated routable files)

---

### 13. Settings

**Current Steps:**
1. Navigate from profile hamburger menu -> Settings page
2. Sections: Account (phone number, delete account), Preferences (objective, notifications), Assistance and Legal (assistance, privacy, terms)
3. Logout at bottom

**Emotional Journey:**
- Utilitarian. Users visit settings for specific purposes, not browsing.

**Friction Points:**
- Delete account copy ("You will lose all your memories and circles") is appropriately serious but the confirmation buttons ("Yes, delete the account" / "I changed my mind") are good emotional design.

**Moments of Delight:**
- "I changed my mind" as the cancel button text is warmer than "Cancel."

**Missed Opportunities:**
- Could include personal stats: total lockout time, posts shared, circle growth over time.
- No notification preferences granularity beyond on/off.

**Key File References:**
- `lib/presentation/pages/settings/settings_page.dart`
- `lib/presentation/pages/settings/views/settings_view.dart`

---

## Cross-Cutting Observations

### 1. The 24h Lifecycle is Invisible
The most philosophically important feature -- content disappearing after 24 hours -- has zero visual ceremony. Posts appear, posts disappear, and the user has no awareness of the lifecycle. No countdown, no fading, no "last moments" notification, no farewell. The only trace is the memorable post selection dialog, which appears *after* content has already disappeared. This needs to be made visible and emotionally meaningful.

### 2. Loading States Are Generic
Every loading state in the app uses `CircularProgressIndicator()`. The lockout timer is the only screen that has personality while waiting. All other transitions are generic Flutter defaults. For an app about intentionality, even loading states could communicate the brand.

### 3. Transitions Between Emotional States Are Abrupt
The app has distinct emotional zones (calm home -> committed lockout -> reflective completion -> expressive sharing) but transitions between them are standard navigation pushes. The lockout *screen* itself has beautiful animation (triangle fade, text appear), but entering and leaving the lockout is a simple route change.

### 4. Error Handling Is Developer-Facing
Multiple views expose raw error objects (`${error.toString()}`). Error states should be warm and human: "Something went sideways. Let's try that again." instead of "Error: SocketException: Connection refused."

### 5. Empty States Are Underutilized
The app has several empty states (no posts, no circle members, no notifications, no friends locked out) that are single lines of text. These are opportunities for brand voice. The notification empty state ("Nothing new -- enjoy the quiet") is the gold standard that other empty states should match.

### 6. Sound and Haptics Are Absent
The only haptic feedback in the codebase is `HapticFeedback.mediumImpact()` during batch friend removal. The lockout start, lockout completion, post publish, new notification -- none have haptic or audio feedback. For an app about presence and consciousness, tactile feedback would reinforce the intentionality of each action.

### 7. The Glass Design System Is Strong but Inconsistent
`AppGlassContainer` with `GlassConfig` creates a premium, distinctive visual language. It's used consistently in the lockout flow, circle management, and onboarding overlay, but the home feed uses a different visual approach (background image + standard scaffold). The glass system could unify the entire experience.

### 8. Internationalization Is Incomplete
Many strings are hardcoded in English directly in widget code rather than going through the translation system. Examples: "No friends locked out", "Share", "Skip", "Remove connections", "Your circle is full!", "Got it", "Circle", "Requests". This creates inconsistency and makes i18n expansion harder.

---

## Priority Opportunities

### Tier 1: High Impact, Low Effort
1. **Add post expiry indicator**: Show remaining time on each post in the feed (e.g., small "12h left" badge). Minimal code change, massive philosophical alignment.
2. **Celebrate lockout completion with haptic**: Add `HapticFeedback.heavyImpact()` when lockout timer hits zero. One line of code, significant emotional payoff.
3. **Improve empty states**: Replace generic text with personality-rich copy using the existing translation system. Match the "enjoy the quiet" standard.
4. **Un-hide lockout notifications**: Remove the filter that hides `lockoutStarted` and `lockoutJoined` from the notifications view. These are the app's most philosophically aligned events.

### Tier 2: High Impact, Medium Effort
5. **Post disappearance ceremony**: Add a visual/animation when posts are approaching their 24h expiry (subtle opacity reduction, "fading" effect in the feed).
6. **Lockout start ceremony**: Replace the Material dialog with a dedicated full-screen moment that builds anticipation before the timer begins.
7. **Circle join celebration**: When a new member joins, show a warm welcome moment rather than silently adding them to the list.
8. **Goback score explanation**: Add an info button or first-time tooltip explaining what the score means and how battery usage correlates with phone-down quality.

### Tier 3: High Impact, High Effort
9. **Onboarding redesign**: Replace text-heavy step cards with experiential onboarding that shows the lockout experience, demonstrates the 24h lifecycle, and names the inviting friend.
10. **Calendar narrative**: Transform the calendar from a grid of dots into a visual story of the user's offline journey, with saved posts, lockout durations, and streaks.
11. **Relationship depth indicators**: Show connection strength in the circle (based on mutual lockouts, content exchanges, time connected) to encourage deeper, not wider, connection.
12. **Sound design**: Create a minimal audio identity for key moments (lockout start chime, completion return sound, post publish confirmation).
