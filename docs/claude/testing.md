# Testing Strategy

## Test Types & When to Use Each

### Unit Tests (preferred for new work)
Location: `test/core/features/<feature>/domain/`
Use for: providers with pure state logic, use cases, mappers, model methods.
Do NOT use for: anything that calls Supabase directly (use integration tests).

```dart
// test/core/features/post/domain/providers/feed_posts_cache_provider_test.dart
// Pattern: ProviderContainer with no overrides for pure state
container = ProviderContainer();
final notifier = container.read(feedPostsCacheProvider.notifier);
notifier.addPost(post);
expect(container.read(feedPostsCacheProvider).posts.length, equals(1));
```

### Refactor Verification Tests
Location: `test/refactor_verification/`
These exist to verify behavior hasn't changed during refactors.
Do not delete or modify — they are a safety net, not documentation.

### Integration Tests (future)
Location: `test/integration/`
Use for: service methods that call Supabase, full auth flows.
Requires: local Supabase running (`supabase start`) or a test project.
Not yet established in this codebase — build pattern before adding.

## Provider Testing Pattern
```dart
setUp(() => container = ProviderContainer());
tearDown(() => container.dispose());

// Override a dependency:
container = ProviderContainer(overrides: [
  supabaseClientProvider.overrideWithValue(mockClient),
]);
```

## Fake Data Helpers
`test/test_utils/fake_feed_post.dart` — `createFakePost(id:, publishedAt:, authorUsername:)`
`createPostsWithExpiry(validCount:, expiredCount:)` — creates sets with known expiry states.
Add new fakes to this file when a feature needs test data.

## Test File Naming
- `lib/core/features/post/domain/providers/foo_provider.dart`
  → `test/core/features/post/domain/providers/foo_provider_test.dart`
- Mirror the lib/ directory structure exactly in test/

## What Must Be Tested
- Every new Riverpod notifier: state transitions, error states, loading states
- Every new use case: success path, failure path, edge cases
- Every new mapper: valid input, missing optional fields, null handling
- Widgets: only if they contain conditional rendering logic

## What Is Intentionally Not Tested
- Generated code (*.g.dart, *.freezed.dart)
- Supabase service methods (require real DB — integration test territory)
- Pure passthrough providers (one-liner that just reads another provider)

## Async Testing
```dart
test('async provider loads', () async {
  final future = container.read(myAsyncProvider.future);
  final result = await future;
  expect(result, isNotNull);
});
```

## Running Tests
```bash
fvm flutter test                        # all tests
fvm flutter test test/core/             # unit tests only
fvm flutter test --coverage             # with coverage report
```
