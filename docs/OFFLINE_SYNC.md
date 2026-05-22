# Offline Sync Guide

This document defines offline and synchronization behavior for the mobile app.

## Current Implementation

Full offline sync is not implemented yet. The current app routes local
contribution, review, and knowledge data through repository interfaces and can
persist the contributor's own non-sensitive local drafts with
`shared_preferences`, but it has no sync queue, no media upload queue, and no
conflict resolution UI. Culturally sensitive drafts, submitted contributions,
review decisions, and approved demo knowledge reset when the app restarts.
Authentication tokens are stored separately with secure device storage and are
not part of the offline draft cache.

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
