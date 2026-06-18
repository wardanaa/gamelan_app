# Accessibility and UX Guide

This document defines mobile UX and accessibility standards.

## Current Implementation

The current UI is a backend-connected Material 3 mobile MVP using a
bottom-navigation shell.
Implemented tabs are:

- Home
- Search
- Contribute
- Review
- Profile

The app now gates the mobile shell behind backend authentication. Registration,
login, `/me` profile loading, and logout are wired to the configured API. The
Search and Contribute tabs use backend repositories in production wiring. The
Review tab shows review workflows only when the backend profile has a reviewer,
curator, expert validator, or admin role, and individual review actions are
driven by backend `allowed_actions`. Admin screens remain scaffold-level
placeholders.

## UX Principles

The app must be usable by:

- community contributors
- students
- practitioners
- curators
- cultural experts
- users with limited technical experience

The app should feel respectful, clear, and calm.

## Navigation

Current MVP tabs:

```txt
Home
Search
Contribute
Review
Profile
```

Target future tabs may add:

```txt
Saved
Validation
Settings
```

## Core Screens

Current MVP screens include backend-connected contribution list/detail/form/status,
online media upload/removal, knowledge list/detail, review
queue/detail/decision screens, expert workflow dialogs, provenance timelines,
and backend authentication. User management and audit logs are still
placeholders.

| Screen | Purpose |
|---|---|
| Home | Highlight knowledge, recently added items, categories |
| Search | Backend keyword search over published, non-sensitive knowledge |
| Knowledge Detail | Entity details, relations, source summary, provenance summary |
| Contribution Form | Save API-backed draft or submit for backend review |
| Review Queue | Backend-authorized review list |
| Review Detail | Review contribution, source note, sensitivity, and decision actions |
| Profile | Backend profile label, backend roles, privacy boundary, and ontology boundary |
| Settings | Language, accessibility, account |
| Login | Backend sign-in and registration with clear validation and error messaging |

## Contribution UX

The current MVP contribution form is a single scrolling form. It includes:

- title
- description
- knowledge type
- gamelan type
- source note
- contributor note
- cultural sensitivity flag
- contributor consent checkbox
- save draft
- submit for review

As the form grows, it should be broken into steps:

1. Basic information
2. Knowledge classification
3. Description/source
4. Related entities
5. Media attachments
6. Review and submit

## Status Messaging

Use clear messages.

Bad:

```txt
Invalid transition.
```

Good:

```txt
This contribution cannot be edited because it is already under curator review.
```

## Accessibility Requirements

Minimum:

- tap targets at least 44x44 points
- readable text size
- high contrast
- screen reader labels
- clear focus order
- no color-only status indicators
- error messages near fields
- support for system text scaling
