import 'package:cloudless/core/features/post/data/dtos/post_report_dto.dart';
import 'package:cloudless/core/features/post/domain/enums/post_report_reason.dart';
import 'package:cloudless/core/features/post/domain/models/post_report_model.dart';
import 'package:cloudless/core/mappers/dto_to_model_mapper_contract.dart';

class PostReportDtoToModelMapper
    extends DtoToModelMapperContract<PostReportDto, PostReportModel> {
  @override
  PostReportModel mapDto(PostReportDto dto) {
    return PostReportModel(
      id: dto.id,
      postId: dto.postId,
      reportedBy: dto.reportedBy,
      reason: PostReportReason.fromValue(dto.reason),
      createdAt: DateTime.parse(dto.createdAt),
    );
  }
}
