# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

As a general rule for all modifications: where possible I want you to use semantic compression (code generation) to keep the size of the project small, in order for you to find it easier to manage context. For all changes refer to the development-guide at the bottom of this document

## Project Overview

goback - A Flutter mobile app (iOS/Android) for creating private circles where users share temporary photo/video content with selected members. Social media today assumes that scale and meaningful connection are compatible by default, this has led to exploitation, destructiveness, and addiction. Goback aims to be a social network that is compatible with human neurochemistry which evolved to socialise in groups of no more than 150 members. In doing this, we want to make social connection meaningful again, using tech as a tool to aid our already present social algorithms (trust). We believe the way to do this in simplicity and transparency, giving the trust algorithm the tools it needs to operate at full potential. 
At the same time, we want to make the app engaging, and not too far from the network enabling social medias that exist today, but so that every action is a conscious one, and the user is in full control.
Think of goback like restoring social interaction as it was in the village, and goback is the townhall.
Features invite-only access, 24h content auto-deletion, and daily usage limits.
For any development changes, stick to the guidelines and best practices at the end of this document. I want you to code in a way that is scalable to millions of users, and compresses context in a way that you can keep working on this project for a long time without issues.

## Build Commands

All commands use FVM (Flutter Version Management) with Flutter 3.35.5. YOU MAY NOT USE THESE COMMANDS AS fvm requires an elevated shell

```bash
# Install dependencies
fvm flutter pub get

# Code generation (Riverpod, Freezed, JSON serialization)
fvm dart run build_runner build --delete-conflicting-outputs

# Watch mode for development
fvm dart run build_runner watch --delete-conflicting-outputs

# Generate icon fonts from SVG sources
fvm dart run icon_font_generator:generator --config-file=icon_font_generator.yaml

# Run app with flavor
fvm flutter run --flavor prestage
fvm flutter run --flavor stage
fvm flutter run --flavor production

# Analyze code
fvm flutter analyze
```

### Sub-Package Code Generation

Packages requiring build_runner: `dedecube_environment`, `dedecube_logger`, `dedecube_router`, `dedecube_startup`, `dedecube_storage`, `dedecube_themify`, `dedecube_translator`.

```bash
cd packages/<package_name>
fvm dart run build_runner build --delete-conflicting-outputs
```

## Architecture

### Layer Structure

```
lib/
├── core/                    # Business logic layer
│   ├── features/           # Feature modules (auth, post, profile, etc.)
│   │   └── <feature>/
│   │       ├── data/       # Implementations: repositories, services, mappers, DTOs
│   │       └── domain/     # Contracts, use cases, providers, models, hooks
│   ├── config/             # App configuration
│   ├── exceptions/         # Base exception types
│   └── utilities/          # Shared utilities
├── presentation/           # UI layer
│   ├── pages/             # Screen implementations
│   │   └── <page>/
│   │       ├── <page>_routable.dart    # Route definition with path, middlewares
│   │       ├── <page>_page.dart        # Main page widget
│   │       ├── views/                  # Page views/layouts
│   │       ├── components/             # Page-specific widgets
│   │       └── hooks/                  # Page-specific React-style hooks
│   ├── components/        # Shared UI components
│   ├── hooks/             # Shared hooks
│   ├── themes/            # Theme definitions
│   └── routes.dart        # Route registry
└── packages/              # Internal packages (dedecube_*)
```

### Key Patterns

**State Management**: Riverpod with code generation (`@riverpod` annotations). Providers are generated via build_runner.

**Result Pattern**: Async operations return `Result<T>` (success/failure) instead of throwing exceptions:
```dart
final result = await ref.read(someProvider.notifier).call(args);
result.fold(
  (value) => // handle success,
  (error) => // handle failure,
);
```

**Routing**: Uses `dedecube_router` with Freezed-based Routable classes. Each page has a `*_routable.dart` defining path, middlewares, and parameters. Navigation: `router.go(SomeRoutable())`, `router.push(SomeRoutable())`.

**Hooks**: React-style hooks pattern via `flutter_hooks` and custom hooks in `domain/hooks/` directories.

### Core Features

- **auth**: OTP-based authentication via Supabase (sign-in, verify, resend, session management)
- **post**: Content creation/viewing with 24h expiration
- **profile**: User profile management with avatar upload
- **connection**: Circle membership and invite codes
- **time_limit**: Daily usage limits enforcement
- **lockout**: Manual lockout functionality
- **notification**: Push notification handling

### Flavors

Two build flavors: `stage`, `production`. Each has separate Firebase/Supabase configs in `config/<flavor>/`.

## Linting

Uses `flutter_lints`, custom lints via `dedecube_custom_lints`, and `pyramid_lint`. Key rules enforced:
- `avoid_print` - use logger instead
- `max_lines_for_file: 500`
- `max_lines_for_function: 200`
- `avoid_returning_widgets` - extract to separate widget classes
- `prefer_single_quotes`
- `always_use_package_imports`

## Generated Files

Exclude from edits - regenerated by build_runner:
- `*.freezed.dart`
- `*.g.dart`
- `*.tailor.dart`
- `*.gen.dart`

## Development guide

===============================================================================
0) GLOBAL OPERATING MODE (NON-NEGOTIABLE)
===============================================================================
- Default to the smallest possible change that satisfies the requirement.
- Preserve existing behavior unless explicitly told otherwise.
- Never refactor, rename, reformat, reorganize, or “improve” code implicitly.
- Do not introduce new packages, patterns, or architecture layers.
- Touch the fewest files possible. Prefer single-file edits.
- Avoid cleverness. Prefer boring, explicit, readable code.
- Assume every existing line exists for a reason unless proven otherwise.

===============================================================================
1) CHANGE DISCIPLINE (HOW CODE IS MODIFIED)
===============================================================================
- Identify the exact function, widget, or model that must change.
- Edit locally. No cascading edits across unrelated modules.
- Prefer additive changes over destructive ones.
- Do not delete code unless:
  - It is unreachable AND
  - The task explicitly requires removal.
- Avoid “while I’m here” edits.

===============================================================================
2) SPEC-FIRST REQUIREMENT (FOR ANY NONTRIVIAL TASK)
===============================================================================
Before writing code, produce a micro-spec:

- Goal: what changes, in one sentence.
- Non-goals: what must remain unchanged.
- Assumptions: facts relied on (schema, API, auth state).
- Files touched: explicit list.
- Acceptance: observable behavior that proves correctness.

No code until the spec is logically sound.

===============================================================================
3) FLUTTER-SPECIFIC RULES
===============================================================================
- Widgets:
  - UI only. No business logic, no Supabase calls.
  - build() must be pure and fast.
  - Extract widgets only if readability improves materially.
- State:
  - Use the project’s existing state management approach.
  - Do not introduce a new state solution.
- Navigation:
  - Preserve existing routes and parameters.
- Styling:
  - Match existing theming and spacing conventions.
  - Do not restyle unrelated UI.

===============================================================================
4) SUPABASE RULES (DATA IS SACRED)
===============================================================================
- Dart models must mirror Supabase schema exactly.
- No silent schema assumptions.
- Do not rename, remove, or change field semantics without a migration.
- Treat JSON keys and wire formats as stable contracts.
- No service role keys or security bypasses in client code.
- All data access goes through existing services/repositories.

===============================================================================
5) MODELS & CODE GENERATION
===============================================================================
- All data models use:
  - freezed for immutability
  - json_serializable for JSON
- Never hand-write equality, copyWith, or JSON parsing.
- Never edit generated files.
- After model changes, run:
  flutter pub run build_runner build --delete-conflicting-outputs
- Do not introduce new generators.

===============================================================================
6) ARCHITECTURE BOUNDARIES
===============================================================================
- UI → state/controller → service → Supabase
- No Supabase calls from widgets.
- No Flutter imports in data or service layers.
- No UI state inside data models.
- Reuse existing services instead of creating parallel ones.

===============================================================================
7) DEPENDENCY & COMPLEXITY BUDGET
===============================================================================
- Standard Dart/Flutter APIs first.
- Existing dependencies second.
- New dependencies only if explicitly requested.
- Avoid abstractions unless they reduce real complexity.
- No “future-proofing”.

===============================================================================
8) TESTING & VERIFICATION
===============================================================================
- Existing tests must continue to pass.
- For bugs: add a regression test when feasible.
- Do not add new test frameworks.
- Verify:
  - flutter analyze
  - flutter test
- If runtime behavior changes, it must be documented explicitly.

===============================================================================
9) TOKEN & CONTEXT EFFICIENCY (CRITICAL)
===============================================================================
- Do not scan the entire repo.
- Only load files directly involved in the task.
- Prefer small, focused prompts.
- Avoid long logs; extract the exact failing lines.
- Split large tasks into independent steps or sessions.
- Treat large files as liabilities.

===============================================================================
10) OUTPUT RULES (HOW CURSOR RESPONDS)
===============================================================================
When delivering work:
- Brief summary (max 5 bullets).
- Files touched.
- Commands to run.
- Explicit note of any behavior change.
- Avoid dumping large code blocks unless necessary.

===============================================================================
11) WHEN UNCERTAINTY EXISTS
===============================================================================
- Do not guess.
- Trace call sites and usage.
- Choose the option with the smallest blast radius.
- Prefer default-off behavior or local containment.
- Stop rather than hallucinate.
