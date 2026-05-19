# Mobile-Based Balinese Gamelan Knowledge Management Application

This repository contains a mobile-based knowledge management application for Balinese gamelan.

## Current State

This repository currently contains the Flutter mobile application scaffold at the
repository root. The app uses Material 3 and currently starts on the
`ContributionListScreen`. Feature folders exist for authentication,
contributions, knowledge browsing, review, and administration, but most screens
and repositories are placeholders.

Implemented app scaffolding includes:

- Flutter/Dart mobile shell
- Basic feature folder structure under `lib/features`
- Lightweight API endpoint constants and API client helpers
- Placeholder contribution and review repositories
- In-memory token storage for development scaffolding only

## Target Capability

The intended application supports:

- Community-based knowledge contribution
- Curator and expert validation
- Semantic ontology enrichment using RDF/OWL
- Mobile access through Flutter
- REST API backend through Laravel
- SPARQL-based semantic search through Apache Jena Fuseki or compatible triplestore

Laravel, relational database, RDF/OWL ontology files, SPARQL integration,
offline sync, media upload, and AI triage are target architecture capabilities
and are not implemented in this Flutter scaffold yet.

Start with:

- `AGENTS.md`
- `docs/README.md`
- `docs/PRODUCT_CONTEXT.md`
- `docs/ARCHITECTURE.md`
- `docs/KNOWLEDGE_MODEL.md`
- `docs/ONTOLOGY_GUIDE.md`
- `docs/CROWDSOURCING_WORKFLOW.md`
