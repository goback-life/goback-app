extension ListExtension<T> on List<T> {
  /// shorthand to check if an index is valid to access elements on a list
  bool isIndexValid(int index) => index < length && index >= 0;

  /// shorthand to move an item from an index to another in a list,
  ///  returns false if either index is invalid
  bool move(int from, int to) {
    if (isIndexValid(from) && isIndexValid(to)) {
      insert(to, removeAt(from));
      return true;
    } else {
      return false;
    }
  }
}
