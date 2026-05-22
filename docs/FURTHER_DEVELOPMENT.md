# Further Development

This document suggests practical next steps after the current local Flutter MVP.

## Current Baseline

The current app is a backend-connected Flutter MVP. It demonstrates:

- Home, Search, Contribute, Review, and Profile tabs
- backend login/logout/registration client wiring
- `/me` profile loading for new and restored sessions
- expired or invalid saved-token handling when `/me` returns unauthenticated
- secure device storage for the access token
- Laravel API-backed contributions, contribution media upload/removal, review
  queue, and knowledge browse/search
- API-only contribution drafts in production wiring
- mobile UX validation with backend `422` and `409` error handling
- role-aware Review tab gating from backend profile roles
- repository interfaces with remote production implementations and local test
  implementations

The current app does not include RDF publication UI, provenance and version
screens, semantic-search fallback UI, encrypted sensitive draft storage, full
offline sync, offline media upload queues, expert-validation-specific mobile
flows, or AI triage display beyond API-provided suggestions.

## Recommended Next Steps

1. Continue backend authorization integration.
   Mobile login/logout/registration, secure access-token storage, `/me` profile
   loading, invalid-token clearing, and role-aware Review UX gating are
   implemented. Next, enforce the matching Laravel policies on the backend for
   contribution ownership, review actions, admin operations, workflow status,
   and culturally sensitive data. Keep backend authorization as the source of
   truth.

2. Replace the in-memory store with repository-backed state. Implemented.
   `GamelanMvpStore` coordinates UI-facing state while contribution, review,
   and knowledge data access lives behind repository interfaces.

3. Implement Laravel API integration. Implemented for authentication,
   contributions, review queue actions, and public knowledge browse/search.
   Production wiring uses remote repositories with API-only drafts. Mobile
   validation improves UX, but backend validation remains mandatory. Next mobile
   follow-up: broader live integration coverage and conflict-resolution UI for
   concurrent edits.

4. Add media metadata and upload flow. Implemented for online editable drafts.
   Contributors can attach media with consent, visibility, sensitivity, and
   descriptive metadata through the Laravel API, then remove attachments before
   submission. Sensitive or restricted media is not publicly exposed by default.
   Offline media upload queues remain future work.

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
authentication, authorization, and repository-backed local state
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
