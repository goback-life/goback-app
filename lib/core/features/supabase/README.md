# Supabase Integration

This feature provides a clean, testable integration with Supabase using the startup system and dependency injection pattern.

## Configuration

Set these environment variables:

- `SUPABASE_PROJECT_URL`: Your Supabase project URL
- `SUPABASE_ANON_KEY`: Your Supabase anonymous key

## Usage

### Providers

The feature provides several Riverpod providers for dependency injection:

- `supabaseClientProvider`: Provides the initialized `SupabaseClient` instance
- `supabaseClientServiceProvider`: Provides the `SupabaseClientService` for initialization
- `supabaseClientServiceConfigProvider`: Provides the configuration for Supabase

### Example

```dart
// Access the Supabase client
final supabaseClient = ref.read(supabaseClientProvider);

// Use in a widget or provider
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(supabaseClientProvider);
    // Use client for database operations
  }
}
```

## Error Handling

The system implements comprehensive error handling:

- **Initialization Errors**: Throws exceptions if environment variables are missing or Supabase initialization fails
- **Access Errors**: Throws `StateError` if client is accessed before initialization
- **UI Exception Handling**: Provides `CommonSupabaseExceptionUIHandlerContract` for handling exceptions in the UI layer
- **Result Processing**: Includes `SupabaseResultProcessorContract` for unified exception handling and result mapping

All errors are fail-fast during startup to ensure proper configuration.
