# Media Asset Guide

This document defines rules for audio, video, image, and document assets.

## Current Implementation

Media upload and media metadata management are not implemented in the current
local Flutter MVP. There are no media models, upload screens, upload queues,
storage configuration, or backend validation endpoints yet.

This guide defines target media behavior for future mobile and backend work.

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

## Implemented MVP Endpoints

```txt
POST   /api/v1/contributions/{uuid}/media
DELETE /api/v1/contributions/{uuid}/media/{media_asset_uuid}
```

Upload and removal require bearer authentication, contribution ownership, and an editable contribution status of `draft` or `needs_revision`. Removal soft-deletes the metadata record and deletes the stored private file.
