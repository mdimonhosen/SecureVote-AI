# Voting App with Face Recognition

A Flutter application for secure voting using Supabase database and Microsoft Face API for biometric authentication.

## Features

### Admin Module
- Login with credentials
- Approve/disapprove user accounts
- Create and manage polls (public and private)
- Add candidates to polls
- View poll results and voter lists
- Manage poll lifecycle (current, upcoming, expired)

### User Module
- Register and login with email/password
- Biometric authentication (fingerprint/face unlock)
- Update profile information
- View active polls and candidates
- Cast votes with face recognition verification
- View poll results for completed polls
- Access private polls with security codes

## Setup Instructions

### 1. Prerequisites
- Flutter SDK (3.9.2 or higher)
- Supabase account
- Microsoft Azure account with Face API

### 2. Supabase Setup
1. Create a new Supabase project
2. Go to SQL Editor and run the SQL code from `all sql.sql`
3. Get your project URL and anon key from Settings > API
4. Create an admin user manually in the database or via auth

### 3. Microsoft Face API Setup
1. Create a Face resource in Azure
2. Get your API key and endpoint
3. Create a person group called 'voters'

### 4. Configuration
Update `lib/utils/constants.dart` with your API keys:

```dart
class Constants {
  static const String supabaseUrl = 'your_supabase_url';
  static const String supabaseAnonKey = 'your_supabase_anon_key';
  static const String faceApiKey = 'your_face_api_key';
  static const String faceApiEndpoint = 'your_face_api_endpoint';
}
```

### 5. Install Dependencies
```bash
flutter pub get
```

### 6. Run the App
```bash
flutter run
```

## Database Schema

The app uses the following tables:
- `profiles`: User profiles with approval status
- `polls`: Poll information with dates and privacy settings
- `candidates`: Poll candidates
- `votes`: User votes with timestamps
- `invited_users`: Users invited to private polls

## Face Recognition Flow

1. User registers and uploads a photo
2. System creates a person in Microsoft Face API person group
3. When voting, user takes a photo
4. System verifies the face matches the registered user
5. Vote is cast only if verification succeeds

## Security Features

- Row Level Security (RLS) policies in Supabase
- Face recognition for vote authentication
- Private polls with security codes
- User approval system
- Biometric app unlock

## Technologies Used

- Flutter
- Supabase (PostgreSQL, Auth, RLS)
- Microsoft Azure Face API
- Local Authentication (biometrics)
- Camera package

## Project Structure

```
lib/
├── models/          # Data models
├── providers/       # State management
├── screens/         # UI screens
│   ├── admin/       # Admin screens
│   ├── auth/        # Authentication screens
│   └── user/        # User screens
├── services/        # API services
└── utils/           # Constants and utilities
```

## License

This project is for educational purposes.
