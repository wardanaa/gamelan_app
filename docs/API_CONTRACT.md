# API Contract

This document defines REST API standards.

## Current Implementation

The current Flutter app performs real HTTP requests for authentication only.
`ApiClient` builds JSON requests from the configured API base URL and
`AuthRepository` calls backend registration, login, logout, and `/me` profile
endpoints. The base URL is read from:

```txt
--dart-define=API_BASE_URL=https://127.0.0.1:8000/api/v1
```

If no value is provided, local development defaults to:

```txt
http://127.0.0.1:8000/api/v1
```

Existing mobile constants are:

```txt
/auth/login
/auth/register
/auth/logout
/me
/contributions
/reviews
/knowledge
/admin/audit-logs
/admin/users
```

Registration and login expect the standard response envelope and a token at
`data.access_token`. The app validates new and restored tokens by calling
`GET /me`, stores only the token in secure device storage, and sends it as a
bearer token for authenticated API requests. If `/me` returns `401`, the mobile
app clears the stored token and returns to the auth screen.

The local MVP now routes contribution, review, and knowledge data through
repository interfaces coordinated by `GamelanMvpStore`. The current repository
implementations are local demo data sources and do not call the contribution,
review, or knowledge API endpoints. Only non-sensitive draft contributions are
persisted locally; broader API integration remains target architecture.

The Flutter test suite includes an opt-in live Laravel-backed integration test
for the implemented authentication contract. The test is skipped unless the
following dart-defines are supplied:

```txt
GAMELAN_TEST_API_BASE_URL
GAMELAN_TEST_EMAIL
GAMELAN_TEST_PASSWORD
```

That live test signs in through `POST /auth/login`, confirms the app can load
the authenticated profile through `GET /me`, and signs out through
`POST /auth/logout`. It does not exercise contribution, review, knowledge,
semantic search, ontology, SPARQL, media, RDF publication, or provenance
endpoints because those mobile workflows are not yet API-backed in this
repository.

Chrome web execution of the live authentication test should use the Flutter
driver entrypoint at `test_driver/integration_test.dart`:

```sh
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/live_laravel_backend_test.dart \
  -d chrome \
  --dart-define=GAMELAN_TEST_API_BASE_URL=https://127.0.0.1:8000/api/v1 \
  --dart-define=GAMELAN_TEST_EMAIL=test@example.com \
  --dart-define=GAMELAN_TEST_PASSWORD=secret
```

Use local shell values or CI secrets for live credentials. Do not store them in
repository files or print backend tokens from the test.

The contract below is the target REST API contract for the future backend.

## Base URL

```txt
/api/v1
```

## Response Format

### Success

```json
{
  "success": true,
  "message": "Data retrieved successfully.",
  "data": {}
}
```

### Error

```json
{
  "success": false,
  "message": "Validation failed.",
  "errors": {}
}
```

### Pagination

```json
{
  "success": true,
  "message": "Data retrieved successfully.",
  "data": [],
  "meta": {
    "current_page": 1,
    "per_page": 10,
    "total": 100
  }
}
```

## Core Endpoints

### Authentication

```txt
POST /auth/register
POST /auth/login
POST /auth/logout
GET  /me
```

Expected auth data:

```json
{
  "access_token": "opaque-token",
  "token_expires_at": "2026-05-20T12:00:00Z",
  "user": {
    "name": "Curator User",
    "email": "curator@example.com",
    "roles": ["curator"],
    "permissions": ["review.contributions"]
  }
}
```

`GET /me` should return the authenticated user profile with the same `user`
shape. Mobile role checks are only UX gates; Laravel policies must still enforce
authorization on every protected endpoint and return `403` when the user is
authenticated but not allowed.

### Knowledge Browsing

The current Flutter constant is `/knowledge`. The target backend should expose
resource-oriented knowledge endpoints:

```txt
GET /knowledge-items
GET /knowledge-items/{id}
GET /knowledge-items/{id}/relations
GET /knowledge-types
GET /gamelan-types
```

### Semantic Search

```txt
GET /search
GET /search/semantic
GET /search/suggestions
```

### Contributions

The current Flutter constant is `/contributions`. The target backend should
support:

```txt
GET    /contributions
POST   /contributions
GET    /contributions/{id}
PUT    /contributions/{id}
DELETE /contributions/{id}
POST   /contributions/{id}/submit
POST   /contributions/{id}/media
```

### Review

The current Flutter constant is `/reviews`. The target backend should support:

```txt
GET  /reviews/queue
POST /reviews/{contribution}/approve
POST /reviews/{contribution}/reject
POST /reviews/{contribution}/request-revision
POST /reviews/{contribution}/expert-validate
```

### Ontology

```txt
GET /ontology/classes
GET /ontology/properties
GET /ontology/entities
GET /ontology/entities/{id}
GET /ontology/entities/{id}/graph
```

### SPARQL Proxy

```txt
POST /sparql/query
```

This endpoint should be protected or restricted. Public users should normally use predefined semantic search endpoints, not arbitrary SPARQL.

## Example Contribution Payload

```json
{
  "title": "Gangsa in Gong Kebyar",
  "description": "Gangsa is a metallophone instrument used in Gong Kebyar ensemble.",
  "knowledge_type": "instrument",
  "gamelan_type": "gong_kebyar",
  "source_note": "Community interview and local practice note.",
  "cultural_sensitivity": false,
  "related_entities": [
    {
      "type": "ensemble",
      "label": "Gong Kebyar",
      "relation": "used_in"
    }
  ]
}
```
