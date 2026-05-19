# System Architecture

## Architecture Overview

The current repository contains the Flutter mobile app scaffold at the project
root. It does not yet contain a Laravel backend, database schema, ontology
files, RDF publication jobs, media storage, or SPARQL integration.

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
- Home screen is `ContributionListScreen`.
- Feature folders exist for `auth`, `contributions`, `knowledge`, `review`, and `admin`.
- API helper classes exist under `lib/core/api`.
- Repositories are placeholders and do not perform real network requests yet.

Target responsibilities:

- Authentication UI
- Knowledge browsing
- Semantic search interface
- Contribution forms
- Media upload UI
- Draft/offline storage
- Review screens for curator/expert roles
- Notifications and status tracking

The mobile app must not contain authoritative business rules. It may mirror validation for UX, but backend validation remains mandatory once the backend exists.

### Laravel REST API

Target responsibility. The Laravel REST API is not present in this repository yet.

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

The current Flutter scaffold names screens and models for this flow, but the
workflow is not executed end to end yet.

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

## Do Not

Do not let the mobile app write directly to the triplestore.

Do not let AI write final triples directly to the triplestore.

Do not publish rejected or draft contributions through SPARQL.
