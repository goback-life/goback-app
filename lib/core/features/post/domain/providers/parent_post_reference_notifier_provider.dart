import 'package:cloudless/core/features/post/domain/models/parent_post_reference_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'parent_post_reference_notifier_provider.g.dart';

@Riverpod(keepAlive: true)
class ParentPostReferenceNotifier extends _$ParentPostReferenceNotifier {
  @override
  ParentPostReferenceModel? build() => null;

  Future<void> setParentPost(ParentPostReferenceModel parentPost) async {
    state = parentPost;
  }

  void clear() {
    state = null;
  }
}
