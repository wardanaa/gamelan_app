# Evaluation and QA Guide

This document defines software, ontology, and research evaluation rules.

## Current Implementation

The current default test suite contains deterministic Flutter widget tests for
the local MVP, mocked authentication HTTP responses, and focused repository
tests for local contribution, review, draft persistence, and knowledge-search
behavior. Backend persistence, ontology, SPARQL, offline sync, media, and AI
triage tests are not applicable until those capabilities are implemented.

An opt-in live Laravel-backed integration test exists at:

```txt
integration_test/live_laravel_backend_test.dart
```

It is skipped unless `GAMELAN_TEST_API_BASE_URL`, `GAMELAN_TEST_EMAIL`, and
`GAMELAN_TEST_PASSWORD` are supplied with `--dart-define`. The live test covers
only login, `/me` profile loading, token storage through the test-only
in-memory backend, and logout against the configured Laravel API.

Chrome web execution uses the Flutter integration driver at:

```txt
test_driver/integration_test.dart
```

Run the live Laravel authentication smoke test on Chrome with:

```sh
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/live_laravel_backend_test.dart \
  -d chrome \
  --dart-define=GAMELAN_TEST_API_BASE_URL=https://127.0.0.1:8000/api/v1 \
  --dart-define=GAMELAN_TEST_EMAIL=test@example.com \
  --dart-define=GAMELAN_TEST_PASSWORD=secret
```

The same test target may still be run with `flutter test
integration_test/live_laravel_backend_test.dart` for non-Chrome/local
integration execution where supported. Live credentials must come from local
command-line values or CI secrets and must not be stored in repository files.
The test must not print backend tokens.

## Evaluation Dimensions

The project should be evaluated across:

1. Functional correctness
2. Usability
3. Ontology quality
4. SPARQL competency question coverage
5. Curation workflow reliability
6. Security and privacy
7. Performance

## Functional Testing

Test scenarios:

- user registration
- token-based login/logout
- current-user retrieval
- unauthenticated API access
- browse knowledge items
- semantic search
- create draft
- submit contribution
- upload media
- curator review
- request revision
- expert validation
- publish to RDF
- query published knowledge
- reject contribution
- idempotent retry of contribution submission
- idempotent retry of media upload and removal
- conflict handling for stale contribution updates

Current schema foundation tests cover:

- domain table creation
- role seeding without cultural knowledge seed data
- contribution, review, media, provenance, RDF publication, and idempotency relationships
- default workflow status, UUID assignment, JSON casts, boolean casts, and date/time casts

Workflow endpoint tests now cover contribution submission, review queue visibility, peer-review recommendation boundaries, curator approval/rejection, expert-required routing, expert validation, self-review blocking, private-note privacy, safe provenance/version timeline access, review provenance/audit records, contribution lifecycle audit records, idempotent trace behavior, stale contribution update conflicts, consent-aware media upload/removal, RDF publication queue/job behavior, published knowledge browsing, keyword search, semantic search fallback behavior, protected predefined SPARQL proxy filtering, and the critical contribution-to-publication flow.

## Ontology Evaluation

Ontology evaluation should include:

- expert review
- OOPS! pitfall checking
- competency question testing
- SPARQL query testing
- consistency checking if reasoner is used
- sample RDF instance review

## Usability Evaluation

Recommended methods:

- SUS questionnaire
- task-based testing
- interview
- observation

Suggested participants:

```txt
12–15 participants including general users, contributors, practitioners, curators, experts, and admins
```

Target:

```txt
SUS score >= 70
```

## Performance Targets

Suggested MVP targets:

| Operation | Target |
|---|---|
| Login | < 2 seconds |
| Browse list | < 2 seconds |
| Semantic search common query | < 2 seconds |
| Contribution submit without media | < 2 seconds |
| Contribution submit with media | progress visible |
| RDF publication job | async |
| AI triage job | async |

## API Contract Evaluation

API evaluation should include:

- stable response envelope
- field-level validation errors
- `/api/v1` auth contract for register, login, logout, and current user
- bearer-token revocation on logout
- authorization checks for every sensitive endpoint
- restricted data excluded from public and unauthorized responses
- retry-safe idempotency behavior for write endpoints
- safe trace timeline responses for provenance and version endpoints
- protected RDF publication queueing and failed-publication safety
- optional AI triage dispatch, review-only suggestion visibility, and suggestion-only side effects
- public knowledge browsing and search filtering for published, non-sensitive content only
- semantic search unavailable behavior when the SPARQL query endpoint is not configured
- protected predefined SPARQL proxy authorization and filtering
- clear conflict responses for stale or duplicate client requests
- consistent `/api/v1` route versioning

## Deployment Readiness Evaluation

Run before staging demos or field testing:

```txt
php artisan gamelan:deployment-check
php artisan gamelan:deployment-check --json
composer test
```

The deployment check reports `pass`, `warn`, or `fail` without printing secrets. Warnings may be acceptable for local development, but staging and production must resolve failures before client field testing.
