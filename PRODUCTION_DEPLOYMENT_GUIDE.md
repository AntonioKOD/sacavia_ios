# Production Deployment Guide

## Environment Configuration

The iOS app is currently configured for **development** using localhost:3000. To deploy to production, you need to update the environment configuration in the following files:

### Files to Update for Production:

1. **Utils.swift** - Main API configuration
2. **APIService.swift** - API service configuration

### Steps to Deploy to Production:

#### 1. Update Utils.swift
```swift
// Change this line in Utils.swift
let isDevelopment = false  // Set to false for production
```

#### 2. Update APIService.swift
```swift
// Change this line in APIService.swift
static let isDevelopment = false  // Set to false for production
```

### Current Configuration (Development):
- **Base URL**: `http://localhost:3000`
- **API Endpoint**: `http://localhost:3000/api/mobile/saved`
- **Environment**: Development

### Production Configuration:
- **Base URL**: `https://sacavia.com`
- **API Endpoint**: `https://sacavia.com/api/mobile/saved`
- **Environment**: Production

## API Endpoints

The SavedView uses the following endpoint:
- **Development**: `http://localhost:3000/api/mobile/saved`
- **Production**: `https://sacavia.com/api/mobile/saved`

## Testing

Before deploying to production:

1. **Test with localhost**: Ensure the app works correctly with localhost:3000
2. **Verify API responses**: Check that the saved content loads properly
3. **Test authentication**: Ensure user authentication works with the production server
4. **Test error handling**: Verify error states display correctly

## Deployment Checklist

- [ ] Update `isDevelopment = false` in Utils.swift
- [ ] Update `isDevelopment = false` in APIService.swift
- [ ] Test API connectivity to production server
- [ ] Verify authentication works with production
- [ ] Test all saved content functionality
- [ ] Build and archive the app
- [ ] Submit to App Store Connect

## Rollback Plan

If issues arise in production, quickly rollback by:
1. Setting `isDevelopment = true` in both files
2. Rebuilding and redeploying
3. This will revert to localhost:3000 for testing

## Notes

- The app uses the same authentication system for both environments
- Media URLs are handled automatically by the `absoluteMediaURL` function
- Error handling is consistent across environments
- The SavedView will automatically use the correct base URL based on the environment setting 