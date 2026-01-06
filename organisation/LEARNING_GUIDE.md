# Learning Guide: Getting Familiar with the Codebase

This guide will help you understand the architecture, patterns, and conventions used in this Flutter codebase so you can modify it confidently.

## 📚 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Key Concepts & Patterns](#key-concepts--patterns)
3. [Step-by-Step Learning Path](#step-by-step-learning-path)
4. [Common Tasks & How-To](#common-tasks--how-to)
5. [Important Files to Understand](#important-files-to-understand)
6. [Code Conventions](#code-conventions)

---

## Architecture Overview

### High-Level Structure

The app follows **Clean Architecture** with a **feature-based** organization:

```
lib/
├── core/                    # Business logic layer
│   ├── features/           # Feature modules (auth, post, profile, etc.)
│   ├── exceptions/          # Global exception types
│   ├── models/              # Shared domain models
│   └── utilities/           # Shared utilities
│
├── presentation/            # UI layer
│   ├── pages/              # Screen implementations
│   ├── components/         # Reusable UI components
│   ├── themes/             # App theming
│   └── routes.dart         # Route definitions
│
└── main.dart               # App entry point

packages/                    # Reusable packages
├── dedecube_core/          # Core utilities (Result pattern, DI)
├── dedecube_router/         # Navigation system
├── dedecube_startup/        # App initialization
└── ...                     # Other shared packages
```

### Feature Structure

Each feature follows this pattern:

```
feature_name/
├── data/                   # Infrastructure layer
│   ├── services/          # External API calls (Supabase)
│   ├── repositories/      # Data access abstraction
│   ├── mappers/           # DTO ↔ Domain model conversion
│   ├── exceptions/        # Data-layer exceptions
│   └── providers/         # Riverpod providers for DI
│
└── domain/                 # Business logic layer
    ├── contracts/         # Interfaces (repositories, services)
    ├── models/            # Domain models
    ├── use_cases/         # Business logic operations
    ├── providers/         # Riverpod providers (use cases)
    └── hooks/             # Custom hooks for UI
```

---

## Key Concepts & Patterns

### 1. **Result Pattern** (Error Handling)

All async operations return `Result<T>` instead of throwing exceptions:

```dart
// Success case
Result.success(data)

// Failure case
Result.failure(exception)

// Usage
final result = await ref.read(someProvider.future);
result.fold(
  (data) => // handle success
  (error) => // handle failure
);
```

**Why?** Type-safe error handling, forces explicit error handling, no surprise exceptions.

### 2. **Riverpod State Management**

- **Providers** are the source of truth
- Use `ref.watch()` to listen to changes (reactive)
- Use `ref.read()` for one-time access (non-reactive)
- Use `ref.invalidate()` to refresh data

```dart
// In a widget
class MyWidget extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for changes (reactive)
    final userAsync = ref.watch(getCurrentUserProvider);
    
    // Read once (non-reactive)
    final result = await ref.read(signInProvider.notifier).call(phone);
    
    // Invalidate to refresh
    ref.invalidate(getCurrentUserProvider);
  }
}
```

### 3. **Navigation System** (`dedecube_router`)

Routes are type-safe and defined as classes:

```dart
// Define a route
@freezed
sealed class HomeRoutable extends Routable<HomeRoutable> {
  const factory HomeRoutable() = _HomeRoutable;
  
  @override
  String get path => '/home';
  
  @override
  Widget buildPage(BuildContext context, HomeRoutable routeData) {
    return const HomePage();
  }
}

// Navigate
router.go(const HomeRoutable());      // Replace stack
router.push(const HomeRoutable());    // Add to stack
```

### 4. **Exception Mapping**

Supabase exceptions are mapped to domain exceptions:

```dart
// Data layer catches Supabase exceptions
try {
  await supabaseClient.auth.signIn(...);
} catch (e) {
  return Result.failure(e); // Supabase exception
}

// Repository maps to domain exception
return processSupabaseResult(
  request: () => authService.signIn(...),
  exceptionMapper: SignInExceptionsMapper.fromSupabaseException,
);
```

### 5. **Use Cases Pattern**

Business logic is encapsulated in use cases:

```dart
class SignInUseCase {
  final AuthRepositoryContract repository;
  final String phoneNumber;
  
  Future<Result<void>> execute() async {
    return await repository.signIn(phoneNumber: phoneNumber);
  }
}

// Used via provider
@Riverpod
Future<Result<void>> signIn(Ref ref, String phoneNumber) async {
  final useCase = SignInUseCase(
    phoneNumber: phoneNumber,
    repository: ref.watch(authRepositoryProvider),
  );
  return useCase.execute();
}
```

---

## Step-by-Step Learning Path

### Phase 1: Understanding the Basics (Day 1-2)

#### 1. Start with Entry Points
- **`lib/main.dart`** - See how the app initializes
- **`lib/core/features/startup/data/config/startup_config.dart`** - App configuration
- **`lib/presentation/routes.dart`** - All available routes

**Key Questions:**
- How does the app start?
- What happens during initialization?
- What routes are available?

#### 2. Understand Navigation
- Read **`lib/presentation/pages/home/home_routable.dart`** - Example route
- Check **`packages/dedecube_router/README.md`** - Router documentation
- Look at **`lib/core/features/auth/domain/middlewares/auth_navigation_flow_middleware.dart`** - Navigation guards

**Practice:** Navigate from one page to another in the code.

#### 3. Learn the Result Pattern
- Read **`packages/dedecube_core/lib/src/result/result.dart`**
- See examples in **`lib/core/features/auth/data/repositories/auth_repository.dart`**
- Understand **`lib/core/features/supabase/data/mixins/supabase_result_processor.dart`**

**Practice:** Find a use case and trace how errors flow from service → repository → use case → provider.

### Phase 2: Understanding Features (Day 3-5)

#### 4. Study the Auth Feature (Simplest)
Start here - it's the most straightforward:

1. **Domain Layer:**
   - `lib/core/features/auth/domain/use_cases/` - Business logic
   - `lib/core/features/auth/domain/providers/` - Riverpod providers
   - `lib/core/features/auth/domain/contracts/` - Interfaces

2. **Data Layer:**
   - `lib/core/features/auth/data/services/auth_service.dart` - Supabase calls
   - `lib/core/features/auth/data/repositories/auth_repository.dart` - Abstraction
   - `lib/core/features/auth/data/mappers/` - Exception mapping

3. **Presentation Layer:**
   - `lib/presentation/pages/sign_in/` - UI implementation

**Practice:** Add a new auth method (e.g., email sign-in) following the same pattern.

#### 5. Study a Complex Feature (Post Feature)
This shows how complex features are structured:

1. Notice the service decomposition:
   - `post_service.dart` - Main orchestrator
   - `post_crud_service.dart` - CRUD operations
   - `post_media_upload_service.dart` - Media handling
   - `post_query_service.dart` - Query operations

2. See how use cases are organized:
   - `lib/core/features/post/domain/use_cases/`

3. Understand the data flow:
   - UI → Provider → Use Case → Repository → Service → Supabase

**Practice:** Add a new post operation (e.g., pin post) following the pattern.

### Phase 3: Understanding UI Patterns (Day 6-7)

#### 6. Study Widget Patterns
- **`lib/presentation/pages/home/home_page.dart`** - Page structure
- **`lib/presentation/pages/home/views/home_view.dart`** - View with state
- **`lib/presentation/components/main_data_loader.dart`** - Loading/error handling

**Key Patterns:**
- `HookConsumerWidget` - Widgets with hooks + Riverpod
- `MainDataLoader` - Handles async data with loading/error states
- Layout mixins (`MainLayout`, `HomeLayout`) - Consistent spacing

#### 7. Understand State Management in UI
- See how `ref.watch()` is used for reactive updates
- See how `useEffect()` handles side effects
- See how `useState()` manages local state

**Example from `home_view.dart`:**
```dart
final feedPosts = useFeedPosts(ref, userId: userId ?? '');

useEffect(() {
  final timer = Timer.periodic(const Duration(seconds: 30), (_) {
    ref.invalidate(getCircleMembersProvider);
  });
  return timer.cancel;
}, []);
```

### Phase 4: Advanced Topics (Day 8+)

#### 8. Custom Packages
Explore the `packages/` directory:
- **`dedecube_core`** - Result pattern, utilities
- **`dedecube_router`** - Navigation system
- **`dedecube_storage`** - Local storage abstraction
- **`dedecube_startup`** - App initialization

#### 9. Error Handling Deep Dive
- **`lib/core/features/supabase/data/mixins/supabase_result_processor.dart`** - Central error processor
- **`lib/core/features/auth/data/mappers/sign_in_exceptions_mapper.dart`** - Feature-specific mapping
- **`lib/core/exceptions/`** - Global exception types

#### 10. Middleware System
- **`lib/core/features/auth/domain/middlewares/auth_navigation_flow_middleware.dart`** - Auth guard
- **`lib/core/features/time_limit/domain/middlewares/time_limit_middleware.dart`** - Time limit guard

---

## Common Tasks & How-To

### Adding a New Feature

1. **Create feature structure:**
```
lib/core/features/my_feature/
├── data/
│   ├── services/my_feature_service.dart
│   ├── repositories/my_feature_repository.dart
│   ├── mappers/
│   └── providers/
└── domain/
    ├── contracts/
    ├── use_cases/
    ├── providers/
    └── models/
```

2. **Implement in order:**
   - Domain models (`domain/models/`)
   - Contracts (`domain/contracts/`)
   - Service (`data/services/`)
   - Repository (`data/repositories/`)
   - Use cases (`domain/use_cases/`)
   - Providers (`domain/providers/`)
   - UI (`presentation/pages/`)

3. **Follow the pattern:**
   - Service calls Supabase
   - Repository uses `processSupabaseResult` with exception mapper
   - Use case calls repository
   - Provider creates use case
   - UI uses provider

### Adding a New Page

1. **Create the page:**
```dart
// lib/presentation/pages/my_page/my_page.dart
class MyPage extends HookConsumerWidget with MainLayout {
  const MyPage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: topMargin),
          // Your content
        ],
      ),
    );
  }
}
```

2. **Create the route:**
```dart
// lib/presentation/pages/my_page/my_page_routable.dart
@freezed
sealed class MyPageRoutable extends Routable<MyPageRoutable> {
  const factory MyPageRoutable() = _MyPageRoutable;
  
  @override
  String get path => '/my-page';
  
  @override
  Widget buildPage(BuildContext context, MyPageRoutable routeData) {
    return const MyPage();
  }
}
```

3. **Register in routes:**
```dart
// lib/presentation/routes.dart
final List<BaseRoutable> routes = [
  // ... existing routes
  const MyPageRoutable(),
];
```

4. **Run code generation:**
```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

### Adding a New API Call

1. **Add to service:**
```dart
// data/services/my_service.dart
FutureResult<MyData> getMyData() async {
  try {
    final response = await supabaseClient
        .from('my_table')
        .select()
        .single();
    return Result.success(MyDataDto.fromJson(response));
  } on Exception catch (e) {
    return Result.failure(e);
  }
}
```

2. **Add to repository:**
```dart
// data/repositories/my_repository.dart
FutureResult<MyModel> getMyData() async {
  return processSupabaseResult<MyDataDto, MyModel>(
    request: () => service.getMyData(),
    responseMapper: (dto) async => MyModel.fromDto(dto),
    exceptionMapper: MyExceptionsMapper.fromSupabaseException,
  );
}
```

3. **Create use case:**
```dart
// domain/use_cases/get_my_data_use_case.dart
class GetMyDataUseCase {
  final MyRepositoryContract repository;
  
  Future<Result<MyModel>> execute() async {
    return await repository.getMyData();
  }
}
```

4. **Create provider:**
```dart
// domain/providers/get_my_data_provider.dart
@Riverpod
Future<Result<MyModel>> getMyData(Ref ref) async {
  final useCase = GetMyDataUseCase(
    repository: ref.watch(myRepositoryProvider),
  );
  return useCase.execute();
}
```

5. **Use in UI:**
```dart
final myDataAsync = ref.watch(getMyDataProvider);

return MainDataLoader(
  provider: myDataAsync,
  builder: (context, data) {
    // Use data
  },
);
```

### Handling Errors in UI

```dart
final result = await ref.read(someProvider.notifier).call();

result.fold(
  (data) {
    // Success - show data or navigate
  },
  (error) {
    // Error - show error message
    // Common errors are auto-handled by MainDataLoader
    // For custom handling, use errorBuilder
  },
);
```

### Adding Translations

1. **Add key to JSON:**
```json
// assets/translations/en.json
{
  "pages": {
    "my_page": {
      "title": "My Page"
    }
  }
}
```

2. **Use in code:**
```dart
translator.translate('pages.my_page.title')
```

3. **Custom lint ensures key exists** - IDE will warn if missing

---

## Important Files to Understand

### Core Files
- **`lib/main.dart`** - App entry point, initialization
- **`lib/core/features/startup/data/config/startup_config.dart`** - App configuration
- **`lib/presentation/routes.dart`** - All routes

### Architecture Files
- **`packages/dedecube_core/lib/src/result/result.dart`** - Result pattern
- **`lib/core/features/supabase/data/mixins/supabase_result_processor.dart`** - Error handling
- **`lib/core/features/auth/data/repositories/auth_repository.dart`** - Repository pattern example

### Feature Examples
- **`lib/core/features/auth/`** - Simple feature (good starting point)
- **`lib/core/features/post/`** - Complex feature (advanced patterns)

### UI Examples
- **`lib/presentation/pages/home/`** - Complex page with state
- **`lib/presentation/pages/sign_in/`** - Simple form page
- **`lib/presentation/components/main_data_loader.dart`** - Async data handling

### Navigation
- **`lib/presentation/pages/home/home_routable.dart`** - Route definition
- **`lib/core/features/auth/domain/middlewares/auth_navigation_flow_middleware.dart`** - Navigation guard

---

## Code Conventions

### Naming
- **Files:** `snake_case.dart`
- **Classes:** `PascalCase`
- **Variables/Methods:** `camelCase`
- **Constants:** `camelCase` (not `SCREAMING_SNAKE_CASE`)

### File Organization
- One class per file (enforced by custom lint)
- Group related files in folders
- Use `_` prefix for private members

### Widgets
- Use `HookConsumerWidget` for widgets needing state + Riverpod
- Use mixins for layout constants (`MainLayout`, `HomeLayout`)
- Extract complex widgets to separate files

### Error Handling
- Always use `Result<T>` for async operations
- Map exceptions at repository level
- Use `MainDataLoader` for async data in UI

### State Management
- Use `ref.watch()` for reactive updates
- Use `ref.read()` for one-time access or actions
- Use `ref.invalidate()` to refresh data
- Use `useState()` for local widget state
- Use `useEffect()` for side effects

### Imports
- Always use package imports (`package:cloudless/...`)
- Group imports: Flutter → Packages → Local
- Sort imports alphabetically

---

## Quick Reference

### Common Commands

```bash
# Get dependencies
fvm flutter pub get

# Generate code (Riverpod, Freezed, etc.)
fvm dart run build_runner build --delete-conflicting-outputs

# Watch mode (auto-generate on changes)
fvm dart run build_runner watch --delete-conflicting-outputs

# Run app
fvm flutter run --flavor production

# Analyze code
fvm flutter analyze
```

### Common Patterns

```dart
// Provider definition
@Riverpod
Future<Result<T>> myProvider(Ref ref, String param) async {
  final useCase = MyUseCase(
    repository: ref.watch(myRepositoryProvider),
  );
  return useCase.execute(param: param);
}

// Using provider in widget
final dataAsync = ref.watch(myProvider('param'));

// Navigation
router.go(const MyPageRoutable());
router.push(const MyPageRoutable());

// Error handling
result.fold(
  (data) => // success
  (error) => // failure
);
```

---

## Next Steps

1. **Start with Phase 1** - Get familiar with entry points and navigation
2. **Study the Auth feature** - Simplest feature, good learning example
3. **Try modifying something small** - Add a button, change text, etc.
4. **Read the README files** - Each feature has documentation
5. **Ask questions** - The codebase is well-structured, patterns are consistent

**Remember:** The codebase follows consistent patterns. Once you understand one feature, others follow the same structure!

