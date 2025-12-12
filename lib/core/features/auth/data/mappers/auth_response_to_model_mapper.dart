import 'package:cloudless/core/mappers/dto_to_model_mapper_contract.dart';
import 'package:cloudless/core/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthResponseToModelMapper
    extends DtoToModelMapperContract<AuthResponse, UserModel> {
  @override
  UserModel mapDto(AuthResponse dto) {
    final user = dto.user!;

    return UserModel(id: user.id, phoneNumber: user.phone!);
  }
}
