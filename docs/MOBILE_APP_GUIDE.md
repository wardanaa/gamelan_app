# Mobile App Guide

This document defines standards for the Flutter mobile application.

## Current Implementation

The current app is a local Flutter MVP:

- `lib/main.dart` runs `GamelanApp`.
- `lib/app.dart` configures a Material 3 `MaterialApp`, restores the saved
  authentication token from secure storage, and gates the bottom-navigation
  shell behind `LoginScreen`.
- Authenticated sessions open `GamelanHomeShell` with Home, Search, Contribute,
  Review, and Profile tabs.
- Feature folders exist for `auth`, `contributions`, `knowledge`, `review`, and `admin`.
- `GamelanMvpStore` and `GamelanScope` provide local MVP state.
- Non-sensitive contribution drafts are persisted locally with
  `shared_preferences`.
- Search uses seeded Gong Kebyar and Gong Gede knowledge plus approved local
  contributions.
- Contribution list, detail, form, and status screens are implemented for local
  data and non-sensitive draft persistence.
- Review queue, detail, and decision screens are implemented for local curator
  simulation.
- `AuthRepository` performs real JSON login/logout requests against the
  configured Laravel API base URL.
- `TokenStorage` stores the access token through `flutter_secure_storage`.
- `ContributionRepository` and `ReviewRepository` remain placeholders and do
  not perform real network requests.
- Culturally sensitive drafts, submitted items, review decisions, and approved
  demo knowledge remain session-only.
- Admin screens and registration remain scaffold-level placeholders.

Do not document a mobile capability as implemented unless it is backed by code
in `lib/`.

## Mobile Stack

Current:

- Flutter
- Dart
- Material 3
- Flutter test
- `http` for current authentication API requests
- `flutter_secure_storage` for access-token storage

Target additions when needed:

- Riverpod, Bloc, or Provider for state management
- Dio or http for API requests
- Hive, Isar, Drift, or SQLite for richer offline draft storage
- Encrypted storage for culturally sensitive drafts if product rules allow it

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
│   ├── state/
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

The current local MVP contribution form supports:

- Title
- Description
- Knowledge type
- Related gamelan type
- Source note
- Contributor note
- Consent checkbox
- Cultural sensitivity flag
- Save as draft
- Submit for review

Target future additions include related entity selection, media attachments, and
backend-backed validation.

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

Basic offline draft persistence is partially implemented. The current app stores
only the contributor's own non-sensitive local drafts with `shared_preferences`.
It does not persist culturally sensitive drafts, submitted contributions, review
decisions, media, or approved demo knowledge across app restarts, and it does
not sync with a backend.

Rules:

1. Drafts may be saved offline.
2. Drafts must show sync status.
3. Media uploads may wait until connection is available.
4. Backend remains the source of truth after sync.
5. Conflicts must be shown clearly.

Current MVP limits:

- Only non-sensitive `draft` contributions are cached locally.
- Plain local storage must not be used for culturally sensitive drafts.
- Submitted and reviewed local contributions remain session-only until backend
  persistence and sync are implemented.

## API Error Handling

Current authentication uses real HTTP requests for login and logout. Other
repositories do not make real HTTP requests yet. API-backed mobile code must
handle:

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

SPARQL-backed semantic search is a target capability. The current app implements
local keyword search over seeded knowledge and approved local contributions.

Current local search supports:

- keyword search over title, description, and relation labels
- filter by gamelan type
- filter by knowledge type
- detail view with relations, source summary, and provenance summary

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

Current review screens support a local curator simulation:

- submitted and under-review contributions appear in the review queue
- reviewer can mark an item under review
- reviewer can approve, request changes, or reject with a note
- approved contributions appear in local Search as community approved demo
  content
- request-changes and rejected contributions do not appear in public browsing

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
