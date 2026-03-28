/// Configuration contract for Supabase client initialization.
abstract interface class SupabaseClientServiceConfigContract {
  String get projectUrl;
  String get anonKey;
}
