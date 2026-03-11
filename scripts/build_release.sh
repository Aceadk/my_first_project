#!/bin/bash
# =============================================================================
# CRUSHHOUR RELEASE BUILD SCRIPT
# =============================================================================
# This script builds release artifacts for Android (AAB) and iOS (IPA)
# =============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Project root (script assumes it's in scripts/ folder)
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo -e "${GREEN}=== CrushHour Release Build ===${NC}"
echo "Project root: $PROJECT_ROOT"

# =============================================================================
# CONFIGURATION
# =============================================================================

resolve_flavor() {
    local raw_value="$1"
    local normalized
    normalized=$(echo "$raw_value" | tr '[:upper:]' '[:lower:]')

    case "$normalized" in
        dev|development)
            echo "development"
            ;;
        stage|staging)
            echo "staging"
            ;;
        prod|production)
            echo "production"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Build flavor resolution:
# 1) Canonical FLAVOR
# 2) Legacy APP_ENV (deprecated fallback)
# 3) Default production
if [ -n "${FLAVOR:-}" ]; then
    RESOLVED_FLAVOR=$(resolve_flavor "$FLAVOR")
    if [ -z "$RESOLVED_FLAVOR" ]; then
        echo -e "${YELLOW}Warning: Unknown FLAVOR='$FLAVOR'. Falling back to production.${NC}"
        FLAVOR="production"
    else
        FLAVOR="$RESOLVED_FLAVOR"
    fi

    if [ -n "${APP_ENV:-}" ]; then
        echo -e "${YELLOW}Warning: APP_ENV is deprecated and ignored because FLAVOR is set.${NC}"
    fi
elif [ -n "${APP_ENV:-}" ]; then
    RESOLVED_FLAVOR=$(resolve_flavor "$APP_ENV")
    if [ -z "$RESOLVED_FLAVOR" ]; then
        echo -e "${YELLOW}Warning: Unknown APP_ENV='$APP_ENV'. Falling back to production.${NC}"
        FLAVOR="production"
    else
        FLAVOR="$RESOLVED_FLAVOR"
        echo -e "${YELLOW}Warning: APP_ENV is deprecated. Use FLAVOR instead (mapped to '$FLAVOR').${NC}"
    fi
else
    FLAVOR="production"
fi

# Version from pubspec.yaml
VERSION=$(grep 'version:' pubspec.yaml | awk '{print $2}')
echo "Version: $VERSION"
echo "Flavor: $FLAVOR"

# Build date for artifact naming
BUILD_DATE=$(date +%Y%m%d_%H%M%S)

# Output directory
OUTPUT_DIR="$PROJECT_ROOT/build/releases"
mkdir -p "$OUTPUT_DIR"

# =============================================================================
# DART DEFINE FLAGS
# =============================================================================

DART_DEFINES=""
DART_DEFINES="$DART_DEFINES --dart-define=FLAVOR=$FLAVOR"

# Add Agora if set
if [ -n "$AGORA_APP_ID" ]; then
    DART_DEFINES="$DART_DEFINES --dart-define=AGORA_APP_ID=$AGORA_APP_ID"
fi

# Production defaults
if [ "$FLAVOR" = "production" ]; then
    DART_DEFINES="$DART_DEFINES --dart-define=ENABLE_ANALYTICS=true"
    DART_DEFINES="$DART_DEFINES --dart-define=ENABLE_CRASHLYTICS=true"
    DART_DEFINES="$DART_DEFINES --dart-define=ENABLE_PERFORMANCE=true"
    DART_DEFINES="$DART_DEFINES --dart-define=ENABLE_CHAT_E2EE=true"
fi

echo "Dart defines: $DART_DEFINES"

# =============================================================================
# FUNCTIONS
# =============================================================================

build_android() {
    echo -e "\n${YELLOW}Building Android App Bundle (AAB)...${NC}"

    # Check for keystore
    if [ ! -f "$PROJECT_ROOT/android/key.properties" ]; then
        echo -e "${RED}Error: android/key.properties not found${NC}"
        echo "Create key.properties with your signing configuration"
        return 1
    fi

    # Clean previous builds
    flutter clean

    # Get dependencies
    flutter pub get

    # Build AAB
    flutter build appbundle --release $DART_DEFINES

    # Copy to releases folder
    AAB_PATH="$PROJECT_ROOT/build/app/outputs/bundle/release/app-release.aab"
    if [ -f "$AAB_PATH" ]; then
        OUTPUT_NAME="crushhour-${VERSION}-${FLAVOR}-${BUILD_DATE}.aab"
        cp "$AAB_PATH" "$OUTPUT_DIR/$OUTPUT_NAME"
        echo -e "${GREEN}Android AAB built successfully!${NC}"
        echo "Output: $OUTPUT_DIR/$OUTPUT_NAME"

        # Show AAB size
        ls -lh "$OUTPUT_DIR/$OUTPUT_NAME"
    else
        echo -e "${RED}Error: AAB not found at expected path${NC}"
        return 1
    fi
}

build_apk() {
    echo -e "\n${YELLOW}Building Android APK (for testing)...${NC}"

    flutter build apk --release $DART_DEFINES

    APK_PATH="$PROJECT_ROOT/build/app/outputs/flutter-apk/app-release.apk"
    if [ -f "$APK_PATH" ]; then
        OUTPUT_NAME="crushhour-${VERSION}-${FLAVOR}-${BUILD_DATE}.apk"
        cp "$APK_PATH" "$OUTPUT_DIR/$OUTPUT_NAME"
        echo -e "${GREEN}Android APK built successfully!${NC}"
        echo "Output: $OUTPUT_DIR/$OUTPUT_NAME"
    fi
}

build_ios() {
    echo -e "\n${YELLOW}Building iOS Archive...${NC}"

    # Check platform
    if [[ "$(uname)" != "Darwin" ]]; then
        echo -e "${RED}Error: iOS builds require macOS${NC}"
        return 1
    fi

    # Clean
    flutter clean

    # Get dependencies
    flutter pub get

    # Install pods
    cd ios
    pod install --repo-update
    cd ..

    # Build iOS (no codesign for archive preparation)
    flutter build ios --release $DART_DEFINES

    echo -e "${GREEN}iOS build completed!${NC}"
    echo "Open Xcode to create archive: open ios/Runner.xcworkspace"
    echo "Then: Product > Archive"
}

show_help() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  android    Build Android AAB for Play Store"
    echo "  apk        Build Android APK for testing"
    echo "  ios        Build iOS for App Store"
    echo "  all        Build both Android and iOS"
    echo "  help       Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  FLAVOR           Build flavor (development/staging/production)"
    echo "  APP_ENV          Legacy flavor alias (deprecated; use FLAVOR)"
    echo "  AGORA_APP_ID     Agora App ID for video calls"
    echo ""
    echo "Examples:"
    echo "  FLAVOR=production ./scripts/build_release.sh android"
    echo "  AGORA_APP_ID=xxx ./scripts/build_release.sh all"
}

# =============================================================================
# MAIN
# =============================================================================

case "${1:-help}" in
    android)
        build_android
        ;;
    apk)
        build_apk
        ;;
    ios)
        build_ios
        ;;
    all)
        build_android
        build_ios
        ;;
    help|*)
        show_help
        ;;
esac

echo -e "\n${GREEN}Done!${NC}"
