# Media Asset Guide

This document defines rules for audio, video, image, and document assets.

## Current Implementation

The Flutter app implements online media attachment for editable contribution
drafts and needs-revision contributions through the Laravel media API.

Implemented mobile behavior:

- safe media metadata models for contribution, review, and public knowledge
  responses
- file selection with `file_picker`
- multipart upload to `POST /api/v1/contributions/{uuid}/media`
- removal through `DELETE /api/v1/contributions/{uuid}/media/{media_asset_uuid}`
- consent, visibility, and cultural-sensitivity checks before upload
- read-only media metadata on review and public knowledge detail screens

The mobile app does not implement an offline media upload queue, media playback,
download links, storage configuration, malware scanning, or public URL handling.
Backend validation and authorization remain mandatory.

## Supported Media Types

| Type | Examples |
|---|---|
| Image | instrument photos, performance photos, manuscript/document scans |
| Audio | instrument sound, ensemble recording, oral explanation |
| Video | performance documentation, technique demonstration |
| Document | PDF, transcription, notes, scanned literature |

## Metadata Requirements

Every media asset should store:

```txt
title
description
media_type
file_url
mime_type
file_size
creator
uploader
credit
license
consent_status
recording_date
recording_place
related_entity
cultural_sensitivity
```

API responses expose safe metadata only. They must not expose `storage_disk`, `file_path`, `file_url`, raw filesystem paths, original local filenames, or object storage internals.

## Consent

Media involving identifiable people, community rituals, private spaces, or sacred context must include consent status.

Possible values:

```txt
unknown
granted
restricted
revoked
not_required
```

## Cultural Sensitivity

Media may be marked:

```txt
public
restricted
curator_only
expert_only
private
```

## File Validation

Backend must validate:

- extension
- MIME type
- file size
- upload permission
- malware scan if available
- media visibility

Implemented MVP upload limits:

| Type | Extensions | Max size |
|---|---|---:|
| Image | jpg, jpeg, png, webp | 10 MB |
| Audio | mp3, wav, ogg, m4a | 50 MB |
| Video | mp4, mov, webm | 200 MB |
| Document | pdf, txt, doc, docx | 20 MB |

Consent and visibility rules:

- `revoked` consent cannot be uploaded.
- `public` visibility requires `granted` or `not_required` consent.
- culturally sensitive media cannot be marked `public`.
- restricted, curator-only, expert-only, private, sensitive, or unconsented media may be stored as workflow evidence but must not expose public file URLs.

## API Client Upload Rules

API clients should:

- show upload progress
- support retry
- support draft attachment
- preserve metadata
- warn on large uploads
- allow removal before submission

The API must enforce upload permission, consent status, file validation, and media visibility regardless of client behavior.

Current Flutter upload UI supports draft attachment and removal with retry-safe
API calls. Full progress display and offline queued retry remain target
capabilities.

## Implemented MVP Endpoints

```txt
POST   /api/v1/contributions/{uuid}/media
DELETE /api/v1/contributions/{uuid}/media/{media_asset_uuid}
```

Upload and removal require bearer authentication, contribution ownership, and an editable contribution status of `draft` or `needs_revision`. Removal soft-deletes the metadata record and deletes the stored private file.
