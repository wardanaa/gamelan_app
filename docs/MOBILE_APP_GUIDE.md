# Mobile App Guide

This document defines standards for the Flutter mobile application.

## Current Implementation

The current app is a lightweight Flutter scaffold:

- `lib/main.dart` runs `GamelanApp`.
- `lib/app.dart` configures a Material 3 `MaterialApp`.
- The app currently opens `ContributionListScreen`.
- Feature folders exist for `auth`, `contributions`, `knowledge`, `review`, and `admin`.
- Most screens are placeholders with an app bar and centered text.
- `ContributionModel` and `ReviewModel` define minimal data shapes.
- `ContributionRepository`, `ReviewRepository`, and `AuthRepository` are placeholders.
- `TokenStorage` stores a token in memory only and is not production-ready.

Do not document a mobile capability as implemented unless it is backed by code
in `lib/`.

## Mobile Stack

Current:

- Flutter
- Dart
- Material 3
- Flutter test

Target additions when needed:

- Riverpod, Bloc, or Provider for state management
- Dio or http for API requests
- Hive, Isar, Drift, or SQLite for offline draft storage
- Secure storage for authentication token

Do not mix multiple state management systems without a clear reason.

## App Modules

Current structure:

```txt
lib/
├── app.dart
├── main.dart
├── core/
│   ├── api/
│   ├── constants/
│   ├── storage/
│   └── utils/
├── features/
│   ├── admin/
│   ├── auth/
│   ├── contributions/
│   ├── knowledge/
│   ├── review/
└── ...
```

Target structure may add routing, theme extraction, shared widgets, profile,
settings, search, and dedicated state-management layers when the app grows.

```txt
lib/
├── app.dart
├── main.dart
├── router.dart
├── theme.dart
├── core/
├── features/
└── shared/
```

## Contribution Form Requirements

The contribution form should support:

- Title
- Description
- Knowledge type
- Related gamelan type
- Related instrument/ensemble/composition/person/place
- Source note
- Contributor note
- Media attachments
- Consent checkbox
- Cultural sensitivity flag
- Save as draft
- Submit for review

## Status Display

Current Dart contribution statuses:

```txt
draft
submitted
underReview
approved
rejected
```

Target backend workflow statuses:

```txt
draft
submitted
needs_revision
under_review
curator_approved
expert_required
expert_approved
published
rejected
archived
```

## Offline Draft

Offline draft support is a target capability. The current app does not persist
drafts locally.

Rules:

1. Drafts may be saved offline.
2. Drafts must show sync status.
3. Media uploads may wait until connection is available.
4. Backend remains the source of truth after sync.
5. Conflicts must be shown clearly.

## API Error Handling

Current repositories do not make real HTTP requests. Once API calls are
implemented, the mobile app must handle:

- 401 unauthenticated
- 403 unauthorized
- 404 not found
- 422 validation error
- 429 rate limited
- 500 server error
- network timeout
- offline state

Do not show raw backend stack traces.

## Search UI

Semantic search is a target capability. The current app only has placeholder
knowledge entity list and detail screens.

The target search interface should support:

- keyword search
- semantic search suggestions
- filter by gamelan type
- filter by instrument
- filter by ensemble
- filter by place/region
- filter by media type
- recent searches

## Review UI

Current review screens are placeholders for review queue, detail, and decision.

Target curator/expert screens should show:

- submitted content
- contributor identity if permitted
- source note
- media assets
- AI triage suggestion
- duplicate candidates
- ontology mapping suggestion
- review history
- approve/reject/revision actions
- validation notes

## Localization

Localization is a target capability. The current app uses hard-coded English UI
strings.

The target mobile app should support at least:

- Indonesian
- English

Balinese terms should preserve original cultural terminology, with definitions and translations as supporting metadata rather than forced replacement.
