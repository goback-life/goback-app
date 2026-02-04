import 'package:cloudless/core/features/lockout/data/storables/friends_locked_out_storable.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'friends_locked_out_storable_provider.g.dart';

@Riverpod(keepAlive: true)
FriendsLockedOutStorable friendsLockedOutStorable(Ref ref) {
  return FriendsLockedOutStorable();
}
