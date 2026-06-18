# System Architecture

## Architecture Overview

The current repository contains the Flutter mobile client at the project root.
It consumes Laravel API contracts for authentication, contributions, media,
review, provenance, knowledge browsing/search, ontology collections, and RDF
publication queueing. It does not contain the Laravel backend service,
database migrations, ontology files, RDF publication jobs, media storage, or
Fuseki/SPARQL infrastructure.

The target system consists of five major layers:

```txt
Flutter Mobile App
        |
        v
Laravel REST API
        |
        +--------------------+
        |                    |
        v                    v
Relational Database      Media Storage
        |
        v
Curation and Validation Workflow
        |
        v
RDF/OWL Mapping Service
        |
        v
Apache Jena Fuseki / SPARQL Endpoint
```

## Layer Responsibilities

### Mobile App

Current implementation:

- Flutter app entrypoint in `lib/main.dart`.
- Material 3 app shell in `lib/app.dart`.
- `GamelanApp` restores secure authentication state before showing
  `GamelanHomeShell`, with Home, Search, Contribute, Review, and Profile tabs.
  Restore validates the saved token through `/me`.
- Feature folders exist for `auth`, `contributions`, `knowledge`, `review`, and `admin`.
- API helper classes exist under `lib/core/api`; authentication uses real JSON
  registration, login, logout, and `/me` profile requests.
- Access tokens are stored through `flutter_secure_storage`.
- The Review workflow is UX-gated by backend profile roles or the
  `review.contributions` permission. Backend policies remain the source of
  truth for protected actions.
- Review detail screens render action groups from backend `allowed_actions`
  and open dedicated expert dialogs for escalation and validation when those
  actions are present.
- Review detail screens render a curator/admin RDF publication action only
  when backend `allowed_actions` includes `publish_rdf`; the mobile form queues
  the backend publication job and never writes RDF triples directly.
- Contribution and review detail screens can open a safe, read-only
  provenance timeline route that merges contribution versions and provenance
  events from backend trace endpoints.
- Review detail screens can render backend triage suggestions as a helper card,
  but only on review-capable views and only when the API includes
  `triage_suggestion`.
- UI-facing mobile state is coordinated by `GamelanMvpStore` and exposed
  through `GamelanScope`.
- Contribution, review, and knowledge data access is behind repository
  interfaces. Production wiring uses remote Laravel repositories; local
  repositories remain only for deterministic tests and offline demo fixtures.
- Contribution drafts, submitted records, review queues, media, and published
  knowledge are API-backed in production wiring.
- Ontology DTOs and repository access exist for classes, properties, entities,
  and RDF publication lookup/queueing.
- Semantic-search fallback UI is implemented. Full offline sync, offline media
  queues, and production admin screens are not implemented.

Target responsibilities:

- Account management UI
- Knowledge browsing
- Semantic search interface
- Contribution forms
- Media upload UI
- Draft/offline storage
- Review screens for curator/expert roles
- Notifications and status tracking

The mobile app must not contain authoritative business rules. It may mirror
validation for UX, but backend validation and authorization remain mandatory.

### Current Mobile Client Flow

After backend sign-in, the current mobile client runs this API-backed
contribution and review flow:

```txt
Backend profile and published knowledge
    ↓
Remote contribution form
    ↓
Draft or submitted contribution through Laravel API
    ↓
Online media attachment/removal for editable drafts
    ↓
Backend review/expert workflow through allowed_actions
    ↓
Published backend knowledge appears in browse/search
```

Draft, submitted, under-review, needs-revision, expert-required,
expert-approved, rejected, archived, unpublished, and sensitive contributions
must not appear in public knowledge browsing unless the backend publishes safe
knowledge records. The mobile app does not directly publish RDF or write to the
triplestore.

### Laravel REST API

Target/external responsibility. The Laravel REST API is not present in this
Flutter repository, but the mobile app is already wired to consume the
documented API routes.

Responsible for:

- Authentication and authorization
- User and role management
- Contribution workflow
- Review and validation logic
- Relational data persistence
- Media metadata management
- RDF generation orchestration
- SPARQL query proxy or integration
- Audit log and provenance
- Idempotency and retry-safe writes for offline-capable clients
- Client-safe response messages and workflow action metadata

### Relational Database

Target responsibility. No relational schema or migrations are present in this
Flutter repository yet.

Stores workflow and operational data:

- users
- roles
- contributions
- reviews
- media assets
- validation status
- provenance records
- RDF publication records
- idempotency and sync records where needed
- local drafts if synced

### RDF/OWL Triplestore

Stores semantic knowledge after validation.

Possible tools:

- Apache Jena Fuseki
- GraphDB
- Other SPARQL-compatible triplestore

### Ontology Files

Target responsibility. No `ontology/` directory is present in the current
repository.

Stores ontology definitions:

```txt
ontology/
├── gamelan-ontology.ttl
├── gamelan-ontology.owl
├── competency-questions.md
└── examples/
    ├── gong-kebyar-example.ttl
    └── gong-gede-example.ttl
```

## Recommended Repository Structure

Current repository structure:

```txt
repository-root/
├── AGENTS.md
├── README.md
├── docs/
├── lib/
│   ├── app.dart
│   ├── main.dart
│   ├── core/
│   │   ├── api/
│   │   ├── constants/
│   │   ├── storage/
│   │   └── utils/
│   └── features/
│       ├── admin/
│       ├── auth/
│       ├── contributions/
│       ├── knowledge/
│       └── review/
├── test/
├── android/
├── ios/
├── web/
├── linux/
├── macos/
└── windows/
```

Target multi-service structure if backend and ontology are later added:

```txt
repository-root/
├── AGENTS.md
├── README.md
├── docs/
├── mobile/
│   └── gamelan_app/
├── backend/
│   └── gamelan_api/
├── ontology/
│   ├── gamelan-ontology.ttl
│   ├── gamelan-ontology.owl
│   └── examples/
├── scripts/
│   ├── rdf/
│   ├── import/
│   └── export/
└── deployment/
    ├── docker/
    └── server/
```

## Critical Flow

The target production flow remains:

```txt
Contributor submits draft
    ↓
Backend validates input
    ↓
AI triage may suggest entity/relation/duplicate
    ↓
Peer review or curator review
    ↓
Curator normalizes content
    ↓
Expert validation if needed
    ↓
Approved contribution mapped to RDF
    ↓
RDF triples inserted into triplestore
    ↓
Published knowledge appears in semantic search
```

The current mobile client implements the API-facing contribution, media,
review, expert action, provenance display, AI triage display, public
browse/search, semantic-search fallback UI, ontology DTO, and
backend-authorized RDF publication queueing portions of this flow. Backend
validation, authorization, ontology mapping execution, RDF insertion, SPARQL
query execution, and publication state remain backend-owned.

## Do Not

Do not let the mobile app write directly to the triplestore.

Do not let AI write final triples directly to the triplestore.

Do not publish rejected or draft contributions through SPARQL.
