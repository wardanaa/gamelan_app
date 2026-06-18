# API Client Guide

This document defines how external clients should consume the Laravel REST API.

The Flutter mobile application is an expected client, but this repository owns only the API backend. Client implementation choices such as widget structure, state management, routing, and local UI architecture belong outside this repository.

## Client Boundary

API clients may:

- authenticate users through the API
- browse published knowledge items
- submit contributions and evidence
- upload media through approved API endpoints
- display contribution status and review history
- consume semantic search results
- show curator, reviewer, or expert actions when authorized

API clients must not:

- bypass backend validation
- infer workflow transitions locally
- publish knowledge directly
- write RDF triples or call SPARQL update endpoints
- expose unpublished or restricted cultural knowledge
- treat AI triage suggestions as authoritative decisions

## Authentication

Clients should use token-based authentication through the API.

Expected behavior:

- call `POST /api/v1/auth/register` or `POST /api/v1/auth/login` to receive a bearer token
- send authenticated requests with `Authorization: Bearer <token>`
- send tokens only over HTTPS
- store tokens securely on the client platform
- call `POST /api/v1/auth/logout` when a user signs out so the current token is revoked
- handle `401` by clearing invalid local session state
- handle `403` by hiding or disabling unauthorized actions

The Flutter mobile client also expects `GET /api/v1/me` to return backend
`roles` and `permissions`, so review and expert-approval UX can stay aligned
with backend policy instead of inferring authorization locally.

The API remains responsible for all authentication and authorization decisions.
Plain text tokens are returned only in register and login responses. Clients should not expect token values from `GET /api/v1/me`.

## Contribution Payloads

Contribution forms in external clients should collect enough information for backend validation:

- title
- description
- knowledge type
- related gamelan type
- related instrument, ensemble, composition, person, place, or term
- source note
- contributor note
- contribution intent
- media attachment metadata
- consent status when media or personal identity is involved
- cultural sensitivity flag

The API must validate submitted data and return field-level errors for invalid input.

Implemented MVP contribution endpoints use UUIDs in URLs and responses. Authenticated users can list, view, update, submit, and archive only their own contributions. Drafts may omit `description`, `source_note`, and `contribution_intent`, but submission requires those fields to be complete.

For draft updates, offline-capable clients may send the last server timestamp they loaded:

```json
{
  "title": "Updated draft title",
  "last_known_updated_at": "2026-05-22T10:00:00.000000Z"
}
```

This field is optional for backward compatibility. When present, the API rejects stale updates with `409 Conflict` and the message `This contribution has changed since you last loaded it. Please refresh and try again.` Clients should refresh the contribution, show the user the latest server state, and let the user reapply local changes deliberately.

Clients may retrieve trace timelines for authorized contribution detail screens:

```txt
GET /api/v1/contributions/{uuid}/versions
GET /api/v1/contributions/{uuid}/provenance
GET /api/v1/reviews/{uuid}/provenance
```

Contribution owners receive safe workflow trace entries for their own submissions. Review, curator, expert, and admin clients receive trace timelines only when backend review authorization permits access. Clients must not infer missing actor fields as missing data; contributor-facing responses intentionally hide reviewer and expert identities.

The Flutter mobile client now exposes those trace endpoints through a dedicated
read-only provenance timeline route. It merges contribution versions and safe
provenance events and shows a neutral placeholder when actor identity is
withheld by the backend.

## Status Display

Clients should display contribution statuses exactly as returned by the API.

Supported workflow statuses:

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

Clients may map these statuses to localized display labels, but must preserve the original API value for workflow decisions.

Contribution responses include `status_label`, `status_description`, and `allowed_actions`. Clients should render actions from `allowed_actions`; for the MVP, editable own `draft` and `needs_revision` contributions return `view`, `edit`, `submit`, and `archive`, while submitted, archived, and later workflow statuses return `view`.

Review and expert clients may receive role-aware actions such as `view_review`, `recommend_approve`, `recommend_reject`, `approve`, `reject`, `request_revision`, `mark_expert_required`, and `expert_validate`. These actions are hints from backend authorization and workflow status; clients must still submit decisions to the backend for enforcement.

The Flutter mobile client now renders those actions as two UI groups:

- standard review actions for approve, reject, and request revision
- expert workflow actions for `mark_expert_required` and `expert_validate`

Contributor-facing screens must never surface `private_note` fields or reviewer/expert identities. The public note and private note are separate fields in the expert validation dialog, and the private note is write-only from the contributor’s point of view.

When review responses include `triage_suggestion`, the mobile review detail
screen shows it as a review-only helper card labeled `AI suggestion, not
validated.`. Contributor-facing screens do not render that card.

Client repositories should serialize expert workflow payloads exactly as documented:

- `mark_expert_required` with `note` and `expert_required_reasons`
- `expert_validate` with `decision`, `note`, and `private_note`

Curator and admin clients may receive `publish_rdf` for non-sensitive contributions in `curator_approved` or `expert_approved` status. Clients trigger publication with:

```txt
POST /api/v1/contributions/{uuid}/rdf-publications
```

Publication is asynchronous. A successful request means the RDF publication job was queued, not that the triplestore insert has already completed. Clients must not call SPARQL update endpoints directly.

The Flutter mobile client now exposes this as a Review detail publication form
only when `allowed_actions` includes `publish_rdf`. The form loads ontology
classes and properties from the backend ontology routes, submits the documented
mapping payload, and displays queued publication status from contribution
detail responses.

Contribution detail responses may also include a nested `rdf_publication`
summary and a client-side `isPublishable` hint. Clients should treat
`isPublishable` as a convenience only; backend authorization and workflow
status remain authoritative.

The Flutter mobile repositories also consume the ontology collection routes
directly:

```txt
GET /api/v1/ontology/classes
GET /api/v1/ontology/properties
GET /api/v1/ontology/entities
GET /api/v1/ontology/entities/{id}
```

Clients should treat empty or malformed ontology collections as backend
failures, not as valid empty state. Entity list responses may include pagination
metadata, and the mobile repository preserves it for deterministic paging.

`getRdfPublication` on the mobile side is a read-through convenience over the
contribution detail payload. It does not imply a dedicated
`GET /api/v1/contributions/{uuid}/rdf-publications` endpoint.

## Error Handling

Clients must handle:

- `400` invalid request
- `401` unauthenticated
- `403` unauthorized
- `404` not found
- `409` conflict or duplicate idempotency key
- `422` validation error
- `429` rate limited
- `500` server error
- network timeout

The API must never expose raw backend stack traces. Error responses should be stable, clear, and safe to show in client interfaces when possible.

## Pagination and Filtering

List endpoints should support predictable pagination metadata.

Clients should rely on API-provided pagination fields instead of inventing local paging rules.

Implemented public browsing endpoints:

```txt
GET /api/v1/knowledge-items
GET /api/v1/knowledge-items/{uuid_or_slug}
GET /api/v1/knowledge-items/{uuid_or_slug}/relations
GET /api/v1/knowledge-types
GET /api/v1/gamelan-types
```

Browsing responses contain only published, non-sensitive knowledge items backed by published ontology entities. Clients should treat `404` for a known-looking ID as unavailable content, not proof that a rejected, draft, private, or culturally restricted item exists.

Search and browsing clients may use filters such as:

- keyword
- semantic query
- gamelan type
- instrument
- ensemble
- place or region
- media type
- validation status when authorized

Implemented public search endpoints:

```txt
GET /api/v1/search?q=gangsa
GET /api/v1/search/semantic?q=gangsa
GET /api/v1/search/suggestions?q=gang
```

Keyword search uses relational public knowledge fields. Semantic search uses the backend SPARQL query endpoint and returns `503` when semantic search is not configured or temporarily unavailable, allowing clients to fall back to keyword search explicitly. Suggestions require at least two characters and return only public-safe labels.

The Flutter mobile client uses semantic search by default for non-empty Search
tab queries and shows a visible keyword fallback notice only for that documented
`503` semantic-unavailable response. Other authorization, validation, and server
errors are surfaced through normal API error handling instead of silently
falling back.

Curator and admin clients may use the protected predefined SPARQL proxy:

```txt
POST /api/v1/sparql/query
```

The proxy accepts `query_key` and `parameters`, not raw SPARQL. External clients must not call the triplestore directly.

## Media Uploads

Clients may upload media only through approved API endpoints.

Implemented MVP endpoints:

```txt
POST   /api/v1/contributions/{uuid}/media
DELETE /api/v1/contributions/{uuid}/media/{media_asset_uuid}
```

Expected client behavior:

- send required media metadata
- preserve consent and license information
- handle upload progress if the platform supports it
- retry safely according to API idempotency rules
- remove unsent local attachments when users discard drafts

The API validates file type, MIME type, file size, upload permission, cultural sensitivity, consent status, and visibility. Upload and removal are accepted only for the contribution owner while the contribution is `draft` or `needs_revision`.

Clients should not expect file URLs from media responses. The API returns safe metadata only; restricted or private media files are not directly exposed.

## Review and Curation Clients

Clients used by peer reviewers, curators, experts, or admins should display:

- submitted content
- contributor identity only when permitted
- source note
- evidence and media assets
- AI triage suggestions
- duplicate candidates
- ontology mapping suggestions
- review history
- allowed workflow actions
- validation notes

Available actions must be derived from API authorization and workflow state, not from hard-coded client assumptions.

Implemented MVP review behavior:

- peer reviewers see non-sensitive submitted or under-review contributions they do not own
- peer reviewer approve and reject actions are recommendations only
- peer reviewers can request contributor revision
- curators and admins can approve, reject, request revision, or require expert validation
- sensitive contributions approved by a curator move to `expert_required`
- experts and admins validate only `expert_required` contributions
- contributors can see public review notes for their own contribution but must not receive private notes or expert identity fields
- authorized review clients can retrieve provenance timelines through `GET /api/v1/reviews/{uuid}/provenance`
- curator and admin clients can queue RDF publication for eligible validated non-sensitive contributions
- authorized non-owner review clients may receive `triage_suggestion` labeled `AI suggestion, not validated.`
- contributor-facing and public clients must not expect triage suggestions from normal contribution, browsing, search, RDF, or SPARQL responses

Triage suggestions are advisory only. Clients must not use them to approve, reject, publish, validate, or automatically rewrite submitted cultural knowledge.

## Localization

Clients should support at least:

- Indonesian
- English

Balinese terms should preserve original cultural terminology. Translations, aliases, and definitions should be represented as supporting metadata rather than replacing source terms.
