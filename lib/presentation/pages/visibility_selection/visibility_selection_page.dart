import 'package:cloudless/core/features/connection/domain/providers/get_circle_members_provider.dart';
import 'package:cloudless/presentation/components/main_data_loader.dart';
import 'package:cloudless/presentation/pages/visibility_selection/views/visibility_selection_view.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

class VisibilitySelectionPage extends HookConsumerWidget {
  const VisibilitySelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(getCircleMembersProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: MainDataLoader(
        provider: asyncValue,
        useScaffold: false,
        onRetry: () => ref.invalidate(getCircleMembersProvider),
        builder: (context, members) {
          return VisibilitySelectionView(members: members);
        },
      ),
    );
  }
}
