import 'package:dedecube_presentation/widgets/animations/animated_presented.dart';
import 'package:flutter/material.dart';

/// A widget that creates animated transitions between pages in a list.
///
/// The transition animates pages sliding in and out horizontally or vertically,
/// with the direction determined by the relative position of pages in [orderedPages].
///
/// The [page] parameter determines which page is currently shown, while [orderedPages]
/// defines the sequence and possible pages that can be displayed.
class RadioPageTransition<A> extends StatefulWidget {
  const RadioPageTransition({
    required this.page,
    required this.builder,
    required this.orderedPages,
    super.key,
    this.backgroundColor,
    this.offset = 100,
    this.axis = Axis.horizontal,
    this.staticOffset,
  }) : assert(offset > 0, 'Offset must be positive');

  /// The currently displayed page
  final A page;

  /// The ordered list of all possible pages
  final List<A> orderedPages;

  /// Builder function that creates the widget for a given page value
  final Widget Function(BuildContext context, A value) builder;

  /// Optional background color for the transition container
  final Color? backgroundColor;

  /// The distance pages move during the transition animation
  final double offset;

  /// The axis along which the transition animation occurs
  final Axis axis;

  /// Optional fixed offset direction, overriding the dynamic direction calculation
  final double? staticOffset;

  @override
  State<RadioPageTransition<A>> createState() => _RadioPageTransitionState<A>();
}

/// The state class for RadioPageTransition that manages the transition animations
class _RadioPageTransitionState<A> extends State<RadioPageTransition<A>> {
  /// The previously displayed page, used to determine transition direction
  late A previous;

  @override
  void initState() {
    super.initState();
    previous = widget.page;
  }

  @override
  void didUpdateWidget(covariant RadioPageTransition<A> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page != widget.page) {
      previous = oldWidget.page;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.backgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          for (int i = 0; i < widget.orderedPages.length; i++)
            if (widget.orderedPages[i] case final A p)
              if ((widget.staticOffset ?? pageOffset(i)) case final double o)
                AnimatedPresented(
                  slideOffset: switch (widget.axis) {
                    Axis.horizontal => Offset(o, 0),
                    Axis.vertical => Offset(0, o),
                  },
                  presented: widget.page == p,
                  presentMode: PresentMode.slide,
                  curve: Curves.easeOut,
                  fadeFirstFraction: 0.55,
                  duration: const Duration(milliseconds: 250),
                  child: widget.builder(context, p),
                ),
        ],
      ),
    );
  }

  double pageOffset(int i) {
    return switch (widget.orderedPages[i] == widget.page) {
      // current page
      true =>
        i < indexOf(previous) // if this is to the left of the previous one
            ? -widget.offset // comes from the left
            : widget.offset, // comes from the right
      // another page
      false =>
        i < indexOf(widget.page) // if this is to the left of the current one
            ? -widget.offset // goes to the left
            : widget.offset, // goes to the right
    };
  }

  int indexOf(p) => widget.orderedPages.indexOf(p);
}
