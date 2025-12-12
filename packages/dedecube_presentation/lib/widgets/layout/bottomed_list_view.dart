import 'package:dedecube_presentation/widgets/layout/custom_align.dart';
import 'package:flutter/material.dart';

/// A custom scrollable widget that displays a list of widgets with a fixed widget at the bottom.
///
/// This widget combines a [CustomScrollView] with a [SliverList] for the main content
/// and a [SliverFillRemaining] for the bottom widget. The bottom widget will always
/// stay at the bottom of the view when the children are small, but will be
/// pushed down with the rest of the list content if the children are big.
///
/// Parameters:
/// * [children] - The list of widgets to display in the scrollable area
/// * [bottom] - The widget to display at the bottom of the view
/// * [useSafeArea] - Whether to apply safe area padding to the bottom widget
class BottomedListView extends StatelessWidget {
  const BottomedListView({
    required this.children,
    required this.bottom,
    required this.useSafeArea,
    super.key,
  });

  final List<Widget> children;
  final Widget bottom;
  final bool useSafeArea;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverList(delegate: SliverChildListDelegate(children)),
        SliverFillRemaining(
          fillOverscroll: true,
          hasScrollBody: false,
          child: CustomAlign.bottomCenter(
            child: SafeArea(
              bottom: useSafeArea,
              top: false,
              left: false,
              right: false,
              child: bottom,
            ),
          ),
        ),
      ],
    );
  }
}
