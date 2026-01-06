import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:cloudless/core/features/supabase/data/providers/supabase_client_provider.dart';
import 'package:cloudless/core/utilities/riverpod_cache_for_extension.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:http/http.dart' as http;
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
  } on http.ClientException catch (_) {
    // Handle network errors gracefully (connection abort, host lookup failures, etc.)
    // This commonly happens when app resumes from background with stale connections
    // Rethrow to allow caller to handle with retry logic
    rethrow;
  } on SocketException catch (_) {
    // Handle DNS resolution failures and other socket errors
    // Rethrow to allow caller to handle with retry logic
    rethrow;
  }
}
