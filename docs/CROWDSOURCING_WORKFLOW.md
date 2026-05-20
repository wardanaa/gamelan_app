# Crowdsourcing Workflow

This document defines the contribution, review, curation, and validation workflow.

## Current Implementation

The Flutter app currently implements a local contribution and review
simulation. Non-sensitive drafts may persist locally; submitted, reviewed, and
sensitive contributions remain session-only. It uses the following Dart
contribution statuses:

```txt
ContributionStatus: draft, submitted, underReview, approved, rejected
```

Implemented local behavior:

- contributors can save a local draft or submit a local contribution
- non-sensitive drafts survive app restart on the same device
- contribution fields include title, description, knowledge type, gamelan type,
  source note, contributor note, consent, and cultural sensitivity
- submitted and under-review contributions appear in the local Review tab
- curator-style actions can mark under review, approve, request changes, or
  reject with a note
- approved local contributions appear in Search as community approved demo
  content
- draft, submitted, under-review, request-changes, and rejected contributions do
  not appear in public knowledge browsing

No backend workflow, role authorization, durable curation decision persistence,
expert validation, RDF publication, or durable provenance storage is implemented
yet.

The workflow below is the target application workflow.

## Workflow Goals

The workflow must:

- Accept community knowledge
- Prevent unverified content from becoming authoritative
- Support revision and discussion
- Preserve contributor attribution
- Support expert validation
- Produce traceable RDF publication

## Contribution Lifecycle

Current local MVP lifecycle:

```txt
draft
  ↓
submitted
  ↓
underReview
  ↓
approved OR rejected
```

In the current MVP, request changes is represented as `rejected` with a review
note prefixed by `Changes requested:`. This should be replaced by a dedicated
`needs_revision` state when backend workflow support is added.

Target lifecycle:

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

Current mobile statuses are intentionally simpler than the target workflow. Do
not expose target statuses in the UI until backend support exists.

| Status | Meaning |
|---|---|
| `draft` | Contribution saved but not submitted |
| `submitted` | Contribution submitted by contributor |
| `underReview` | Being reviewed by peer reviewer or curator in the local MVP |
| `approved` | Approved in the local MVP; appears in Search as demo content |
| `rejected` | Rejected or changes requested in the local MVP |
| `under_review` | Target backend status for active review |
| `needs_revision` | Contributor must revise |
| `curator_approved` | Curator accepts normalized content |
| `expert_required` | Requires expert validation |
| `expert_approved` | Expert validates content |
| `published` | Published to public knowledge graph |
| `rejected` | Rejected with reason |
| `archived` | No longer active |

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

## AI Triage Role

AI may produce:

- duplicate candidates
- suggested entity type
- suggested ontology class
- suggested relation
- possible missing metadata
- language/spelling normalization suggestion

AI output must be shown as suggestion, not decision.
