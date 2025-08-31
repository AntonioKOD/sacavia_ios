#!/bin/bash

# Script to add Push Notifications capability to Xcode project
# This script modifies the project.pbxproj file to add the required capability

PROJECT_FILE="SacaviaApp.xcodeproj/project.pbxproj"
TEMP_FILE="project_temp.pbxproj"

echo "🔧 Adding Push Notifications capability to Xcode project..."

# Check if project file exists
if [ ! -f "$PROJECT_FILE" ]; then
    echo "❌ Project file not found: $PROJECT_FILE"
    exit 1
fi

# Create backup
cp "$PROJECT_FILE" "${PROJECT_FILE}.backup"
echo "✅ Created backup: ${PROJECT_FILE}.backup"

# Add the SystemCapabilities section if it doesn't exist
if ! grep -q "SystemCapabilities" "$PROJECT_FILE"; then
    echo "📝 Adding SystemCapabilities section..."
    
    # Find the main target section and add SystemCapabilities
    awk '
    /isa = PBXNativeTarget;/ {
        print $0
        print "\t\t\t\tSystemCapabilities = {"
        print "\t\t\t\t\tcom.apple.Push = {"
        print "\t\t\t\t\t\tenabled = 1;"
        print "\t\t\t\t\t};"
        print "\t\t\t\t};"
        next
    }
    { print $0 }
    ' "$PROJECT_FILE" > "$TEMP_FILE"
    
    mv "$TEMP_FILE" "$PROJECT_FILE"
    echo "✅ Added SystemCapabilities section"
else
    echo "ℹ️  SystemCapabilities section already exists"
fi

# Add Push Notifications capability if not already present
if ! grep -q "com.apple.Push" "$PROJECT_FILE"; then
    echo "📝 Adding Push Notifications capability..."
    
    # Find SystemCapabilities and add Push capability
    awk '
    /SystemCapabilities = {/ {
        print $0
        print "\t\t\t\t\tcom.apple.Push = {"
        print "\t\t\t\t\t\tenabled = 1;"
        print "\t\t\t\t\t};"
        next
    }
    { print $0 }
    ' "$PROJECT_FILE" > "$TEMP_FILE"
    
    mv "$TEMP_FILE" "$PROJECT_FILE"
    echo "✅ Added Push Notifications capability"
else
    echo "ℹ️  Push Notifications capability already exists"
fi

echo "🎉 Push Notifications capability added successfully!"
echo "📱 Next steps:"
echo "   1. Open Xcode and clean build folder (Product > Clean Build Folder)"
echo "   2. Delete app from device/simulator"
echo "   3. Build and run again"
echo "   4. Check console logs for successful APNS registration"
