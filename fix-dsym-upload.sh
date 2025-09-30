#!/bin/bash

# Script to help fix Firebase dSYM upload issues for App Store submission
# This script addresses common dSYM upload failures

echo "🔧 Fixing Firebase dSYM upload issues..."

# 1. Clean build folder
echo "📦 Cleaning build folder..."
xcodebuild clean -project SacaviaApp.xcodeproj -scheme SacaviaApp

# 2. Archive with proper dSYM generation
echo "🏗️ Creating archive with dSYM generation..."
xcodebuild archive \
    -project SacaviaApp.xcodeproj \
    -scheme SacaviaApp \
    -configuration Release \
    -archivePath "build/SacaviaApp.xcarchive" \
    -destination "generic/platform=iOS" \
    DEBUG_INFORMATION_FORMAT="dwarf-with-dsym" \
    ENABLE_BITCODE=NO \
    STRIP_INSTALLED_PRODUCT=NO \
    SEPARATE_STRIP=NO \
    COPY_PHASE_STRIP=NO

# 3. Check if dSYM files were generated
echo "🔍 Checking dSYM files..."
if [ -d "build/SacaviaApp.xcarchive/dSYMs" ]; then
    echo "✅ dSYM files found:"
    ls -la "build/SacaviaApp.xcarchive/dSYMs/"
else
    echo "❌ No dSYM files found in archive"
fi

# 4. Export IPA
echo "📱 Exporting IPA..."
xcodebuild -exportArchive \
    -archivePath "build/SacaviaApp.xcarchive" \
    -exportPath "build/Export" \
    -exportOptionsPlist "ExportOptions.plist"

echo "✅ Archive and export completed!"
echo "📋 Next steps:"
echo "1. Upload the IPA to App Store Connect"
echo "2. If dSYM upload still fails, try uploading dSYM files manually:"
echo "   - Go to App Store Connect > Your App > TestFlight > Builds"
echo "   - Click on your build > Download dSYM"
echo "   - Upload the dSYM files manually if needed"
