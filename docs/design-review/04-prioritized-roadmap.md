# Emotional Design Roadmap — goback v2

Synthesized from: UX Flow Analysis, Psychology Research, Emotional Design Patterns.

---

## Guiding Philosophy

Every recommendation below serves one principle: **goback should feel like returning to a place, not opening an app.** The village townhall doesn't have infinite scroll, notification badges, or engagement metrics — it has warmth, familiarity, ritual, and closure.

Three psychological tests for every change:
1. **Oxytocin over dopamine** — Does this create bonding or craving?
2. **Closure over continuation** — Does this complete an experience or extend it?
3. **Agency over manipulation** — Does this empower or exploit?

---

## What's Already Working (Protect These)

| Element | Why It Works | File Reference |
|---------|-------------|----------------|
| Lockout screen cutout effect | Genuinely novel. The sky-through-text creates reverence. Best emotional moment in the app. | `manual_lockout_view.dart` |
| Goback triangle as lockout button | Iconic. Logo = action = philosophy. | `home_lockout_button.dart` |
| Glass container system | Premium, distinctive visual language. | `AppGlassContainer` |
| Chat-style staggered feed | Feels like a conversation, not a broadcast. | `feed_view.dart` |
| 150-member cap | Dunbar's number enforced. The most powerful design decision. | `your_circle_view.dart` |
| Goback score (battery-based) | Measures real disconnection without gamification. | `goback_score_calculator.dart` |
| Memorable post selection | Forces daily reflection. Brilliant concept. | `memorable_post_selection_dialog.dart` |
| "Nothing new — enjoy the quiet" | The gold standard for empty state copy. | Notification empty state |
| Remove confirmation copy | "True bonds deserve attention..." — emotionally aware. | `your_circle_view.dart` |

---

## Phase 1: Quick Wins (1-2 days each, high emotional ROI)

These are copy changes, single-line additions, and minimal animations that dramatically shift the emotional experience.

### 1.1 — Add Haptic Feedback to Key Moments
**What:** Add haptic feedback to lockout completion, post publish, circle join, and lockout activation.
**Why (Psychology):** Haptic feedback creates embodied cognition — physical sensation reinforces emotional meaning. Currently only 1 haptic call exists in the entire codebase.
**Implementation:**
- `HapticFeedback.heavyImpact()` on lockout timer completion (`manual_lockout_view.dart`)
- `HapticFeedback.mediumImpact()` on post publish success (`publish_content_view.dart`)
- `HapticFeedback.mediumImpact()` on lockout activation confirmation (`manual_lockout_dialog.dart`)
- `HapticFeedback.lightImpact()` on circle join success (`join_circle_view.dart`)
**Complexity:** S — 4 single-line additions
**Files:** `manual_lockout_view.dart`, `publish_content_view.dart`, `manual_lockout_dialog.dart`, `join_circle_view.dart`

### 1.2 — Unhide Lockout Notifications
**What:** Remove the filter that excludes `lockoutStarted` and `lockoutJoined` from the notifications view.
**Why (Psychology):** Lockout is the app's signature behavior. Hiding lockout events contradicts the philosophy. "Sarah went offline for 3 hours" is exactly the kind of social proof that normalizes healthy behavior (Cialdini) and creates collective effervescence (Durkheim).
**Implementation:** Remove the `n.type != NotificationType.lockoutStarted && n.type != NotificationType.lockoutJoined` filter.
**Complexity:** S — Single line removal
**Files:** `notifications_view.dart`

### 1.3 — Warm Up Empty States
**What:** Replace generic empty state text with personality-rich, philosophy-aligned copy.
**Why (Psychology):** Empty states are moments of maximum emotional vulnerability for users. "Nothing here" creates loneliness. "Your circle is waiting" creates anticipation.
**Proposed copy:**
- Feed (no posts): "Your circle is quiet. Start a lockout and share what you come back to."
- Feed (caught up): "All caught up. Your circle knows you were here."
- Circle (no members): "Invite the people who matter. You can have up to 150."
- Friends locked out (none): "No one's offline right now. Be the first to go back."
- Memorable post dialog: "Yesterday's moments are fading. Save one to remember?"
- Notifications (empty): Already perfect — "Nothing new — enjoy the quiet."
**Complexity:** S — Translation key updates
**Files:** `en.json`, `home_feed_empty_state.dart`, `friends_locked_out_view.dart`, `memorable_post_selection_dialog.dart`

### 1.4 — Post Expiry Indicator
**What:** Show remaining time on each post in the feed as a small badge (e.g., "12h left" or "2h left").
**Why (Psychology):** The 24h lifecycle is the product's defining philosophical feature, yet it's completely invisible to users. Making it visible reinforces scarcity (increases perceived value), creates healthy presence ("I should see this now"), and teaches the app's core concept through experience rather than words.
**Implementation:** Calculate `post.expiresAt.difference(DateTime.now())` and display as a small text badge on the squircle card. Posts in their final 2 hours get warmer-toned badge.
**Complexity:** S — One widget addition per card
**Files:** `feed_post_card.dart`

### 1.5 — Rename "Skip" to "Keep It Private"
**What:** After lockout completion, change "Skip" to "Keep it to yourself" or "Just for you."
**Why (Psychology):** "Skip" dismisses the offline experience. "Keep it to yourself" honors it. The user chose not to share, and that's a valid choice that deserves respect.
**Complexity:** S — Translation key change
**Files:** `manual_lockout_view.dart`, `en.json`

### 1.6 — Notification Copy Warmth
**What:** Update push notification templates to create gentle curiosity instead of clinical reporting.
**Why (Psychology):** Curiosity gap (partial information) creates anticipation without anxiety. "Name felt something about your post" is warmer than "Name reacted to your post."
**Proposed templates:**
- Reaction: "[Name] felt something about your moment"
- Comment: "[Name] has something to say"
- Tag: "[Name] is thinking of you"
- Friend joined: "Someone new just joined your circle"
- Lockout started: "[Name] went back for [duration]"
**Complexity:** S — Backend notification template changes
**Files:** Push notification templates (server-side), `en.json`

---

## Phase 2: Medium Effort, High Impact (3-5 days each)

### 2.1 — Publish Moment Celebration
**What:** Replace the success snackbar with a brief full-screen celebration: post thumbnail floats upward + drawn checkmark animation + "Shared." text + heavy haptic.
**Why (Psychology):** Peak-End Rule (Kahneman) — the publish moment is both the peak and end of the creation flow. Currently it's a dismissible snackbar. This is the primary value exchange of the app and deserves ceremony. Commitment consistency means a satisfying completion reinforces future sharing.
**Implementation:**
- On publish success: dim background, `CustomPaint` stroke animation for checkmark (400ms), "Shared." text fade-in, `HapticFeedback.heavyImpact()`.
- After 600ms, crossfade to feed with highlight glow on the new post.
**Complexity:** M — New overlay widget, animation controller, modification to publish flow
**Files:** `publish_content_view.dart`, `lockout_post_editor_view.dart`, `feed_view.dart`

### 2.2 — Onboarding Story Pacing
**What:** Replace the static objective page text block with 3 sequential statements that fade in on tap: "Your brain evolved for tribes." → "Not timelines." → "goback is connection without the noise."
**Why (Psychology):** Primacy effect — first impressions form lasting mental models. Narrative transportation — stories you participate in persuade more than text you read. The current page dumps intellectual content; the proposed version creates an experience that teaches the philosophy through pacing itself.
**Implementation:**
- 3 `AnimatedOpacity` + `AnimatedSlide` phases, user-paced via tap
- Background transitions from black to dark surface across all phases
- Final phase: triangle logo rotation entrance + "You were invited to be here"
- `HapticFeedback.mediumImpact()` on triangle entrance
**Complexity:** M — Rework of objective page view
**Files:** `objective_view.dart`, `en.json`

### 2.3 — Time Limit Gentle Warnings
**What:** As the daily time limit approaches, use breathing triangle animation and warm amber tinting instead of a hard cutoff. When time expires, blur the feed and show a glass card: "Your time today is complete. You connected with N friends."
**Why (Psychology):** Self-Determination Theory — autonomy-supportive constraints feel caring, not controlling. Nudge theory — gentle environmental cues are more effective than hard stops. The time limit should feel like sunset, not a siren.
**Implementation:**
- 5-min warning: lockout triangle button begins gentle breathing animation
- 2-min warning: feed date overlay gains amber tint, triangle quickens
- Time reached: feed blurs (sigma 0→5), glass card with connection count
- No "extend time" button — the constraint is a gift
**Complexity:** M — Modifications to feed view, lockout button, new overlay
**Files:** `feed_lockout_button.dart`, `feed_date_overlay.dart`, `feed_view.dart`, time limit page implementation

### 2.4 — Loading State Skeletons
**What:** Replace all `CircularProgressIndicator` instances with contextual skeleton loading (shimmer squircles for feed, shimmer circles for members, shimmer cards for notifications).
**Why (Psychology):** Endowed progress effect — seeing the shape of what's coming increases patience and satisfaction. Generic spinners communicate "waiting"; skeleton screens communicate "preparing your space."
**Implementation:**
- `ShaderMask` with animated `LinearGradient` for shimmer effect
- Skeleton shapes matching actual content layout (squircles, circles, cards)
- Reusable `ShimmerPlaceholder` widget
**Complexity:** M — New shared component, modifications to multiple views
**Files:** New `shimmer_placeholder.dart`, `feed_view.dart`, `notifications_view.dart`, `your_circle_view.dart`

### 2.5 — Goback Score Contextual Feedback
**What:** After lockout completion, animate the score counting up (0→final, 800ms) and show a tier-based phrase below: 80-100 "You were truly present" / 60-79 "A meaningful pause" / 40-59 "Every moment counts" / <40 "A good start."
**Why (Psychology):** Numbers without context create anxiety. Narrative framing transforms a metric into an affirmation. The count-up animation creates anticipation and makes the score feel earned.
**Implementation:**
- `TweenAnimationBuilder<double>` for count-up
- Tier phrases as translation keys
- Brief pause (400ms) before score reveal for anticipation
**Complexity:** M — Modification to lockout completion view
**Files:** `manual_lockout_view.dart`, `en.json`

### 2.6 — "All Caught Up" Completion Moment
**What:** When the user has viewed all posts in the feed, show a brief centered overlay: "All caught up" with a light haptic. Appears once per session.
**Why (Psychology):** The Zeigarnik effect (inverted) — providing closure prevents the anxious "maybe there's more" feeling. Schwartz's satisficing research shows that knowing you've seen everything produces satisfaction. This is "the most important screen in the app" per the psychology research.
**Implementation:**
- Detect scroll reaching `maxScrollExtent` in reversed list
- `AnimatedOpacity` overlay, `HapticFeedback.lightImpact()`
- Auto-dismiss after 2 seconds, shown once per session via flag
**Complexity:** M — Feed view modification
**Files:** `feed_view.dart`

### 2.7 — Daily Greeting on First Open
**What:** First app open each day shows a brief (2s) time-appropriate greeting: "Good morning, [username]. N friends shared today." Fades out and reveals the feed.
**Why (Psychology):** Ritual anchoring — consistent temporal cues create healthy rhythms. The greeting humanizes the app and creates a "returning to a place" feeling rather than "checking a feed."
**Implementation:**
- Check `DateTime.now().hour` for greeting variant
- Store last-greeted date in `SharedPreferences`
- `AnimatedOpacity` + `AnimatedSlide` overlay
**Complexity:** M — New overlay component, lifecycle hook
**Files:** `home_view.dart` or `home_page.dart`, new greeting component

---

## Phase 3: High Effort, Transformative Impact (1-2 weeks each)

### 3.1 — Content Expiration Ceremony
**What:** Posts in their final 2 hours show subtle opacity reduction (0.9). When a post expires while the user is in the feed, it fades out gracefully (400ms opacity → 0, then 200ms height collapse) with a light haptic, rather than disappearing instantly.
**Why (Psychology):** Wabi-sabi — beauty in impermanence. The 24h lifecycle is the product's defining philosophy but currently has zero visual ceremony. Making disappearance beautiful teaches acceptance and reinforces the app's worldview.
**Implementation:**
- Cache notifier needs to emit removal events (not just remove)
- `AnimatedList.removeItem()` with `FadeTransition` + `SizeTransition`
- Age calculation per card for opacity treatment
**Complexity:** L — Requires cache event architecture change
**Files:** Feed cache provider, `feed_view.dart`, `feed_post_card.dart`

### 3.2 — Circle Join Threshold Ritual
**What:** When joining a circle, the goback triangle expands from center screen as a mask, revealing the circle view behind it (like stepping through a doorway). Member avatars appear one by one with staggered bounce animation. Triple haptic welcome sequence.
**Why (Psychology):** Threshold ritual (anthropology) — transitions between social spaces deserve ceremony. Belonging cues (Daniel Coyle) — small signals that say "you are part of this group now." Currently, joining is indistinguishable from submitting a form.
**Implementation:**
- `ClipPath` with animated triangle scale
- `AnimatedList` with staggered `Curves.elasticOut` per member
- Haptic sequence via `Future.delayed` chain
**Complexity:** L — Custom route builder, new celebration view
**Files:** `join_circle_view.dart`, `review_circle_page.dart`

### 3.3 — Lockout Start Ceremony
**What:** Replace the Material dialog with a full-screen "declaration of intention" experience. After selecting duration and activity, the activity text flashes full-screen ("Going running" — Lilita One, large, centered) for 600ms with heavy haptic, then transitions to the lockout screen with a "closing door" animation.
**Why (Psychology):** Commitment device activation — the moment of choosing to disconnect should feel monumental. Implementation intentions (Gollwitzer) show that articulating what you'll do dramatically increases follow-through. The current dialog feels like setting a kitchen timer.
**Implementation:**
- New full-screen lockout setup page replacing dialog
- Intention declaration flash with `FadeTransition`
- Custom "closing door" `PageRouteBuilder` (screen halves slide inward)
**Complexity:** L — New page, custom transition
**Files:** `manual_lockout_dialog.dart` (replace), new lockout setup page

### 3.4 — Emotion-Aware Navigation Transitions
**What:** Different destinations get different transition animations: circle view slides laterally (entering a room), profile scales down (looking inward), notifications slide up (opening a mailbox), lockout closes inward (shutting a door).
**Why (Psychology):** Spatial metaphor theory — directional movement creates meaning in the user's mental model. Currently all transitions are default `MaterialPageRoute`. Each destination has a different emotional quality that should be reinforced by motion.
**Implementation:**
- Custom `PageRouteBuilder` per destination type
- Register in the router configuration
**Complexity:** L — Router/navigation infrastructure change
**Files:** Route definitions, `dedecube_router` integration

### 3.5 — Session Summary on Departure
**What:** Track session stats (time spent, posts viewed, friends' content seen). On resume after >5 minutes, show a brief glass card: "Last visit: you spent 8 min and connected with 4 friends." Optional delayed local notification after closing: "Your circle saw you today. See you tomorrow."
**Why (Psychology):** Peak-End Rule — the end of an experience shapes memory. Closure need — completing an experience creates satisfaction. Post-interaction emotional residue should be warm, not anxious.
**Implementation:**
- `WidgetsBindingObserver` for lifecycle events
- Session stats stored in memory, persisted on pause
- Resume check with time threshold
- `flutter_local_notifications` for delayed departure notification
**Complexity:** L — New system, lifecycle integration
**Files:** New session tracker, `home_page.dart`, notification service

### 3.6 — Invite Code Envelope Experience
**What:** When entering an invite code, show a glass card styled like a sealed letter with a breathing animation. Tap to "open" with 3D perspective transform. Code field appears inside. On success: "Welcome to [Circle Name]. You are member #47."
**Why (Psychology):** Scarcity principle (Cialdini) + social proof of trust — being invited means someone vouched for you. Currently entering a code feels like entering a discount coupon. The envelope metaphor transforms it into receiving a personal invitation.
**Implementation:**
- `AppGlassContainer` with `AnimatedScale` breathing
- `Transform` with `Matrix4` for 3D envelope open
- Member count display on success
**Complexity:** L — New interaction pattern, 3D transform
**Files:** `join_circle_view.dart`

---

## Phase 4: Vision (Long-term, foundational)

### 4.1 — Calendar as Personal Journal
Transform the profile calendar from a grid of dots into a visual story: saved posts with thumbnails, lockout durations overlaid, streaks visible, activity types from lockout text. The calendar becomes a reflection tool that shows your relationship with presence over time.

### 4.2 — Relationship Depth Indicators
Show connection strength in the circle based on mutual lockouts, content exchanges, time connected. Not a score — a warmth indicator (thicker accent ring, subtle glow). Encourages deeper connection, not wider networks.

### 4.3 — Sound Design Identity
Create a minimal audio identity: lockout start chime (single bell tone), completion return sound (warm chord), post publish confirmation (soft click). All optional, all defeatable. Sound is the most underutilized emotional channel in mobile apps.

### 4.4 — Time-Aware Lockout Screen
Lockout sky image changes based on real time: dawn, day, sunset, night. The locked screen reflects the actual world outside, reinforcing "the real world is beautiful — go experience it."

### 4.5 — Circle Covenant
A visible shared agreement visible to all circle members: "What is shared here stays here." Even a simple banner reinforces psychological safety (Edmondson) and enables the vulnerability (Brown) that creates deep connection.

---

## Anti-Patterns to Avoid

These emerged consistently across all three research documents. **Never implement these:**

| Anti-Pattern | Why It's Harmful | Alternative |
|-------------|-----------------|-------------|
| Like/follower counts | Creates dopamine-driven status games, variable reward addiction | "Seen by" indicators create belonging without competition |
| Public profiles / discoverability | Destroys the trust boundary that enables vulnerability | Keep profiles circle-only |
| "You missed X posts" notifications | Creates guilt-driven FOMO, punishes absence | Content that expires leaves no trace of what was missed |
| "Extend time" on daily limit | Undermines the commitment device, teaches the user their choice doesn't matter | No negotiation — the constraint is a gift |
| Save/archive for shared content | Collapses authenticity benefit, users revert to curating for posterity | Only the memorable post single-selection exists |
| Infinite scroll / load more | Prevents closure, enables mindless consumption | Finite feed with "all caught up" |
| Algorithmic feed ordering | Undermines autonomy, creates variable reward patterns | Chronological only |
| Streaks / gamification badges | Satisfies competence but quickly becomes extrinsic motivation, creates guilt | Reflective stats (showing patterns) not competitive metrics |
| Red notification count badges | Creates urgency and anxiety | Subtle dot indicator or no badge |

---

## Measurement Framework

Do not measure engagement time. Measure these instead:

| Metric | What It Tells You | Target |
|--------|-------------------|--------|
| Post-session satisfaction (survey) | "Did this feel like time well spent?" | >80% positive |
| Lockout completion rate | Are users following through on their commitment? | >70% |
| Circle message diversity | Are all members participating, not just a few? | Gini coefficient < 0.4 |
| Return rate without notification | Do users come back on their own? | >50% daily opens are organic |
| Session length distribution | Is usage concentrated or spread? | Bimodal: short check-ins + intentional sessions |
| Memorable post save rate | Are users reflecting on their content? | >60% when prompted |
| Time to "all caught up" | Can users reach closure quickly? | <5 min median |

---

## Implementation Order (Recommended)

```
Week 1:  Phase 1 (all quick wins — ship as a single emotional update)
Week 2:  2.1 (publish celebration) + 2.5 (score feedback) + 2.6 (all caught up)
Week 3:  2.2 (onboarding pacing) + 2.7 (daily greeting)
Week 4:  2.3 (time limit warnings) + 2.4 (skeleton loading)
Week 5:  3.1 (expiration ceremony) + 3.3 (lockout start ceremony)
Week 6:  3.2 (circle join ritual) + 3.6 (invite envelope)
Week 7:  3.4 (emotion-aware transitions)
Week 8:  3.5 (session summary) + polish pass

Phase 4 items are ongoing vision work — schedule based on user feedback.
```

---

## The One-Sentence Thesis

**goback already has the right philosophy and the right constraints; it now needs the emotional language — in haptics, motion, copy, and ceremony — to make users *feel* what the product *means*.**
