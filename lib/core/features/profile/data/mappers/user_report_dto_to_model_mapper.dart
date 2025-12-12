import 'package:cloudless/core/features/profile/data/dtos/user_report_dto.dart';
import 'package:cloudless/core/features/profile/domain/enums/user_report_reason.dart';
import 'package:cloudless/core/features/profile/domain/models/user_report_model.dart';
import 'package:cloudless/core/mappers/dto_to_model_mapper_contract.dart';

class UserReportDtoToModelMapper
    extends DtoToModelMapperContract<UserReportDto, UserReportModel> {
  @override
  UserReportModel mapDto(UserReportDto dto) {
    return UserReportModel(
      id: dto.id,
      reportedUserId: dto.reportedUserId,
      reportedBy: dto.reportedBy,
      reason: UserReportReason.fromValue(dto.reason),
      createdAt: DateTime.parse(dto.createdAt),
    );
  }
}
