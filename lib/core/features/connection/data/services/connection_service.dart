import 'dart:math';

import 'package:cloudless/core/features/connection/data/dtos/get_circle_members_response_dto.dart';
import 'package:cloudless/core/features/connection/data/dtos/outgoing_request_dto.dart';
import 'package:cloudless/core/features/connection/data/exceptions/invite_code_generation_exception.dart';
import 'package:cloudless/core/features/connection/data/exceptions/invite_limit_exception.dart';
import 'package:cloudless/core/features/connection/domain/contracts/connection_service_contract.dart';
import 'package:cloudless/core/features/connection/domain/exceptions/cannot_use_own_invite_code_exception.dart';
import 'package:cloudless/core/features/connection/domain/exceptions/circle_full_exception.dart';
import 'package:cloudless/core/features/connection/domain/exceptions/connection_exception.dart';
import 'package:cloudless/core/features/connection/domain/exceptions/connection_request_exception.dart';
import 'package:cloudless/core/features/connection/domain/exceptions/invite_code_already_used_exception.dart';
import 'package:cloudless/core/features/connection/domain/exceptions/invite_code_expired_exception.dart';
import 'package:cloudless/core/features/connection/domain/exceptions/invite_code_not_found_exception.dart';
import 'package:cloudless/core/features/connection/domain/exceptions/target_user_circle_size_limit_exception.dart';
import 'package:cloudless/core/features/connection/domain/exceptions/user_circle_size_limit_exception.dart';
import 'package:cloudless/core/features/connection/domain/exceptions/users_already_connected_exception.dart';
import 'package:cloudless/core/features/connection/domain/models/invite_validation_result.dart';
import 'package:cloudless/core/features/storage/data/providers/signed_url_provider.dart';
import 'package:cloudless/core/features/supabase/utilities/supabase_buckets.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConnectionService implements ConnectionServiceContract {
  const ConnectionService({required this.supabase, required this.ref});

  final SupabaseClient supabase;
  final Ref ref;

  static const int _maxActiveInvites = 100;
  static const int _defaultExpiryHours = 72;
  static const int _maxCircleSize = 150;

  @override
  FutureResult<String> createInviteCode({
    int expiryHours = _defaultExpiryHours,
  }) async {
    try {
      final userId = supabase.auth.currentUser!.id;

      final activeCount = await _getActiveInviteCount(userId);
      if (activeCount >= _maxActiveInvites) {
        throw const InviteLimitException();
      }

      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          final code = _generateRandomCode();
          final expiresAt = DateTime.now().add(Duration(hours: expiryHours));

          await supabase.from('invite_codes').insert({
            'code': code,
            'creator_id': userId,
            'expires_at': expiresAt.toIso8601String(),
          });

          return Result.success(code);
        } on PostgrestException catch (e) {
          if (e.message.contains('Limit of 100 active codes reached')) {
            throw const InviteLimitException();
          }

          if (e.code == '23505' && attempt < 2) {
            continue;
          }
          rethrow;
        }
      }

      throw const InviteCodeGenerationException();
    } catch (e) {
      final exception = e is Exception ? e : Exception(e.toString());
      return Result.failure(exception);
    }
  }

  @override
  FutureResult<InviteValidationResult> validateInviteCode(String code) async {
    try {
      final currentUserId = supabase.auth.currentUser!.id;

      final inviteData = await supabase
          .from('invite_codes')
          .select('''
          id, creator_id, used_by_id, expires_at,
          profiles!creator_id (username)
        ''')
          .eq('code', code.toUpperCase())
          .maybeSingle();

      if (inviteData == null) {
        throw const InviteCodeNotFoundException();
      }

      if (inviteData['used_by_id'] != null) {
        throw const InviteCodeAlreadyUsedException();
      }

      final expiresAt = DateTime.parse(inviteData['expires_at']);
      if (DateTime.now().isAfter(expiresAt)) {
        throw const InviteCodeExpiredException();
      }

      final creatorId = inviteData['creator_id'];
      if (currentUserId == creatorId) {
        throw const CannotUseOwnInviteCodeException();
      }

      // Check if current user has reached circle size limit
      final currentUserCircleSize = await _getCircleSize(currentUserId);
      final creatorCircleSize = await _getCircleSize(creatorId);
      if (currentUserCircleSize >= _maxCircleSize) {
        throw const UserCircleSizeLimitException();
      } else if (creatorCircleSize >= _maxCircleSize) {
        throw const TargetUserCircleSizeLimitException();
      }

      // Check for existing friendship using ordered UUID pair
      final orderedIds = _orderUserIds(currentUserId, creatorId);
      final existingFriendship = await supabase
        .from('friendships')
        .select('id')
        .eq('user_a_id', orderedIds.$1)
        .eq('user_b_id', orderedIds.$2)
        .limit(1)
        .maybeSingle();

      if (existingFriendship != null) {
        throw const UsersAlreadyConnectedException();
      }

      final result = InviteValidationResult.valid(
        creatorProfile: inviteData['profiles'],
      );
      return Result.success(result);
    } catch (e) {
      final exception = e is Exception ? e : Exception(e.toString());
      return Result.failure(exception);
    }
  }

  @override
  FutureResult<bool> joinCircle(String inviteCode) async {
    try {
      final currentUserId = supabase.auth.currentUser!.id;

      final inviteData = await supabase
          .from('invite_codes')
          .select('id, creator_id')
          .eq('code', inviteCode.toUpperCase())
          .single();

      await supabase.rpc(
        'join_friendship_transaction',
        params: {
          'invite_id': inviteData['id'],
          'user_id': currentUserId,
          'creator_id': inviteData['creator_id'],
        },
      );

      return Result.success(true);
    } catch (e) {
      final exception = e is Exception ? e : Exception(e.toString());
      return Result.failure(exception);
    }
  }

  /// Helper method to get circle members data from database without avatar URLs.
  /// This allows for fast initial data loading while avatar URLs are fetched separately.
  FutureResult<List<GetCircleMembersResponseDto>> getCircleMembersBasic() async {
    try {
      // get_user_friends() uses auth.uid() internally, no parameters needed
      final result = await supabase.rpc('get_user_friends') as List<dynamic>;

      final members = <GetCircleMembersResponseDto>[];

      for (final memberData in result) {
        final data = memberData as Map<String, dynamic>;

        try {
          // Map SQL columns to DTO: friend_id -> id
          final friendId = data['friend_id']?.toString() ?? '';
          final dto = GetCircleMembersResponseDto.fromJson({
            'friendship_id': friendId, // Use friend_id as friendship_id
            'id': friendId,
            'username': data['username']?.toString() ?? '',
            'biography': data['biography']?.toString(),
            'avatar_url': data['avatar_url']?.toString(),
            'phone_number': null, // Not returned by get_user_friends
          });

          members.add(dto);
        } catch (e) {
          logger.error('Error processing member ${data['friend_id']}', exception: e);
          continue;
        }
      }

      return Result.success(members);
    } catch (e) {
      logger.error('Error getting circle members', exception: e);
      final exception = e is Exception
          ? e
          : Exception('Failed to get circle members: $e');
      return Result.failure(exception);
    }
  }

  /// Fetches avatar URLs for a list of members with rate limiting.
  /// Skips members that already have avatar URLs to avoid unnecessary network requests.
  /// Uses batched processing (10 concurrent requests) to avoid overwhelming the server.
  FutureResult<List<GetCircleMembersResponseDto>> enrichMembersWithAvatars(
    List<GetCircleMembersResponseDto> members,
  ) async {
    final enrichedMembers = <GetCircleMembersResponseDto>[];
    const batchSize = 10; // Process 10 at a time to avoid overwhelming server

    for (var i = 0; i < members.length; i += batchSize) {
      final batch = members.skip(i).take(batchSize).toList();

      final batchResults = await Future.wait(
        batch.map((member) async {
          // Skip if avatar URL already exists
          if (member.avatarUrl != null && member.avatarUrl!.isNotEmpty) {
            return member;
          }

          String? avatarUrl;
          try {
            avatarUrl = await ref.read(
              signedUrlProvider(
                SupabaseBuckets.avatars,
                member.id,
              ).future,
            );
          } catch (e) {
            avatarUrl = null;
          }

          return member.copyWith(avatarUrl: avatarUrl);
        }),
      );

      enrichedMembers.addAll(batchResults);
    }

    return Result.success(enrichedMembers);
  }

  @override
  FutureResult<List<GetCircleMembersResponseDto>> getCircleMembers() async {
    // Get basic member data first
    final basicResult = await getCircleMembersBasic();
    return await basicResult.asyncFold(
      (basicMembers) async {
        // Then enrich with avatar URLs (synchronous, one by one, preserving original mechanism)
        return await enrichMembersWithAvatars(basicMembers);
      },
      (error) async => Result.failure(error),
    );
  }

  @override
  FutureResult<bool> removeConnection(String userId) async {
    try {
      final currentUserId = supabase.auth.currentUser!.id;

      // Order UUIDs to match the friendship_ordered constraint (user_a_id < user_b_id)
      final String userA;
      final String userB;
      if (currentUserId.compareTo(userId) < 0) {
        userA = currentUserId;
        userB = userId;
      } else {
        userA = userId;
        userB = currentUserId;
      }

      // Direct DELETE - RLS policy allows users to delete their own friendships
      await supabase
          .from('friendships')
          .delete()
          .eq('user_a_id', userA)
          .eq('user_b_id', userB);

      return Result.success(true);
    } on PostgrestException catch (e) {
      logger.error('Error removing connection', exception: e);
      final exception = ConnectionException(
        'Failed to remove connection: ${e.message}',
      );
      return Result.failure(exception);
    } catch (e) {
      logger.error('Unexpected error removing connection', exception: e);
      const exception = ConnectionException('Failed to remove connection');
      return Result.failure(exception);
    }
  }

  Future<int> _getActiveInviteCount(String userId) async {
    final result = await supabase
        .from('invite_codes')
        .select('id')
        .eq('creator_id', userId)
        .isFilter('used_by_id', null)
        .gt('expires_at', DateTime.now().toIso8601String())
        .count();

    return result.count;
  }

  Future<int> _getCircleSize(String userId) async {
    final result = await supabase
        .from('friendships')
        .select('id')
        .or('user_a_id.eq.$userId,user_b_id.eq.$userId')
        .count();

    return result.count;
  }

  /// Orders two user IDs to match the friendships table constraint (user_a_id < user_b_id).
  (String, String) _orderUserIds(String userIdA, String userIdB) {
    return userIdA.compareTo(userIdB) < 0
        ? (userIdA, userIdB)
        : (userIdB, userIdA);
  }

  @override
  FutureResult<List<Map<String, dynamic>>> searchUsers(
    String query, {
    int limit = 20,
  }) async {
    try {
      final result = await supabase.rpc(
        'search_users',
        params: {'p_query': query.trim(), 'p_limit': limit},
      ) as List<dynamic>;
      return Result.success(
        result.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      );
    } catch (e) {
      final exception = e is Exception ? e : Exception(e.toString());
      return Result.failure(exception);
    }
  }

  @override
  FutureResult<String> sendConnectionRequest(String receiverId) async {
    try {
      final result = await supabase.rpc(
        'send_connection_request',
        params: {'p_receiver_id': receiverId},
      ) as String;
      return Result.success(result);
    } on PostgrestException catch (e) {
      if (e.message.contains('circle is full')) {
        return Result.failure(const CircleFullException());
      }
      return Result.failure(ConnectionRequestException(e.message));
    } catch (e) {
      final exception = e is Exception ? e : Exception(e.toString());
      return Result.failure(exception);
    }
  }

  @override
  FutureResult<void> respondToConnectionRequest(
    String requestId, {
    required bool accept,
  }) async {
    try {
      await supabase.rpc(
        'respond_to_connection_request',
        params: {'p_request_id': requestId, 'p_accept': accept},
      );
      return Result.success(null);
    } on PostgrestException catch (e) {
      if (e.message.contains('circle is full')) {
        return Result.failure(const CircleFullException());
      }
      return Result.failure(ConnectionRequestException(e.message));
    } catch (e) {
      final exception = e is Exception ? e : Exception(e.toString());
      return Result.failure(exception);
    }
  }

  @override
  FutureResult<void> cancelConnectionRequest(String requestId) async {
    try {
      await supabase
          .from('connection_requests')
          .delete()
          .eq('id', requestId)
          .eq('sender_id', supabase.auth.currentUser!.id);
      return Result.success(null);
    } catch (e) {
      final exception = e is Exception ? e : Exception(e.toString());
      return Result.failure(exception);
    }
  }

  @override
  FutureResult<List<OutgoingRequestDto>> getOutgoingRequests() async {
    try {
      final result = await supabase.rpc(
        'get_outgoing_connection_requests',
      ) as List<dynamic>;
      return Result.success(
        result.map((e) =>
          OutgoingRequestDto.fromJson(Map<String, dynamic>.from(e as Map)),
        ).toList(),
      );
    } catch (e) {
      final exception = e is Exception ? e : Exception(e.toString());
      return Result.failure(exception);
    }
  }

  @override
  FutureResult<bool> isUserConnected(String userId) async {
    try {
      final currentUserId = supabase.auth.currentUser!.id;
      final orderedIds = _orderUserIds(currentUserId, userId);

      final response = await supabase
          .from('friendships')
          .select('id')
          .eq('user_a_id', orderedIds.$1)
          .eq('user_b_id', orderedIds.$2)
          .limit(1);

      return Result.success(response.isNotEmpty);
    } catch (e) {
      return Result.failure(
        ConnectionException('Failed to check user connection: $e'),
      );
    }
  }

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        6,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }
}
