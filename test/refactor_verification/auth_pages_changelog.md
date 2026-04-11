# Auth Pages Refactoring - Changelog

## Summary
Extracted shared `FormSubmitButton` widget from 4 near-identical submit button implementations across auth and profile pages.

## Changes

### New Files
- `lib/presentation/components/buttons/form_submit_button.dart` - Shared submit button wrapping `FormerFormConsumer` + `CallToAction.primary.filled`. Accepts `onSubmit`, `isEnabled`, `labelText`.
- `test/refactor_verification/auth_pages_test.dart` - Structural verification test.
- `test/refactor_verification/auth_pages_confidence.md` - Bayesian confidence analysis (99%).

### Modified Files
- `lib/presentation/pages/sign_in/components/sign_in_button.dart` - Simplified to delegate to `FormSubmitButton`. Removed unused `MainLayout`/`SignInLayout` mixins and `FormerFormConsumer`/`CallToAction` imports (42 -> 22 lines).
- `lib/presentation/pages/otp/components/otp_button.dart` - Simplified to delegate to `FormSubmitButton`. Removed unused `MainLayout`/`OtpLayout` mixins (38 -> 16 lines).
- `lib/presentation/pages/create_profile/components/create_profile_button.dart` - Simplified to delegate to `FormSubmitButton`. Removed unused `MainLayout`/`CreateProfileLayout` mixins (43 -> 22 lines).
- `lib/presentation/pages/edit_profile/components/confirm_edit_profile_button.dart` - Simplified to delegate to `FormSubmitButton`. Removed unused `MainLayout`/`EditProfileLayout` mixins (43 -> 22 lines).

### Unchanged Files
- All `*_page.dart`, `*_view.dart`, `*_layout.dart`, `*_routable.dart` files - no changes.
- All hooks (`use_sign_in_form.dart`, `use_otp_form.dart`, `use_create_profile_form.dart`, `use_edit_profile_form.dart`) - no changes.
- All shared form fields (`username_form_field.dart`, `description_form_field.dart`) - no changes.

## Line Count Impact
- Before: 166 lines across 4 button files (42 + 38 + 43 + 43)
- After: 82 lines across 4 button files + 44 lines shared widget = 126 total
- Net reduction: 40 lines (-24%)

## Behavioral Changes
- **OTP button text color**: Now uses `canSubmit` (form valid AND enabled) for text color instead of just `isEnabled`. This aligns with the other 3 buttons. Cosmetic only - button was already disabled when form invalid.

## Public API
- No changes to any public class names, constructors, or parameters.
- No changes to any route paths.
- No changes to any layout values.
