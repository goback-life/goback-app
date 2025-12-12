import 'dart:async';
import 'dart:math' as math;

import 'package:cloudless/core/features/supabase/data/providers/supabase_client_provider.dart';
import 'package:cloudless/core/utilities/riverpod_cache_for_extension.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'signed_url_provider.g.dart';

@Riverpod(keepAlive: false)
Future<String?> signedUrl(
  Ref ref,
  String bucketName,
  String fileName, {
  int ttlSeconds = 60 * 60 * 4,
}) async {
  // Cache for 90% of the TTL duration (minimum 1 minute)
  final cacheSeconds = math.max(60, (ttlSeconds * 0.9).round());
  ref.cacheFor(Duration(seconds: cacheSeconds));

  final supabaseClient = ref.watch(supabaseClientProvider);

  try {
    return await supabaseClient.storage
        .from(bucketName)
        .createSignedUrl(fileName, ttlSeconds);
  } on StorageException catch (_) {
    rethrow;
  }
}
