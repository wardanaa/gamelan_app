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

## Mobile Upload Rules

Mobile uploads should:

- show upload progress
- support retry
- support draft attachment
- preserve metadata
- warn on large uploads
- allow removal before submission
