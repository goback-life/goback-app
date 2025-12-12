import 'package:cloudless/core/features/auth/domain/providers/has_completed_objective_provider.dart';
import 'package:cloudless/core/features/auth/domain/providers/mark_objective_completed_provider.dart';
import 'package:cloudless/presentation/pages/sign_in/sign_in_routable.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';

AuthNavigationFlowHookResult useAuthNavigationFlow(WidgetRef ref) {
  final isLoading = useState<bool>(false);
  final hasCompleted = useState<bool?>(null);

  useEffect(() {
    void checkAuthNavigationFlowStatus() async {
      final result = await ref.read(hasCompletedObjectiveProvider.future);
      result.fold(
        (completed) => hasCompleted.value = completed,
        (error) => hasCompleted.value = false,
      );
    }

    checkAuthNavigationFlowStatus();
    return null;
  }, []);

  Future<void> markAsCompleted() async {
    if (isLoading.value) {
      return;
    }

    isLoading.value = true;

    final result = await ref.read(markObjectiveCompletedProvider.future);
    result.fold(
      (success) {
        hasCompleted.value = true;
        router.replace(const SignInRoutable(), context: ref.context);
      },
      (error) {
        logger.error('Failed to mark objective as completed', exception: error);
      },
    );

    isLoading.value = false;
  }

  return AuthNavigationFlowHookResult(
    hasCompleted: hasCompleted.value,
    isLoading: isLoading.value,
    markAsCompleted: markAsCompleted,
  );
}

class AuthNavigationFlowHookResult {
  const AuthNavigationFlowHookResult({
    required this.hasCompleted,
    required this.isLoading,
    required this.markAsCompleted,
  });

  final bool? hasCompleted;
  final bool isLoading;
  final Future<void> Function() markAsCompleted;
}
