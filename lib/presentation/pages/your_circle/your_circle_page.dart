import 'package:cloudless/core/features/connection/domain/hooks/use_circle_members.dart';
import 'package:cloudless/presentation/components/main_app_bar/main_app_bar.dart';
import 'package:cloudless/presentation/pages/your_circle/views/your_circle_view.dart';
import 'package:cloudless/presentation/pages/your_circle/your_circle_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class YourCirclePage extends HookConsumerWidget
    with MainLayout, YourCircleLayout {
  const YourCirclePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final circleMembersData = useCircleMembers(ref);
    final friendCount = circleMembersData.allUsers.map((user) => user.id).toSet().length;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      resizeToAvoidBottomInset: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: topMargin),
          MainAppBar(title: translator.translate('pages.your_circle.title')),
          const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Text(
              translator.translate(
                'pages.invite_to_circle.friend_count',
                arguments: {'count': friendCount.toString()},
              ),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(height: titleToImage),
          const Expanded(child: YourCircleView()),
        ],
      ),
    );
  }
}
