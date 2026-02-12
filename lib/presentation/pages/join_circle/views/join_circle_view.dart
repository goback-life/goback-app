import 'package:cloudless/presentation/pages/join_circle/components/join_circle_button.dart';
import 'package:cloudless/presentation/pages/join_circle/components/join_circle_form_field.dart';
import 'package:cloudless/presentation/pages/join_circle/hooks/use_join_circle_form.dart';
import 'package:cloudless/presentation/pages/join_circle/join_circle_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_form/dedecube_form.dart';
import 'package:dedecube_presentation/hooks/use_loading_overlay.dart';
import 'package:dedecube_presentation/widgets/layout/bottomed_list_view.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class JoinCircleView extends HookConsumerWidget
    with MainLayout, JoinCircleLayout {
  const JoinCircleView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final joinCircleFormResult = useJoinCircleForm(ref);

    useLoadingOverlay(joinCircleFormResult.isLoadingOverlay);

    return FormerForm(
      form: joinCircleFormResult.form,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: BottomedListView(
          useSafeArea: true,
          bottom: Padding(
            padding: EdgeInsets.only(bottom: bottomMargin),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: joinCircleFormResult.isSubmitting,
                  builder: (context, isSubmitting, child) {
                    return JoinCircleButton(
                      onSubmit: joinCircleFormResult.submit,
                      isEnabled: !isSubmitting,
                    );
                  },
                ),
              ],
            ),
          ),
          children: [
            Text(
              translator.translate('pages.join_circle.subtitle'),
              style: textTheme.headlineSmall,
            ),
            SizedBox(height: titleToText),
            Text(
              translator.translate('pages.join_circle.description'),
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            SizedBox(height: descriptionToFormField),
            Padding(
              padding: EdgeInsets.only(right: rightPadding),
              child: const JoinCircleFormField(),
            ),
            SizedBox(height: bottomMargin),
          ],
        ),
      ),
    );
  }
}
