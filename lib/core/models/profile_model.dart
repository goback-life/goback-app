// ignore_for_file: invalid_annotation_target

import 'package:dedecube_core/dedecube_core.dart';

part 'profile_model.freezed.dart';
part 'profile_model.g.dart';

@freezed
sealed class ProfileModel with _$ProfileModel {
  const factory ProfileModel({
    required String id,
    required String username,
    String? biography,
    String? avatarUrl,
    String? phoneNumber,
    @JsonKey(name: 'weekly_lockout_minutes') int? weeklyLockoutMinutes,
    @JsonKey(name: 'notifications_checked_at') DateTime? notificationsCheckedAt,
  }) = _ProfileModel;

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);
}
