// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:cloudless/presentation/assets/assets.dart';
import 'package:cloudless/presentation/components/buttons/call_to_action/call_to_action.dart';
import 'package:cloudless/presentation/components/error_view/main_error_layout.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_presentation/dedecube_presentation.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class MainErrorView extends StatelessWidget with MainLayout, MainErrorLayout {
  const MainErrorView({
    super.key,
    this.title,
    this.description,
    this.onRetry,
    this.image,
    this.useScaffold = true,
  });

  final String? title;
  final String? description;
  final VoidCallback? onRetry;
  final Widget? image;
  final bool useScaffold;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    final content = BottomedListView(
      useSafeArea: true,
      bottom: Padding(
        padding: EdgeInsets.only(bottom: bottomMargin),
        child: onRetry != null
            ? CallToAction.primary.filled(
                action: onRetry,
                label: Text(
                  translator.translate('pages.error_view.retry'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                horizontalMargin: 100,
              )
            : null,
      ),

      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title == null || title?.isNotEmpty == true) ...[
              SizedBox(height: topMargin),
              CustomPadding(
                horizontal: horizontalMargin,
                child: Text(
                  title ?? translator.translate('pages.error_view.title'),
                  style: theme.textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              CustomSpace.vertical(titleDescriptionSpacing),
            ],
            CustomPadding(
              horizontal: horizontalMargin,
              child:
                  image ??
                  Assets.svg.errorImage.render(
                    alignment: Alignment.center,
                    fit: BoxFit.contain,
                  ),
            ),

            SizedBox(height: imageToDescription),

            CustomPadding(
              horizontal: horizontalMargin,
              child: Text(
                description ??
                    translator.translate('pages.error_view.description'),
                style: theme.textTheme.titleSmall?.copyWith(
                  height: 23.0 / 18.0,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            if (onRetry != null) const SizedBox(height: 40),
          ],
        ),
      ],
    );

    if (useScaffold) {
      return Scaffold(body: content);
    } else {
      return content;
    }
  }
}
