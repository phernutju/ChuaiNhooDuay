# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get          # install dependencies
flutter run              # run on connected device/simulator
flutter run -d chrome    # run on web
flutter test             # run all tests
flutter test test/widget_test.dart  # run single test file
flutter analyze          # static analysis (dart analyze)
flutter build apk        # build Android
flutter build ios        # build iOS
```

## Architecture

Disaster-response app connecting **civilians** (create help requests) with **volunteers** (accept and fulfill requests). Two user roles: `UserRole.civilian` and `UserRole.volunteer`.

### Backend: Cloud Firestore

All data lives in Firestore. Models live in `lib/models/` and each implements `fromFirestore(DocumentSnapshot)` + `toFirestore()` + `copyWith()`.

**Firestore collections:**
- `users` — `UserModel` (civilian or volunteer, phone-based identity)
- `requests` — `RequestModel` (help requests with geo location, urgency, volunteer cap)
- `requests/{id}/messages` — `MessageModel` subcollection (in-request chat)
- `civilianNotifications` — `CivilianNotificationModel` (notified when volunteer accepts)
- `volunteerNotifications` — `VolunteerNotificationModel` (notified when nearby request created)
- `globalNotifications` — `GlobalNotificationModel` (broadcast alerts, evacuations)

**Key domain concepts:**
- `RequestModel.urgencyScore` — numeric score used for prioritization alongside `UrgencyLevel` enum (`critical > urgent > general`)
- `RequestModel.isFull` — computed bool, true when `assignedVolunteerIds.length >= maxVolunteer`
- `RequestStatus`: `open → assigned → closed`
- `MessageModel.markSeenUpdate()` — static helper returning Firestore update map using `arrayUnion` + `increment` to avoid race conditions on seen tracking
- Enum values stored in Firestore as snake_case strings (e.g. `request_type`, `urgency_level`) — note the inconsistency: `UserModel` stores `role` as camelCase `.name`

### Planned lib/ structure (mostly empty stubs)

```
lib/
  models/       # Firestore data models (only populated layer so far)
  features/     # Feature-based UI modules (empty)
  services/     # Firestore/API service layer (empty)
  providers/    # State management providers (empty)
  data/         # Repository layer (empty)
  router/       # App routing (empty)
  constants/    # App-wide constants (empty)
  utils/        # Utility functions (empty)
  mock/         # Mock data for development (empty)
```

State management and routing packages have not been added to `pubspec.yaml` yet — check before implementing features.
