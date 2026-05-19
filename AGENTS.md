# AGENTS.md

This repository contains a mobile-based Balinese gamelan knowledge management application.

The current repository is a Flutter application scaffold. It already contains
feature folders and placeholder screens for authentication, contributions,
knowledge browsing, review, and administration. Backend, database, RDF/OWL,
SPARQL, offline sync, media upload, and AI triage capabilities are target
architecture unless corresponding code or infrastructure is added later.

The target system combines:

- Flutter/Dart mobile frontend
- Laravel REST API backend
- MySQL or PostgreSQL relational database
- Apache Jena Fuseki or compatible SPARQL endpoint
- RDF/OWL ontology modeled using Methontology and Protégé
- Community-based crowdsourcing
- Curator and expert validation
- Provenance and versioning
- AI-assisted preprocessing/triage only

## Required Reading Before Making Changes

Before modifying mobile app code, read:

- `docs/PRODUCT_CONTEXT.md`
- `docs/MOBILE_APP_GUIDE.md`
- `docs/API_CONTRACT.md`
- `docs/OFFLINE_SYNC.md`
- `docs/ACCESSIBILITY_UX.md`
- `docs/CODE_STYLE.md`

Before modifying backend code, read:

- `docs/ARCHITECTURE.md`
- `docs/BACKEND_GUIDE.md`
- `docs/API_CONTRACT.md`
- `docs/DATA_MODEL.md`
- `docs/CROWDSOURCING_WORKFLOW.md`
- `docs/SECURITY_PRIVACY.md`
- `docs/CODE_STYLE.md`

Before modifying ontology, semantic search, RDF, SPARQL, or triplestore integration, read:

- `docs/KNOWLEDGE_MODEL.md`
- `docs/ONTOLOGY_GUIDE.md`
- `docs/SPARQL_GUIDE.md`
- `docs/PROVENANCE_VERSIONING.md`
- `docs/AI_TRIAGE_GUIDE.md`

Before modifying validation, review, or testing logic, read:

- `docs/CROWDSOURCING_WORKFLOW.md`
- `docs/EVALUATION_QA.md`
- `docs/SECURITY_PRIVACY.md`

## Core Project Scope

The project focuses on traditional Balinese gamelan knowledge.

Initial domain focus:

- Gong Kebyar
- Gong Gede

The system may later support other Balinese gamelan types, but new domains must not be added casually without extending the ontology, validation workflow, and content taxonomy.

## Current Implementation Snapshot

Current Flutter implementation:

- `GamelanApp` uses Material 3.
- The app starts at `ContributionListScreen`.
- Feature folders exist under `lib/features/` for `auth`, `contributions`, `knowledge`, `review`, and `admin`.
- `lib/core/api/` contains a lightweight API client and auth header helper.
- `lib/core/constants/api_endpoints.dart` defines endpoint constants for auth, contributions, reviews, knowledge, audit logs, and users.
- Repositories are placeholders and do not perform real network requests yet.
- `TokenStorage` is in-memory development scaffolding and is not production secure storage.

When updating documentation, keep this current state separate from target
architecture requirements.

## Main Roles

| Role | Responsibility |
|---|---|
| Guest | Browse published knowledge |
| Registered User | Save bookmarks and submit contributions |
| Contributor | Submit new knowledge items, media, notes, and corrections |
| Peer Reviewer | Review community submissions |
| Curator | Normalize, approve, reject, or request revisions |
| Expert Validator | Validate culturally sensitive or authoritative knowledge |
| Admin | Manage users, roles, settings, and system operations |

## AI Usage Boundary

AI may be used only for:

- Draft classification
- Entity suggestion
- Duplicate detection
- Metadata suggestion
- Spelling/normalization support
- Triage scoring
- Summarization for curator review

AI must not:

- Publish knowledge automatically
- Replace curator or expert validation
- Invent cultural facts
- Generate final RDF triples without human review
- Train new models unless explicitly approved
- Override community or expert consensus

## Engineering Rules

1. Do not bypass the contribution review workflow.
2. Do not publish crowdsourced content directly into the public knowledge graph without validation.
3. Do not treat AI output as authoritative cultural knowledge.
4. Preserve provenance for every contribution, edit, validation, RDF triple, and media asset.
5. Keep mobile UI usable for non-technical community contributors.
6. Keep ontology terms stable once published.
7. Use explicit status transitions for content workflow.
8. Validate user input on both mobile and backend.
9. Protect personal data of contributors, practitioners, elders, and experts.
10. Keep REST API responses consistent.
11. Keep SPARQL queries readable and documented.
12. Do not add new entities or relations without checking `docs/KNOWLEDGE_MODEL.md` and `docs/ONTOLOGY_GUIDE.md`.
13. Do not expose unpublished, rejected, or sensitive cultural knowledge through public APIs.
14. Prefer small, reviewable changes over sweeping rewrites.

## Expected AI Response Format

When proposing code or architecture changes, answer with:

1. Problem summary
2. Assumptions
3. Affected files/modules
4. Proposed approach
5. Code or schema changes
6. Security and privacy notes
7. Ontology/provenance impact
8. Test checklist

## Naming Prefixes

Use project-safe prefixes.

Suggested:

```txt
gamelan_
kg_
ontology_
curation_
```

For API routes:

```txt
/api/v1/contributions
/api/v1/knowledge-items
/api/v1/reviews
/api/v1/ontology
/api/v1/search
```

For RDF namespace examples:

```txt
https://example.org/gamelan#
```

Replace the example namespace with the official project namespace before production.
