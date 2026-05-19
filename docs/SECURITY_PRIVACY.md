# Security and Privacy Guide

This document defines security, privacy, and cultural sensitivity rules.

## Current Implementation

The current Flutter scaffold has an in-memory `TokenStorage` placeholder and an
`AuthInterceptor` helper for attaching bearer tokens. It does not yet implement
real login, secure token storage, backend authorization, media access control,
SPARQL restrictions, or AI prompt logging controls.

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

The current in-memory token storage must be replaced before real authentication
or production builds use access tokens.

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
