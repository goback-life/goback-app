extension IterablePartition<T> on Iterable<T> {
// extension to quickly subdivide a list into many lists of a specified size
// (e.g: a list of 7 items subdivided into 4 lists of up to two elements
// (with the last one being just one element)) would be:
  /// ```dart
  /// final list = [
  ///   Doc,
  ///   Grumpy,
  ///   Happy,
  ///   Sleepy,
  ///   Bashful,
  ///   Sneezy,
  ///   Dopey,
  /// ];
  /// print(list.part(2).toList()); // [[Doc, Grumpy], [Happy, Sleepy], [Bashful, Sneezy], [Dopey]]
  /// ```
  Iterable<List<T>> partition(int size) =>
      isEmpty ? <List<T>>[] : _Partition<T>(this, size);
}

class _Partition<T> extends Iterable<List<T>> {
  _Partition(this._iterable, this._size) {
    if (_size <= 0) {
      throw ArgumentError(_size);
    }
  }
  final Iterable<T> _iterable;
  final int _size;

  @override
  Iterator<List<T>> get iterator => _PartitionIterator<T>(
        _iterable.iterator,
        _size,
      );
}

class _PartitionIterator<T> implements Iterator<List<T>> {
  _PartitionIterator(this._iterator, this._size);
  final Iterator<T> _iterator;
  final int _size;
  List<T>? _current;

  @override
  List<T> get current => _current ?? [];

  @override
  bool moveNext() {
    final newValue = <T>[];
    var count = 0;
    while (count < _size && _iterator.moveNext()) {
      newValue.add(_iterator.current);
      count++;
    }
    _current = (count > 0) ? newValue : null;
    return _current != null;
  }
}
