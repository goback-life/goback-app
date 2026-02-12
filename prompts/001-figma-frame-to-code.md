<objective>
Implement a single Figma design frame as pixel-perfect Flutter code in the GoBack app.

You will be given a Figma node ID. Your job is to:
1. Pull the frame from Figma via MCP
2. Extract every visual specification
3. Ask clarifying questions before writing ANY code
4. Implement the frame to exact pixel-perfect fidelity
5. Present your work for approval

The bar is pixel-for-pixel match to the Figma prototype. No approximations. No "improvements". When in doubt, ask.
</objective>

<input>
Figma file: https://www.figma.com/design/Rp6c3WfSPsUx9y5bCtp7qB/V1-UI
Target node ID: {{NODE_ID}}
</input>

<design_system>
These specifications are NON-NEGOTIABLE. Do not deviate.

<palette>
Exactly 3 colours. No others may be introduced.

| Token  | Hex     | Usage                                      |
|--------|---------|--------------------------------------------|
| white  | #FFFFFF | Backgrounds, primary text (dark mode)      |
| dark   | #1A1A1A | Backgrounds, primary text (light mode)     |
| accent | #598EB5 | Interactive elements, highlights           |

Light mode is achieved by inverting white and dark. That is the ONLY difference.
</palette>

<typography>
| Role                    | Font              |
|-------------------------|-------------------|
| Content text            | Quicksand Medium  |
| Logo / lockout text     | Lilita One Regular|

Extract exact font sizes, weights, and line heights from the Figma frame.
</typography>

<surfaces>
Liquid Glass is the default surface treatment. Menus, overlays, toolbars, and all chrome-level UI use liquid glass so background content refracts and remains visible through them. The app feels immersive — UI is an overlay on content, not separate from it.

Feed items are squircles (continuous-curvature rounded rectangles) — chosen because they are calming on the eyes.

Corner radius must be a single consistent value app-wide. Extract the exact value from the Figma frame.

For every glass surface in a Figma frame, extract:
- Glass variant intent: regular (medium transparency) or clear (high transparency for media backgrounds)
- Tint colour (from the 3-colour palette only)
- Shape and corner radius
- Whether the element is interactive (buttons, toggles) or passive (panels, overlays)
- Any border: colour, width, opacity

These extracted values drive the configuration of the platform-adaptive glass system described below.
</surfaces>

<liquid_glass_architecture>
We use a HYBRID approach — native Apple Liquid Glass on iOS, shader-based on Android.

Platform routing:
- iOS 26+  → Native SwiftUI `.glassEffect()` via UiKitView (pixel-perfect Apple implementation)
- iOS < 26 → `liquid_glass_renderer` package (shader fallback)
- Android   → `liquid_glass_renderer` package (shader-based)

Dependencies (already added to pubspec):
- `liquid_glass_renderer: ^0.2.0-dev.4`
- `liquid_glass_widgets: ^0.3.0-dev.1`

Native iOS files (in `ios/Runner/`):
- `LiquidGlassViewFactory.swift` — FlutterPlatformViewFactory that creates SwiftUI glass views
- `LiquidGlassView.swift` — UIHostingController wrapper for SwiftUI views with `.glassEffect()`
- Registered in AppDelegate with viewType `"app_liquid_glass"`

Dart abstraction (in `lib/presentation/components/glass/`):
- `app_glass_container.dart` — Unified widget wrapping both implementations
- `glass_config.dart` — Shared config: variant, tint, shape, cornerRadius, interactive

The unified Dart API:
```dart
AppGlassContainer(
  variant: GlassVariant.regular,  // regular | clear
  tint: AppColors.accent,         // from 3-colour palette only
  cornerRadius: 24,               // extracted from Figma
  interactive: true,              // enables press feedback (iOS: bounce/shimmer, Android: shader glow)
  child: myContent,
)
```

When implementing any glass surface from a Figma frame:
1. Determine the glass variant from the Figma visual (regular for most chrome, clear for media overlays)
2. Map the tint to one of the 3 palette colours
3. Extract the corner radius
4. Decide if the element is interactive or passive
5. Use `AppGlassContainer` — NEVER use raw `BackdropFilter` or `LiquidGlass` directly

For each glass element, you must implement BOTH sides:
- The Dart widget using `AppGlassContainer` (which handles platform branching)
- Any new SwiftUI glass configuration needed in the iOS native layer (new shapes, new glass groupings via `GlassEffectContainer`, morphing transitions via `glassEffectID`)

SwiftUI glass variants reference:
- `.glassEffect()` — regular, default for most UI
- `.glassEffect(.clear)` — high transparency, for media-rich backgrounds
- `.tint(_ color:)` — chainable, applies semantic colour
- `.interactive()` — chainable, enables scaling/bounce/shimmer on press
- `GlassEffectContainer` — groups glass elements to prevent glass-sampling-glass
- `.glassEffectID(_ id:, in: namespace)` — enables morphing transitions between glass elements
</liquid_glass_architecture>

<scroll_direction>
All scrollable views scroll UPWARD. This is deliberate — a departure from the downward-scroll pattern of TikTok/Instagram/etc.
</scroll_direction>

<navigation_model>
- Press-and-hold anywhere opens the nav overlay (from any screen)
- Press-and-hold while locked out shows the list of friends who are also locked out
- Navigation and action are strictly separated (see design principles)
</navigation_model>
</design_system>

<design_principles>
Apply these everywhere. If a decision is ambiguous, resolve it using these rules:

1. GESTURE — Where it makes spatial sense that one element is above, below, or beside another, the user must be able to swipe between them.
2. PATTERN — If a pattern works once, it works everywhere. No one-off treatments.
3. UNITY — One dominant action per view. If there are two competing CTAs, one shouldn't be there.
4. SEPARATION — Navigation changes location; actions change state. A single interaction must never do both.
5. DECORATION — If an element does not serve a clear purpose, remove it.
</design_principles>

<workflow>
Follow these steps in exact order. Do NOT skip or combine steps.

<step_1_extract>
Pull the Figma frame using the MCP tools:

1. Call `get_design_context` with the target node ID to get the full design specification.
2. Call `get_screenshot` with the same node ID to see the visual output.
3. If the frame contains sub-components or nested groups, call `get_metadata` on the node to understand the full hierarchy, then call `get_design_context` on important child nodes for their specifications.

From the design context, extract and document ALL of the following:

Layout & dimensions:
- Frame dimensions (width x height)
- Layout direction (row/column), alignment, distribution
- Every spacing value: padding, margin, gap (in exact pixels)

Typography:
- Every text element: content, font family, font size, font weight, line height, colour, opacity

Visual:
- Every corner radius value
- Every border: colour, width, opacity
- Every shadow: offset, blur, spread, colour, opacity
- Every image/icon: size, position, any overlays or treatments

Glass surfaces (for each glass element):
- Glass variant: regular or clear (infer from transparency level and context)
- Tint colour (map to white, dark, or accent)
- Shape and corner radius
- Whether interactive (button/toggle) or passive (panel/overlay)
- Any border on the glass surface

Present this extraction as a structured specification table BEFORE asking questions.
</step_1_extract>

<step_2_clarify>
MANDATORY: Ask the user ALL of the following before writing any code:

1. What is this frame? What screen state does it represent?
2. How does it relate to adjacent frames? What gesture transitions to/from it?
3. For each interactive element visible: What does tap do? What does hold do? What does swipe do? Or is it passive/decorative?
4. Anything ambiguous in the design — unclear layering, overlapping elements, states that aren't obvious.

Wait for answers. Do NOT proceed to implementation until you have responses.
</step_2_clarify>

<step_3_implement>
After receiving clarification, implement the frame in Flutter. Each frame requires BOTH Dart and iOS native work.

Fidelity rules:
- If Figma says 16px padding, use 16px padding
- Match exact hex colours — no Material theme colours, no Color.withOpacity approximations that lose precision
- Match exact font sizes, weights, line heights
- Match exact spacing, alignment, sizing
- Match exact corner radii, border widths, shadow parameters

Glass implementation (for every glass surface in the frame):
1. In Dart: use `AppGlassContainer` with the extracted config (variant, tint, cornerRadius, interactive)
2. In iOS native (`ios/Runner/`): ensure the SwiftUI side supports the required glass configuration
   - If a new glass shape or grouping is needed, add it to the SwiftUI layer
   - If glass elements need to morph between states, set up `GlassEffectContainer` and `glassEffectID`
   - If a glass element needs a new tint or variant not yet handled, extend the platform channel config
3. NEVER use raw `BackdropFilter`, `LiquidGlass`, or `LiquidGlassLayer` directly — always go through `AppGlassContainer`

Non-glass implementation:
- Use `ClipRRect` with `SmoothRectangleBorder` or equivalent for squircles on non-glass elements
- Use `Container` decoration for non-glass backgrounds
- Prefer `SizedBox` for fixed spacing, `Padding` for insets
- Keep widgets pure — no business logic in build methods
- Follow existing naming conventions: `{page_name}_{component_name}.dart`
</step_3_implement>

<step_4_present>
Present the implementation with:
1. A brief summary of what was built (max 3 bullets)
2. Files created or modified, grouped by layer:
   - **Dart** (lib/presentation/...): widget files, component files
   - **iOS native** (ios/Runner/...): any SwiftUI additions or modifications
   - **Glass config**: any new AppGlassContainer configurations introduced
3. Any assumptions made due to Figma ambiguity
4. Any values that could not be extracted precisely
5. Note any deviations from the Figma spec and why they were necessary
6. Platform notes: any differences in how the glass renders between iOS native and Android shader

Then wait for approval before moving on.
</step_4_present>
</workflow>

<codebase_conventions>
Read the project's CLAUDE.md before implementing. Additionally:

- Package imports use `package:cloudless/...`
- Pages live in `lib/presentation/pages/{page_name}/`
- Page-specific components go in `lib/presentation/pages/{page_name}/components/`
- Shared components go in `lib/presentation/components/`
- Glass abstraction lives in `lib/presentation/components/glass/`
  - `app_glass_container.dart` — the unified glass widget (platform-adaptive)
  - `glass_config.dart` — GlassVariant, GlassShape, and config classes
- iOS native glass layer lives in `ios/Runner/`
  - `LiquidGlassViewFactory.swift` — FlutterPlatformViewFactory
  - `LiquidGlassView.swift` — UIHostingController wrapper for SwiftUI glass views
- Theme constants are in `lib/presentation/themes/constants/`
- File naming: `{page_name}_{descriptor}.dart` for page-specific, `main_{descriptor}.dart` for shared
- Routables use Freezed: `{page_name}_routable.dart`
- Max 500 lines per file, max 200 lines per function
- Use `prefer_single_quotes` and `always_use_package_imports`
- Generated files (*.freezed.dart, *.g.dart) are never edited manually
</codebase_conventions>

<constraints>
- Do NOT write any code before completing step_2_clarify and receiving answers
- Do NOT introduce colours outside the 3-colour palette (white, dark, accent)
- Do NOT introduce fonts outside Quicksand Medium and Lilita One Regular
- Do NOT add packages beyond `liquid_glass_renderer` and `liquid_glass_widgets` (already in pubspec)
- Do NOT approximate values — extract exact specifications from Figma
- Do NOT refactor or modify unrelated existing code
- Do NOT create navigation wiring or gesture handlers — visual implementation only at this stage
- Do NOT use raw `BackdropFilter` or raw `LiquidGlass` widgets — always use `AppGlassContainer`
- Every glass surface MUST work on both platforms — implement the Dart widget AND verify the iOS native SwiftUI layer supports it
- Touch the fewest files possible
</constraints>

<success_criteria>
- Frame visually matches the Figma design at pixel-level fidelity
- All extracted values (spacing, sizing, colour, typography, radius) match Figma exactly
- Every glass surface uses `AppGlassContainer` — no raw BackdropFilter or LiquidGlass
- iOS native SwiftUI layer supports all glass configurations used in the frame
- Both platforms are handled: native `.glassEffect()` on iOS 26+, shader renderer on Android/older iOS
- Code follows existing codebase conventions and naming patterns
- No new colours or fonts introduced
- Clarifying questions were asked and answered before any code was written
- Implementation is purely visual — no business logic or navigation wiring
</success_criteria>
