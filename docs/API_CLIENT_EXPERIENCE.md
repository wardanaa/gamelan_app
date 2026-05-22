# API Client Experience Guide

This document defines API response expectations that help external clients provide clear, accessible, and respectful user experiences.

This repository does not own mobile or web UI implementation. It owns the API data, error messages, metadata, and authorization signals that clients need to render reliable interfaces.

## Experience Principles

API responses should support users such as:

- community contributors
- students
- practitioners
- curators
- cultural experts
- users with limited technical experience

Responses should be clear, respectful, and safe to display.

## Client-Facing Messages

Use explicit messages that explain the user-facing condition without exposing internals.

Bad:

```txt
Invalid transition.
```

Good:

```txt
This contribution cannot be edited because it is already under curator review.
```

Messages should be suitable for translation and should not reveal private review notes, server paths, SQL errors, stack traces, or restricted cultural content.

## Validation Errors

Validation responses should include field-level errors.

Recommended shape:

```json
{
  "success": false,
  "message": "Validation failed.",
  "errors": {
    "title": ["The title field is required."],
    "source_note": ["A source note is required before submission."]
  }
}
```

Clients should be able to associate each error with the relevant input field.

Authentication and routing errors use the same envelope so clients can handle them consistently:

```json
{
  "success": false,
  "message": "Unauthenticated.",
  "errors": {}
}
```

The API currently standardizes JSON envelopes for validation, unauthenticated, forbidden, not found, rate limited, and server error responses under `/api/v1`.

## Status Metadata

Where useful, the API may return client-safe status metadata:

```json
{
  "status": "needs_revision",
  "status_label": "Needs revision",
  "status_description": "The curator requested changes before this contribution can continue."
}
```

Clients may localize labels, but workflow decisions must use stable status values.

## Authorized Actions

For workflow-heavy responses, the API should expose allowed actions based on the authenticated user, role, and contribution status.

Example:

```json
{
  "allowed_actions": [
    "edit",
    "submit",
    "delete"
  ]
}
```

Clients should not hard-code permissions from role names alone.

The review workflow now returns role-aware allowed actions for authorized reviewer, curator, expert, and admin clients. Contributor-facing review history may include public notes and decisions, but must omit private notes and reviewer or expert identity fields.

Optional MVP 9 triage suggestions may appear in authorized non-owner review responses as `triage_suggestion`. Clients must display the included label, `AI suggestion, not validated.`, and present the data as curator assistance rather than a decision.

The RDF publication workflow may return `publish_rdf` for eligible curator/admin clients. Publication requests return `202 Accepted` when queued. Failed publication attempts use safe messages and do not expose SPARQL credentials, raw triplestore responses, or restricted cultural detail.

Published knowledge browsing and search responses are public but filtered. Clients should expect draft, rejected, unpublished, deprecated, removed, private, and culturally sensitive records to be absent or returned as `404`.

Contribution draft updates may return `409 Conflict` when an offline-capable client sends a stale `last_known_updated_at` marker. The message is safe to display: `This contribution has changed since you last loaded it. Please refresh and try again.` Clients should refresh the draft before asking the user to reapply local edits.

## Trace Timelines

Contribution detail screens may use provenance and version endpoints to show workflow history:

```txt
GET /api/v1/contributions/{uuid}/versions
GET /api/v1/contributions/{uuid}/provenance
```

Review clients may use:

```txt
GET /api/v1/reviews/{uuid}/provenance
```

Trace entries are intentionally safe for display. A missing `actor` means the backend hid identity information for privacy, not that the workflow event is untraceable internally.

## Accessibility Support

The API should help clients build accessible interfaces by returning:

- clear field names
- stable status values
- readable labels where appropriate
- safe descriptions for workflow states
- media alternative text or captions when available
- language metadata for multilingual content
- structured errors instead of plain text blobs

Contribution detail and review detail responses may include `media_assets` when media metadata is loaded. These objects include safe metadata such as title, type, consent, visibility, credit, and alternative text, but never raw storage paths or URLs.

Version and provenance responses follow the same rule. They must not expose storage paths, file URLs, private notes, IP address, user agent, raw AI prompts, raw AI responses, or restricted cultural details.

The API should avoid color-only status semantics. Statuses must be understandable from text values and labels.

## Cultural Sensitivity

Client-facing responses must respect cultural sensitivity rules.

Restricted data must not be exposed through:

- public knowledge endpoints
- search endpoints
- SPARQL proxy responses
- media URLs
- sync payloads
- validation messages
- logs surfaced to clients

When content is unavailable because of sensitivity or authorization, return a safe message rather than the restricted detail.

Semantic search returns a safe `503` message when the SPARQL query endpoint is unavailable. Clients should show the condition as temporary search unavailability and may offer keyword search without implying that no cultural knowledge exists.
