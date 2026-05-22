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

Current implemented scenario:

- user registration, login, `/me` profile loading, logout, and expired-token
  clearing
- opt-in live Laravel authentication smoke coverage for login, profile loading,
  and logout
- reviewer role gating for the local Review workflow
- app shell renders the Material 3 bottom navigation
- Search shows seeded Gong Kebyar and Gong Gede knowledge
- contribution form validates title, description, source note, and consent
- submitted contribution appears in the contribution list and review queue
- culturally sensitive contribution shows a warning marker
- approving a contribution moves it into searchable knowledge
- local repository tests verify non-sensitive draft persistence, sensitive
  draft exclusion from plain storage, submitted item non-persistence, review
  queue filtering, review decisions, and approved demo knowledge search

Live Laravel integration tests must not store credentials in the repository or
print tokens. They do not currently validate contribution persistence, curator
review approval, semantic search, RDF publication, SPARQL queries, media
upload, or provenance records.

Target scenarios:

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
- offline draft sync

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
