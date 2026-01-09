# goback .

A lightweight mobile application (iOS and Android) built with Flutter, designed for creating private circles where users can share temporary photo and video content with selected members. The app includes invite-only access, content auto-deletion after 24h, and daily usage limits to encourage mindful engagement.

## Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) (managed via FVM)
- [FVM](https://fvm.app/) - Flutter Version Management
- [GPG](https://gnupg.org/) - For decrypting configuration files
- Xcode (for iOS development)
- Android Studio (for Android development)

## Getting Started

### 1. Environment Setup

Copy the example environment file and configure it with your settings:

```bash
cp .env.example .env
```

Edit the `.env` file with your configuration values. Key variables include:
- `APP_DEBUG` - Enable/disable debug mode
- `SUPABASE_PROJECT_URL` - Your Supabase project URL
- `SUPABASE_ANON_KEY` - Your Supabase anonymous key
- `GPG_*_PASSPHRASE` - Passphrases for decrypting environment-specific configs

### 2. Load Environment Variables

Before decrypting config files, load the environment variables from the `.env` file:

```bash
# Load environment variables (run this in your current shell session)
export $(grep -v '^#' .env | xargs)
```

Alternatively, you can use `source` with a proper parser or manually set the specific variables:

```bash
# Or manually load specific variables (replace with actual values from .env)
export GPG_PRESTAGE_CONFIG_PASSPHRASE='your_prestage_passphrase'
export GPG_STAGE_CONFIG_PASSPHRASE='your_stage_passphrase'
export GPG_PRODUCTION_CONFIG_PASSPHRASE='your_production_passphrase'
```

### 3. Decrypt Configuration Files

The project uses GPG-encrypted configuration files for different environments (prestage, stage, production). 

**Decrypt Prestage environment:**

```bash
gpg --batch --yes --passphrase="$GPG_PRESTAGE_CONFIG_PASSPHRASE" --output config/prestage/google-services.json --decrypt config/prestage/google-services.json.gpg
gpg --batch --yes --passphrase="$GPG_PRESTAGE_CONFIG_PASSPHRASE" --output config/prestage/GoogleService-Info.plist --decrypt config/prestage/GoogleService-Info.plist.gpg
```

**Decrypt Stage environment:**

```bash
gpg --batch --yes --passphrase="$GPG_STAGE_CONFIG_PASSPHRASE" --output config/stage/google-services.json --decrypt config/stage/google-services.json.gpg
gpg --batch --yes --passphrase="$GPG_STAGE_CONFIG_PASSPHRASE" --output config/stage/GoogleService-Info.plist --decrypt config/stage/GoogleService-Info.plist.gpg
```

**Decrypt Production environment:**

```bash
gpg --batch --yes --passphrase="$GPG_PRODUCTION_CONFIG_PASSPHRASE" --output config/production/google-services.json --decrypt config/production/google-services.json.gpg
gpg --batch --yes --passphrase="$GPG_PRODUCTION_CONFIG_PASSPHRASE" --output config/production/GoogleService-Info.plist --decrypt config/production/GoogleService-Info.plist.gpg
```

**Or decrypt all at once:**

```bash
gpg --batch --yes --passphrase="$GPG_PRESTAGE_CONFIG_PASSPHRASE" --output config/prestage/google-services.json --decrypt config/prestage/google-services.json.gpg && gpg --batch --yes --passphrase="$GPG_PRESTAGE_CONFIG_PASSPHRASE" --output config/prestage/GoogleService-Info.plist --decrypt config/prestage/GoogleService-Info.plist.gpg && gpg --batch --yes --passphrase="$GPG_STAGE_CONFIG_PASSPHRASE" --output config/stage/google-services.json --decrypt config/stage/google-services.json.gpg && gpg --batch --yes --passphrase="$GPG_STAGE_CONFIG_PASSPHRASE" --output config/stage/GoogleService-Info.plist --decrypt config/stage/GoogleService-Info.plist.gpg && gpg --batch --yes --passphrase="$GPG_PRODUCTION_CONFIG_PASSPHRASE" --output config/production/google-services.json --decrypt config/production/google-services.json.gpg && gpg --batch --yes --passphrase="$GPG_PRODUCTION_CONFIG_PASSPHRASE" --output config/production/GoogleService-Info.plist --decrypt config/production/GoogleService-Info.plist.gpg
```

### 4. Copy Configuration Files

After decrypting the configuration files, copy them to the correct locations for iOS and Android:

```bash
# Create necessary directories
mkdir -p ios/Runner/prestage ios/Runner/stage ios/Runner/production
mkdir -p android/app/src/prestage android/app/src/stage android/app/src/production

# Copy iOS configuration files
cp config/prestage/GoogleService-Info.plist ios/Runner/prestage/
cp config/stage/GoogleService-Info.plist ios/Runner/stage/
cp config/production/GoogleService-Info.plist ios/Runner/production/

# Copy Android configuration files
cp config/prestage/google-services.json android/app/src/prestage/
cp config/stage/google-services.json android/app/src/stage/
cp config/production/google-services.json android/app/src/production/
```

Or copy all at once:

```bash
mkdir -p ios/Runner/prestage ios/Runner/stage ios/Runner/production android/app/src/prestage android/app/src/stage android/app/src/production && cp config/prestage/GoogleService-Info.plist ios/Runner/prestage/ && cp config/stage/GoogleService-Info.plist ios/Runner/stage/ && cp config/production/GoogleService-Info.plist ios/Runner/production/ && cp config/prestage/google-services.json android/app/src/prestage/ && cp config/stage/google-services.json android/app/src/stage/ && cp config/production/google-services.json android/app/src/production/
```

### 5. Install Dependencies

```bash
# Get main project dependencies
fvm flutter pub get
```

### 6. Build Icons

Generate custom icon fonts from SVG sources:

```bash
fvm dart run icon_font_generator:generator --config-file=icon_font_generator.yaml
```

Or use the VS Code task: `icon_font: generate`

### 7. Build Generated Files

#### Main Project Build

Generate code for the main project (Riverpod providers, JSON serialization, etc.):

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

Or use the VS Code task: `build_runner: build`

For continuous generation during development:

```bash
fvm dart run build_runner watch --delete-conflicting-outputs
```

Or use the VS Code task: `build_runner: watch`

#### Sub-Package Builds

The project contains multiple packages in the `packages/` directory that also require code generation. Build them individually or all at once:

**Build all packages:**

```bash
cd packages
for dir in */; do
  if [ -f "${dir}pubspec.yaml" ]; then
    echo "Building $dir..."
    cd "$dir"
    if grep -q "build_runner" pubspec.yaml; then
      fvm dart run build_runner build --delete-conflicting-outputs
    fi
    cd ..
  fi
done
cd ..
```

**Build individual packages:**

```bash
# Example: Build dedecube_environment
cd packages/dedecube_environment
fvm dart run build_runner build --delete-conflicting-outputs
cd ../..
```

Packages that require build_runner:
- `dedecube_environment`
- `dedecube_logger`
- `dedecube_router`
- `dedecube_startup`
- `dedecube_storage`
- `dedecube_themify`
- `dedecube_translator`

### 8. Run the Application

```bash
# Run in debug mode
fvm flutter run

# Run with specific flavor
fvm flutter run --flavor prestage
fvm flutter run --flavor stage
fvm flutter run --flavor production   
```

## Available VS Code Tasks

The project includes several VS Code tasks for common operations:

- `build_runner: clean` - Clean generated files
- `build_runner: build` - Generate files once
- `build_runner: watch` - Continuously generate files
- `build_runner: clean and watch` - Clean and then watch
- `icon_font: generate` - Generate icon fonts
- `icon_font: generate and build` - Generate icons and run build_runner
- `clean cache: remove .build and .dart_tool` - Deep clean

## Troubleshooting

### GPG Decryption Errors

If you get errors like `gpg: decryption failed: Bad session key` or `gcry_kdf_derive failed: Invalid data`, the passphrase might not be loaded correctly. Try:

**Option 1: Use passphrases directly in the command**

```bash
# Prestage (replace with actual passphrase from .env)
gpg --batch --yes --passphrase="your_prestage_passphrase" --output config/prestage/google-services.json --decrypt config/prestage/google-services.json.gpg
gpg --batch --yes --passphrase="your_prestage_passphrase" --output config/prestage/GoogleService-Info.plist --decrypt config/prestage/GoogleService-Info.plist.gpg

# Stage (replace with actual passphrase from .env)
gpg --batch --yes --passphrase="your_stage_passphrase" --output config/stage/google-services.json --decrypt config/stage/google-services.json.gpg
gpg --batch --yes --passphrase="your_stage_passphrase" --output config/stage/GoogleService-Info.plist --decrypt config/stage/GoogleService-Info.plist.gpg

# Production (replace with actual passphrase from .env)
gpg --batch --yes --passphrase="your_production_passphrase" --output config/production/google-services.json --decrypt config/production/google-services.json.gpg
gpg --batch --yes --passphrase="your_production_passphrase" --output config/production/GoogleService-Info.plist --decrypt config/production/GoogleService-Info.plist.gpg
```

**Option 2: Export variables without quotes**

```bash
export GPG_PRESTAGE_CONFIG_PASSPHRASE=your_prestage_passphrase
export GPG_STAGE_CONFIG_PASSPHRASE=your_stage_passphrase
export GPG_PRODUCTION_CONFIG_PASSPHRASE=your_production_passphrase
```

Then run the GPG commands with the variables.

### Missing generated files errors

If you see errors like `Target of URI hasn't been generated`, run:

1. Main project: `fvm dart run build_runner build --delete-conflicting-outputs`
2. All sub-packages: Follow the "Sub-Package Builds" instructions above

### Clean build

If you encounter persistent issues:

```bash
# Clean Flutter
fvm flutter clean

# Remove build artifacts
rm -rf .build .dart_tool

# Get dependencies again
fvm flutter pub get

# Rebuild everything
fvm dart run build_runner build --delete-conflicting-outputs
```
