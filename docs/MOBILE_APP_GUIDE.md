# Mobile App Guide

This document defines standards for the Flutter mobile application.

## Current Implementation

The current app is a backend-connected Flutter MVP:

- `lib/main.dart` runs `GamelanApp`.
- `lib/app.dart` configures a Material 3 `MaterialApp`, restores the saved
  authentication token from secure storage, loads `/me`, and gates the
  bottom-navigation shell behind `LoginScreen`.
- Authenticated sessions open `GamelanHomeShell` with Home, Search, Contribute,
  Review, and Profile tabs.
- Feature folders exist for `auth`, `contributions`, `knowledge`, `review`, and `admin`.
- `GamelanMvpStore` and `GamelanScope` provide UI-facing state over repository
  interfaces.
- Production wiring uses `RemoteContributionRepository`,
  `RemoteReviewRepository`, and `RemoteKnowledgeRepository` against the Laravel
  API configured by `API_BASE_URL`.
- `LocalContributionRepository`, `LocalReviewRepository`, and
  `LocalKnowledgeRepository` remain for deterministic offline widget and unit
  tests through `GamelanMvpStore.local()`.
- Contribution drafts, submissions, review queue items, and review decisions
  are persisted by the backend in production wiring. The mobile app does not
  keep API drafts in `shared_preferences`.
- Search uses `GET /search` with optional taxonomy filters. Published browse
  data uses `GET /knowledge-items`.
- Contribution forms apply mobile UX validation, send API slug values for
  knowledge and gamelan types, and surface backend `422`/`409` responses.
- Editable contribution detail screens support media attachment and removal
  through the Laravel media API. The upload form captures file, consent,
  visibility, cultural sensitivity, and descriptive metadata.
- Review screens call backend review endpoints and render action groups from
  API `allowed_actions` when present. Standard approve/reject/request-change
  actions open the existing review decision screen, while expert workflow
  actions open dedicated dialogs for `markExpertRequired` and
  `expertValidate`.
- `RemoteReviewRepository` exposes expert-workflow methods for
  `markExpertRequired` and `expertValidate`, matching the backend contract for
  curator and expert flows.
- Contribution and review detail screens now open a dedicated, read-only
  provenance timeline route. The screen merges contribution versions and safe
  provenance events from backend trace endpoints, and it hides actor identity
  when the API withholds that field.
- Review detail screens display `triage_suggestion` only when the backend
  includes it. The UI labels it `AI suggestion, not validated.` and keeps it
  subordinate to human review actions.
- Status badges reuse a shared presentation component so `expert_required`
  and `expert_approved` are visually distinct from curator states across
  contribution and review lists.
- Contributor-facing contribution detail screens do not render reviewer notes
  or private expert notes. Private note entry is limited to the expert
  validation dialog.
- Review and knowledge detail screens render safe read-only media metadata when
  the API includes `media_assets`.
- `AuthRepository` performs real JSON registration, login, logout, and `/me`
  profile requests against the configured Laravel API base URL.
- `TokenStorage` stores the access token through `flutter_secure_storage`.
- Expired or invalid saved tokens are cleared when `/me` returns
  unauthenticated.
- The Review tab is hidden behind backend profile roles for reviewer, curator,
  expert validator, or admin users. This is only UX gating; backend policies
  remain authoritative. Within the review surface itself, individual buttons
  are still driven by backend `allowed_actions`.
- `test/remote_repository_test.dart` covers mocked API parsing and error
  handling. Widget tests inject local repositories for offline flows.
- An opt-in live Laravel-backed integration test at
  `integration_test/live_laravel_backend_test.dart` exercises the
  authentication flow and verifies that `GET /me` returns backend `roles` and
  `permissions`.
- A separate opt-in live reviewer workflow test at
  `integration_test/review_workflow_test.dart` covers queue navigation, review
  detail navigation, provenance timeline display, expert escalation, and
  expert validation when reviewer credentials and a target review UUID are
  supplied.
- Curator-facing RDF publication UI, semantic-search fallback UI, SPARQL proxy
  UI, encrypted sensitive draft storage, offline media upload queues, richer
  stale-update conflict resolution UI, and full offline sync remain target
  architecture for the mobile client.
- Admin screens remain scaffold-level placeholders.

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
- `file_picker` for media file selection

Current testing:

- `flutter test` runs deterministic local and mocked-auth widget tests.
- `integration_test/live_laravel_backend_test.dart` provides opt-in live
  Laravel authentication coverage when `GAMELAN_TEST_API_BASE_URL`,
  `GAMELAN_TEST_EMAIL`, and `GAMELAN_TEST_PASSWORD` are supplied with
  `--dart-define`.
- `integration_test/review_workflow_test.dart` provides opt-in live reviewer
  workflow coverage when `GAMELAN_TEST_API_BASE_URL`,
  `GAMELAN_TEST_REVIEW_EMAIL`, `GAMELAN_TEST_REVIEW_PASSWORD`, and
  `GAMELAN_TEST_REVIEW_UUID` are supplied with `--dart-define`.
- `test_driver/integration_test.dart` provides the `integrationDriver()`
  entrypoint required to run the live Laravel integration target on Chrome web
  with `flutter drive`.
- Live auth smoke coverage currently verifies login, `/me` profile loading,
  in-memory test token storage, and logout only.
- Live reviewer workflow coverage verifies queue navigation, provenance
  timeline display, expert-required escalation, expert validation, and status
  transitions.

Chrome web live integration tests should be run with `flutter drive`:

```sh
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/live_laravel_backend_test.dart \
  -d chrome \
  --dart-define=GAMELAN_TEST_API_BASE_URL=https://127.0.0.1:8000/api/v1 \
  --dart-define=GAMELAN_TEST_EMAIL=test@example.com \
  --dart-define=GAMELAN_TEST_PASSWORD=secret
```

Run the live reviewer workflow integration target with:

```sh
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/review_workflow_test.dart \
  -d chrome \
  --dart-define=GAMELAN_TEST_API_BASE_URL=https://127.0.0.1:8000/api/v1 \
  --dart-define=GAMELAN_TEST_REVIEW_EMAIL=reviewer@example.com \
  --dart-define=GAMELAN_TEST_REVIEW_PASSWORD=secret \
  --dart-define=GAMELAN_TEST_REVIEW_UUID=00000000-0000-0000-0000-000000000000
```

Use local shell values or CI secrets for the `GAMELAN_TEST_*` values. Do not
store live backend credentials in the repository. `flutter test
integration_test/live_laravel_backend_test.dart` and `flutter test
integration_test/review_workflow_test.dart` remain useful for non-Chrome/local
integration execution where supported.

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

Current production state flow:

```txt
Screens
  ↓
GamelanScope / GamelanMvpStore
  ↓
ContributionRepository / ReviewRepository / KnowledgeRepository
  ↓
Remote Laravel API repositories (ApiClient + bearer token)
```

Local repository implementations remain available for tests and offline demo
flows, but they are not used by default production wiring.

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

## Mobile MVP Progress

Implemented in the current mobile client:

- backend auth/session restore with secure token storage
- API-backed contribution drafts, submission, status display, and online media
  attachment/removal
- backend-driven review and expert actions through `allowed_actions`
- safe read-only provenance timelines and review-only AI triage summaries
- public browse and keyword search through backend APIs
- ontology and RDF publication DTO/repository contracts
- deterministic Flutter tests plus opt-in live backend integration targets

Partially implemented:

- ontology mapping and RDF publication are available at repository/DTO level,
  but there is no curator-facing publication UI.

Not implemented:

- semantic-search fallback UI, full offline sync, offline media queues,
  encrypted sensitive draft cache, richer `409` conflict resolution UI,
  production admin screens, and SUS/task evaluation execution.

## Contribution Form Requirements

The current mobile contribution form supports:

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

Target future additions include related entity selection and richer
backend-backed validation.
Current media attachment is available from editable contribution detail screens
after a draft exists.

## Status Display

Current Dart contribution statuses:

```txt
draft
submitted
needsRevision
underReview
curatorApproved
expertRequired
expertApproved
published
rejected
archived
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

- Production contribution drafts are API-backed; local draft persistence is
  limited to deterministic test repositories.
- Plain local storage must not be used for culturally sensitive drafts.
- Full offline sync, offline media queues, and encrypted sensitive draft caches
  are not implemented.

## API Error Handling

Current production repositories use real HTTP requests for authentication,
contributions, review, media, public knowledge browsing/search, provenance,
ontology collections, and RDF publication queueing contracts. API-backed
mobile code must handle:

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

SPARQL-backed semantic search is a target capability. The current app
implements backend keyword search over published, non-sensitive knowledge and
uses test-only seeded knowledge in local repository fixtures.

Current mobile search supports:

- keyword search through the backend `/search` route
- filter by gamelan type
- filter by knowledge type
- detail view with relations, source summary, and provenance summary
- provenance timeline route for safe version and provenance history

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

- the Review tab only shows the local queue when the `/me` profile includes a
  reviewer, curator, expert validator, or admin role, or a
  `review.contributions` permission
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
- review-only AI triage summary
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
