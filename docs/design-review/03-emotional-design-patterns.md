# Emotional Design Patterns & Micro-Interactions

## Design Review for goback v1

---

## Table of Contents

1. [Onboarding Emotional Design](#1-onboarding-emotional-design)
2. [Content Creation as Ritual](#2-content-creation-as-ritual)
3. [Content Viewing as Intimate Experience](#3-content-viewing-as-intimate-experience)
4. [Circle Rituals and Belonging](#4-circle-rituals-and-belonging)
5. [Constraints as Self-Care UX](#5-constraints-as-self-care-ux)
6. [Notification Design](#6-notification-design)
7. [Motion Design and Transitions](#7-motion-design-and-transitions)
8. [Empty States and Waiting](#8-empty-states-and-waiting)
9. [Departure Design](#9-departure-design)

---

## 1. Onboarding Emotional Design

### 1.1 First Impression: App Philosophy Introduction

**Psychological Principle:** _Primacy Effect_ -- the first experience with a product forms a lasting mental model. Combine with _Narrative Transportation_ -- people are more persuaded by stories they feel part of than by feature lists.

**Current State:** The `ObjectivePage` (`lib/presentation/pages/objective/objective_page.dart`) shows a static text block from translations: "Your brain evolved for tribes, not timelines..." followed by a Continue button. The `OnboardingOverlay` (`lib/presentation/components/onboarding/onboarding_overlay.dart`) is a 4-step glass card walkthrough with Next/Skip controls. Both are purely informational -- text and buttons, no animation, no imagery, no emotional arc.

**Proposed Interaction:**

_Phase 1 -- The Breath (2 seconds):_ On first launch, the screen is pure black. The goback wordmark fades in from 0% to 100% opacity over 1.2 seconds, accompanied by a single gentle haptic pulse (like a heartbeat). This signals: "we are not in a hurry."

_Phase 2 -- The Story (user-paced):_ Instead of a single text block, present the objective as 3 sequential statements that fade in one at a time as the user taps:
1. "Your brain evolved for tribes." (large, centered, Lilita One)
2. "Not timelines." (same treatment, slight pause before appearing)
3. "goback is connection without the noise." (Quicksand, smaller, softer)

Each transition uses a crossfade with slight upward drift (16px over 400ms, Curves.easeOutCubic). Background transitions from pure black (#000000) to the dark surface (#1A1A1A) gradually across all three steps.

_Phase 3 -- The Invitation:_ After the story, the goback triangle logo animates in with a rotation from -90 degrees to its resting position, accompanied by a medium haptic impact. Below it: "You were invited to be here." This reframes the invite-only model as exclusivity, not restriction.

**Emotional Outcome:** Reverence. The user feels they are entering something intentional, not downloading yet another app. The pacing itself teaches the app's philosophy -- slow down, be present.

**Flutter Implementation Notes:**
- `AnimatedOpacity` + `AnimatedSlide` for text phasing
- `AnimationController` with `CurveTween(curve: Curves.easeOutCubic)` for drift
- `HapticFeedback.mediumImpact()` for the "heartbeat" moment
- `AnimatedContainer` for background color transition
- `Transform.rotate` with `Tween<double>(begin: -pi/2, end: 0)` for triangle entrance
- Reuse existing `GobackLogo` widget from `lib/presentation/components/goback_logo.dart`

---

### 1.2 Making Invite Codes Feel Special

**Psychological Principle:** _Scarcity Principle_ (Cialdini) -- limited access increases perceived value. Combined with _Social Proof of Trust_ -- being invited means someone vouched for you.

**Current State:** `JoinCirclePage` (`lib/presentation/pages/join_circle/join_circle_page.dart`) presents a form field for entering an invite code with a subtitle and description. Functional but clinical -- identical UX to entering a discount code.

**Proposed Interaction:**

When the user navigates to Join Circle, instead of immediately showing the form:

1. _Envelope metaphor:_ Show a glass-morphism card (using existing `AppGlassContainer`) styled like a sealed letter. The card has a subtle breathing animation (scale 1.0 to 1.02, 2s cycle, `Curves.easeInOut`).

2. _Tap to open:_ On tap, the card "opens" -- the top half lifts upward with a 3D perspective transform while the content fades in below. A light haptic accompanies the "break" moment.

3. _Reveal the form:_ The invite code field appears with the prompt "Enter the code you were given" -- language of receiving a gift, not inputting data.

4. _Validation celebration:_ When a valid code is entered and the circle join succeeds, instead of a simple snackbar, the screen briefly shows the circle name with member count: "Welcome to [Circle Name]. You are member #47." The number makes belonging concrete.

**Emotional Outcome:** The user feels chosen, not processed. The invite code transforms from a string of characters into a personal invitation from a friend.

**Flutter Implementation Notes:**
- `AppGlassContainer` with `GlassConfig(variant: GlassVariant.clear)` for the envelope card
- `AnimatedScale` with `Curves.easeInOut` for the breathing effect
- `Transform` with `Matrix4.identity()..setEntry(3, 2, 0.001)..rotateX(-angle)` for 3D envelope open
- `HapticFeedback.lightImpact()` on envelope open
- Existing `JoinCircleView` form can appear inside the revealed area

---

### 1.3 Joining Your First Circle

**Psychological Principle:** _Threshold Ritual_ -- anthropologically, transitions between social spaces are marked by ceremony. Combined with _Belonging Cues_ (Daniel Coyle) -- small signals that say "you are part of this group now."

**Current State:** After successfully joining via invite code, the app navigates to `ReviewCirclePage` (`lib/presentation/pages/review_circle/review_circle_page.dart`). The transition is a standard route push with no ceremony.

**Proposed Interaction:**

On successful circle join:

1. _The Portal:_ The screen transitions using the existing goback triangle shape as a mask. The triangle starts at center screen (small) and expands outward, revealing the circle view behind it -- like stepping through a doorway. Duration: 600ms with `Curves.easeOutQuart`.

2. _Circle Members Arrival:_ Once inside, member avatars appear one by one in a staggered animation (80ms delay per member), each dropping in with a slight bounce (`Curves.elasticOut`). This makes the group feel alive and present, not like a static list.

3. _Welcome Haptic Sequence:_ A quick triple-tap haptic pattern (light, pause, light, pause, medium) -- rhythmic, like a welcome knock.

**Emotional Outcome:** Crossing a threshold. The user feels they have entered a space, not just opened a screen. The staggered member appearance makes it feel like walking into a room where people turn to greet you.

**Flutter Implementation Notes:**
- `ClipPath` with `SquircleClipper` (from `lib/presentation/components/squircle_clipper.dart`) animated via `TweenSequence` on scale
- `AnimatedList` or `ListView` with `SlideTransition` + `CurvedAnimation(curve: Curves.elasticOut)` per member item
- `Future.delayed` with 80ms increments for stagger effect
- Triple haptic: `HapticFeedback.lightImpact()`, `Future.delayed(100ms)`, repeat, then `mediumImpact()`

---

## 2. Content Creation as Ritual

### 2.1 Making Posting Feel Intentional

**Psychological Principle:** _Friction as Feature_ -- deliberate micro-friction slows impulsive behavior and increases the perceived value of the action. Combined with _Gift Economy Theory_ -- reframing sharing as giving transforms the psychology from performance to generosity.

**Current State:** `ContentEditorPage` (`lib/presentation/pages/content_editor/content_editor_page.dart`) opens directly with image/video picker hooks. The flow is: select media -> edit -> navigate to `PublishContentPage` -> select visibility -> publish. There is a lockout-specific variant (`LockoutPostEditorView`) for post-lockout sharing. The flow is efficient but no different from any social media app.

**Proposed Interaction:**

_The Moment Before:_ When opening the content editor (non-lockout flow), introduce a 1-second "settling" animation:
1. The camera/gallery picker doesn't appear immediately
2. Instead, a subtle message fades in: "What do you want to share with your circle?" (Quicksand, 16px, grey500)
3. After 800ms, this fades out and the media picker options slide up from below
4. Light haptic on the text appearance

This tiny delay transforms "lemme post real quick" into "let me share something meaningful."

_The Composition Space:_ After media is selected, the editor background should use a slight gradient shift (from dark surface to a slightly warmer tone) to create a sense of "workspace" -- you are crafting something now.

**Emotional Outcome:** The user pauses, even if only for a beat. That pause is the difference between impulsive posting and intentional sharing. The question "What do you want to share?" activates reflective processing.

**Flutter Implementation Notes:**
- `AnimatedOpacity` + `AnimatedSlide` for the settling message
- `Future.delayed(Duration(milliseconds: 800))` before showing picker
- `AnimatedContainer` for subtle background gradient shift
- `HapticFeedback.selectionClick()` for the text appearance beat

---

### 2.2 The "Send" Moment -- Gifting to Your Circle

**Psychological Principle:** _Peak-End Rule_ (Kahneman) -- people remember experiences by their peak moment and ending. The publish action is both. _Commitment Consistency_ -- a satisfying completion reinforces future behavior.

**Current State:** `PublishContentView` (`lib/presentation/pages/publish_content/views/publish_content_view.dart`) has a `PublishContentButton` at the bottom. On success, it shows a `MainSnackbar.showSuccess()` and navigates to `HomeRoutable`. The success feedback is minimal -- a brief text snackbar.

**Proposed Interaction:**

_Pre-publish confirmation:_ The publish button should transform before tap. When all members are selected and the post is ready, the button text shifts from "Publish" to "Share with your circle" (or shows member count: "Share with 12 friends"). This makes the audience concrete.

_The publish moment:_
1. On tap, the button plays a "sealing" animation -- a brief scale-down to 0.95 then back to 1.0 (100ms), accompanied by a satisfying `HapticFeedback.mediumImpact()`.
2. While uploading, instead of a generic spinner, the post thumbnail visually "floats" upward with a gentle scale-down + opacity fade, like releasing a message in a bottle or a lantern into the sky.
3. On success, a brief full-screen moment: the background dims slightly and a checkmark draws itself (stroke animation, 400ms), accompanied by `HapticFeedback.heavyImpact()`. Text below: "Shared." Simple, final, satisfying.
4. After 600ms, crossfade to the feed.

_Post-creation in feed:_ The auto-scroll behavior (already implemented at `feed_view.dart:227-241`) should be enhanced with a brief highlight glow on the new post's squircle -- a 2-second accent-colored border that fades out, confirming "this is yours, it's here now."

**Emotional Outcome:** The user feels they've completed something meaningful. The floating animation and checkmark create a moment of closure -- not "content uploaded" but "gift delivered."

**Flutter Implementation Notes:**
- `AnimatedScale` for button press feedback
- `SlideTransition` + `FadeTransition` for floating thumbnail (upward Offset(0, -50))
- `CustomPaint` with `PathMetric` for drawing checkmark stroke animation
- `AnimatedContainer` with accent border that animates to transparent for the feed highlight
- Existing auto-scroll code in `FeedView` can trigger the highlight animation

---

### 2.3 Post-Lockout Sharing: The Homecoming Ritual

**Psychological Principle:** _Narrative Completion_ -- humans need closure for experiences. _Reflective Practice_ -- the act of sharing what you did offline reinforces the value of being offline.

**Current State:** The lockout view (`lib/presentation/pages/manual_lockout/views/manual_lockout_view.dart`) has an excellent existing design -- sky cutout effect, timer, goback score, and "Share your goback" / "Skip" completion flow with animation transitions (triangle fade, text fade). The `LockoutPostEditorView` provides a streamlined post creation for the lockout context. This is already the most emotionally designed flow in the app.

**Proposed Enhancement:**

The lockout completion is strong. Enhancements should be subtle:

1. _Score reveal anticipation:_ Before showing the goback score, hold a brief blank moment (400ms) after the triangle fades. This builds anticipation. Then reveal the score with a count-up animation (0 to final score, 800ms, `Curves.easeOutCubic`) rather than appearing instantly.

2. _Score meaning:_ Below the score, add a brief contextual phrase that changes based on score tier:
   - 80-100: "You were truly present"
   - 60-79: "A meaningful pause"
   - 40-59: "Every moment counts"
   - Below 40: "A good start"

3. _Share prompt warmth:_ The "Share your goback" text could pulse very subtly (opacity 0.8 to 1.0, 2s cycle) to draw attention without urgency.

**Emotional Outcome:** The score transforms from a number to a narrative. The user doesn't just see "72" -- they see "A meaningful pause. 72."

**Flutter Implementation Notes:**
- Modify `_CutoutPainter` to support animated score value (pass as double, interpolate in paint)
- `TweenAnimationBuilder<double>` for count-up effect
- Score tier phrases can be added as translation keys
- Subtle pulse: additional `TweenSequence` on opacity for the share text

---

## 3. Content Viewing as Intimate Experience

### 3.1 Opening Content Like Opening a Letter

**Psychological Principle:** _Anticipatory Savoring_ -- the brief delay before experiencing something pleasant increases the pleasure. _Epistolary Intimacy_ -- letters feel personal because opening them is a physical ritual.

**Current State:** `FeedPostCard` (`lib/presentation/pages/feed/components/feed_post_card.dart`) uses a `Hero` animation with tag `'post_${post.id}'` that transitions to `PostDetailPage.show()` via a `PageRouteBuilder` with 350ms `FadeTransition`. The posts display as squircle-clipped images in a chat-style staggered layout. Tapping opens the detail overlay. The transition is smooth but standard.

**Proposed Interaction:**

_The reveal:_ Instead of a pure fade, combine the existing Hero with a slight scale-up (1.0 to 1.05) and a gentle blur-to-sharp transition on the image:

1. Tap the squircle -- `HapticFeedback.selectionClick()`
2. Hero animates the image from its feed position to the detail overlay position (350ms, already implemented)
3. During the Hero transition, the image goes from slightly blurred (sigma 2.0) to sharp (sigma 0.0) over 300ms -- like your eyes adjusting, like the image is "developing" for you
4. The post detail content (author, description, reactions) slides up from below with a staggered fade (100ms delays between elements)

_One-at-a-time viewing emphasis:_ The `PostDetailOverlay` (`lib/presentation/pages/post_detail/views/post_detail_overlay.dart`) already overlays on top of the feed. Enhance this by increasing the background dim slightly (from transparent to rgba(26,26,26,0.85)) to create a "spotlight" effect on the viewed content.

**Emotional Outcome:** Each piece of content feels like it deserves your attention. The blur-to-sharp transition creates a micro-moment of anticipation and discovery, like opening an envelope.

**Flutter Implementation Notes:**
- `BackdropFilter` with animated `ImageFilter.blur(sigmaX: blurValue, sigmaY: blurValue)` via `TweenAnimationBuilder`
- Modify existing `PageRouteBuilder` in `PostDetailPage.show()` to include `ScaleTransition`
- Staggered content reveal: `AnimatedOpacity` with `Future.delayed` increments on description, reactions, etc.
- Background dim: change `barrierColor` from `Colors.transparent` to `MainColors.dark.withValues(alpha: 0.85)` with animation

---

### 3.2 Reactions That Feel Personal

**Psychological Principle:** _Reciprocity Norm_ -- acknowledging someone's sharing with a reaction strengthens the social bond. _Embodied Cognition_ -- physical gestures (tapping, holding) create emotional investment.

**Current State:** The `PostDetailLayout` (`lib/presentation/pages/post_detail/post_detail_layout.dart`) defines a reaction picker modal with emoji grid layout (32px emojis, 16px spacing). Reactions display with horizontal padding and pill-shaped containers with border radius 999. The emoji picker opens as a bottom sheet.

**Proposed Interaction:**

_Reaction as gesture:_ Instead of tapping a reaction button to open a picker, support double-tap on the image to send a quick heart/love reaction (like the physical gesture of "I see this, I appreciate it"). A heart animates from the tap point, floats upward with slight drift, and fades out (600ms, `Curves.easeOut`).

_Intentional reaction picker:_ The existing emoji bottom sheet should slide up with a slight "bounce" at the top of its travel (`Curves.easeOutBack`). When the user selects an emoji, it should briefly enlarge (scale 1.0 to 1.3 and back, 200ms) and the sheet should dismiss with a satisfying haptic.

_Reaction received feedback:_ When viewing your own post and a new reaction arrives, the reaction count should briefly pulse (scale bump + accent color flash) rather than just incrementing silently.

**Emotional Outcome:** Reactions feel like genuine acknowledgments, not drive-by likes. The double-tap heart mirrors a real-life gesture of pressing something to your chest.

**Flutter Implementation Notes:**
- Double-tap: `GestureDetector.onDoubleTap` on the post image
- Floating heart: `AnimatedPositioned` + `AnimatedOpacity` with `Curves.easeOut`
- Bounce sheet: `showModalBottomSheet` with custom `AnimationController` and `Curves.easeOutBack`
- `AnimatedScale` on emoji selection (1.0 -> 1.3 -> 1.0 via `TweenSequence`)
- Reaction pulse: `AnimatedContainer` with color + scale tween on the reaction pill

---

### 3.3 The Feeling of "Catching Up"

**Psychological Principle:** _Completion Drive_ -- humans feel satisfaction in completing a set. _Social Grooming Theory_ -- browsing friends' updates is the digital equivalent of social grooming in primates.

**Current State:** The feed (`FeedView` in `lib/presentation/pages/feed/views/feed_view.dart`) is a reversed ListView where newest posts are at the bottom. The `FeedNewPostsBanner` shows when new posts are available. There is scroll tracking and auto-scroll behavior. The feed layout is chat-style staggered (left/right alignment based on author).

**Proposed Interaction:**

_Progress awareness:_ As the user scrolls through the feed (upward = older, since the list is reversed), add a subtle progress indicator. When the user has seen all posts, trigger a gentle completion moment:

1. A brief text overlay fades in at the center: "All caught up" (Quicksand, 14px, grey500)
2. Accompanied by a single light haptic
3. Fades out after 2 seconds

This should trigger only once per session, when the user first reaches the top of the loaded feed.

_New post notification warmth:_ The existing `FeedNewPostsBanner` could include the poster's name when there's a single new post: "[Name] shared something" instead of just indicating new content. For multiple: "3 friends shared something new."

**Emotional Outcome:** The user feels they've "visited" everyone in their circle. The "all caught up" moment provides satisfying closure -- unlike infinite scroll apps where there is never an end.

**Flutter Implementation Notes:**
- Detect scroll reaching `maxScrollExtent` (which is the "top" in reversed list)
- `AnimatedOpacity` overlay positioned centrally, with `Future.delayed(2000ms)` to fade out
- `HapticFeedback.lightImpact()` on reaching the end
- Banner text: modify `FeedNewPostsBanner` to accept optional author name string

---

## 4. Circle Rituals and Belonging

### 4.1 Daily Check-In Rhythms

**Psychological Principle:** _Ritual Theory_ (Durkheim) -- shared rhythms create collective identity. _Variable Ratio Reinforcement_ -- but unlike addictive apps, goback's rhythm is bounded and predictable (you know content expires, you know your time limit).

**Current State:** The feed refreshes on 60-second intervals (`feed_view.dart:132-142`), on app resume (`useAppResumeRefresh`), and via pull-to-refresh. There is no sense of "today's activity" vs "yesterday's" beyond individual post timestamps. The `FeedDateOverlay` shows the date of the visible post area.

**Proposed Interaction:**

_Morning greeting (first open of the day):_ When the user opens the app for the first time each calendar day, before the feed loads, show a brief (2-second) greeting:
- "Good morning, [username]" / "Good afternoon" / "Good evening" (time-appropriate)
- Below: "[N] friends shared today" or "Your circle is quiet today" if no posts
- This fades out and the feed slides up behind it

This creates a daily ritual anchor -- the app greets you like a space you return to, not a feed you check.

_Activity pulse on circle view:_ In `YourCircleView` (shown via `YourCirclePage`), member avatars could have a subtle indicator showing who has been active today -- a thin accent ring around their profile image. Not a status dot (which creates FOMO pressure), but a warmth indicator.

**Emotional Outcome:** The user develops a healthy rhythm with the app. The greeting humanizes the technology. The activity pulse creates gentle awareness without urgency.

**Flutter Implementation Notes:**
- Time-of-day greeting: check `DateTime.now().hour` for morning/afternoon/evening
- Store last-greeted-date in a `SharedPreferences`-backed storable (pattern exists with `OnboardingCompletedStorable`)
- `AnimatedOpacity` + `AnimatedSlide` for the greeting overlay
- Activity ring: `DecoratedBox` with `Border.all(color: MainColors.accent, width: 2)` conditionally applied to profile images in member list

---

### 4.2 Visual Representation of Circle Health

**Psychological Principle:** _Group Cohesion Indicators_ -- visible signs of group activity reinforce belonging. _Social Facilitation_ -- knowing others are active motivates participation.

**Current State:** `YourCirclePage` (`lib/presentation/pages/your_circle/your_circle_page.dart`) has two tabs (Circle / Requests) with an `AppGlassContainer` toggle. The circle view lists members. There are no aggregate metrics about circle activity.

**Proposed Interaction:**

_Circle vitality indicator:_ At the top of the circle view, below the tab toggle, show a simple "circle pulse" -- a horizontal bar or circular indicator that fills based on the percentage of members who have posted in the last 24 hours:
- Low activity (0-20%): Bar is mostly empty, subtle grey fill
- Medium (20-60%): Partial fill, accent color
- High (60%+): Full or near-full, accent color with a very subtle glow

The bar animates on first load (fills from 0 to current %, 800ms, `Curves.easeOutCubic`).

No exact numbers or names -- this is a feeling, not a leaderboard. The indicator says "your circle is alive" without creating pressure about who specifically has or hasn't posted.

**Emotional Outcome:** The circle feels like a living entity, not a contact list. High activity creates a warm "my people are here" feeling. Low activity creates gentle invitation to contribute, not guilt.

**Flutter Implementation Notes:**
- `AnimatedContainer` with width tween for bar fill
- `LinearGradient` with accent color + transparent for the glow effect
- Calculate activity percentage from feed posts cache (posts in last 24h / total members)
- Position below the existing `_TabToggle` in `YourCirclePage`

---

### 4.3 Celebrating Milestones

**Psychological Principle:** _Ritual Marking_ -- celebrations at transition points strengthen group identity. _Nostalgia Effect_ -- looking back at shared history increases group attachment.

**Current State:** No milestone tracking or celebration exists in the current app.

**Proposed Interaction:**

_Membership milestone:_ When a new member joins via invite, other circle members could see a brief, non-intrusive celebration in the feed -- a system card (not a post) that says "[Name] joined the circle" with a subtle shimmer effect. The card uses the glass container style to distinguish it from regular posts.

_Circle anniversary:_ On the anniversary of a user joining their circle, show a brief glass card when they open the feed: "1 year in your circle. You've shared [N] moments." This appears once, dismisses on tap.

These are gentle, infrequent, and informational. They celebrate without creating notification fatigue.

**Emotional Outcome:** Milestones create temporal anchoring -- "I've been here for a year" transforms the app from a tool into a place with history.

**Flutter Implementation Notes:**
- System card: `AppGlassContainer` with `GlassConfig(tint: MainColors.accent)` inserted into feed list
- Shimmer: `ShaderMask` with `LinearGradient` that animates position via `AnimationController`
- Anniversary check: compare user's `created_at` with current date in a post-frame callback
- Store "seen milestone" flag in local storable to prevent repeat showing

---

## 5. Constraints as Self-Care UX

### 5.1 Time Limit Approaching: Gentle Warnings

**Psychological Principle:** _Self-Determination Theory_ -- autonomy-supportive constraints feel caring, not controlling. _Nudge Theory_ -- gentle environmental cues are more effective than hard stops.

**Current State:** The time limit feature exists at the domain level (`lib/core/features/time_limit/`) with a tracker notifier. The `time_limit_reached` page has only generated routable files -- the actual page/view implementation appears to be elsewhere or minimal. The lockout button (`FeedLockoutButton`) serves as the primary "step away" affordance.

**Proposed Interaction:**

_5-minute warning:_ When 5 minutes remain in the daily time limit, the lockout triangle button on the feed should begin a very slow, gentle breathing animation (scale 1.0 to 1.04, 3-second cycle). Not attention-grabbing, but subtly alive. If the user notices, it's because they're ready to notice.

_2-minute warning:_ The feed date overlay at the top gains a warm amber tint (not red -- red means danger; amber means "sunset is coming"). The triangle breathing quickens slightly (2-second cycle).

_Time reached:_ The screen doesn't abruptly cut to a "time's up" page. Instead:
1. The feed content gently blurs (sigma 0 to 5 over 2 seconds)
2. The lockout triangle pulses once with `HapticFeedback.mediumImpact()`
3. A glass card fades in at center: "Your time today is complete. See you tomorrow."
4. Below: "You connected with [N] friends today" (calculated from viewed posts)

No "extend time" button. No negotiation. The constraint is a gift, and the app treats it as such.

**Emotional Outcome:** The time limit feels like sunset -- natural, expected, even beautiful. Not punishment. The "you connected with N friends" reframes the end as completion, not interruption.

**Flutter Implementation Notes:**
- Breathing triangle: modify `FeedLockoutButton`'s `glowController` to accept an `isTimeLimitApproaching` parameter that activates a continuous subtle pulse
- Amber tint: `AnimatedContainer` color shift on `FeedDateOverlay`
- Blur transition: `TweenAnimationBuilder<double>` on a `BackdropFilter` wrapping the feed content
- Glass card: `AppGlassContainer` with `AnimatedOpacity`
- Connection count: count distinct `authorId` values in `feedPostsCacheProvider`

---

### 5.2 Manual Lockout: Choosing to Be Present

**Psychological Principle:** _Self-Regulation as Strength_ -- choosing to step away is an act of agency, not deprivation. _Commitment Device Theory_ -- public commitments increase follow-through.

**Current State:** The `ManualLockoutDialog` (`lib/presentation/pages/home/components/manual_lockout_dialog.dart`) is a well-designed dialog with a CupertinoPicker for hours/minutes and an optional activity text field ("What are you doing?"). Minimum 1 hour. The lockout screen itself is the most emotionally designed element in the app -- sky cutout with timer countdown, inverted colors, triangle reveal.

**Proposed Enhancement:**

_Activity text as intention setting:_ The activity field hint "What are you doing?" could be reframed to "What are you going back to?" This subtle language shift reinforces the app's philosophy -- you're not leaving something, you're returning to something.

_Duration selection warmth:_ As the user scrolls through higher durations, add a very subtle color warmth shift to the dialog background (imperceptible but felt). Longer lockouts = warmer tones. This subconsciously rewards choosing longer offline time.

_Confirmation moment:_ When the user taps "Confirm", before navigating to the lockout screen, flash the activity text (if provided) at full screen for 600ms: "Going running" (Lilita One, large, centered on dark background). This makes their intention feel monumental, like a declaration. Then transition to the lockout view.

**Emotional Outcome:** The lockout activation feels like a declaration of intention, not a restriction. The user feels proud of their choice.

**Flutter Implementation Notes:**
- Reframe hint text: translation key change for `'pages.manual_lockout.dialog.activity_hint'`
- Background warmth: `AnimatedContainer` with color lerp based on selected duration
- Intention flash: insert a `PageRouteBuilder` with `FadeTransition` showing the activity text before navigating to `ManualLockoutRoutable`
- `HapticFeedback.heavyImpact()` on the declaration moment

---

### 5.3 Lockout Screen: Beautiful Stillness

**Psychological Principle:** _Environmental Calm Transfer_ -- serene environments reduce cortisol. _Positive Reinforcement of Absence_ -- making the "off" state beautiful reinforces choosing it.

**Current State:** The lockout view (`manual_lockout_view.dart`) is already the emotional highlight of the app. The sky cutout effect is visually striking -- a solid foreground (inverted colors) with transparent "holes" punched through for the timer text and triangle, revealing a sky background image beneath. The timer uses LilitaOne at ~80% screen width. The triangle fades on completion, replaced by goback score and share/skip options. Long-press reveals a `LockoutFriendsOverlay` showing who else is locked out.

**Proposed Enhancement:**

_Sky image variation:_ Rather than a single static sky image, consider providing 3-4 sky images (dawn, day, sunset, night) and selecting based on the user's local time. This makes the lockout screen feel temporally aware -- you see the sky that's actually outside.

_Timer breathing:_ The countdown text, while beautifully large, is static. Add an extremely subtle opacity oscillation (0.95 to 1.0, 4-second cycle) that mimics breathing. Not visible at a glance, but felt if you stare at the screen -- which is the point. The app breathes with you.

_Friends overlay warmth:_ The `LockoutFriendsOverlay` (shown on long-press) could show friends' activity text alongside their names: "Alex -- going running". This creates social reinforcement: "other people in my circle are also choosing to be present right now."

**Emotional Outcome:** The lockout screen is a place you want to look at, not away from. It models the calm it's asking you to embody.

**Flutter Implementation Notes:**
- Time-based sky: `Assets.png.backgroundGobackDawn/Day/Sunset/Night.render()` selected by `DateTime.now().hour`
- Timer breathing: add opacity parameter to `_CutoutPainter._holePaint()` driven by `AnimationController` with `Curves.easeInOut`
- Friends activity: extend `LockoutFriendsOverlay` data model to include `actionText` from lockout session

---

## 6. Notification Design

### 6.1 Notifications That Create Anticipation, Not Anxiety

**Psychological Principle:** _Curiosity Gap_ -- partial information creates wanting. _Autonomy-Supportive Framing_ -- notifications that inform rather than demand.

**Current State:** `NotificationsView` (`lib/presentation/pages/notifications/views/notifications_view.dart`) shows a list of `NotificationItem` widgets. Types include: reaction, tag, comment, lockoutStarted, lockoutJoined, friendJoined, connectionRequest. Lockout notifications are filtered out from the main list. Notifications auto-mark as read after 1.5 seconds. The page is a standard ListView.

**Proposed Interaction:**

_Notification tone:_ Push notification copy should create gentle curiosity:
- Reaction: "[Name] felt something about your post" (not "[Name] reacted to your post")
- Comment: "[Name] has something to say" (not "[Name] commented")
- Tag: "[Name] is thinking of you" (not "[Name] tagged you")
- Friend joined: "Someone you know just arrived"

_In-app notification list:_ Add subtle visual differentiation:
- Unread notifications have a thin accent-colored left border (2px)
- The border fades out over 2 seconds when the notification becomes visible (marking as read)
- This creates a satisfying "clearing" visual as the user scrolls through

_Batching:_ For non-urgent notifications (reactions, tags), batch them into digest-style notifications: "[Name] and 2 others responded to your post." Only deliver push notifications for comments (which imply conversation) and connection requests (which require action).

**Emotional Outcome:** Notifications feel like gentle taps on the shoulder from friends, not demands for attention. The "felt something" language creates curiosity without specificity.

**Flutter Implementation Notes:**
- Notification copy: update translation keys for push notification templates
- Left border: `AnimatedContainer` with `Border(left: BorderSide(color: accent, width: 2))` that animates to transparent
- `VisibilityDetector` (from `visibility_detector` package, already in Flutter) to trigger fade on scroll-into-view
- Batching: server-side aggregation (already partially implemented via `AggregatedNotificationModel`)

---

### 6.2 The Lockout Notification: Social Solidarity

**Psychological Principle:** _Social Proof_ -- seeing others make healthy choices normalizes the behavior. _Collective Effervescence_ (Durkheim) -- shared experiences create group bonding.

**Current State:** Lockout notifications (lockoutStarted, lockoutJoined) are filtered OUT of the notifications view (`notifications_view.dart:68-72`). They appear only via push notifications. The feed's `FeedLockoutButton` and the `LockoutFriendsOverlay` (long-press on lockout screen) show who's currently locked out.

**Proposed Interaction:**

Rather than showing lockout notifications in the standard notification list (correct current decision), enhance the feed-level awareness:

_Lockout awareness in feed:_ When a friend starts a lockout, their latest post in the feed could gain a subtle visual modifier -- a thin frosted overlay on their squircle that says they're "away." Not disruptive, but noticeable. The overlay clears when the lockout ends.

_Join invitation warmth:_ The `HomeJoinLockoutButton` could show the friend's activity text: "Alex went back to run -- join?" This makes joining feel like joining a friend's activity, not just copying their phone behavior.

**Emotional Outcome:** Lockouts become visible, normal, celebrated behavior. The circle sees each other choosing to be present and can choose to join.

**Flutter Implementation Notes:**
- Frosted overlay: `ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5)` applied via `BackdropFilter` inside the `ClipSquircle` on `FeedPostCard`
- Check lockout status from `friendsLockedOutCacheProvider`
- Activity text in join button: pass `actionText` to button widget text

---

## 7. Motion Design and Transitions

### 7.1 Transitions That Reinforce Emotional States

**Psychological Principle:** _Spatial Metaphor_ -- directional movement creates meaning. Upward = aspiration, growth. Downward = grounding, returning. Lateral = exploring.

**Current State:** Navigation uses `router.go()` and `router.push()` from dedecube_router. The primary feed uses `AppGlassLayer` for glass compositing. The post detail uses a custom `PageRouteBuilder` with `FadeTransition` (350ms in, 250ms out). The nav overlay (`NavOverlay` in `lib/presentation/components/nav_overlay/nav_overlay.dart`) appears on long-press with solid labels on a dim dark background. Most page transitions are default MaterialPageRoute transitions.

**Proposed Interaction:**

_Entering a circle = entering a room:_ When navigating from the feed to the circle view, the transition should slide the feed to the left while the circle view slides in from the right -- lateral movement suggesting "going to another room."

_Going to profile = looking inward:_ Navigation to profile should use a scale-down + fade transition -- the world zooms out and you see yourself. Reverse on exit: the world zooms back in.

_Opening notifications = opening a mailbox:_ Slide up from bottom, like lifting a lid.

_Lockout activation = closing a door:_ When navigating to the lockout screen after confirming duration, the transition should be a "closing" motion -- the screen content slides together from left and right edges, meeting in the middle, then the lockout screen reveals behind.

**Emotional Outcome:** Each navigation feels different because each destination means something different. The user's spatial memory maps to emotional meaning.

**Flutter Implementation Notes:**
- Custom `PageRouteBuilder` instances per destination type
- Lateral: `SlideTransition` with `Offset(1.0, 0.0)` to `Offset.zero`
- Scale-down: `ScaleTransition` with `Tween(begin: 1.0, end: 0.9)` + `FadeTransition`
- Slide-up: `SlideTransition` with `Offset(0.0, 1.0)` to `Offset.zero`
- Closing door: `AnimatedBuilder` with two `Positioned` widgets sliding inward

---

### 7.2 Loading States That Build Anticipation

**Psychological Principle:** _Endowed Progress Effect_ -- showing that something is happening (even before it's done) increases patience and satisfaction.

**Current State:** Loading states use `CircularProgressIndicator` (default Flutter, seen in `feed_view.dart:343-345` and `notifications_view.dart:135-136`). The feed shows the indicator when `feedPosts.isLoading && feedPosts.posts.isEmpty`.

**Proposed Interaction:**

Replace generic spinners with contextual loading indicators:

_Feed loading:_ Instead of a circular spinner, show 2-3 placeholder squircle shapes (like the feed layout) with a subtle shimmer effect. This "skeleton loading" pattern primes the user for what's coming.

_Post detail loading:_ When loading a post by ID (e.g., from a notification), show the post frame (squircle shape) with a breathing opacity pulse while content loads.

_Circle members loading:_ Show placeholder circular avatars in a grid with shimmer.

**Emotional Outcome:** Loading doesn't feel like waiting -- it feels like the room is preparing for you.

**Flutter Implementation Notes:**
- Shimmer: `ShaderMask` with animated `LinearGradient` (translate x position over 1.5s cycle)
- Skeleton shapes: `Container` with `borderRadius` matching squircle/circle proportions + `color: colorScheme.surfaceContainerHigh`
- Breathing pulse: `AnimatedOpacity` with `Curves.easeInOut`, 1.5s cycle

---

### 7.3 Content Expiration: Gentle Fading

**Psychological Principle:** _Wabi-Sabi_ -- beauty in impermanence. _Closure_ -- endings that are graceful create acceptance, not loss.

**Current State:** Content expires after 24 hours via the 30-minute cleanup timer in `feed_view.dart:75-80` (`cn.removeExpiredPosts()`). Expired posts simply disappear from the cache. There is no visual indication of approaching expiration.

**Proposed Interaction:**

_Aging indicator:_ Posts nearing expiration (last 2 hours of their 24h life) could have a very subtle visual treatment -- slightly reduced opacity (0.9) or a thin, barely visible border that's warmer in tone. Not enough to draw attention, but enough that if you notice, you understand: this moment is passing.

_Disappearance animation:_ When a post expires while the user is in the feed (during the periodic cleanup), instead of instant removal, the squircle could fade to 0% opacity over 400ms and then collapse (height animates to 0 over 200ms). A single light haptic marks the departure.

This makes impermanence beautiful rather than jarring.

**Emotional Outcome:** Content doesn't just vanish -- it gently departs. This models the app's philosophy: moments pass, and that's okay.

**Flutter Implementation Notes:**
- Aging: calculate `post.expiresAt.difference(DateTime.now())`, if < 2h, apply `Opacity(opacity: 0.9)` to card
- Disappearance: `AnimatedList.removeItem()` with `SizeTransition` + `FadeTransition`
- `HapticFeedback.lightImpact()` on removal
- Would require the cache notifier to emit removal events rather than just removing

---

## 8. Empty States and Waiting

### 8.1 No Content Yet: Invitation to Contribute

**Psychological Principle:** _Social Proof + Call to Action_ -- empty states that show possibility rather than absence. _Seed Planting_ -- framing the empty state as the beginning of something.

**Current State:** `HomeFeedEmptyState` (`lib/presentation/pages/home/components/home_feed_empty_state.dart`) shows "No activity" title and "Start a lockout to go back and share a moment with your circle" description. `MainEmptyState` (`lib/presentation/components/main_empty_state.dart`) shows "You don't have anyone in your circle yet, invite a friend now!" Both are simple text in containers.

**Proposed Interaction:**

_Feed empty state:_ Replace static text with an inviting visual:
1. The goback triangle (from `GobackLogo`) displayed at large scale (120px) with a gentle breathing animation
2. Below: "Your circle is waiting" (Lilita One, 24px)
3. Below: "Share a moment to start the day" (Quicksand, 14px, grey500)
4. The triangle doubles as a tap target that opens the content creation flow

The empty state should feel like the beginning of something, not the absence of something. The breathing triangle says "the app is alive, even if the feed isn't."

_Circle empty state:_ Show a circular arrangement of placeholder dots (like empty seats around a table) with a count: "0 / 150"
Below: "Invite the people who matter"
The dots could subtly pulse in sequence (like a ripple), suggesting the table is waiting to be filled.

**Emotional Outcome:** Empty is not lonely -- it's full of potential. The breathing animation and "waiting" language creates anticipation rather than absence.

**Flutter Implementation Notes:**
- Large triangle: reuse `GobackLogo` with `fontSize: 60` or use `CustomPaint` with `_LeftTrianglePainter`
- Breathing: `AnimatedScale` with `Curves.easeInOut`, 2.5s cycle
- Placeholder dots: `CustomPaint` drawing 8-12 circles in a ring with `AnimatedOpacity` stagger
- Tap-to-create: `GestureDetector` wrapping the triangle

---

### 8.2 Waiting for Friends to Post

**Psychological Principle:** _Positive Anticipation_ -- the expectation of a reward is itself pleasurable. _Secure Attachment_ -- confidence that connection will happen reduces anxiety about its absence.

**Current State:** When the feed has posts but no new activity, the user sees their existing timeline. There is no indicator of "no new activity since last visit."

**Proposed Interaction:**

When the feed is fully caught up (user has scrolled to the oldest loaded post or all posts are visible):

_Gentle prompt at the top of the feed:_ A small glass card fades in: "Waiting for your circle to share. In the meantime, why not go back?" with an arrow pointing down toward the lockout button. The card is dismissible with a tap and doesn't reappear for 30 minutes.

This elegantly connects the two key behaviors: when there's nothing to consume, the app gently suggests the healthier alternative -- go offline.

**Emotional Outcome:** Waiting is reframed as an opportunity, not a deficit. The app doesn't try to fill the void with more content -- it suggests you fill it with life.

**Flutter Implementation Notes:**
- `AppGlassContainer` with compact dimensions, positioned at feed top
- `AnimatedOpacity` for fade-in when scroll reaches the end
- `Timer`-based flag to prevent re-showing for 30 minutes
- Dismiss on tap: `GestureDetector` wrapping the card

---

### 8.3 After Content Expires: Memory, Not Loss

**Psychological Principle:** _Nostalgia Effect_ -- brief triggers of past experiences strengthen emotional bonds. _Temporal Discounting Reversal_ -- knowing something was temporary makes it feel more precious in retrospect.

**Current State:** The `MemorablePostSelectionDialog` (`lib/presentation/pages/home/components/memorable_post_selection_dialog.dart`) already exists -- it prompts users to select "memorable" posts. There is also a calendar feature with `ProfileCalendar` and `calendarPostsCacheProvider` for historical post browsing. Content expires but is apparently preserved in some form via the calendar system.

**Proposed Enhancement:**

The memorable post selection is a strong existing pattern. Enhance it:

_Selection prompt warmth:_ When the memorable post selection dialog appears, frame it as: "Yesterday's moments are fading. Save one to remember?" rather than a utilitarian "select a post."

_Calendar as memory:_ The profile calendar (already implemented) could show days with saved memorable posts as having a subtle accent dot (like a diary with bookmarks). This transforms the calendar from a navigation tool into a personal journal.

**Emotional Outcome:** Expiration is not deletion -- it's graduation from present to memory. The user curates their own history, which feels deeply personal.

**Flutter Implementation Notes:**
- Dialog copy: update translation key for the memorable selection prompt
- Calendar dots: add a small accent-colored circle indicator to calendar day cells that contain saved posts

---

## 9. Departure Design

### 9.1 Leaving the App Should Feel Complete

**Psychological Principle:** _Peak-End Rule_ -- the end of an experience disproportionately shapes memory. _Closure Need_ -- unfinished tasks create anxiety (Zeigarnik Effect); complete ones create satisfaction.

**Current State:** There is no departure design. When the user leaves the app (background, lock screen, close), whatever was on screen freezes. There is no end-of-session acknowledgment.

**Proposed Interaction:**

_Session summary (app going to background):_ When the app lifecycle transitions to `AppLifecycleState.paused`, briefly save session stats locally:
- Time spent
- Posts viewed
- Reactions given
- Friends' content seen

_Re-entry summary:_ On next app open (not cold start, but resume after > 5 minutes), before showing the feed, display a brief glass card with session summary: "Last visit: you spent 8 min and connected with 4 friends." Disappears after 2 seconds or on tap.

This is subtle and infrequent -- only shown when the gap between sessions is meaningful (> 5 minutes). It creates a sense of "sessions" rather than "always on."

_Graceful time limit reached:_ When the daily time limit expires, the departure is already handled by the time limit feature. But if the user manually closes the app near their time limit, a local notification could fire 5 minutes later: "Your circle saw you today. See you tomorrow." This creates a warm ending even when the departure is abrupt.

**Emotional Outcome:** Every session has a beginning and an end. The user feels they had a complete visit, like leaving a friend's house, not like abandoning a task.

**Flutter Implementation Notes:**
- Lifecycle: `WidgetsBindingObserver` with `didChangeAppLifecycleState`
- Session stats: store in memory during session, write to local storable on pause
- Resume check: compare `DateTime.now()` with stored `lastPauseTime`
- Glass card: `AppGlassContainer` with `AnimatedOpacity`, auto-dismiss timer
- Delayed notification: schedule via `flutter_local_notifications` with 5-minute delay, cancel on app resume

---

### 9.2 The Promise of Return

**Psychological Principle:** _Secure Base Theory_ (Bowlby) -- knowing you can return makes leaving easier. _Anticipated Utility_ -- looking forward to the next interaction increases current satisfaction.

**Current State:** No "see you tomorrow" or return-oriented messaging exists.

**Proposed Interaction:**

_Lockout completion departure:_ The lockout completion flow already says "Share your goback" or "Skip." After either action, when navigating back to the feed, a brief overlay could say: "Your circle will be here tomorrow." This subtle promise reduces any separation anxiety.

_Time limit reached departure:_ The time limit reached screen (to be designed) should end with: "See you in [hours until reset]" -- making the return time concrete and anticipated.

_App icon badge:_ When friends post while the user is away, instead of showing a number badge (which creates urgency), consider showing no badge at all, or a simple dot -- presence, not pressure. This is a design philosophy decision that reinforces "the app serves you, not the other way around."

**Emotional Outcome:** The user leaves with confidence that connection is ongoing and will be there when they return. No FOMO, no guilt, just a promise.

**Flutter Implementation Notes:**
- Departure overlay: `AnimatedOpacity` + `Text` widget shown briefly (1.5s) before navigation
- Time until reset: calculate from time limit provider's reset schedule
- Badge control: configure via push notification service to suppress badge counts or show only dot indicator

---

## Summary: Design Priorities

### Highest Impact, Lowest Complexity
1. **Onboarding story pacing** (Section 1.1) -- transforms first impression with simple opacity/slide animations
2. **Publish moment celebration** (Section 2.2) -- a checkmark + "Shared." changes the entire posting psychology
3. **Time limit gentle warnings** (Section 5.1) -- breathing triangle + warm amber tinting
4. **Empty state invitation** (Section 8.1) -- breathing triangle with "Your circle is waiting"
5. **Notification language warmth** (Section 6.1) -- pure copy changes, zero code

### Medium Impact, Medium Complexity
6. **Content viewing blur-to-sharp** (Section 3.1) -- enhances existing Hero transition
7. **Lockout activity text reframing** (Section 5.2) -- "What are you going back to?"
8. **Loading state skeletons** (Section 7.2) -- replaces spinners with contextual placeholders
9. **Daily greeting** (Section 4.1) -- time-aware "Good morning" on first open
10. **All caught up** (Section 3.3) -- completion satisfaction when feed is fully viewed

### Highest Impact, Highest Complexity
11. **Invite code envelope metaphor** (Section 1.2) -- 3D perspective animation
12. **Circle join threshold ritual** (Section 1.3) -- triangle mask expansion
13. **Content expiration animation** (Section 7.3) -- requires cache event system
14. **Session summary on departure** (Section 9.1) -- lifecycle observer + stats tracking
15. **Emotion-aware transitions** (Section 7.1) -- custom route builders per destination

---

### Existing Strengths to Preserve

The app already has several emotionally powerful elements:
- **The lockout screen** (`manual_lockout_view.dart`) with sky cutout effect is exceptional
- **The goback triangle** as both logo element and lockout button is iconic
- **The glass container system** (`AppGlassContainer`) provides a beautiful, consistent material
- **The chat-style feed layout** with staggered left/right posts feels intimate
- **The squircle clip** from Figma gives content a distinctive, soft character
- **The "goback score"** with battery-based calculation is a uniquely thoughtful metric
- **The LilitaOne typography** at display sizes creates emotional weight
- **The 150-member cap** (matching Dunbar's number) is the most powerful design decision in the entire product

These elements should be protected and amplified, not replaced.
