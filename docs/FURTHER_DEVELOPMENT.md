# Further Development

This document tracks practical next steps after the current Flutter mobile
client MVP. The MVP scope in this repository is the mobile client; Laravel
authorization, workflow persistence, RDF publication jobs, triplestore
configuration, and deployment remain backend-owned capabilities even when the
mobile app consumes their API contracts.

## Current Baseline

The current app is a backend-connected Flutter MVP. It demonstrates:

- Home, Search, Contribute, Review, and Profile tabs
- backend login/logout/registration client wiring
- `/me` profile loading for new and restored sessions
- live integration verification of `/me` roles/permissions
- opt-in live reviewer workflow integration coverage that exercises queue
  navigation, provenance, expert escalation, and expert validation against a
  configured Laravel backend
- remote review repository methods now cover expert-required and expert-validation payloads
- expired or invalid saved-token handling when `/me` returns unauthenticated
- secure device storage for the access token
- Laravel API-backed contributions, contribution media upload/removal, review
  queue, and knowledge browse/search
- review detail screens now render standard and expert action groups from
  backend `allowed_actions`, with dedicated dialogs for expert escalation and
  validation
- contribution and review detail screens now open a safe, read-only provenance
  timeline route backed by Laravel trace endpoints
- review detail screens now render backend `triage_suggestion` payloads as a
  review-only helper card labeled `AI suggestion, not validated.`
- API-only contribution drafts in production wiring
- mobile UX validation with backend `422` and `409` error handling
- role-aware Review tab gating from backend profile roles
- repository interfaces with remote production implementations and local test
  implementations
- ontology DTOs and repository access for classes, properties, entities, and
  RDF publication lookup/queueing

The current app does not include curator-facing RDF publication UI,
semantic-search fallback UI, encrypted sensitive draft storage, full offline
sync, offline media upload queues, richer stale-update conflict resolution UI,
production admin screens, or broader offline-first expert-validation flows.

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

5. Add role-aware review and expert validation UI.
   Implemented. The mobile data/repository contract is aligned with backend
   expert workflow endpoints, and the review detail screen now builds its
   action groups from `allowed_actions` while keeping client-side role-based
   authorization out of the widget layer.

6. Add provenance and version records.
   Implemented in the mobile client as safe read-only timelines backed by the
   Laravel trace endpoints. Remaining work is backend publication and any
   future write-side audit expansion.

7. Add ontology mapping and RDF publication after approval.
   Approved contributions should be mapped to stable ontology classes and
   properties before any RDF publication. The mobile DTO and repository layers
   for ontology mapping and RDF publication are now implemented; backend
   contract verification and future curator/admin UI wiring remain the
   remaining phases. The mobile app must not write directly to the triplestore,
   and backend authorization remains the source of truth for publication
   eligibility.

8. Add SPARQL-backed semantic search.
   Expose predefined semantic search endpoints through the backend. Public users
   should not run arbitrary SPARQL. Mobile follow-up work should add explicit
   semantic-search UI and a safe fallback to keyword search when the backend
   reports semantic search as unavailable.

9. Add AI triage as suggestions only.
   AI may suggest entity types, relations, duplicates, metadata, or summaries
   for curator review. AI must not publish knowledge, validate cultural claims,
   invent sources, or generate final RDF triples without human approval. The
   mobile app already renders backend triage suggestions as review-only helper
   cards and keeps them out of contributor-facing screens.

## Suggested Acceptance Criteria

- Non-sensitive drafts survive app restart without exposing sensitive data.
- Authenticated users can submit contributions through the Laravel API.
- Curators can approve, reject, or request revisions with persisted review
  notes.
- Sensitive contributions require explicit review and can trigger expert
  validation.
- Review screens render backend-driven standard and expert action groups.
- Approved content has traceable provenance before it appears in public search.
- RDF publication occurs only after human validation, ontology mapping, and
  backend authorization.
- Semantic search excludes unpublished, rejected, and restricted knowledge and
  falls back clearly when semantic search is unavailable.
- Widget and integration tests cover the contribution and review workflow,
  provenance timeline safety, triage visibility, and shared expert status
  presentation.

## Testing Status

Phase 5 test-hardening is implemented. The repo now keeps the auth smoke test
separate from the live reviewer workflow test, so auth/profile verification
stays fast while the review-specific integration path can use reviewer
credentials and a target UUID when available. The deterministic Flutter test
suite currently covers the mobile repository, widget, provenance, review,
ontology, and RDF publication DTO/repository contracts.

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
