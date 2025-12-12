# Profile Feature

Provides user profile management functionality, including creating/updating profiles, retrieving profile information, checking username availability, uploading avatars, and determining profile completion status. This feature wraps profile-related operations into testable services and repositories.

## Configuration

Requires the Supabase integration to be configured for data persistence. The profile feature expects a working `SupabaseClient` to be provided by the app's dependency injection/startup system.

## Usage

Example with Riverpod providers for use-cases:

```dart
// Create or update profile
final createResult = await ref.read(createOrUpdateProfileProvider.notifier).call(
  id: 'user-id',
  username: 'newusername',
  biography: 'Optional bio',
  avatarUrl: 'optional-avatar-url',
);

// Get profile
final getResult = await ref.read(getProfileProvider.notifier).call('user-id');
getResult.fold(
  (profile) {
    if (profile != null) {
      print('Username: ${profile.username}');
      print('Biography: ${profile.biography}');
      print('Avatar URL: ${profile.avatarUrl}');
    }
  },
  (error) => print('Error: $error'),
);

// Check username availability
final availabilityResult = await ref.read(checkUsernameAvailabilityProvider.notifier).call('desired-username');
availabilityResult.fold(
  (isAvailable) => print('Username available: $isAvailable'),
  (error) => print('Error: $error'),
);

// Upload avatar
final uploadResult = await ref.read(uploadAvatarProvider.notifier).call('user-id', imageFile);

// Check if profile is completed
final completionResult = await ref.read(hasCompletedProfileProvider.notifier).call('user-id');
completionResult.fold(
  (isCompleted) => print('Profile completed: $isCompleted'),
  (error) => print('Error: $error'),
);
```

## Profile Model

The `ProfileModel` contains the following fields:

- `id`: Unique identifier for the profile
- `username`: Unique username chosen by the user
- `createdAt`: Timestamp when the profile was created
- `updatedAt`: Timestamp when the profile was last updated
- `biography`: Optional user biography
- `avatarUrl`: Optional URL to the user's avatar image

## Error Handling

The profile feature implements comprehensive error handling:

### Custom Domain Exceptions

- `ProfileException` - Base class for all profile-related errors
- `ProfileUsernameNotAvailableException` - Thrown when attempting to use a username that's already taken

### Result Pattern

All async methods return `Result<T>` instead of throwing exceptions:

- Success cases: `Result.success(value)`
- Error cases: `Result.failure(exception)`

### Usage Pattern

```dart
final result = await ref.read(getProfileProvider.notifier).call(userId);
result.fold(
  (profile) => // handle success
  (error) => // handle failure
);
```

## Architecture

The feature follows clean architecture principles:

- **Domain Layer**: Contains business logic, use cases, contracts, and domain models
- **Data Layer**: Contains implementations of repositories and services, data transfer objects, mappers, and external service integrations

Key components:

- `ProfileRepositoryContract`: Defines the interface for profile data operations
- `ProfileServiceContract`: Defines the interface for external profile service calls
- Use cases for each operation (create/update, get, check availability, upload avatar, check completion)
- Riverpod providers for dependency injection and state management</content>
<parameter name="filePath">/Users/fabrizioinfante/Desktop/Repositories/cloudless-mobile/lib/core/features/profile/README.md
