# Data Model

This document defines the relational data model used for workflow and operational data.

## Current Implementation

The current Flutter app has local Dart models for the repository-backed local
MVP:

```txt
ContributionModel
- id
- title
- description
- status
- knowledgeType
- gamelanType
- sourceNote
- contributorNote
- culturalSensitivity
- consentGiven
- createdAt
- reviewNote
- rdfPublication

ReviewModel
- id
- contributionId
- decision
- notes

KnowledgeItem
- id
- title
- description
- knowledgeType
- gamelanType
- relations
- sourceSummary
- provenanceSummary
- isCommunityApproved
```

The Flutter data layer also now includes typed ontology and RDF publication
DTOs used by the mobile client:

```txt
OntologyClass
OntologyProperty
OntologyEntity
OntologyMapping
OntologyRelation
RdfPublicationModel
RdfPublicationPublisher
```

`ContributionModel` may now carry an optional `rdfPublication` summary and a
client-side `isPublishable` hint derived from contribution status and cultural
sensitivity. These additions are read-only client conveniences; backend
authorization remains the source of truth for publication.

There is no relational database, migration set, backend model, or persisted
schema in this repository yet. Local contribution, review, and knowledge
repositories hold current demo records, while `GamelanMvpStore` coordinates
UI-facing state. `ContributionDraftStorage` persists only non-sensitive local
drafts in `shared_preferences`. The model below is the target backend data
model.

## Core Tables

Implemented MVP foundation tables:

```txt
users
roles
role_user
knowledge_items
contributions
contribution_versions
contribution_relations
reviews
expert_validations
media_assets
provenance_records
rdf_publications
ontology_entities
ontology_mappings
notifications
audit_logs
idempotency_records
triage_results
```

The tables above provide the relational foundation for workflow truth. Contribution draft creation, draft updates, submission, archiving, review decisions, expert validations, media uploads/removal, version snapshots, provenance records, audit records, safe trace timelines, contribution/media idempotency, RDF publication for validated non-sensitive contributions, published knowledge browsing, keyword search, controlled semantic search, and optional rule-based AI triage suggestions are now implemented. Notification delivery remains a later workflow phase.

## Contribution Status

Recommended status enum:

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

## Knowledge Item

Represents validated, public knowledge.

Implemented fields:

```txt
id
uuid
ontology_entity_id
title
slug
description
knowledge_type
gamelan_type
publish_status
source_summary
cultural_sensitivity
metadata
created_by
approved_by
published_by
published_at
created_at
updated_at
```

Public browsing and search expose only records with `publish_status = published`, `cultural_sensitivity = false`, and a linked published, non-sensitive ontology entity. Metadata returned through public resources is intentionally narrowed to safe keys such as ontology class and language.

## Contribution

Represents user-submitted draft or candidate knowledge.

Implemented fields:

```txt
id
uuid
user_id
title
description
knowledge_type
gamelan_type
status
source_note
contributor_note
cultural_sensitivity
ai_triage_status
ai_suggested_entity_type
ai_suggested_relations
ai_duplicate_candidates
ai_confidence_score
ai_triage_note
ai_model_name
ai_processed_at
duplicate_score
metadata
submitted_at
created_at
updated_at
```

`contributions.status` defaults to `draft`. The contribution workflow service supports `draft` creation, `draft` or `needs_revision` updates, `submitted` transitions, and `archived` transitions. The review workflow supports `under_review`, `needs_revision`, `curator_approved`, `expert_required`, `expert_approved`, and `rejected` transitions. The RDF publication workflow moves eligible validated contributions to `published` only after successful triplestore insertion. Optional MVP 9 triage mirrors the latest suggestion into `ai_*` fields without changing contribution status.

## Contribution Version

Stores snapshots for important edits.

Created through the shared `ProvenanceService` for contribution lifecycle, review transitions, expert validation transitions, and media changes.

Implemented fields:

```txt
id
contribution_id
editor_id
version_number
snapshot
change_note
status
edited_at
created_at
updated_at
```

## Contribution Relation

Stores candidate relationships between a contribution and ontology entities before curator validation.

Implemented fields:

```txt
id
uuid
contribution_id
ontology_entity_id
related_ontology_entity_id
relation_type
relation_label
subject_label
object_label
status
metadata
created_at
updated_at
```

## Review

Implemented fields:

```txt
id
contribution_id
reviewer_id
role
decision
note
private_note
metadata
reviewed_at
created_at
updated_at
```

Possible decisions:

```txt
approve
reject
request_revision
mark_expert_required
```

Peer reviewer approve and reject decisions are stored as recommendation-only review records. Curator and admin decisions are final workflow decisions for approval, rejection, revision requests, and expert-required marking.

## Expert Validation

Implemented fields:

```txt
id
contribution_id
expert_id
decision
note
private_note
metadata
validated_at
created_at
updated_at
```

Expert validation records are created only for contributions in `expert_required` status. Supported decisions are `approve`, `reject`, and `request_revision`.

## Media Asset

Implemented metadata fields:

```txt
id
uuid
contribution_id
knowledge_item_id
ontology_entity_id
uploader_id
title
description
media_type
storage_disk
file_path
file_url
mime_type
file_size
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
deleted_at
created_at
updated_at
```

Media uploads store private file references with consent, visibility, and cultural sensitivity metadata. API resources expose safe metadata only and must not expose `storage_disk`, `file_path`, or `file_url`. Removing draft media soft-deletes the metadata record and deletes the stored private file.

## Provenance Record

Implemented fields:

```txt
id
uuid
contribution_id
contribution_version_id
knowledge_item_id
media_asset_id
ontology_mapping_id
actor_id
event_type
source_type
source_id
summary
metadata
occurred_at
created_at
updated_at
```

Trace API resources expose `provenance_records` through safe, paginated timelines for contribution owners and authorized review roles. Public API resources must not expose raw `source_id` database identifiers, private notes, storage paths, file URLs, IP address, user agent, raw AI prompt content, or restricted cultural details.

Rule-based triage suggestion events use `event_type = ai_triage_suggested` with a nullable `actor_id` because the queue job is system initiated.

## Audit Log

Implemented fields:

```txt
id
uuid
actor_id
auditable_type
auditable_id
action
description
ip_address
user_agent
metadata
occurred_at
created_at
updated_at
```

Audit logs are operational records for troubleshooting sensitive actions. They are not exposed through a general API endpoint in MVP 6.

## RDF Publication

Tracks publication to the triplestore.

Implemented fields:

```txt
id
uuid
contribution_id
knowledge_item_id
ontology_mapping_id
rdf_subject_uri
rdf_graph_uri
status
published_at
published_by
error_message
metadata
created_at
updated_at
```

Implemented publication statuses:

```txt
pending
published
failed
deprecated
```

`pending` records are queued for `PublishContributionToRdfJob`. `published` records have been inserted into the configured public named graph. `failed` records keep a sanitized failure message and do not publish the contribution.

## Ontology Entity and Mapping

`ontology_entities` stores candidate, approved, or published relational references to ontology concepts. `ontology_mappings` links contributions or knowledge items to ontology classes/properties. MVP 7 creates approved mappings when a curator/admin queues RDF publication, then marks the mapping as `published` only after the triplestore insert succeeds.

## Triage Result

Stores rule-based preprocessing output for curator/reviewer assistance.

Implemented fields:

```txt
id
contribution_id
processed_by
status
suggested_entity_type
suggested_relations
duplicate_candidates
confidence_score
note
model_name
processed_at
metadata
created_at
updated_at
```

MVP 9 creates `suggested` records from `RunContributionTriageJob` when enabled. `metadata` stores safe fields such as provider, ontology class hint, missing metadata, language normalization, curator summary, and uncertainty notes. It must not store raw prompts, raw AI responses, private notes, media storage paths, file URLs, credentials, IP address, user agent, or restricted cultural detail.

## Idempotency Record

Implemented fields:

```txt
id
uuid
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
created_at
updated_at
```

Contribution create and submit write endpoint idempotency is now wired through this table. Matching retries return the stored response, while reusing the same user, purpose, and idempotency key with different request content returns `409 Conflict`. Media requests still need idempotency handling in a later phase.

## Important Rule

The relational database stores workflow truth.

The triplestore stores validated semantic knowledge.

Do not use the triplestore as the only place to track review status.
