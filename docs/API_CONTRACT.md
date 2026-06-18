# API Contract

This document defines REST API standards for the Laravel backend.

Endpoint examples describe the intended API v1 contract. Some endpoints may be planned before they are implemented, but new backend work should preserve these route shapes unless a documented versioned change is made.

## Current Implementation

The current Flutter app performs real HTTP requests for authentication,
contributions, review, and public knowledge browsing/search through the Laravel
API. `ApiClient` builds JSON requests from the configured API base URL. The
base URL is read from:

```txt
--dart-define=API_BASE_URL=https://127.0.0.1:8000/api/v1
```

If no value is provided, local development defaults to:

```txt
http://127.0.0.1:8000/api/v1
```

Production mobile endpoint constants include:

```txt
/auth/login
/auth/register
/auth/logout
/me
/contributions
/reviews/queue
/reviews/{uuid}/approve
/reviews/{uuid}/reject
/reviews/{uuid}/request-revision
/knowledge-items
/knowledge-types
/gamelan-types
/search
/admin/audit-logs
/admin/users
```

Registration and login expect the standard response envelope and a token at
`data.access_token`. The app validates new and restored tokens by calling
`GET /me`, stores only the token in secure device storage, and sends it as a
bearer token for authenticated API requests. If `/me` returns `401`, the mobile
app clears the stored token and returns to the auth screen.

`GamelanMvpStore` coordinates UI-facing state through repository interfaces.
Production wiring uses:

- `RemoteContributionRepository` for list/create/update/submit/archive
- `RemoteReviewRepository` for queue and review decisions
- `RemoteKnowledgeRepository` for browse, detail, search, and taxonomy labels

Contribution drafts are API-only in production wiring. The server is the source
of truth; local `shared_preferences` draft persistence remains only in
`LocalContributionRepository` for deterministic tests.

Mobile forms apply UX validation before requests, but backend validation remains
mandatory. The app maps `422` field errors and `409` conflict responses to form
and snackbar feedback.

The Flutter test suite includes mocked remote repository tests and widget tests
that inject `GamelanMvpStore.local()` for offline demo flows. An opt-in live
Laravel-backed integration test is skipped unless these dart-defines are
supplied:

```txt
GAMELAN_TEST_API_BASE_URL
GAMELAN_TEST_EMAIL
GAMELAN_TEST_PASSWORD
```

That live test exercises authentication (`POST /auth/login`, `GET /me`,
`POST /auth/logout`). Separate opt-in live tests cover reviewer workflow and
ontology/RDF contracts when suitable backend credentials and fixture UUIDs are
provided. The mobile app implements online media upload/removal for editable
contributions and safe provenance timeline screens. Curator-facing RDF
publication UI and semantic-search fallback UI are implemented in the mobile
app. SPARQL proxy UI, offline media queues, richer conflict resolution UI, and
full offline sync remain target architecture in the mobile app. The Flutter
client consumes the documented semantic-search unavailable response by falling
back visibly to keyword search.

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

The contract below is the shared REST API contract for the Laravel backend and
external clients such as this Flutter app.

The live integration coverage in this repository now verifies that `GET /me`
returns backend `roles` and `permissions` consumable by the mobile app. When
opt-in review credentials and target UUIDs are provided, the same live test also
checks the documented expert-review endpoints and workflow-status transitions,
while keeping contributor-facing trace/privacy expectations explicit in the test
fixtures.

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

Errors must not expose stack traces, SQL errors, filesystem paths, credentials, private review notes, or restricted cultural knowledge.

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
POST /api/v1/auth/register
POST /api/v1/auth/login
POST /api/v1/auth/logout
GET  /api/v1/me
```

Authentication uses bearer tokens suitable for external mobile and web API clients.

Registration (`POST /api/v1/auth/register`) expects:

```json
{
  "name": "Made Contributor",
  "email": "made@example.com",
  "password": "secretpassword",
  "password_confirmation": "secretpassword"
}
```

Register and login responses return the token once:

```json
{
  "success": true,
  "message": "Login successful.",
  "data": {
    "user": {
      "id": 1,
      "name": "Made Contributor",
      "email": "made@example.com",
      "roles": [
        "contributor"
      ],
      "permissions": [],
      "email_verified_at": null,
      "created_at": "2026-05-20T10:00:00.000000Z",
      "updated_at": "2026-05-20T10:00:00.000000Z"
    },
    "token": "plain-text-token-returned-once",
    "token_type": "Bearer"
  }
}
```

Authenticated requests must send:

```txt
Authorization: Bearer <token>
```

`POST /api/v1/auth/logout` revokes the current bearer token only. User payloads must not include passwords, remember tokens, token model internals, or private profile fields.

### Knowledge Browsing

```txt
GET /api/v1/knowledge-items
GET /api/v1/knowledge-items/{id}
GET /api/v1/knowledge-items/{id}/relations
GET /api/v1/knowledge-types
GET /api/v1/gamelan-types
```

Implemented MVP browsing endpoints are public and return only published, non-sensitive content. `{id}` may be either the knowledge item UUID or slug. Public filtering requires:

- `knowledge_items.publish_status = published`
- `knowledge_items.cultural_sensitivity = false`
- linked `ontology_entities.status = published`
- linked `ontology_entities.cultural_sensitivity = false`

`GET /api/v1/knowledge-items` supports:

```txt
page
per_page
q
knowledge_type
gamelan_type
```

`per_page` is capped at `50`. `knowledge_type` and `gamelan_type` use the same documented allowlists as contribution payloads.

Knowledge item responses use safe metadata only:

```json
{
  "success": true,
  "message": "Knowledge item retrieved successfully.",
  "data": {
    "knowledge_item": {
      "id": "knowledge-item-uuid",
      "slug": "gangsa-in-gong-kebyar",
      "title": "Gangsa in Gong Kebyar",
      "description": "Validated public description.",
      "knowledge_type": "instrument",
      "knowledge_type_label": "Instrument",
      "gamelan_type": "gong_kebyar",
      "gamelan_type_label": "Gong Kebyar",
      "source_summary": "Curator-approved source summary.",
      "cultural_sensitivity": false,
      "ontology_entity": {
        "id": "ontology-entity-uuid",
        "uri": "https://example.org/gamelan/entity/gangsa-in-gong-kebyar",
        "slug": "gangsa-in-gong-kebyar",
        "label": "Gangsa in Gong Kebyar",
        "entity_type": "instrument",
        "description": "Validated public description."
      },
      "media_assets": [],
      "metadata": {
        "ontology_class": "Instrument"
      },
      "published_at": "2026-05-22T10:00:00.000000Z"
    }
  }
}
```

Public media metadata is included only when the media is linked to the published knowledge item, has `visibility = public`, has consent status `granted` or `not_required`, and is not culturally sensitive. Responses never include `storage_disk`, `file_path`, or `file_url`.

`GET /api/v1/knowledge-items/{id}/relations` returns published mapping relations from the approved ontology mapping payload and includes a linked public knowledge item only when the related object is also public.

### Semantic Search

```txt
GET /api/v1/search
GET /api/v1/search/semantic
GET /api/v1/search/suggestions
```

Implemented MVP search endpoints are public and apply the same publication and cultural-sensitivity restrictions as browsing endpoints.

`GET /api/v1/search` requires `q` and performs relational keyword search over public title, slug, description, and source summary fields. It supports `page`, `per_page`, `knowledge_type`, and `gamelan_type`.

`GET /api/v1/search/suggestions` requires `q` with at least 2 characters and returns capped public-safe suggestions from taxonomy labels and public knowledge item titles/slugs.

`GET /api/v1/search/semantic` requires `q` and runs a backend-built SPARQL `SELECT` query against the configured published graph only. Returned subject URIs are reconciled with relational public knowledge items before any result is returned. If `SPARQL_QUERY_ENDPOINT` is not configured or the triplestore query fails, the endpoint returns:

```json
{
  "success": false,
  "message": "Semantic search is temporarily unavailable.",
  "errors": {}
}
```

with HTTP `503`.

Search result items use this shape:

```json
{
  "result_type": "knowledge_item",
  "match_type": "semantic",
  "knowledge_item": {
    "id": "knowledge-item-uuid",
    "slug": "gangsa-in-gong-kebyar",
    "title": "Gangsa in Gong Kebyar"
  }
}
```

### Contributions

```txt
GET    /api/v1/contributions
POST   /api/v1/contributions
GET    /api/v1/contributions/{uuid}
GET    /api/v1/contributions/{uuid}/versions
GET    /api/v1/contributions/{uuid}/provenance
PUT    /api/v1/contributions/{uuid}
DELETE /api/v1/contributions/{uuid}
POST   /api/v1/contributions/{uuid}/submit
POST   /api/v1/contributions/{uuid}/media
DELETE /api/v1/contributions/{uuid}/media/{media_asset_uuid}
POST   /api/v1/contributions/{uuid}/rdf-publications
```

Implemented MVP contribution endpoints require bearer authentication and return only authorized records. Standard contribution list/show/update/archive endpoints are owner scoped. Trace endpoints are visible to the contribution owner and to authorized review roles. `DELETE` archives eligible drafts instead of hard-deleting them. Contribution create and submit support idempotency for retry-safe clients.

`PUT /api/v1/contributions/{uuid}` accepts an optional optimistic concurrency marker for offline-capable clients:

```json
{
  "title": "Updated draft title",
  "last_known_updated_at": "2026-05-22T10:00:00.000000Z"
}
```

If `last_known_updated_at` is omitted, existing client behavior is unchanged. If it is present and older than the current contribution `updated_at`, the API returns HTTP `409`:

```json
{
  "success": false,
  "message": "This contribution has changed since you last loaded it. Please refresh and try again.",
  "errors": {}
}
```

The marker is validated but not stored, and stale rejected updates do not create contribution versions or provenance records.

Contribution version responses are paginated and return safe snapshots:

```json
{
  "success": true,
  "message": "Contribution versions retrieved successfully.",
  "data": [
    {
      "version_number": 1,
      "status": "draft",
      "change_note": "Draft created.",
      "editor": {
        "id": 1,
        "name": "Made Contributor"
      },
      "snapshot": {
        "title": "Gangsa in Gong Kebyar",
        "status": "draft"
      },
      "edited_at": "2026-05-22T10:00:00.000000Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 10,
    "total": 1
  }
}
```

Contribution provenance responses are paginated and client-safe:

```json
{
  "success": true,
  "message": "Contribution provenance retrieved successfully.",
  "data": [
    {
      "id": "provenance-uuid",
      "event_type": "contribution_submitted",
      "summary": "Contribution submitted for review.",
      "actor": {
        "id": 1,
        "name": "Made Contributor"
      },
      "source": {
        "type": "Contribution"
      },
      "contribution_version_number": 2,
      "metadata": {
        "status": "submitted"
      },
      "occurred_at": "2026-05-22T10:00:00.000000Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "per_page": 10,
    "total": 1
  }
}
```

Contributor-facing trace responses hide reviewer and expert identities. Trace responses must not include private notes, IP address, user agent, storage paths, file URLs, raw AI prompts, raw AI responses, or restricted cultural details.

Media upload endpoints require bearer authentication and contribution ownership. Upload and removal are allowed only while the contribution is `draft` or `needs_revision`. Media upload accepts multipart form data with:

```txt
file
title
description
media_type
creator
credit
license
consent_status
visibility
cultural_sensitivity
recording_date
recording_place
related_entity_label
alt_text
metadata
```

Required fields are `file`, `title`, `media_type`, `consent_status`, `visibility`, and `cultural_sensitivity`.

Allowed media types and upload limits:

| media_type | Extensions | Max size |
|---|---|---:|
| `image` | jpg, jpeg, png, webp | 10 MB |
| `audio` | mp3, wav, ogg, m4a | 50 MB |
| `video` | mp4, mov, webm | 200 MB |
| `document` | pdf, txt, doc, docx | 20 MB |

Media responses return safe metadata only:

```json
{
  "success": true,
  "message": "Media asset uploaded successfully.",
  "data": {
    "media_asset": {
      "id": "media-uuid",
      "title": "Gangsa instrument photo",
      "description": "Photo evidence for curator review.",
      "media_type": "image",
      "mime_type": "image/jpeg",
      "file_size": 12345,
      "creator": "Made Contributor",
      "credit": "Community documentation",
      "license": "cc-by",
      "consent_status": "granted",
      "visibility": "private",
      "cultural_sensitivity": false,
      "recording_date": "2026-05-22",
      "recording_place": "Denpasar",
      "related_entity_label": "Gangsa",
      "alt_text": "Gangsa instrument photo for documentation.",
      "metadata": {},
      "created_at": "2026-05-22T10:00:00.000000Z",
      "updated_at": "2026-05-22T10:00:00.000000Z"
    }
  }
}
```

Media responses must not include `file_path`, `storage_disk`, or `file_url`.

RDF publication endpoints require bearer authentication and are restricted to curators and admins. Publication is a separate action after human validation; curator approval or expert approval does not automatically publish RDF.

`POST /api/v1/contributions/{uuid}/rdf-publications` queues an asynchronous publication job for an eligible, non-sensitive contribution in `curator_approved` or `expert_approved` status. The authenticated publisher cannot be the original contributor. Draft, submitted, under-review, rejected, archived, already pending, already published, and culturally sensitive contributions are rejected with safe client messages.

Publication payload:

```json
{
  "ontology_class": "Instrument",
  "subject_slug": "gangsa-in-gong-kebyar",
  "preferred_label": "Gangsa in Gong Kebyar",
  "language": "id",
  "source_summary": "Community interview and local practice note.",
  "relations": [
    {
      "property": "usedInEnsemble",
      "object_slug": "gong-kebyar",
      "object_label": "Gong Kebyar",
      "object_class": "Ensemble"
    }
  ]
}
```

Successful queue response:

```json
{
  "success": true,
  "message": "RDF publication queued successfully.",
  "data": {
    "rdf_publication": {
      "id": "rdf-publication-uuid",
      "contribution_id": "contribution-uuid",
      "knowledge_item_id": null,
      "ontology_mapping_id": "ontology-mapping-uuid",
      "rdf_subject_uri": "https://example.org/gamelan/entity/gangsa-in-gong-kebyar",
      "rdf_graph_uri": "graph/published",
      "status": "pending",
      "published_at": null,
      "published_by": {
        "id": 2,
        "name": "Made Curator"
      },
      "error_message": null,
      "metadata": {
        "ontology_class": "Instrument",
        "subject_slug": "gangsa-in-gong-kebyar",
        "relations_count": 1,
        "provenance_graph_uri": "graph/provenance"
      }
    }
  }
}
```

The response never includes SPARQL credentials, raw triplestore errors, private notes, raw AI output, media storage paths, or media URLs.

### Review

```txt
GET  /api/v1/reviews/queue
GET  /api/v1/reviews/{contribution_uuid}
GET  /api/v1/reviews/{contribution_uuid}/provenance
POST /api/v1/reviews/{contribution_uuid}/approve
POST /api/v1/reviews/{contribution_uuid}/reject
POST /api/v1/reviews/{contribution_uuid}/request-revision
POST /api/v1/reviews/{contribution_uuid}/mark-expert-required
POST /api/v1/reviews/{contribution_uuid}/expert-validate
```

Review endpoints must enforce role, ownership, workflow status, and cultural sensitivity checks.

Implemented MVP review endpoints require bearer authentication and use contribution UUIDs in URLs. Peer reviewers may record approve or reject recommendations for non-sensitive submitted contributions, but those recommendations do not final-approve or final-reject content. Peer reviewers may request revision. Curators and admins may approve, reject, request revision, or mark expert validation required. Expert validators and admins may validate contributions in `expert_required` status.

Review decision payloads may include:

```json
{
  "note": "Client-safe reviewer note.",
  "private_note": "Private reviewer note for authorized reviewers only."
}
```

`POST /api/v1/reviews/{contribution_uuid}/mark-expert-required` additionally requires `expert_required_reasons`:

```json
{
  "note": "Origin claim needs expert validation.",
  "expert_required_reasons": ["origin_claim", "curator_flagged"]
}
```

`POST /api/v1/reviews/{contribution_uuid}/expert-validate` requires a `decision` of `approve`, `reject`, or `request_revision`.

Private review notes, private expert notes, and reviewer or expert identity fields must not be returned to contributor-facing responses.

When optional MVP 9 triage has run, review queue and review detail responses for authorized non-owner review roles may include:

```json
{
  "triage_suggestion": {
    "label": "AI suggestion, not validated.",
    "provider": "rules",
    "status": "suggested",
    "model_name": "rule-based-v1",
    "processed_at": "2026-05-22T10:00:00.000000Z",
    "confidence_score": "0.7600",
    "suggested_entity_type": "instrument",
    "suggested_relations": [],
    "duplicate_candidates": [],
    "missing_metadata": [],
    "language_normalization": {
      "suggested_language": "id"
    },
    "curator_summary": "Extractive summary from submitted text.",
    "uncertainty_notes": [
      "Human validation is still required."
    ]
  }
}
```

The API must not expose `triage_suggestion` in public endpoints, normal contributor-facing contribution responses, RDF publication responses, or SPARQL responses.

### Ontology

```txt
GET /api/v1/ontology/classes
GET /api/v1/ontology/properties
GET /api/v1/ontology/entities
GET /api/v1/ontology/entities/{id}
GET /api/v1/ontology/entities/{id}/graph
```

### SPARQL Proxy

```txt
POST /api/v1/sparql/query
```

Implemented MVP SPARQL proxy behavior is protected by bearer authentication and restricted to `curator` and `admin` users. Public users should use predefined browsing and search endpoints.

The endpoint does not accept raw SPARQL. It accepts only predefined query keys:

```txt
published_entities_by_type
related_entities
instruments_in_ensemble
```

Example payload:

```json
{
  "query_key": "published_entities_by_type",
  "parameters": {
    "ontology_class": "Instrument",
    "limit": 25
  }
}
```

`related_entities` accepts `subject_slug` or `subject_uri`. `instruments_in_ensemble` accepts `ensemble_slug` or `ensemble_uri`. Proxy results are reconciled with public relational `knowledge_items`; unpublished or culturally sensitive RDF bindings are filtered out before the response.

## Example Contribution Payload

```json
{
  "title": "Gangsa in Gong Kebyar",
  "description": "Gangsa is a metallophone instrument used in Gong Kebyar ensemble.",
  "knowledge_type": "instrument",
  "gamelan_type": "gong_kebyar",
  "contribution_intent": "new_entity",
  "source_note": "Community interview and local practice note.",
  "contributor_note": "Submitted as community knowledge.",
  "cultural_sensitivity": false,
  "related_entities": [
    {
      "type": "ensemble",
      "label": "Gong Kebyar",
      "relation": "usedInEnsemble"
    }
  ]
}
```

Draft creation allows nullable `description`, `source_note`, and `contribution_intent`, but these fields are required before `POST /api/v1/contributions/{uuid}/submit` can move the contribution to `submitted`.

## Idempotency Headers

Retryable write requests should accept an idempotency key.

Example:

```txt
Idempotency-Key: 018f7c0a-8df5-7b40-a084-6c4f2b62f95f
```

The API binds idempotency keys to the authenticated user and request purpose for implemented contribution create and submit endpoints. Matching retries return the stored accepted response. Reusing the same key with different request content returns `409 Conflict`.

## Client-Safe Workflow Metadata

Where useful, API responses may include workflow metadata that helps clients render allowed actions.

Example:

```json
{
  "status": "submitted",
  "status_label": "Submitted",
  "status_description": "This contribution has been submitted and is waiting for review.",
  "allowed_actions": [
    "view"
  ]
}
```

Clients must not infer permission from role names alone.

For eligible curator/admin review views, `allowed_actions` may include `publish_rdf`. Clients must still call the RDF publication endpoint and rely on backend authorization.
