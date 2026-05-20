# Further Development

This document suggests practical next steps after the current local Flutter MVP.

## Current Baseline

The current app is a local Flutter MVP. It demonstrates:

- Home, Search, Contribute, Review, and Profile tabs
- seeded Gong Kebyar and Gong Gede knowledge
- local keyword search
- local persistence for non-sensitive contribution drafts
- in-memory submitted contributions and review decisions
- local curator-style review decisions
- approved local contributions appearing in Search as community approved demo
  content
- backend login/logout/registration client wiring
- `/me` profile loading for new and restored sessions
- expired or invalid saved-token handling when `/me` returns unauthenticated
- mobile UX gating for the local Review workflow based on backend profile roles
- secure device storage for the access token

The current app does not include backend persistence for contribution/review
data, encrypted sensitive draft storage, media upload, RDF/OWL generation,
SPARQL-backed search, expert validation, or AI triage.

## Recommended Next Steps

1. Continue backend authorization integration.
   Mobile login/logout/registration, secure access-token storage, `/me` profile
   loading, invalid-token clearing, and role-aware Review UX gating are
   implemented. Next, enforce the matching Laravel policies on the backend for
   contribution ownership, review actions, admin operations, workflow status,
   and culturally sensitive data. Keep backend authorization as the source of
   truth.

2. Replace the in-memory store with repository-backed state.
   Keep the current UI flow, but move data access behind repositories that can
   switch between local demo data and API-backed data.

3. Implement Laravel API integration.
   Connect contributions, review queue, knowledge browsing, and authentication
   to the target REST contract. Mobile validation should improve UX, but backend
   validation must remain mandatory.

4. Add media metadata and upload flow.
   Start with media metadata and consent handling before enabling file upload.
   Sensitive or restricted media must not be publicly exposed by default.

5. Add role-aware review and expert validation.
   Replace demo role labels with backend roles and policies. Add a distinct
   expert-required and expert-validated path for sensitive or authoritative
   knowledge.

6. Add provenance and version records.
   Persist contributor attribution, source notes, review decisions, edit
   history, and publication state. Important edits should create version
   snapshots.

7. Add ontology mapping and RDF publication after approval.
   Approved contributions should be mapped to stable ontology classes and
   properties before any RDF publication. The mobile app must not write directly
   to the triplestore.

8. Add SPARQL-backed semantic search.
   Expose predefined semantic search endpoints through the backend. Public users
   should not run arbitrary SPARQL.

9. Add AI triage as suggestions only.
   AI may suggest entity types, relations, duplicates, metadata, or summaries
   for curator review. AI must not publish knowledge, validate cultural claims,
   invent sources, or generate final RDF triples without human approval.

## Suggested Acceptance Criteria

- Non-sensitive drafts survive app restart without exposing sensitive data.
- Authenticated users can submit contributions through the Laravel API.
- Curators can approve, reject, or request revisions with persisted review
  notes.
- Sensitive contributions require explicit review and can trigger expert
  validation.
- Approved content has traceable provenance before it appears in public search.
- RDF publication occurs only after human validation and ontology mapping.
- Semantic search excludes unpublished, rejected, and restricted knowledge.
- Widget and integration tests cover the contribution and review workflow.

## Development Priorities

Prioritize workflow correctness before semantic automation. The safest order is:

```txt
authentication and authorization
  ↓
API-backed contribution workflow
  ↓
review and provenance
  ↓
ontology mapping
  ↓
RDF publication
  ↓
SPARQL-backed search
  ↓
AI triage suggestions
```

Do not bypass curator or expert validation to accelerate publication.
