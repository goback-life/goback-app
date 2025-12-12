import 'package:cloudless/core/models/profile_model.dart';

class InviteCodeModel {
  const InviteCodeModel({
    required this.id,
    required this.code,
    required this.creatorId,
    required this.expiresAt,
    required this.createdAt,
    this.usedById,
    this.creatorProfile,
  });

  final String id;
  final String code;
  final String creatorId;
  final String? usedById;
  final DateTime expiresAt;
  final DateTime createdAt;
  final ProfileModel? creatorProfile;
}
