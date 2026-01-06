import 'dart:math';

import 'package:cloudless/core/features/connection/data/dtos/get_circle_members_response_dto.dart';
import 'package:cloudless/core/features/connection/data/exceptions/invite_code_generation_exception.dart';
import 'package:cloudless/core/features/connection/data/exceptions/invite_limit_exception.dart';
import 'package:cloudless/core/features/connection/domain/contracts/connection_service_contract.dart';
import 'package:cloudless/core/features/connection/domain/exceptions/cannot_use_own_invite_code_exception.dart';
import 'package:cloudless/core/features/connection/domain/exceptions/connection_exception.dart';
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

      final existingConnection = await supabase
        .from('connections')
        .select('id')
        .eq('user_id', currentUserId)
        .eq('connection_id', creatorId)
        .limit(1)
        .maybeSingle();

      if (existingConnection != null) {
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
        'join_circle_transaction',
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
      final userId = supabase.auth.currentUser!.id;

      final result =
          await supabase.rpc('get_circle_members', params: {'user_id': userId})
              as List<dynamic>;

      final members = <GetCircleMembersResponseDto>[];

      for (final memberData in result) {
        final data = memberData as Map<String, dynamic>;

        try {
          final dto = GetCircleMembersResponseDto.fromJson({
            'connection_id': data['connection_id']?.toString() ?? '',
            'id': data['id']?.toString() ?? '',
            'username': data['username']?.toString() ?? '',
            'biography': data['biography']?.toString(),
            'avatar_url': null, // Set to null initially
            'phone_number': data['phone_number']?.toString(),
          });

          members.add(dto);
        } catch (e) {
          logger.error('Error processing member ${data['id']}', exception: e);
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

  /// Fetches avatar URLs for a list of members synchronously (preserving original mechanism).
  /// This method fetches URLs one by one in sequence, exactly as before.
  /// Includes retry logic for network errors that commonly occur when app resumes from background.
  /// Skips members that already have avatar URLs to avoid unnecessary network requests.
  FutureResult<List<GetCircleMembersResponseDto>> enrichMembersWithAvatars(
    List<GetCircleMembersResponseDto> members,
  ) async {
    final enrichedMembers = <GetCircleMembersResponseDto>[];

    for (final member in members) {
      // Skip if avatar URL already exists (from previous successful fetch)
      // This avoids unnecessary network requests when refreshing on app resume
      if (member.avatarUrl != null && member.avatarUrl!.isNotEmpty) {
        enrichedMembers.add(member);
        continue;
      }

      String? avatarUrl;
      
      // Retry logic for network errors (common when app resumes from background)
      const maxRetries = 2;
      const initialDelay = Duration(milliseconds: 500);
      
      for (int attempt = 0; attempt <= maxRetries; attempt++) {
        try {
          avatarUrl = await ref.read(
            signedUrlProvider(
              SupabaseBuckets.avatars,
              member.id,
            ).future,
          );
          break; // Success, exit retry loop
        } catch (e) {
          final isNetworkError = _isNetworkError(e);
          final isLastAttempt = attempt == maxRetries;
          
          if (isNetworkError && !isLastAttempt) {
            // Wait before retrying with exponential backoff
            final delay = Duration(
              milliseconds: initialDelay.inMilliseconds * (1 << attempt),
            );
            await Future.delayed(delay);
            continue;
          }
          
          // Log error only on last attempt or if it's not a network error
          if (isLastAttempt || !isNetworkError) {
            logger.error(
              'Error getting avatar for member ${member.id}',
              exception: e,
            );
          }
          // Keep avatarUrl as null if fetch fails
          avatarUrl = null;
          break;
        }
      }

      enrichedMembers.add(member.copyWith(avatarUrl: avatarUrl));
    }

    return Result.success(enrichedMembers);
  }

  /// Checks if an exception is a network-related error that should be retried.
  bool _isNetworkError(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('clientexception') ||
        errorString.contains('socketexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('connection abort') ||
        errorString.contains('no address associated with hostname');
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

      await supabase.rpc(
        'remove_bidirectional_connection',
        params: {'user_a': currentUserId, 'user_b': userId},
      );

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
        .from('connections')
        .select('id')
        .or('user_id.eq.$userId,connection_id.eq.$userId')
        .count();

    return result.count;
  }

  @override
  FutureResult<bool> isUserConnected(String userId) async {
    try {
      final currentUserId = supabase.auth.currentUser!.id;

      final response = await supabase
          .from('connections')
          .select('id')
          .or('user_id.eq.$currentUserId,connection_id.eq.$currentUserId')
          .or('user_id.eq.$userId,connection_id.eq.$userId')
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
