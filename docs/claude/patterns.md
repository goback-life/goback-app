# Code Patterns

## Riverpod Provider — Async Notifier
```dart
// domain/providers/manual_lockout_notifier_provider.dart
part 'manual_lockout_notifier_provider.g.dart';

@Riverpod(keepAlive: true)
class ManualLockoutNotifier extends _$ManualLockoutNotifier {
  @override
  Future<ManualLockoutModel> build() async {
    final storable = ref.watch(manualLockoutStorableProvider);
    return _readState(storable);
  }

  Future<void> setLockout(Duration duration) async {
    state = const AsyncValue.loading();
    try {
      // ... work ...
      state = AsyncValue.data(await _readState(storable));
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      logger.error('Error', exception: error, stackTrace: stackTrace);
    }
  }
}
```
- `@Riverpod(keepAlive: true)` for app-lifetime state
- Always set `AsyncValue.loading()` before async mutations
- Always catch with `(error, stackTrace)` pair
- Use `ref.read` in methods, `ref.watch` in `build()`
- Run `fvm dart run build_runner build --delete-conflicting-outputs` after any change

## Riverpod Provider — Simple Future Provider
```dart
part 'get_friends_locked_out_provider.g.dart';

@riverpod
Future<List<LockoutSessionModel>> getFriendsLockedOut(
  GetFriendsLockedOutRef ref,
) async {
  final service = ref.watch(lockoutSessionServiceProvider);
  final result = await service.getActiveFriendLockouts();
  return result.fold((data) => data, (error) => throw error);
}
```

## Result Pattern
```dart
// All service/repo async ops return Result<T>
final result = await service.createSession(duration: duration);
result.fold(
  (session) { sessionId = session.id; },
  (error) => logger.warning('Failed: $error'),
);

// asyncFold for nested async in fold branches
await result.asyncFold(
  (data) async { await doSomething(data); },
  (error) async { logger.warning('$error'); },
);
```

## Service — Supabase Query Pattern
```dart
class PostCrudService {
  PostCrudService(this._supabaseClient);
  final SupabaseClient _supabaseClient;

  Future<PostDto> publishPost(String postId) async {
    final response = await _supabaseClient
        .from('posts')
        .update({'published_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', postId)
        .select()
        .single();
    return PostDto.fromJson(response);
  }
}
```
- Constructor injection of `SupabaseClient` — never use `Supabase.instance` in services
- Always `.select().single()` after insert/update to get the returned row
- JSON keys match Supabase column names exactly (snake_case)
- Store `DateTime` as `.toUtc().toIso8601String()`

## Use Case Pattern
```dart
class CreatePostUseCase implements UseCaseContract<Result<PostModel>> {
  CreatePostUseCase({required this.repository});
  final PostRepositoryContract repository;

  @override
  Future<Result<PostModel>> execute() async {
    return repository.createPost(_postData!);
  }
}
// Usage: await CreatePostUseCase(repository: repo).withPostData(data).execute();
```

## Freezed Model (with JSON)
```dart
// domain/models/lockout_session_model.dart
part 'lockout_session_model.freezed.dart';
part 'lockout_session_model.g.dart';

@freezed
class LockoutSessionModel with _$LockoutSessionModel {
  const factory LockoutSessionModel({
    required String id,
    required String endsAt,
    String? actionText,
  }) = _LockoutSessionModel;

  factory LockoutSessionModel.fromJson(Map<String, dynamic> json) =>
      _$LockoutSessionModelFromJson(json);
}
```
- Always `required` for non-nullable fields
- JSON key = Supabase column name
- Run build_runner after any model change

## Plain Model (no JSON serialization needed)
```dart
class ManualLockoutModel {
  const ManualLockoutModel({required this.isLockedOut, this.remainingDuration});
  final bool isLockedOut;
  final Duration? remainingDuration;
  ManualLockoutModel copyWith({bool? isLockedOut, Duration? remainingDuration}) =>
      ManualLockoutModel(
        isLockedOut: isLockedOut ?? this.isLockedOut,
        remainingDuration: remainingDuration ?? this.remainingDuration,
      );
}
```

## Navigation
```dart
// Routable definition
@freezed
class LockoutRoutable with _$LockoutRoutable implements Routable {
  const factory LockoutRoutable() = _LockoutRoutable;
}

// Navigation
router.go(const LockoutRoutable());
router.push(const LockoutRoutable());
```

## Logging (never use print)
```dart
logger.info('Session created: $id');
logger.warning('Non-fatal: $error');
logger.error('Fatal', exception: error, stackTrace: stackTrace);
```

## Provider for Service (data layer)
```dart
// data/providers/post_crud_service_provider.dart
part 'post_crud_service_provider.g.dart';

@riverpod
PostCrudService postCrudService(PostCrudServiceRef ref) {
  final client = ref.watch(supabaseClientProvider);
  return PostCrudService(client);
}
```

## Testing — Provider Unit Test
```dart
void main() {
  group('FeatureName', () {
    late ProviderContainer container;

    setUp(() => container = ProviderContainer());
    tearDown(() => container.dispose());

    test('description', () {
      final notifier = container.read(myProvider.notifier);
      notifier.doAction();
      expect(container.read(myProvider).value, equals(expected));
    });
  });
}
```
