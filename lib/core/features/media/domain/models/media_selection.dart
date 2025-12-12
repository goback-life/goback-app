import 'package:cloudless/core/features/media/domain/enums/media_type.dart';
import 'package:image_picker/image_picker.dart';

/// Classe che rappresenta la selezione di un media (foto o video)
/// combinando la sorgente (camera/galleria) e il tipo (foto/video).
class MediaSelection {
  const MediaSelection({required this.source, required this.mediaType});

  final ImageSource source;
  final MediaType mediaType;
}
