/// A class interface that contains required methods to implement storage behavior.
///
/// This contract defines a standard set of operations for storing, retrieving,
/// and managing data across different storage implementations.
abstract class StorageContract {
  /// Removes a value.
  ///
  /// - [key]: The storage key to remove.
  Future<void> remove(String key);

  /// Clears all values from storage.
  Future<void> clear();
}
