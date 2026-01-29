import 'package:cloudless/core/features/comment/data/services/comment_service.dart';
import 'package:cloudless/core/features/supabase/data/providers/supabase_client_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comment_service_provider.g.dart';

@riverpod
CommentService commentService(Ref ref) {
  return CommentService(supabase: ref.watch(supabaseClientProvider));
}
