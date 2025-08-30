#!/bin/bash

echo "🔍 iOS Notification Setup Checker"
echo "=================================="
echo ""

# Check if we're in the right directory
if [ ! -f "SacaviaApp.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Please run this script from the SacaviaApp directory"
    echo "   Current directory: $(pwd)"
    echo "   Expected: SacaviaApp.xcodeproj should be present"
    exit 1
fi

echo "✅ Found Xcode project: SacaviaApp.xcodeproj"
echo ""

# Check entitlements file
if [ -f "SacaviaApp/SacaviaApp.entitlements" ]; then
    echo "✅ Found entitlements file: SacaviaApp/SacaviaApp.entitlements"
    
    # Check for aps-environment
    if grep -q "aps-environment" "SacaviaApp/SacaviaApp.entitlements"; then
        echo "✅ Found aps-environment in entitlements file"
        APS_ENV=$(grep -A1 "aps-environment" "SacaviaApp/SacaviaApp.entitlements" | tail -1 | sed 's/<[^>]*>//g' | tr -d ' ')
        echo "   Environment: $APS_ENV"
    else
        echo "❌ Missing aps-environment in entitlements file"
    fi
else
    echo "❌ Missing entitlements file: SacaviaApp/SacaviaApp.entitlements"
fi

echo ""

# Check project.pbxproj for capabilities
echo "🔍 Checking Xcode project capabilities..."

if grep -q "com.apple.developer.aps-environment" "SacaviaApp.xcodeproj/project.pbxproj"; then
    echo "✅ Push Notifications capability found in project"
else
    echo "❌ Push Notifications capability NOT found in project"
    echo "   You need to add 'Push Notifications' capability in Xcode"
fi

if grep -q "com.apple.developer.background-modes" "SacaviaApp.xcodeproj/project.pbxproj"; then
    echo "✅ Background Modes capability found in project"
else
    echo "❌ Background Modes capability NOT found in project"
    echo "   You need to add 'Background Modes' capability in Xcode"
fi

echo ""

# Check for remote notifications background mode
if grep -q "remote-notification" "SacaviaApp.xcodeproj/project.pbxproj"; then
    echo "✅ Remote notifications background mode found"
else
    echo "❌ Remote notifications background mode NOT found"
    echo "   You need to enable 'Remote notifications' in Background Modes"
fi

echo ""

# Check Info.plist for notification permissions
if [ -f "Info.plist" ]; then
    echo "✅ Found Info.plist"
    if grep -q "NSUserNotificationUsageDescription" "Info.plist"; then
        echo "✅ Notification usage description found in Info.plist"
    else
        echo "❌ Missing notification usage description in Info.plist"
    fi
else
    echo "❌ Missing Info.plist"
fi

echo ""
echo "=================================="
echo "📋 Summary:"
echo ""

# Count issues
ISSUES=0
if ! grep -q "com.apple.developer.aps-environment" "SacaviaApp.xcodeproj/project.pbxproj"; then
    ISSUES=$((ISSUES + 1))
fi
if ! grep -q "com.apple.developer.background-modes" "SacaviaApp.xcodeproj/project.pbxproj"; then
    ISSUES=$((ISSUES + 1))
fi
if ! grep -q "remote-notification" "SacaviaApp.xcodeproj/project.pbxproj"; then
    ISSUES=$((ISSUES + 1))
fi

if [ $ISSUES -eq 0 ]; then
    echo "🎉 All checks passed! Your iOS notification setup looks good."
    echo ""
    echo "Next steps:"
    echo "1. Build and run the app on a real device"
    echo "2. Grant notification permission when prompted"
    echo "3. Test notifications using Profile > Settings > Test Notifications"
else
    echo "⚠️  Found $ISSUES issue(s) that need to be fixed:"
    echo ""
    echo "To fix these issues:"
    echo "1. Open SacaviaApp.xcodeproj in Xcode"
    echo "2. Select the project and target"
    echo "3. Go to 'Signing & Capabilities' tab"
    echo "4. Add 'Push Notifications' capability"
    echo "5. Add 'Background Modes' capability"
    echo "6. Enable 'Remote notifications' in Background Modes"
    echo "7. Clean and rebuild the project"
fi

echo ""
echo "📖 For detailed instructions, see: iOS_PUSH_NOTIFICATION_SETUP_GUIDE.md"
