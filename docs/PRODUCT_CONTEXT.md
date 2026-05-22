# Product Context

## Project Name

Mobile-Based Balinese Gamelan Knowledge Management Application

Alternative research-oriented title:

```txt
Crowdsourced Knowledge Curation of Balinese Gamelan via an Ontology-Enabled Mobile Platform
```

## Background

Balinese gamelan knowledge is often distributed across practitioners, elders, communities, recordings, written documentation, teaching materials, and local archives.

Much of this knowledge is contextual and relationship-based:

- Which instruments belong to an ensemble
- Which techniques are used in a composition
- Which composition is associated with a performance context
- Which region or community maintains a certain tradition
- Which practitioner, group, or source contributed a piece of knowledge

A normal database can store records, but it is weak at representing rich semantic relationships. This project therefore combines a mobile application, a backend curation workflow, and an RDF/OWL ontology.

## Current Product State

The current repository is a backend-connected Flutter MVP for this product. It
implements a Material 3 mobile shell with Laravel API workflows for the main
product areas:

- Home, Search, Contribute, Review, and Profile tabs
- backend registration/login/logout wiring with secure access-token storage
- `/me` profile loading and role-aware Review tab gating
- API-backed contribution listing, draft creation, submission, and status display
- API-backed media attachment and removal for editable contribution drafts
- API-backed review queue and curator/reviewer decision actions
- API-backed published knowledge browse and keyword search
- mobile UX validation with backend field errors and conflict handling

The current app does not yet provide RDF publication UI, provenance and version
screens, semantic-search fallback UI, full offline sync, offline media upload
queues, encrypted sensitive draft storage, mobile expert-validation-specific
flows, or AI triage presentation beyond API-provided suggestions. Those remain
target capabilities.

## Goals

The application aims to:

1. Preserve Balinese gamelan knowledge digitally.
2. Support community-based contribution and correction.
3. Enable curator and expert validation.
4. Represent validated knowledge in an ontology/knowledge graph.
5. Provide semantic search and exploration through mobile access.
6. Maintain provenance and version history.
7. Support learning, discovery, and long-term cultural documentation.

## Non-Goals

This project does not aim to:

- Replace cultural experts.
- Automate cultural authority using AI.
- Build a general music streaming platform.
- Digitize every Balinese cultural domain at once.
- Train new machine learning models in the MVP.
- Provide financial incentives for contributors in the initial scope.

## Target Users

| User Type | Description |
|---|---|
| General Public | Users who want to learn about Balinese gamelan |
| Students | Learners exploring instruments, ensembles, and terms |
| Practitioners | People with lived knowledge of gamelan practice |
| Contributors | Users submitting knowledge, corrections, or media |
| Curators | Users who normalize and verify submissions |
| Experts | Cultural or academic validators |
| Admins | System managers |

## Target MVP Features

The full target MVP must include:

- User registration/login
- Knowledge browsing
- Semantic search
- Contribution submission
- Media attachment
- Review workflow
- Curator validation
- Expert validation marker
- RDF triple generation after approval
- SPARQL-backed semantic query
- Provenance tracking
- Basic offline draft support
- SUS and task-based usability evaluation readiness

The current local Flutter MVP implements only a safe subset of this target. It
demonstrates contribution, review, and knowledge-browsing workflows without
claiming backend persistence, semantic publication, or cultural authority.

## Success Criteria

Functional success:

- Users can submit gamelan knowledge through mobile.
- Curators can review, revise, approve, or reject submissions.
- Approved knowledge can be represented as RDF triples.
- Users can search semantically, not only by keyword.
- Provenance remains traceable.

Research/evaluation success:

- Ontology passes expert review.
- Ontology quality issues are checked with tools such as OOPS!.
- SPARQL competency questions can be answered.
- Usability testing achieves SUS score target of at least 70.
- Core query response time target is below 2 seconds for common mobile use cases.
