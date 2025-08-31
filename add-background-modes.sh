#!/bin/bash

# Script to add Background Modes capability to Xcode project
# This script modifies the project.pbxproj file to add the required capability

PROJECT_FILE="SacaviaApp.xcodeproj/project.pbxproj"
TEMP_FILE="project_temp.pbxproj"

echo "🔧 Adding Background Modes capability to Xcode project..."

# Check if project file exists
if [ ! -f "$PROJECT_FILE" ]; then
    echo "❌ Project file not found: $PROJECT_FILE"
    exit 1
fi

# Add Background Modes capability if not already present
if ! grep -q "com.apple.BackgroundModes" "$PROJECT_FILE"; then
    echo "📝 Adding Background Modes capability..."
    
    # Find SystemCapabilities and add Background Modes capability
    awk '
    /SystemCapabilities = {/ {
        print $0
        print "\t\t\t\t\tcom.apple.BackgroundModes = {"
        print "\t\t\t\t\t\tenabled = 1;"
        print "\t\t\t\t\t};"
        next
    }
    { print $0 }
    ' "$PROJECT_FILE" > "$TEMP_FILE"
    
    mv "$TEMP_FILE" "$PROJECT_FILE"
    echo "✅ Added Background Modes capability"
else
    echo "ℹ️  Background Modes capability already exists"
fi

echo "🎉 Background Modes capability added successfully!"
echo "📱 Next steps:"
echo "   1. Open Xcode and clean build folder (Product > Clean Build Folder)"
echo "   2. Delete app from device/simulator"
echo "   3. Build and run again"
echo "   4. Check console logs for successful APNS registration"
