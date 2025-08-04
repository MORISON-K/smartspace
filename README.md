# SmartSpace - Real Estate Mobile Application

A comprehensive Flutter-based real estate application with AI-powered land valuation, multi-role user management, and Firebase backend integration.

## Contributors

| Name                  | RegNo          | StudentNo  |  Github Username     |
| --------------------- | -------------- | ---------- | -------------------- |
| Abinsinguza Morison K | 24/U/02594/PS  | 2400702594 | MORISON-K            |
| Serena Robinah        | 24/U/22603/PS  | 2400703053 | Serena-Robinah       |
| Akadwanaho Jonan      | 24/U/03053/PS  | 2400711034 | RWANGOGA             |
| Lunkuse Dorcus        | 24/U/06515/PS  | 2400706515 | Dorcus-jane          |      
| Elijah Biar Mabior    | 24/E/21430/PS  | 2400721430 | biar211              |


## 🏠 Overview

SmartSpace is a modern real estate platform that connects buyers, sellers, and administrators through an intuitive mobile interface. The application features AI-powered land valuation using machine learning, real-time notifications, and comprehensive property management capabilities.

## ✨ Key Features

### For Sellers

- **AI-Powered Land Valuation**: Get accurate property value predictions using machine learning
- **Easy Listing Creation**: Upload property details with images and documents
- **Activity Tracking**: Monitor listing performance and engagement
- **Media Management**: Upload multiple images and PDF documents

### For Buyers

- **Property Search & Filter**: Find properties based on location, price, and preferences
- **Interactive Maps**: View properties on Google Maps with precise locations
- **Favorites Management**: Save and organize preferred properties
- **Real-time Notifications**: Get notified about new listings and updates

### For Administrators

- **User Management**: Oversee all users and their roles
- **Listing Approval**: Review and approve property listings
- **Analytics Dashboard**: Monitor platform activity and statistics
- **Notification Management**: Send targeted notifications to users

## 🏗️ Architecture

### System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    CLIENT LAYER (Flutter Mobile App)           │
├─────────────────────────────────────────────────────────────────┤
│  Admin Module     │  Buyer Module      │  Seller Module        │
│  - Dashboard      │  - Home/Browse     │  - Add Listings       │
│  - User Mgmt      │  - Search/Filter   │  - AI Valuation       │
│  - Approvals      │  - Favorites       │  - Activity Tracking  │
│  - Settings       │  - Notifications   │  - Media Upload       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   FIREBASE BACKEND SERVICES                    │
├─────────────────────────────────────────────────────────────────┤
│  Firebase Auth    │  Firestore DB     │  Firebase Storage     │
│  Cloud Functions  │  Firebase Messaging│  External APIs        │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│             EXTERNAL ML SERVICE (Django REST API)              │
│                   Land Valuation Predictions                   │
└─────────────────────────────────────────────────────────────────┘
```

### Technology Stack

**Frontend (Flutter)**

- Flutter SDK ^3.7.2
- Firebase Integration (Auth, Firestore, Storage, Messaging)
- Google Maps & Geocoding
- Image & File Picking
- PDF Viewing (Syncfusion)

**Backend Services**

- Firebase Authentication (Role-based access)
- Cloud Firestore (NoSQL Database)
- Firebase Storage (Media files)
- Firebase Cloud Messaging (Push notifications)

**External Services**

- Django REST Framework (ML API)
- Google Maps API
- Random Forest ML Model for land valuation

## 📱 App Structure

```
lib/
├── main.dart                    # App entry point
├── firebase_options.dart        # Firebase configuration
├── admin/                       # Admin module
│   ├── screens/                 # Admin screens
│   └── widgets/                 # Admin-specific widgets
├── auth/                        # Authentication screens
├── buyer/                       # Buyer module
│   ├── buyer_home_screen.dart   # Main buyer interface
│   ├── search_screen.dart       # Property search
│   └── favorite_screen.dart     # Saved properties
├── seller/                      # Seller module
│   ├── add_listing_screen.dart  # Create new listings
│   ├── ai-valuation/           # ML integration
│   ├── widgets/                # Seller widgets
│   └── recent-activity/        # Activity tracking
└── notifications/              # Notification system
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (^3.7.2)
- Android Studio / VS Code
- Firebase account
- Google Maps API key

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/MORISON-K/smartspace.git
   cd smartspace
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Firebase Setup**

   - Create a new Firebase project
   - Add Android/iOS apps to your Firebase project
   - Download and place `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Enable Authentication, Firestore, Storage, and Cloud Messaging

4. **Configure Google Maps**

   - Get Google Maps API key
   - Add to `android/app/src/main/AndroidManifest.xml`
   - Add to `ios/Runner/AppDelegate.swift`

5. **Run the application**
   ```bash
   flutter run
   ```

### Environment Setup

1. **Firebase Configuration**

   ```bash
   # Install Firebase CLI
   npm install -g firebase-tools

   # Login to Firebase
   firebase login

   # Initialize Firebase in your project
   firebase init
   ```

2. **ML API Setup**
   - Deploy the Django ML service
   - Update API endpoints in the Flutter app
   - Configure CORS for cross-origin requests

## 📦 Dependencies

### Core Dependencies

- `firebase_core: ^3.14.0` - Firebase core functionality
- `firebase_auth: ^5.6.0` - Authentication
- `cloud_firestore: ^5.6.9` - Database
- `firebase_storage: ^12.4.7` - File storage
- `firebase_messaging: ^15.2.9` - Push notifications

### UI & Media

- `google_maps_flutter: ^2.12.3` - Maps integration
- `image_picker: ^1.1.2` - Image selection
- `file_picker: ^10.2.0` - File selection
- `syncfusion_flutter_pdfviewer: ^30.1.39` - PDF viewing

### Location & Networking

- `geocoding: ^4.0.0` - Address to coordinates
- `geolocator: ^14.0.2` - Location services
- `http: ^1.4.0` - HTTP requests
- `permission_handler: ^12.0.1` - App permissions

## 🔧 Configuration

### Firebase Security Rules

**Firestore Rules Example:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Listings are publicly readable, but only owners can write
    match /listings/{listingId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### ML API Integration

The app integrates with a Django REST API for land valuation:

```dart
// Example API call
final response = await http.post(
  Uri.parse('https://smartspace-e7e32524ddcb.herokuapp.com/api/predict/'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'tenure': tenure,
    'location': location,
    'use': landUse,
    'plotSize': plotSize,
  }),
);
```

## 👥 User Roles

### Admin

- Full system access
- User management
- Listing approval workflow
- Analytics and reporting

### Seller

- Create and manage listings
- Access AI valuation tools
- Upload property media
- Track listing activity

### Buyer

- Browse and search properties
- Save favorite listings
- Contact sellers
- Receive notifications

## 🔐 Security Features

- Firebase Authentication with role-based access
- Secure file upload with validation
- Input sanitization and validation
- Firestore security rules
- API endpoint protection

## 📊 Features in Detail

### AI Land Valuation

- Machine learning model integration
- Considers location, size, tenure, and land use
- Real-time price predictions
- Historical data analysis

### Real-time Notifications

- Firebase Cloud Messaging integration
- Role-based notification targeting
- Push notifications for listing updates
- In-app notification center

### Media Management

- Multiple image uploads
- PDF document support
- Firebase Storage integration
- Optimized image handling

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For support and questions, please contact:

- Repository: [MORISON-K/smartspace](https://github.com/MORISON-K/smartspace)
- Issues: [GitHub Issues](https://github.com/MORISON-K/smartspace/issues)
