# System Architecture

## Architecture Overview

The system consists of five major layers:

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

Responsible for:

- Authentication UI
- Knowledge browsing
- Semantic search interface
- Contribution forms
- Media upload UI
- Draft/offline storage
- Review screens for curator/expert roles
- Notifications and status tracking

The mobile app must not contain authoritative business rules. It may mirror validation for UX, but backend validation remains mandatory.

### Laravel REST API

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
