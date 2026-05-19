# Mobile App Guide

This document defines standards for the Flutter mobile application.

## Mobile Stack

Recommended:

- Flutter
- Dart
- Riverpod, Bloc, or Provider for state management
- Dio or http for API requests
- Hive, Isar, Drift, or SQLite for offline draft storage
- Secure storage for authentication token

Do not mix multiple state management systems without a clear reason.

## App Modules

Recommended structure:

```txt
lib/
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme.dart
├── core/
│   ├── api/
│   ├── auth/
│   ├── errors/
│   ├── storage/
│   └── utils/
├── features/
│   ├── auth/
│   ├── home/
│   ├── knowledge/
│   ├── search/
│   ├── contribution/
│   ├── review/
│   ├── profile/
│   └── settings/
└── shared/
    ├── widgets/
    ├── models/
    └── constants/
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

Contributors should see contribution status:

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

The mobile app should support local drafts.

Rules:

1. Drafts may be saved offline.
2. Drafts must show sync status.
3. Media uploads may wait until connection is available.
4. Backend remains the source of truth after sync.
5. Conflicts must be shown clearly.

## API Error Handling

Mobile app must handle:

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

The search interface should support:

- keyword search
- semantic search suggestions
- filter by gamelan type
- filter by instrument
- filter by ensemble
- filter by place/region
- filter by media type
- recent searches

## Review UI

Curator/expert screens should show:

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

The mobile app should support at least:

- Indonesian
- English

Balinese terms should preserve original cultural terminology, with definitions and translations as supporting metadata rather than forced replacement.
