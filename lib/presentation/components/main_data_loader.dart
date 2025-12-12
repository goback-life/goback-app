import 'package:cloudless/presentation/components/error_view/main_error_view.dart';
import 'package:cloudless/presentation/components/shell_aware_loading_widget.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

class MainDataLoader<T> extends StatelessWidget {
  const MainDataLoader({
    required this.provider,
    required this.builder,
    super.key,
    this.loading,
    this.errorBuilder,
    this.onRetry,
    this.useScaffold = true,
  });

  final AsyncValue<Result<T>> provider;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? loading;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final bool useScaffold;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final child = provider.when(
      loading: () => loading ?? const ShellAwareLoadingWidget(),
      error: (error, _) => errorBuilder != null
          ? errorBuilder!(context, error)
          : MainErrorView(
              useScaffold: useScaffold,
              onRetry: () {
                onRetry?.call();
              },
            ),
      data: (result) => result.fold(
        (data) => builder(context, data),
        (failure) =>
            errorBuilder?.call(context, failure) ??
            MainErrorView(
              useScaffold: useScaffold,
              onRetry: () {
                onRetry?.call();
              },
            ),
      ),
    );

    if (useScaffold) {
      return Scaffold(body: child);
    } else {
      return child;
    }
  }
}
