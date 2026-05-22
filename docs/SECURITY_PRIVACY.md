# Security and Privacy Guide

This document defines security, privacy, and cultural sensitivity rules.

## Current Implementation

The current Flutter MVP uses repository-backed local state with limited draft
persistence:

- `GamelanMvpStore` coordinates UI-facing state.
- Local contribution, review, and knowledge repositories hold the current demo
  data and workflow mutations.
- `ContributionDraftStorage` uses `shared_preferences` to persist only
  non-sensitive local drafts.
- `TokenStorage` uses `flutter_secure_storage` for access-token persistence.
- `AuthRepository` performs backend registration, login, logout, and `/me`
  profile requests. The app gates the local MVP shell behind a saved or newly
  issued access token that can load an authenticated backend profile.
- Saved tokens are cleared when `/me` returns unauthenticated.
- The local Review workflow is hidden unless the backend profile includes a
  reviewer, curator, expert validator, or admin role, or a
  `review.contributions` permission.
- The contribution form requires a consent checkbox before saving or submitting.
- Contributions can be marked culturally sensitive.
- Culturally sensitive drafts are kept in session-only repository state and are
  not written to plain local draft storage.
- Draft, submitted, under-review, request-changes, and rejected contributions do
  not appear in public knowledge browsing.
- Approved local contributions appear in Search as community approved demo
  content only.

The app does not yet implement backend persistence for contribution/review data,
durable provenance storage, media access control, SPARQL restrictions, or AI
prompt logging controls. Repository-backed local state is not backend
persistence or RDF publication. Mobile role checks are convenience-only UX
gates. Backend authorization must remain authoritative for all protected
actions and data.

The requirements below apply as target security and privacy rules when those
capabilities are implemented.

## Security Principles

1. Validate all input.
2. Sanitize stored values.
3. Escape rendered output.
4. Enforce authorization on backend.
5. Protect personal and cultural data.
6. Log safely.
7. Restrict unpublished data.
8. Protect SPARQL update access.

## Authentication

Use token-based authentication for API clients.

Recommended:

- Laravel Sanctum
- bearer tokens for external API clients
- short-lived access token if supported by deployment policy
- logout token revocation
- client-side secure storage guidance in client-facing docs

Current API foundation:

- `/api/v1/auth/register` and `/api/v1/auth/login` issue Laravel Sanctum bearer tokens.
- `/api/v1/auth/logout` revokes only the current bearer token, so other signed-in devices are not logged out accidentally.
- Plain text token values are returned only once in register/login responses.
- User responses must not expose passwords, remember tokens, token model internals, stack traces, SQL errors, filesystem paths, or private profile fields.

## Authorization

Every sensitive endpoint must check:

- authenticated user
- role
- contribution ownership
- workflow status
- media visibility
- cultural sensitivity restrictions

The API is the enforcement boundary. Clients may hide unavailable actions for usability, but backend authorization must never depend on client behavior.

Current schema foundation:

- Role records and role assignments can be stored through `roles` and `role_user`.
- Private review and expert notes have dedicated fields and must not be returned through public endpoints.
- Media uploads are owner-scoped to editable contribution drafts and store consent, visibility, and cultural sensitivity metadata before review.
- Idempotency records are user-bound so contribution and media writes can be retried safely and conflict-checked.

Current review workflow:

- Peer reviewer queues exclude culturally sensitive submissions.
- Contributors cannot review, approve, reject, or validate their own submissions.
- Contributor-facing review history omits private reviewer notes, private expert notes, and reviewer or expert identity fields.
- Contribution lifecycle, review, expert validation, and media actions create audit records without storing private notes in audit metadata.

Current trace API behavior:

- Contribution owners may retrieve safe version and provenance timelines for their own contributions.
- Authorized reviewer, curator, expert, and admin users may retrieve provenance timelines only when review authorization allows access to the contribution.
- Contributor-facing trace responses hide reviewer and expert identities.
- Trace responses must not expose private notes, IP address, user agent, media storage paths, file URLs, raw AI prompts, raw AI responses, or restricted cultural details.
- Optional stale-update checks use `last_known_updated_at` only after owner authorization, so conflict responses do not reveal another user's unpublished contribution.

Current RDF publication behavior:

- only curators and admins may queue RDF publication
- the publisher cannot be the original contributor
- only `curator_approved` or `expert_approved` contributions are eligible
- culturally sensitive contributions are blocked from the public RDF graph in MVP 7
- SPARQL update credentials remain backend-only
- raw triplestore response bodies and credentials are never returned to API clients

Current published browsing and search behavior:

- public browsing and search endpoints return only published, non-sensitive `knowledge_items` linked to published, non-sensitive ontology entities
- semantic search queries only the configured published graph and reconciles returned RDF subject URIs with public relational records before returning results
- the SPARQL proxy is authenticated, curator/admin-only, and accepts predefined query keys instead of raw SPARQL
- public media metadata is returned only for public, consented, non-sensitive media linked to public knowledge items
- search, browsing, and SPARQL proxy responses must not expose storage paths, file URLs, private notes, raw triplestore errors, credentials, raw AI output, or unpublished contribution details

## Personal Data

Protect:

- contributor name
- phone/email
- practitioner identity
- expert identity if private
- elder/community source identity
- location metadata if sensitive
- private notes

## Cultural Sensitivity

Restricted content must not be exposed through:

- public API
- search endpoint
- SPARQL endpoint
- client sync payload
- media URL
- logs
- AI prompt logs

Current media upload behavior:

- media files are stored on a private configured disk
- media API responses return safe metadata only
- media API responses do not return `file_path`, `storage_disk`, or `file_url`
- `public` media visibility is future publishability metadata and does not expose the asset before validation and publication

Current AI triage behavior:

- MVP 9 triage is local rule-based preprocessing only
- triage is disabled by default through `AI_TRIAGE_ENABLED=false`
- no submitted content is sent to external AI providers in this MVP
- raw prompts and raw AI responses are not stored or logged
- triage suggestions are exposed only to authorized non-owner review roles
- triage output never approves, validates, publishes, or overrides human decisions

## SPARQL Security

Public users should not execute arbitrary SPARQL.

SPARQL update endpoint must never be exposed publicly.

Use backend service credentials and network restrictions.

Only validated, approved, publishable knowledge may be exposed through SPARQL-backed API responses.

RDF publication writes only through backend jobs using configured SPARQL update credentials. Public users and external clients must use REST browsing/search endpoints instead of arbitrary SPARQL update access.

## Rate Limiting

Apply rate limits to:

- login
- registration
- contribution submission
- media upload
- search
- AI triage
- SPARQL proxy

## Deployment Readiness Security

`php artisan gamelan:deployment-check` is safe to run in local, staging, and production shells. It reports configuration status without printing secret values, bearer tokens, SPARQL credentials, raw triplestore responses, private notes, media paths, user data, or restricted cultural detail.

Staging and production must not use `MEDIA_DISK=public` for workflow media. SPARQL update credentials must remain backend-only, and public clients must continue using REST browsing/search endpoints instead of direct triplestore access.
