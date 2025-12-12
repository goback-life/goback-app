import 'package:cloudless/core/features/post/data/services/post_service.dart';
import 'package:cloudless/core/features/post/domain/contracts/post_service_contract.dart';
import 'package:cloudless/core/features/supabase/data/providers/supabase_client_provider.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'post_service_provider.g.dart';

@Riverpod(keepAlive: false)
PostServiceContract postService(Ref ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return PostService(supabaseClient: supabaseClient, ref: ref);
}
