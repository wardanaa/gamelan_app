# Accessibility and UX Guide

This document defines mobile UX and accessibility standards.

## Current Implementation

The current UI is a placeholder scaffold using Material widgets. Existing
screens mostly contain an `AppBar` and centered text for the feature area.

The standards below define the target UX as the app moves from scaffold screens
to real contribution, browsing, review, and admin workflows.

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

Target main tabs:

```txt
Home
Search
Contribute
Saved
Profile
```

Curator/expert roles may see:

```txt
Review Queue
Validation
```

## Core Screens

Current screens exist as placeholders for contribution list/detail/form/status,
knowledge entity list/detail, review queue/detail/decision, authentication, user
management, and audit logs.

| Screen | Purpose |
|---|---|
| Home | Highlight knowledge, recently added items, categories |
| Search | Keyword and semantic search |
| Knowledge Detail | Entity details, relations, media, sources |
| Contribution Form | Submit or edit knowledge |
| Review Queue | Curator/expert review list |
| Review Detail | Review contribution, media, AI suggestion |
| Profile | User info and contribution status |
| Settings | Language, accessibility, account |

## Contribution UX

Contribution form should be broken into steps:

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
