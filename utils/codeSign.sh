#!/bin/bash

set -e  # Exit on any error
set -o pipefail  # Catch errors in piped commands

# Check for required arguments
if [ -z "$1" ]; then
    echo "Usage: $0 <folder-path> [signing-identity]"
    exit 1
fi

FOLDER_PATH="$1"
SIGNING_IDENTITY="$2"

# Check if the folder exists
if [ ! -d "$FOLDER_PATH" ]; then
    echo "Error: Folder not found at $FOLDER_PATH"
    exit 1
fi

# Auto-detect a signing identity if not provided
if [ -z "$SIGNING_IDENTITY" ]; then
    SIGNING_IDENTITY=$(security find-identity -p codesigning -v | grep 'Apple Development' | head -n 1 | awk '{print $2}')
    if [ -z "$SIGNING_IDENTITY" ]; then
        echo "Error: No valid signing identity found."
        exit 1
    fi
fi

# Function to run a command and indent its output
run_and_indent() {
    "$@" 2>&1 | sed 's/^/\t/'
}

is_signed() {
    codesign --verify --verbose=4 "$1" &>/dev/null
}

echo "Using signing identity: $SIGNING_IDENTITY"

# Find all .xcframework directories in the given folder
find "$FOLDER_PATH" -type d -name "*.xcframework" | while read -r XCFRAMEWORK; do
    FRAMEWORK_NAME=$(basename "$XCFRAMEWORK" .xcframework)

 # Check if the xcframework is already signed
    if is_signed "$XCFRAMEWORK"; then
        echo "✅ Already signed, skipping: $XCFRAMEWORK"
        echo "-------------------------------------------------"
        #continue
    fi

    # Check for both possible target directories
    TARGET_PATH_1="$XCFRAMEWORK/ios-arm64_x86_64-maccatalyst"
    TARGET_PATH_2="$XCFRAMEWORK/ios-arm64-maccatalyst"
    echo "CHECKING $FRAMEWORK_NAME"

    if [ -d "$TARGET_PATH_1" ]; then
        TARGET_PATH="$TARGET_PATH_1"
    elif [ -d "$TARGET_PATH_2" ]; then
        TARGET_PATH="$TARGET_PATH_2"
    else
        echo "\t ⚠️ Warning: Neither ios-arm64_x86_64-maccatalyst nor ios-arm64-maccatalyst exists in $FRAMEWORK_NAME"
        continue
    fi

    FRAMEWORK_DIR="$TARGET_PATH/$FRAMEWORK_NAME.framework"
    FRAMEWORK_BINARY="$FRAMEWORK_DIR/Versions/A"

    # Determine which component to sign
    if [ -d "$FRAMEWORK_BINARY" ]; then
        SIGN_TARGET="$FRAMEWORK_BINARY"
        echo "\tChecking framework binary: $SIGN_TARGET"
    elif [ -d "$FRAMEWORK_DIR" ]; then
        SIGN_TARGET="$FRAMEWORK_DIR"
        echo "\tChecking framework directory: $SIGN_TARGET"
    else
        echo "\t ⚠️ Warning: No valid framework binary found, skipping: $SIGN_TARGET"
	continue
    fi

     # Check if already signed
    if is_signed "$SIGN_TARGET"; then
        echo "✅ Already signed, skipping: $SIGN_TARGET"
    else
        echo "\t🔹 Signing target: $SIGN_TARGET"
        run_and_indent codesign --force --deep --sign "$SIGNING_IDENTITY" "$SIGN_TARGET"
    fi

    # Check and sign the xcframework if needed
    if is_signed "$XCFRAMEWORK"; then
        echo "\t✅ Already signed, skipping: $XCFRAMEWORK"
    else
        echo "\t🔹 Signing xcframework:"
        run_and_indent codesign --force --deep --sign "$SIGNING_IDENTITY" "$XCFRAMEWORK"
    fi

    # Verify the signing with indented output
    echo "\t🔍 Verifying framework signature:"
    run_and_indent codesign --verify --verbose=4 "$SIGN_TARGET"

    echo "\t🔍 Verifying xcframework signature:"
    run_and_indent codesign --verify --verbose=4 "$XCFRAMEWORK"

    echo "\t ✅ Successfully signed: $XCFRAMEWORK"
done

echo "🎉 All xcframeworks processed!"
