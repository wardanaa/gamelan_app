# Offline Sync Guide

This document defines offline and synchronization behavior for the mobile app.

## Current Implementation

Full offline sync is not implemented yet. Production app wiring uses Laravel
API repositories with API-only contribution drafts. The server is the source of
truth for draft, submitted, review, and published knowledge state.

`LocalContributionRepository` still supports non-sensitive draft persistence in
`shared_preferences`, but only for deterministic local tests through
`GamelanMvpStore.local()`. It is not used by default production wiring.

The mobile app has no sync queue, no media upload queue, and no dedicated
conflict-resolution screen yet, although the contribution update API already
supports `last_known_updated_at` and returns `409 Conflict` for stale edits.
Authentication tokens are stored separately with secure device storage and are
not part of any offline draft cache.

This guide defines the target behavior for future offline work.

## Goal

The target mobile app should support community contribution even with unstable
connectivity.

## Offline-Supported Features

Target MVP offline support:

- save contribution draft
- edit draft
- attach media metadata
- queue media upload
- browse cached recently viewed knowledge items
- retry failed sync

## Backend Source of Truth

The backend remains the source of truth.

Local data is temporary until synced and accepted by backend.

## Local Draft Status

Current MVP local draft persistence uses the existing Dart `draft` status only.
The statuses below remain target sync states for future backend-backed offline
work.

Suggested local statuses:

```txt
local_draft
pending_sync
syncing
sync_failed
synced
conflict
```

## Sync Rules

1. Sync only authenticated user data.
2. Retry failed sync with exponential backoff.
3. Preserve local draft until backend confirms success.
4. Do not duplicate submissions after retry.
5. Use client-generated UUID for idempotency.
6. Show conflict clearly when server version differs.

## Idempotency

Mobile should send:

```txt
client_request_id
local_draft_uuid
```

Backend should prevent duplicate submissions from repeated sync attempts.

## Do Not Cache

Do not cache sensitive data unless encrypted and required.

Avoid caching:

- access tokens in plain storage; use secure device storage only
- culturally sensitive contribution drafts in plain storage
- unpublished contributions from other users
- expert notes
- restricted media
