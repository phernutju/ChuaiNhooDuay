# ChuaiNhooDuay

A disaster-response mobile app connecting requester in need with nearby volunteers — real-time, location-aware, role-based.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Test Accounts (Locked Phone Numbers)](#test-accounts-locked-phone-numbers)
- [Setup](#setup)
- [Project Structure](#project-structure)
- [Data Models & Firestore Schema](#data-models--firestore-schema)
- [Navigation Flow](#navigation-flow)
- [Tech Stack](#tech-stack)

---

## Overview

ChuaiNhooDuay supports two user roles:

| Role | Description |
|------|-------------|
| **Requester** | Post help requests (medical, shelter, rescue, etc.) and track volunteer responses |
| **Volunteer** | Browse nearby requests, join them, and check in on-site |

Built with Flutter + Firebase. Targets Bangkok and Samut Prakan service area.

---

## Features

### Authentication
- Phone-based login via Firebase SMS OTP
- Thai number formatting (+66 prefix auto-handled)
- PIN / biometric app lock (per-device, stored securely)
- Role selection on first login (Civilian or Volunteer)

### Requester
- Post help requests across 8 categories: Medical, Shelter, Water, Transport, Rescue, Evacuate, Supplies, Other
- Set urgency level: **Critical**, **Urgent**, **General**
- Auto-fetch or manually enter GPS location
- Track request status: `waiting → assigned → matched → completed`
- View volunteer names and response count
- Receive notifications when a volunteer joins your request

### Volunteer
- Real-time feed of open requests sorted by urgency
- Google Maps view with radius filter for nearby requests
- Join requests and track active assignments
- Check-in validation (must be within 100m of request location)
- Receive notifications for new nearby requests
- Role switching (can switch to requester and back)
- Chat

### Notifications
- **Requester notifications** — volunteer joined your request
- **Volunteer notifications** — new request in your area
- **Global notifications** — broadcast alerts, evacuation notices

### App Security
- PIN lock screen on app resume
- Biometric unlock (fingerprint / Face ID)
- Secure token storage via `flutter_secure_storage`
- Anonymous request posting option

---

## Test Accounts (Locked Phone Numbers)

These phone numbers are pre-authorized in Firebase for testing — OTP verification is bypassed or auto-filled in test environments.

| Phone Number | Use |
|---|---|
| +66670000000 | Test account 1 |
| +66440000000 | Test account 2 |
| +66200000000 | Test account 3 |
| +66400000000 | Test account 4 |
| +66500000000 | Test account 5 |
| +66600000000 | Test account 6 |
| +66700000000 | Test account 7 |
| +66900000000 | Test account 8 |
| +66800000000 | Test account 9 |

Otp: 123456

> **Note:** These numbers are locked to the Firebase project for SMS verification testing. Use OTP code `123456` unless the Firebase console shows a different test code.

---

## Setup

### Prerequisites

- Flutter SDK `>=3.x`
- Dart SDK `>=3.x`
- Firebase project with **Authentication** (Phone) and **Firestore** enabled
- Google Maps API key (Android + iOS)
- A connected device or emulator

### 1. Clone the repo

```bash
git clone https://github.com/your-org/ChuaiNhooDuay.git
cd ChuaiNhooDuay
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure environment variables

Create a `.env` file in the project root:

```env
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
```

### 4. Firebase setup

1. Go to [Firebase Console](https://console.firebase.google.com) and create a project
2. Enable **Phone Authentication** under Authentication → Sign-in methods
3. Add test phone numbers under Authentication → Sign-in methods → Phone → Test phone numbers (see table above, OTP: `123456`)
4. Enable **Cloud Firestore** in production or test mode
5. Download config files:
   - Android: place `google-services.json` in `android/app/`
   - iOS: place `GoogleService-Info.plist` in `ios/Runner/`

### 5. Google Maps API key

**Web** — create a `.env` file in the project root:

```
MAPS_API_KEY=your_google_maps_api_key_here
```

**Android** — add the same key to `android/local.properties`:

```
MAPS_API_KEY=your_google_maps_api_key_here
```

Use the exact name `MAPS_API_KEY`. After editing, run `flutter run` again (full restart, not hot reload).
### 6. Run the app

```bash
flutter run                # default device
flutter run -d chrome      # web
flutter run -d emulator-1  # specific emulator
```

### Other useful commands

```bash
flutter test               # run all tests
flutter analyze            # static analysis
flutter build apk          # build Android APK
flutter build ios          # build iOS
```

---

## Project Structure

```
lib/
├── main.dart               # App entry, Firebase init, providers
├── models/                 # Firestore data models
│   ├── user_model.dart
│   ├── request_model.dart
│   ├── message_model.dart
│   ├── civilian_notification_model.dart
│   ├── volunteer_notification_model.dart
│   └── global_notification_model.dart
├── features/               # Feature-based UI modules
│   ├── auth/               # Phone, OTP, Name, Role screens
│   ├── volunteer/          # Feed, Map, Active, Profile tabs
│   ├── requester/          # Home, New Request, Confirmation screens
│   ├── notifications/      # Notification page
│   └── app_lock/           # PIN setup, Lock, Change PIN screens
├── services/               # Firestore / API services
├── providers/              # State management (Riverpod + Provider)
├── router/                 # Go Router configuration
├── constants/              # App-wide constants
└── utils/                  # Utility functions (time formatting, etc.)
```

---

## Data Models & Firestore Schema

```
firestore
├── users/{uid}
│   └── name, phone, role, bio, age, createdAt, updatedAt
│
├── requests/{requestId}
│   ├── createdBy, title, description
│   ├── location { address, coordinates (GeoPoint) }
│   ├── request_type, urgency_level, urgency_score
│   ├── max_volunteer, assignedVolunteerIds[], assignedVolunteerNames[]
│   ├── status, is_anonymous, requesterName
│   ├── volunteerJoinedAt { volunteerId: timestamp }
│   ├── checkedInAt, createdAt, updatedAt
│   │
│   └── messages/{messageId}
│       └── senderId, text, type, seenCount, seenBy[], createdAt
│
├── civilianNotifications/{id}
│   └── userId, requestId, volunteerIds[], title, detail, isRead, priority, expiration
│
├── volunteerNotifications/{id}
│   └── userId, requestId, title, detail, isRead, priority, expiration
│
└── globalNotifications/{id}
    └── userId, volunteerId, requestId, type, title, detail, metadata, isRead, priority, expiration
```

**Request status flow:**
```
waiting → assigned → matched → completed
```

**Urgency levels** (stored as snake_case in Firestore):
```
critical > urgent > general
```

---

## Navigation Flow

```
App Start
│
├── Not authenticated → PhoneScreen → OtpScreen
│                                         │
│                              ┌──────────┴──────────┐
│                         New user              Returning user
│                              │                      │
│                         NameScreen              HomeScreen
│                              │
│                         RoleScreen
│                              │
│                         HomeScreen
│
HomeScreen (role gate)
├── Volunteer → VolunteerShell
│   ├── Tab 0: Feed (browse requests)
│   ├── Tab 1: Map (nearby requests on Google Maps)
│   ├── Tab 2: Active (joined requests + check-in)
│   └── Tab 3: Profile (settings, role switch, sign out)
│
└── Civilian → RequesterHomeScreen
    ├── Post new request → NewRequestScreen → PostConfirmationScreen
    ├── View request detail → RequestDetailScreen
    └── Notifications → NotificationPage
```

> App Lock gate — on resume, if PIN is set, LockScreen shows before HomeScreen.

---

## Tech Stack

| Package | Purpose |
|---------|---------|
| `firebase_auth` | Phone SMS authentication |
| `cloud_firestore` | Real-time database |
| `firebase_storage` | Image uploads |
| `flutter_riverpod` + `provider` | State management |
| `go_router` | Navigation & deep-linking |
| `google_maps_flutter` | Map view |
| `geolocator` | GPS location |
| `local_auth` | Biometric / PIN unlock |
| `flutter_secure_storage` | Secure local storage |
| `google_fonts` | Poppins typography |
| `flutter_dotenv` | Environment variables |
| `image_picker` | Photo selection |
| `cached_network_image` | Image caching |

---

## License

Internal project — King Mongkut's University of Technology Thonburi (KMUTT).
