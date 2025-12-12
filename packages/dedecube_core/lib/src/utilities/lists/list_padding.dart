extension ListPadding<T> on List<T> {
  /// extension to pad a list to the desired length with copies of a desired element.
  List<T> pad(int targetLength, T element) {
    if (length >= targetLength) {
      return this;
    } else {
      return [...this, ...List.filled(targetLength - length, element)];
    }
  }

  /// extension to pad a list to the desired length with copies of null.
  ///  particularly useful in conjunction with .part(n) to create scrollable grids
  ///  that are just a list of rows with fixed length from a list of items
  /// ```dart
  /// class DwarvesGrid extends StatelessWidget {
  ///   const DwarvesGrid({super.key});

  ///   @override
  ///   Widget build(BuildContext context) {
  ///     final items = [
  ///       'Doc',
  ///       'Grumpy',
  ///       'Happy',
  ///       'Sleepy',
  ///       'Bashful',
  ///       'Sneezy',
  ///       'Dopey',
  ///     ];
  ///     return ListView(
  ///       children: [
  ///         for (final couple in items.part(2))
  ///           Row(
  ///             children: [
  ///               for (final dwarfOrNull in couple.padWithNull(2))
  ///                 Expanded(
  ///                   child: switch (dwarfOrNull) {
  ///                     null => Container(),
  ///                     String name => Center(child: Text(name)),
  ///                   },
  ///                 ),
  ///             ],
  ///           ),
  ///       ],
  ///     );
  ///   }
  /// }
  /// ```
  List<T?> padWithNull(int targetLength) {
    return (this as List<T?>).pad(targetLength, null);
  }
}
