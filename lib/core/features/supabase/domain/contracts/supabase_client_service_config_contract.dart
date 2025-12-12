abstract interface class SupabaseClientServiceConfigContract {
  /// The URL of the Supabase project.
  /// This is used to connect to the Supabase backend.
  String get projectUrl;

  /// The anonymous API key for the Supabase project.
  /// This key is required for client-side authentication and requests.
  String get anonKey;
}
