# Authentication Implementation for Flutter App

This implementation provides complete authentication functionality for the Flutter app to connect with the FastAPI backend.

## Features Implemented

### 1. Directory Structure
```
lib/
├── config/
│   └── api_config.dart          # API configuration and endpoints
├── services/
│   ├── auth_service.dart        # Authentication service
│   └── api_service.dart         # General API service for diary operations
└── utils/
    └── validation_utils.dart    # Input validation utilities
```

### 2. Dependencies Added
- `flutter_secure_storage: ^9.2.2` - Secure storage for credentials

### 3. Authentication Features

#### Login Functionality
- Email and password validation using regex
- Real-time form validation with error messages
- Secure credential storage option ("Guardar datos" switch)
- Auto-login on app startup if credentials are saved
- API integration with FastAPI backend
- Loading states and error handling

#### Signup Functionality
- Email, password, nickname validation
- Password confirmation validation
- Account creation via API
- Automatic login after successful signup
- Real-time form validation with error messages

#### Security Features
- Credentials stored in Flutter Secure Storage (encrypted)
- Password validation (min 8 chars, letters + numbers required)
- Email format validation
- Secure auto-login functionality

### 4. API Configuration
- Configured for Android emulator (10.0.2.2:8000)
- Proper headers for JSON communication
- Error handling for network issues
- Structured response handling

### 5. Validation Rules

#### Email Validation
- Must be valid email format
- Required field

#### Password Validation
- Minimum 8 characters
- Must contain at least one letter
- Must contain at least one number

#### Nickname Validation
- 2-20 characters
- Letters, numbers, spaces, and some special characters allowed

### 6. User Experience Features
- Auto-login on app startup
- "Save credentials" toggle with Material switch
- Loading indicators during API calls
- Error messages in Spanish
- Success feedback
- Smooth navigation flow

## Usage

### Starting the Backend
Make sure your FastAPI backend is running:
```bash
cd backend
python -m uvicorn app.main:main --host 0.0.0.0 --port 8000
```

### Testing with Android Emulator
The app is configured to connect to `10.0.2.2:8000` which maps to `localhost:8000` on your host machine when running in the Android emulator.

### Authentication Flow
1. User opens app
2. App checks for saved credentials
3. If credentials exist and "save data" was enabled, auto-login is attempted
4. On successful login, user data is stored securely
5. User is navigated to MainMenuScreen

## Files Modified/Created

### New Files
- `lib/config/api_config.dart` - API configuration
- `lib/services/auth_service.dart` - Authentication service
- `lib/services/api_service.dart` - General API service
- `lib/utils/validation_utils.dart` - Validation utilities

### Modified Files
- `pubspec.yaml` - Added flutter_secure_storage dependency
- `lib/screens/login_screen.dart` - Complete authentication implementation
- `lib/main.dart` - Added auto-login check on app startup

## API Endpoints Used
- `POST /login` - User authentication
- `POST /signup` - User registration
- `POST /diary` - Add diary entry (available for future use)
- `GET /diary/{user}` - Get user diary entries (available for future use)
- `GET /diary/{user}/{date}` - Get diary entries by date (available for future use)
- `POST /predict-image` - Image prediction (available for future use)
- `POST /prompt` - AI prompt processing (available for future use)

The implementation is production-ready with proper error handling, validation, and security measures.