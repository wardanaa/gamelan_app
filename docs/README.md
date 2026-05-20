# Documentation Index

This folder contains documentation for the mobile-based Balinese gamelan knowledge management application.

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

This MVP uses `GamelanMvpStore` and `GamelanScope` for local state.
Non-sensitive draft contributions are persisted with `shared_preferences` so
they can survive app restart on the same device. Access tokens are stored
separately with `flutter_secure_storage`. Sensitive drafts, submitted items,
review decisions, and approved demo content remain in memory only.

The Laravel backend, relational database, RDF/OWL ontology files, Fuseki/SPARQL
integration, media storage, full offline sync, encrypted sensitive draft
storage, and AI triage pipeline are documented as target architecture unless
corresponding implementation appears in the repository.

## Documentation Map

| File | Purpose |
|---|---|
| `PRODUCT_CONTEXT.md` | Project background, goals, scope, and users |
| `ARCHITECTURE.md` | System architecture and module boundaries |
| `MOBILE_APP_GUIDE.md` | Flutter mobile app development guide |
| `BACKEND_GUIDE.md` | Laravel backend development guide |
| `API_CONTRACT.md` | REST API standards and endpoint examples |
| `DATA_MODEL.md` | Relational database model and workflow tables |
| `KNOWLEDGE_MODEL.md` | Domain concepts, entities, and relations |
| `ONTOLOGY_GUIDE.md` | RDF/OWL ontology modeling guide |
| `SPARQL_GUIDE.md` | SPARQL query and triplestore guide |
| `CROWDSOURCING_WORKFLOW.md` | Contribution, review, curation, and validation flow |
| `PROVENANCE_VERSIONING.md` | Provenance, audit trail, and versioning rules |
| `AI_TRIAGE_GUIDE.md` | Safe AI-assisted preprocessing rules |
| `MEDIA_ASSET_GUIDE.md` | Audio, image, video, document, and metadata rules |
| `OFFLINE_SYNC.md` | Offline-first and synchronization behavior |
| `SECURITY_PRIVACY.md` | Security, privacy, and cultural sensitivity rules |
| `ACCESSIBILITY_UX.md` | Mobile UX and accessibility baseline |
| `EVALUATION_QA.md` | Research and software evaluation plan |
| `CODE_STYLE.md` | Naming, formatting, and coding standards |
| `DEPLOYMENT.md` | Deployment, environment, and release workflow |
| `FURTHER_DEVELOPMENT.md` | Suggested next development steps after the local MVP |

## Main Principle

This project is not just a mobile CRUD app.

It is a cultural knowledge management system with a semantic layer, validation workflow, and community participation. Code changes must protect cultural accuracy, provenance, and long-term knowledge usability.

## Target Stack

| Layer | Recommended Stack |
|---|---|
| Mobile | Flutter / Dart |
| Backend | Laravel / PHP |
| Database | MySQL or PostgreSQL |
| Semantic Store | Apache Jena Fuseki or compatible triplestore |
| Ontology Editing | Protégé |
| Ontology Method | Methontology |
| Semantic Query | SPARQL |
| Media Storage | Local storage, S3-compatible storage, or institutional server |
| AI Assistance | External LLM for triage only |

Current implemented stack:

| Layer | Current State |
|---|---|
| Mobile | Flutter / Dart local MVP at repository root |
| State Management | Local `ChangeNotifier` store through `GamelanMvpStore` and `GamelanScope` |
| Local Draft Storage | `shared_preferences` for non-sensitive drafts only |
| API Client | `http` JSON client used for authentication; other repositories remain local/placeholders |
| Token Storage | `flutter_secure_storage` for access tokens |
| Backend | Not present in this repository |
| Ontology/SPARQL | Not present in this repository |

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
