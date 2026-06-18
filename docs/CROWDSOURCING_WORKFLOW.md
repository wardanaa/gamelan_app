# Crowdsourcing Workflow

This document defines the contribution, review, curation, and validation workflow.

## Current Implementation

The Flutter app currently implements a backend-connected mobile contribution
and review client. Production wiring uses remote Laravel repositories for
contribution drafts, submission, media attachment/removal, review queues,
expert workflow actions, provenance timelines, public knowledge browsing, and
keyword search. Local repositories remain available only for deterministic
tests and offline demo fixtures.

It uses the following Dart contribution statuses:

```txt
ContributionStatus: draft, submitted, needsRevision, underReview,
curatorApproved, expertRequired, expertApproved, published, rejected, archived
```

Implemented mobile behavior:

- contributors can create API-backed drafts and submit them for backend review
- contribution fields include title, description, knowledge type, gamelan type,
  source note, contributor note, consent, and cultural sensitivity
- editable draft and needs-revision contributions can attach or remove media
  through the Laravel media API
- submitted and under-review contributions appear in the Review tab only for
  backend profiles with review-capable roles or permissions
- review detail screens render standard and expert actions from backend
  `allowed_actions`
- expert escalation and expert validation payloads are sent to backend review
  endpoints
- contribution and review detail screens can open safe read-only provenance
  timelines
- review detail screens can render backend `triage_suggestion` as
  `AI suggestion, not validated.`
- review detail screens can queue RDF publication through the backend when
  `allowed_actions` includes `publish_rdf`
- published knowledge and keyword search results load from backend APIs
- ontology and RDF publication DTO/repository contracts support the
  curator/admin publication form

Backend authorization remains the source of truth for contribution ownership,
workflow status, review permissions, expert validation, RDF publication
eligibility, cultural sensitivity, private notes, and public filtering. The
mobile app does not write RDF triples or publish content directly.

The workflow below is the target application workflow across the mobile client
and backend services.

## Workflow Goals

The workflow must:

- Accept community knowledge
- Prevent unverified content from becoming authoritative
- Support revision and discussion
- Preserve contributor attribution
- Support expert validation
- Produce traceable RDF publication

## Contribution Lifecycle

```txt
draft
  ↓
submitted
  ↓
under_review
  ↓
needs_revision OR curator_approved OR rejected
  ↓
expert_required
  ↓
expert_approved OR rejected
  ↓
published
```

## Status Definitions

| Status | Meaning |
|---|---|
| `draft` | Contribution saved but not submitted |
| `submitted` | Contribution submitted by contributor |
| `under_review` | Being reviewed by peer reviewer or curator |
| `needs_revision` | Contributor must revise |
| `curator_approved` | Curator accepts normalized content |
| `expert_required` | Requires expert validation |
| `expert_approved` | Expert validates content |
| `published` | Published to public knowledge graph |
| `rejected` | Rejected with reason |
| `archived` | No longer active |

## Schema Foundation

The relational schema now stores workflow truth for contributions, versions, relations, reviews, expert validations, media metadata, provenance records, RDF publication records, ontology mappings, audit logs, notifications, idempotency records, and AI triage suggestions.

The contribution workflow MVP now implements draft creation, owner-only draft updates, draft submission, draft archiving, safe status metadata, idempotent create/submit behavior, and consent-aware media upload/removal for editable drafts. Review queues, curator decisions, expert validation actions, centralized provenance/versioning, safe trace timelines, audit logging, manual RDF publication for validated non-sensitive contributions, semantic search, and optional rule-based AI triage suggestions are also implemented.

## Media Attachment Workflow

Contributors may upload or remove media only on their own `draft` or `needs_revision` contributions. Media attachments preserve consent, visibility, cultural sensitivity, credit, license, creator, recording context, and related-entity labels as candidate evidence for review.

Media visibility does not publish a file. `public` visibility means the asset may become publishable later after validation; restricted and sensitive assets remain protected from public API URLs.

## Role Permissions

| Action | Contributor | Peer Reviewer | Curator | Expert | Admin |
|---|---:|---:|---:|---:|---:|
| Create draft | Yes | Yes | Yes | Yes | Yes |
| Submit contribution | Yes | Yes | Yes | Yes | Yes |
| Edit own draft | Yes | Yes | Yes | Yes | Yes |
| Review submitted item | No | Yes | Yes | Limited | Yes |
| Request revision | No | Yes | Yes | Yes | Yes |
| Approve for curation | No | No | Yes | No | Yes |
| Expert validate | No | No | No | Yes | Yes |
| Publish RDF | No | No | Yes | No | Yes |
| Manage users | No | No | No | No | Yes |

## Validation Rules

A contribution may be published only if:

1. Required fields are complete.
2. Cultural sensitivity is assessed.
3. Duplicate check is completed.
4. Curator review is approved.
5. Expert validation is completed if required.
6. Ontology mapping is valid.
7. Provenance record is created.
8. RDF publication job succeeds.

## Expert Validation Required When

Expert validation is required for:

- sacred or restricted knowledge
- ritual-specific content
- historical claims
- disputed terminology
- claims about origin
- sensitive community practice
- high-impact corrections
- content flagged by curator

## Implemented Review Behavior

- Peer reviewers may record approve and reject recommendations for non-sensitive submitted or under-review contributions, but those decisions do not final-approve or final-reject content.
- Peer reviewers may request revision, moving a contribution to `needs_revision`.
- Curators and admins may approve, reject, request revision, or mark expert validation required.
- Curator approval of culturally sensitive content moves the contribution to `expert_required`.
- Experts and admins may validate only `expert_required` contributions.
- Contributors cannot review, approve, reject, or validate their own submissions.
- Review and expert validation actions create provenance and audit records.
- Contribution owners and authorized review roles can retrieve safe provenance/version timelines without exposing private notes, reviewer or expert identities to contributors, media storage paths, or operational audit internals.
- The Flutter mobile review detail screen now renders standard and expert action groups directly from backend `allowed_actions`, opening dedicated dialogs for expert escalation and expert validation.
- The Flutter mobile review detail screen also shows backend `triage_suggestion`
  data as a review-only helper card, and contribution/review detail screens can
  open the safe provenance timeline route for version and provenance history.
- Contributor-facing contribution detail screens do not render reviewer notes or private expert notes. The expert validation dialog is the only mobile UI surface that accepts a private note.

## Implemented RDF Publication Behavior

- Curators and admins may manually queue RDF publication through `POST /api/v1/contributions/{uuid}/rdf-publications`.
- Publication requires `curator_approved` or `expert_approved` status.
- The publisher cannot be the original contributor.
- Culturally sensitive contributions are blocked from the public RDF graph in MVP 7.
- Queued publication creates an approved ontology mapping, a pending RDF publication record, and `rdf_publication_queued` provenance.
- Successful jobs insert into `graph/published` and `graph/provenance`, create or update the published ontology entity and knowledge item, mark the contribution as `published`, and record `rdf_publication_published`.
- Failed jobs record `rdf_publication_failed`, keep the contribution unpublished, and store only a sanitized failure message.

## AI Triage Role

AI may produce:

- duplicate candidates
- suggested entity type
- suggested ontology class
- suggested relation
- possible missing metadata
- language/spelling normalization suggestion

AI output must be shown as suggestion, not decision.

Implemented MVP 9 triage runs as `RunContributionTriageJob` after successful submission when `AI_TRIAGE_ENABLED=true`. It uses local rule-based preprocessing only, stores `triage_results`, mirrors the latest `contributions.ai_*` fields, records `ai_triage_suggested` provenance/audit metadata, and never changes workflow status or publishes knowledge. The mobile client only displays the suggestion on review-capable screens and never on contributor-facing views.
