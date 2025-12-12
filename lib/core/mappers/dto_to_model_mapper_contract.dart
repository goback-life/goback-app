abstract class DtoToModelMapperContract<Dto, Model> {
  /// Maps a DTO object to the corresponding model object.
  Model mapDto(Dto dto);

  /// Maps a [Dto] to a [Model], returning null if the dto is null.
  Model? mapDtoOrNull(Dto? dto) {
    return dto != null ? mapDto(dto) : null;
  }

  /// Maps a list of [Dto] objects to a list of [Model] objects.
  List<Model> mapDtoList(List<Dto> dtos) {
    return dtos.map(mapDto).toList();
  }
}
