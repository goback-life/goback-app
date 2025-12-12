import 'dart:async';

import 'package:cloudless/core/features/profile/domain/providers/check_username_availability_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';

class DebouncedUsernameResult {
  const DebouncedUsernameResult({
    required this.value,
    required this.isDebouncing,
    this.lastCheckedUsername,
  });

  /// Result of the AsyncValue that wraps a Result
  final AsyncValue<Result<bool>> value;

  /// Whether debounce is active (timer running)
  final bool isDebouncing;

  /// Last username actually checked
  final String? lastCheckedUsername;

  /// Whether the provider is loading
  bool get isLoading => value.isLoading;

  /// Whether the provider threw an error (AsyncError)
  bool get hasError => value.hasError;

  /// true/false if available/not available; null if not checked yet
  /// or if the domain returned a Failure (Result.failure).
  bool? get isAvailable {
    if (lastCheckedUsername == null) {
      return null;
    }

    return value.whenOrNull(
      data: (result) => result.fold(
        (ok) => ok, // success(bool)
        (_) => null, // failure -> indeterminate state for the caller
      ),
    );
  }
}

/// Hook that applies debounce to username availability checks.
/// - [ref]: WidgetRef to access providers
/// - [username]: current value to validate
/// - [debounce]: debounce duration (default 500ms)
/// - [minLength]: minimum length before starting checks (default 1)
DebouncedUsernameResult useDebouncedUsernameCheck(
  WidgetRef ref,
  String username, {
  Duration debounce = const Duration(milliseconds: 500),
  int minLength = 1,
}) {
  final mountedRef = useRef<bool>(true);
  final timer = useRef<Timer?>(null);
  final isDebouncing = useState<bool>(false);
  final debouncedUsername = useState<String?>(null);

  // Cleanup timer on dispose
  useEffect(() {
    mountedRef.value = true; // Ensure mounted state is correct
    return () {
      // mark unmounted and cancel timer
      mountedRef.value = false;
      timer.value?.cancel();
    };
  }, const []);

  // Handle debounce when input updates
  useEffect(() {
    final input = username.trim();
    timer.value?.cancel();

    // Reset if too short or empty
    if (input.isEmpty || input.length < minLength) {
      if (mountedRef.value) {
        isDebouncing.value = false;
        debouncedUsername.value = null;
      }
      return null;
    }

    // Avoid triggering if identical to last checked
    if (input == debouncedUsername.value) {
      if (mountedRef.value) {
        isDebouncing.value = false; // ensure we don't get stuck
      }
      return null;
    }

    if (mountedRef.value) {
      isDebouncing.value = true;
    }

    timer.value = Timer(debounce, () {
      if (!mountedRef.value) {
        return;
      }

      isDebouncing.value = false;
      debouncedUsername.value = input;
    });

    return null;
  }, [username, minLength, debounce]);

  // Watches the provider only when we have a valid debounced value
  final AsyncValue<Result<bool>> value = debouncedUsername.value != null
      ? ref.watch(checkUsernameAvailabilityProvider(debouncedUsername.value!))
      : AsyncValue.data(
          Result.success(false),
        ); // the getter handles the "unchecked" state

  return DebouncedUsernameResult(
    value: value,
    isDebouncing: isDebouncing.value,
    lastCheckedUsername: debouncedUsername.value,
  );
}
