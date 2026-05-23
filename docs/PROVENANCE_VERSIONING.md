# Provenance and Versioning

This document defines provenance and versioning rules.

## Current Implementation

The current Flutter app now exposes safe, read-only provenance and version
timelines in contribution and review detail flows. It still does not persist
provenance locally, but it can display backend trace data when the Laravel API
returns it.

Implemented client behavior:

- contribution detail screens can open a full-screen provenance timeline route
- review detail screens can open the same safe timeline for review-authorized
  users
- missing actor identity is shown as a neutral placeholder rather than
  inferred locally
- private notes, storage paths, URLs, IP address, user agent, and raw AI
  content are omitted from the mobile display

## Why Provenance Matters

Balinese gamelan knowledge may come from practitioners, elders, literature, observation, recordings, community memory, or institutional archives.

The system must record where knowledge came from, who contributed it, who reviewed it, and how it changed.

## Provenance Must Track

For each contribution:

- contributor
- source note
- submitted time
- review history
- curator decisions
- expert validation
- media assets
- RDF publication status
- ontology mapping
- version changes

## Versioning Rule

Every important edit must create a version record.

The schema foundation includes `contribution_versions` with a JSON `snapshot`, `editor_id`, `edited_at`, and `change_note`. `ProvenanceService` creates version records for draft creation, draft updates, submission, archiving, review transitions, expert validation transitions, and media changes.

Version snapshots should include:

```txt
title
description
knowledge_type
gamelan_type
contribution_intent
related_entities
source_note
contributor_note
media_assets
status
editor_id
edited_at
change_note
```

## Provenance Records

The schema foundation now includes `provenance_records` to connect future workflow events to:

```txt
contribution
contribution_version
knowledge_item
media_asset
ontology_mapping
actor
event_type
occurred_at
metadata
```

`ProvenanceService` is the shared write path for contribution versions, provenance records, and sensitive-operation audit logs. It records `draft_created`, `draft_updated`, `contribution_submitted`, `contribution_archived`, `review_recorded`, `revision_requested`, `curator_approved`, `expert_required_marked`, `expert_validation_approved`, `contribution_rejected`, `media_uploaded`, `media_removed`, `rdf_publication_queued`, `rdf_publication_published`, `rdf_publication_failed`, and `ai_triage_suggested`.

Publication trace helpers are used by MVP 7 RDF publication jobs. Successful publication links the provenance record to the RDF publication, ontology mapping, knowledge item, and contribution version created when the contribution moves to `published`.

Media provenance metadata must include only safe fields such as media UUID, media type, MIME type, file size, consent status, visibility, and cultural sensitivity. It must not include storage paths, public URLs, original local filenames, or restricted cultural details.

Triage provenance uses a nullable actor because rule-based triage is system initiated by a queue job. Triage provenance must include only safe summary metadata such as provider, model name, confidence score, and suggestion counts. It must not include raw prompts, raw AI responses, private notes, media paths, URLs, IP address, user agent, or restricted cultural detail.

## Trace API Visibility

Implemented trace endpoints:

```txt
GET /api/v1/contributions/{uuid}/versions
GET /api/v1/contributions/{uuid}/provenance
GET /api/v1/reviews/{uuid}/provenance
```

Contribution owners may retrieve safe version and provenance timelines for their own contributions. Authorized peer reviewers, curators, experts, and admins may retrieve trace timelines only when review authorization permits access to the contribution. Contributor-facing trace responses must hide reviewer and expert identities, private notes, IP address, user agent, storage paths, public URLs, raw AI prompts, raw AI responses, and restricted cultural details.

Operational `audit_logs` remain internal in this MVP and are not exposed through a general API endpoint.

## RDF Provenance

Use PROV-O where suitable.

MVP 7 writes PROV-style triples to the configured provenance named graph during RDF publication and stores relational provenance records for queued, published, and failed publication events. Failed publication traces must not expose raw triplestore response bodies, credentials, private notes, raw AI output, media storage paths, media URLs, IP address, user agent, or restricted cultural detail.

Example:

```turtle
gamelan:Statement123 a prov:Entity ;
    prov:wasAttributedTo gamelan:Contributor456 ;
    prov:wasGeneratedBy gamelan:Validation789 ;
    prov:generatedAtTime "2026-05-19T10:00:00+08:00"^^xsd:dateTime .
```

## Deleting vs Deprecating

Published semantic knowledge should normally be deprecated, not hard-deleted.

Use:

```txt
active
deprecated
superseded
removed_from_public_view
```

Hard delete only for:

- legal removal
- privacy violation
- accidental sensitive exposure
- duplicate technical error before publication
