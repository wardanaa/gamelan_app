# Documentation Index

This folder contains documentation for the Laravel REST API backend for a Balinese gamelan knowledge management platform.

## Current Implementation Status

The repository currently contains a local Flutter MVP at the project root. The
implemented mobile app has backend login/logout wiring, secure access-token
storage, and a Material 3 bottom-navigation shell with Home, Search,
Contribute, Review, and Profile tabs after sign-in.

Implemented local MVP behavior includes:

- seeded Gong Kebyar and Gong Gede knowledge browsing
- keyword search over local knowledge records and relation labels
- a local contribution form with consent and cultural sensitivity fields
- local draft, submitted, under review, approved, and rejected statuses
- local persistence for non-sensitive contribution drafts
- backend email/password login and logout requests
- secure device storage for the backend access token
- a curator-style local review queue
- approval flow that exposes approved local contributions in Search as
  community approved demo content

This MVP uses `GamelanMvpStore` and `GamelanScope` for UI-facing local state,
with contribution, review, and knowledge data behind local repository
implementations. Non-sensitive draft contributions are persisted with
`shared_preferences` so they can survive app restart on the same device. Access
tokens are stored separately with `flutter_secure_storage`. Sensitive drafts,
submitted items, review decisions, and approved demo content remain session-only.

The Laravel backend, relational database, RDF/OWL ontology files, Fuseki/SPARQL
integration, media storage, full offline sync, encrypted sensitive draft
storage, and AI triage pipeline are documented as target architecture unless
corresponding implementation appears in the repository.

## Documentation Map

| File | Purpose |
|---|---|
| `PRODUCT_CONTEXT.md` | Project background, goals, scope, and users |
| `FURTHER_DEVELOPMENT.md` | MVP-focused backend development roadmap and next-step backlog |
| `ARCHITECTURE.md` | System architecture and module boundaries |
| `BACKEND_GUIDE.md` | Laravel backend development guide |
| `API_CONTRACT.md` | REST API standards and endpoint examples |
| `API_CLIENT_GUIDE.md` | API client contract expectations for mobile, web, or other consumers |
| `API_CLIENT_EXPERIENCE.md` | Client-facing response, validation, and accessibility support |
| `DATA_MODEL.md` | Relational database model and workflow tables |
| `KNOWLEDGE_MODEL.md` | Domain concepts, entities, and relations |
| `ONTOLOGY_GUIDE.md` | RDF/OWL ontology modeling guide |
| `SPARQL_GUIDE.md` | SPARQL query and triplestore guide |
| `CROWDSOURCING_WORKFLOW.md` | Contribution, review, curation, and validation flow |
| `PROVENANCE_VERSIONING.md` | Provenance, audit trail, and versioning rules |
| `AI_TRIAGE_GUIDE.md` | Safe AI-assisted preprocessing rules |
| `MEDIA_ASSET_GUIDE.md` | Audio, image, video, document, and metadata rules |
| `SYNC_IDEMPOTENCY_GUIDE.md` | Retry-safe sync, idempotency, and offline-capable client support |
| `SECURITY_PRIVACY.md` | Security, privacy, and cultural sensitivity rules |
| `EVALUATION_QA.md` | Research and software evaluation plan |
| `CODE_STYLE.md` | Naming, formatting, and coding standards |
| `DEPLOYMENT.md` | Deployment, environment, and release workflow |

## Main Principle

This project is not just a CRUD API.

It is a cultural knowledge management system with a semantic layer, validation workflow, and community participation. Code changes must protect cultural accuracy, provenance, and long-term knowledge usability.

## Default Stack

| Layer | Recommended Stack |
|---|---|
| Backend | Laravel / PHP |
| API Clients | Flutter mobile app, web app, or other authorized clients |
| Database | MySQL or PostgreSQL |
| Semantic Store | Apache Jena Fuseki or compatible triplestore |
| Ontology Editing | Protégé |
| Ontology Method | Methontology |
| Semantic Query | SPARQL |
| Media Storage | Local storage, S3-compatible storage, or institutional server |
| AI Assistance | External LLM for triage only |

## Primary Knowledge Scope

Initial focus:

- Traditional Balinese gamelan
- Gong Kebyar
- Gong Gede
- Instruments
- Ensembles
- Compositions
- Performance contexts
- Techniques
- Practitioners
- Places
- Media documentation
- Terminology
