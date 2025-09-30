# TokenAPI Integration Guide - iOS App & Web Backend

## 🎯 Overview

This guide explains how the iOS app's `TokenAPI.swift` integrates with your web app's push notification endpoints to provide seamless FCM token management and push notification delivery.

## 🔗 API Endpoint Mapping

### **iOS TokenAPI** ↔ **Web Backend Endpoints**

| iOS Method | Web Endpoint | Purpose |
|------------|--------------|---------|
| `registerDeviceToken()` | `POST /api/push/register` | Register/update FCM device tokens |
| `deactivateDeviceToken()` | `DELETE /api/push/register` | Deactivate device tokens |
| `getDeviceTokenInfo()` | `GET /api/push/register` | Get token information |
| `subscribeToTopics()` | `POST /api/push/subscribe` | Subscribe to FCM topics |
| `unsubscribeFromTopics()` | `POST /api/push/unsubscribe` | Unsubscribe from topics |
| `unsubscribeFromAllTopics()` | `POST /api/push/unsubscribe` | Unsubscribe from all topics |
| `getCurrentTopics()` | `GET /api/push/unsubscribe` | Get current topic subscriptions |
| `sendNotification()` | `POST /api/push/send` | Send push notifications |
| `getAvailableTopics()` | `GET /api/push/send?action=topics` | Get all available topics |

## 📱 iOS App Integration

### **1. TokenAPI.swift Features**

- **Automatic URL Configuration**: Switches between development (`localhost:3000`) and production (`sacavia.com`)
- **Comprehensive Error Handling**: Network, HTTP, and server error management
- **Device Information Collection**: Automatically gathers device model, OS, app version
- **Async/Await Support**: Modern Swift concurrency for API calls
- **ObservableObject**: Integrates with SwiftUI for real-time updates

### **2. Key Methods**

#### **Device Token Registration**
```swift
// Register FCM token with server
let result = await TokenAPI.shared.registerDeviceToken(
    deviceToken: "fcm_token_here",
    userId: "user123",
    platform: "ios",
    deviceInfo: TokenAPI.getCurrentDeviceInfo()
)
```

#### **Topic Management**
```swift
// Subscribe to topics
let success = await TokenAPI.shared.subscribeToTopics(
    deviceToken: "fcm_token",
    topics: ["news", "updates"],
    userId: "user123"
)

// Unsubscribe from topics
let success = await TokenAPI.shared.unsubscribeFromTopics(
    deviceToken: "fcm_token",
    topics: ["news"],
    userId: "user123"
)
```

#### **Send Test Notifications**
```swift
// Send notification to specific device
let success = await TokenAPI.shared.sendNotification(
    type: "token",
    target: "fcm_token",
    title: "Test Notification",
    body: "This is a test message"
)
```

### **3. AppDelegate Integration**

The `AppDelegate.swift` automatically:
- Registers FCM tokens with your server
- Handles token refresh and updates
- Manages APNs and FCM token synchronization
- Integrates with existing `PushNotificationManager`

### **4. PushNotificationManager Integration**

Enhanced with TokenAPI methods:
- `registerDeviceToken()` - Server registration
- `subscribeToTopics()` - Topic management
- `sendTestNotification()` - Test notification delivery
- Automatic error handling and user feedback

## 🌐 Web Backend Integration

### **1. API Endpoints Structure**

Your web app provides these endpoints:

```
/api/push/
├── register/          # Device token management
├── send/              # Send notifications
├── subscribe/         # Topic subscriptions
├── unsubscribe/       # Topic unsubscriptions
└── status/            # Service health check
```

### **2. Data Flow**

```
iOS App → TokenAPI → Web Backend → Firebase → Device
   ↓           ↓           ↓          ↓        ↓
FCM Token → API Call → Token Store → FCM Send → Push
```

### **3. Authentication Integration**

The TokenAPI automatically includes user context:
- `userId` from your existing `AuthManager`
- Device information for analytics
- Platform identification (`ios`)

## 🔄 Complete Workflow

### **1. App Launch**
```
1. iOS App launches
2. Firebase configures
3. FCM token generated
4. TokenAPI registers token with server
5. Server stores token in deviceTokens collection
6. App ready for push notifications
```

### **2. Topic Subscription**
```
1. User subscribes to topics (e.g., "news", "events")
2. TokenAPI calls /api/push/subscribe
3. Server updates deviceTokens collection
4. FCM topic subscription created
5. User receives topic-based notifications
```

### **3. Notification Delivery**
```
1. Server sends notification via /api/push/send
2. FCM delivers to device
3. AppDelegate handles notification
4. PushNotificationManager processes content
5. User sees notification
```

## 🧪 Testing & Debugging

### **1. Connection Testing**
```swift
// Test server connection
TokenAPI.shared.testConnection()

// Check connection status
if TokenAPI.shared.isConnected {
    print("✅ Connected to server")
} else {
    print("❌ Connection failed: \(TokenAPI.shared.lastError ?? "Unknown")")
}
```

### **2. Token Registration Testing**
```swift
// Test token registration
let success = await PushNotificationManager.shared.registerDeviceToken(
    "test_token",
    userId: "test_user"
)

if success {
    print("✅ Token registered successfully")
} else {
    print("❌ Token registration failed")
}
```

### **3. Topic Management Testing**
```swift
// Test topic subscription
let success = await PushNotificationManager.shared.subscribeToTopics(
    ["test_topic"],
    userId: "test_user"
)

// Test notification sending
let sent = await PushNotificationManager.shared.sendTestNotification(
    title: "Test",
    body: "Test notification"
)
```

## 📊 Monitoring & Analytics

### **1. Console Logs**
Look for these log patterns:
```
✅ [TokenAPI] Connection test: Success
✅ [AppDelegate] FCM token registered successfully
✅ [PushNotificationManager] Subscribed to topics: Successfully subscribed to 2 topic(s)
```

### **2. Server Logs**
Your web backend logs:
- Token registration attempts
- Topic subscription changes
- Notification delivery status
- Error conditions and resolutions

### **3. Firebase Console**
- FCM token generation
- Message delivery statistics
- Topic subscription counts
- Error rates and patterns

## 🚨 Error Handling

### **1. Common Issues**

#### **Connection Failures**
```swift
// TokenAPI automatically handles:
- Network timeouts
- Server errors
- Invalid responses
- Authentication failures
```

#### **Token Registration Failures**
```swift
// Automatic retry logic:
- Invalid token format
- Server validation errors
- Database connection issues
- User permission problems
```

### **2. Error Recovery**
```swift
// TokenAPI provides:
- Detailed error messages
- Automatic connection testing
- Graceful degradation
- User-friendly error reporting
```

## 🔧 Configuration

### **1. Environment Variables**
```swift
#if DEBUG
self.baseURL = "http://localhost:3000/api"  // Development
#else
self.baseURL = "https://www.sacavia.com/api" // Production
#endif
```

### **2. Timeout Settings**
```swift
let config = URLSessionConfiguration.default
config.timeoutIntervalForRequest = 30    // 30 seconds
config.timeoutIntervalForResource = 60   // 60 seconds
```

### **3. Retry Logic**
The TokenAPI automatically:
- Retries failed requests
- Handles network interruptions
- Manages connection state
- Provides user feedback

## 📱 User Experience

### **1. Automatic Token Management**
- Users don't need to manually register devices
- Tokens automatically refresh and update
- Seamless topic subscription management
- Background notification processing

### **2. Error Feedback**
- Success notifications for completed actions
- Error notifications for failed operations
- Clear status indicators
- Helpful troubleshooting information

### **3. Performance**
- Async/await for non-blocking operations
- Efficient token caching
- Minimal network overhead
- Fast response times

## 🚀 Production Deployment

### **1. Environment Switching**
```swift
// Automatically switches based on build configuration
#if DEBUG
// Development: localhost:3000
#else
// Production: sacavia.com
#endif
```

### **2. Security**
- HTTPS for production endpoints
- User authentication integration
- Token validation
- Rate limiting support

### **3. Monitoring**
- Connection health monitoring
- Error rate tracking
- Performance metrics
- User engagement analytics

## ✅ Integration Checklist

- [ ] TokenAPI.swift added to iOS project
- [ ] AppDelegate updated to use TokenAPI
- [ ] PushNotificationManager enhanced with TokenAPI methods
- [ ] Web backend endpoints implemented and tested
- [ ] Firebase configuration verified
- [ ] Token registration flow tested
- [ ] Topic management tested
- [ ] Notification delivery verified
- [ ] Error handling tested
- [ ] Production configuration ready

## 🎉 Benefits

### **For Developers:**
- Clean, maintainable code structure
- Comprehensive error handling
- Easy testing and debugging
- Scalable architecture

### **For Users:**
- Reliable push notifications
- Seamless topic management
- Fast notification delivery
- Better user experience

### **For Operations:**
- Centralized token management
- Easy monitoring and debugging
- Scalable infrastructure
- Reduced maintenance overhead

Your iOS app and web backend are now fully integrated for comprehensive push notification management!
