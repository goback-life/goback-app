extension ListSeparation<T> on List<T> {
  /// extension method to quickly insert separation between elements of a list.
  ///  Particularly useful for when you don't need to know how long the list
  ///  will be or if all possible elements will be present.
  ///  ```dart
  ///  class MySeparatedList extends StatelessWidget {
  ///    const MySeparatedList({
  ///      super.key,
  ///      required this.showProfile,
  ///      required this.showTerms,
  ///    });

  ///    final bool showProfile;
  ///    final bool showTerms;

  ///    @override
  ///    Widget build(BuildContext context) {
  ///      return ListView(
  ///        children: [
  ///          if (showProfile) ProfileCard(),
  ///          SettingsButton(),
  ///          ThemeToggle(),
  ///          if (showTerms) TermsAndConditions(),
  ///        ].separateWith(const SizedBox(height: 20)),
  ///      );
  ///    }
  ///  }
  /// ```
  List<T> separateWith(
    T splitter, {
    bool alsoFirst = false,
    bool alsoLast = false,
    bool alsoFirstAndLast = false,
  }) =>
      <T>[
        if (alsoFirst || alsoFirstAndLast) splitter,
        if (isNotEmpty) first,
        for (int i = 1; i < length; ++i) ...<T>[
          splitter,
          this[i],
        ],
        if (alsoLast || alsoFirstAndLast) splitter,
      ];
}
