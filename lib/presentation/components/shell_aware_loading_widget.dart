import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

class ShellAwareLoadingWidget extends HookConsumerWidget {
  const ShellAwareLoadingWidget({super.key, this.color = MainColors.green500});

  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(child: CircularProgressIndicator(color: color));
  }
}
