import 'dart:convert';

import 'package:dedecube_startup/dedecube_startup.dart';

/// Persists friends locked out cache to survive app restarts.
///
/// Stores serialized lockout sessions so they're available immediately
/// when the app restarts, providing seamless UX.
class FriendsLockedOutStorable extends Storable<String> {
  @override
  String get key => 'friends_locked_out_cache';

  @override
  StorageType get storageType => StorageType.simple;

  /// Gets cached friends data from storage.
  /// Returns list of session maps or empty list if none cached.
  Future<List<Map<String, dynamic>>> getCachedFriends() async {
    final jsonString = await get(defaultValue: '[]');
    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      logger.warning('[FriendsLockedOutStorable] Error decoding cache: $e');
      return [];
    }
  }

  /// Saves friends data to storage.
  Future<void> setCachedFriends(List<Map<String, dynamic>> friends) async {
    try {
      final jsonString = json.encode(friends);
      await set(jsonString);
    } catch (e) {
      logger.warning('[FriendsLockedOutStorable] Error encoding cache: $e');
    }
  }

  /// Clears the cache.
  Future<void> clearCache() async {
    await set('[]');
  }
}
