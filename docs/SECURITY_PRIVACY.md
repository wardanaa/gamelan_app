# Security and Privacy Guide

This document defines security, privacy, and cultural sensitivity rules.

## Current Implementation

The current Flutter MVP uses local state with limited draft persistence:

- `GamelanMvpStore` holds seeded knowledge and local contributions.
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
- Culturally sensitive drafts are kept in memory only and are not written to
  plain local draft storage.
- Draft, submitted, under-review, request-changes, and rejected contributions do
  not appear in public knowledge browsing.
- Approved local contributions appear in Search as community approved demo
  content only.

The app does not yet implement backend persistence for contribution/review data,
media access control, SPARQL restrictions, or AI prompt logging controls. Mobile
role checks are convenience-only UX gates. Backend authorization must remain
authoritative for all protected actions and data.

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

Use token-based authentication for mobile API.

Recommended:

- Laravel Sanctum
- short-lived access token if supported
- secure storage on device
- logout token revocation

The current mobile app stores access tokens in secure device storage and clears
them on logout or when `/me` reports an unauthenticated session. Registration
and login require a backend token response at `data.access_token`, followed by a
successful `/me` profile load before entering the app shell.

The current MVP profile labels and local UI gating are convenience only. They do
not enforce authorization.

## Authorization

Every sensitive endpoint must check:

- authenticated user
- role
- contribution ownership
- workflow status
- media visibility
- cultural sensitivity restrictions

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

In the current MVP, cultural sensitivity is a local UI and review marker only.
It is not backed by durable authorization, encrypted storage, media access
control, or backend policy checks. Because encrypted draft storage and clear
product rules are not implemented yet, culturally sensitive drafts must remain
session-only.

Restricted content must not be exposed through:

- public API
- search endpoint
- SPARQL endpoint
- mobile cache
- media URL
- logs
- AI prompt logs

## SPARQL Security

Public users should not execute arbitrary SPARQL.

SPARQL update endpoint must never be exposed publicly.

Use backend service credentials and network restrictions.

## Rate Limiting

Apply rate limits to:

- login
- registration
- contribution submission
- media upload
- search
- AI triage
- SPARQL proxy
