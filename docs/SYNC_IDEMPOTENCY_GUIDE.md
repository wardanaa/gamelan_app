# Sync and Idempotency Guide

This document defines backend support for offline-capable API clients and retry-safe synchronization.

The API is the source of truth. Client-side drafts, queues, and caches are temporary until accepted by the backend.

## Goal

External clients may support community contribution under unstable connectivity. The API must make repeated submission attempts safe, traceable, and authorization-aware.

## Offline-Capable Client Features

API clients may implement:

- local contribution drafts
- draft editing before submission
- queued media metadata
- queued media upload
- cached recently viewed published knowledge
- retry of failed requests

These features do not change backend ownership of validation, workflow status, provenance, or publication.

## Backend Source of Truth

The backend owns:

- authenticated user identity
- contribution ownership
- workflow status
- review and validation decisions
- accepted media metadata
- duplicate detection
- RDF publication state
- provenance records

Local client state must be reconciled against API responses.

## Client Draft Statuses

Clients may use local-only statuses such as:

```txt
local_draft
pending_sync
syncing
sync_failed
synced
conflict
```

These are not authoritative contribution workflow statuses unless the API explicitly stores and returns them.

## Idempotency Requirements

Clients should send a stable idempotency key for retryable write requests.

Recommended fields:

```txt
client_request_id
local_draft_uuid
```

The API should:

- prevent duplicate submissions from repeated sync attempts
- bind idempotency keys to the authenticated user
- return the existing accepted result when a retry is identical
- return `409 Conflict` when the same idempotency key is reused with different content
- record enough audit data to troubleshoot repeated submissions safely

## Schema Foundation

The relational schema now includes `idempotency_records` with:

```txt
user_id
idempotency_key
purpose
request_method
request_path
request_hash
status
response_status
response_body
locked_until
completed_at
```

The table is bound to authenticated users and request purpose. Contribution create/submit and media upload/removal now use this table to return existing accepted responses for matching retries or `409 Conflict` when the same key is reused with different request content.

For multipart media uploads, the request fingerprint uses safe metadata plus file checksum, size, MIME type, and extension so retry behavior does not depend on serializing uploaded file objects.

## Sync Rules

1. Sync only authenticated user data.
2. Preserve local drafts until the API confirms acceptance.
3. Retry failed requests with exponential backoff.
4. Do not create duplicate contributions after retry.
5. Upload media only after metadata and permission checks pass.
6. Show conflicts clearly when the API version differs from local client state.
7. Never publish content as a side effect of client sync.

## Conflict Handling

The API should return conflict responses when:

- a contribution was modified after the client last fetched it
- a draft was already submitted
- a workflow transition is no longer allowed
- an idempotency key is reused with different payload content
- media visibility or consent status changed

Conflict responses should include a safe message and enough identifiers for the client to refresh state.

Implemented MVP 10 stale-update behavior:

- `PUT /api/v1/contributions/{uuid}` accepts optional `last_known_updated_at`.
- If the marker is older than the current server `updated_at`, the API returns `409 Conflict`.
- If the marker is omitted, existing clients keep the previous update behavior.
- Stale rejected updates do not create contribution versions, provenance records, audit records, or workflow transitions.
- The marker is for conflict detection only and is not stored on the contribution.

## Sensitive Data Restrictions

Clients must not cache sensitive data unless encrypted and necessary.

Avoid caching:

- access tokens in plain storage
- unpublished contributions from other users
- expert notes
- restricted media URLs
- private source identities
- culturally sensitive details marked as restricted

The API must not include restricted fields in sync payloads unless the authenticated user is authorized to receive them.
