# Mobile-Based Balinese Gamelan Knowledge Management Application

This repository contains a mobile-based knowledge management application for Balinese gamelan.

## Current State

This repository currently contains a local Flutter MVP at the repository root.
The app uses Material 3 and starts on a bottom-navigation shell with these
implemented tabs:

- Home
- Search
- Contribute
- Review
- Profile

Implemented local MVP behavior includes:

- Flutter/Dart mobile shell
- Basic feature folder structure under `lib/features`
- In-memory `GamelanMvpStore` state using `ChangeNotifier`
- Seeded Gong Kebyar and Gong Gede knowledge items
- Keyword search over local knowledge titles, descriptions, and relation labels
- Contribution form with required title, description, source note, consent,
  knowledge type, gamelan type, contributor note, and cultural sensitivity flag
- Local draft and submitted contribution states
- Curator-style local review queue with mark-under-review, approve, request
  changes, and reject actions
- Approved local contributions appear in Search as community approved demo
  content
- Lightweight API endpoint constants and API client helpers
- Placeholder contribution and review repositories that do not make HTTP calls
- In-memory token storage for development scaffolding only

The MVP data is in memory only. Local contributions reset when the app restarts.
Approved local content is demo knowledge, not RDF publication.

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
and are not implemented in this local Flutter MVP yet.

## Run And Test

```sh
flutter run
flutter analyze
flutter test
```

The current widget tests cover:

- app shell and bottom navigation rendering
- seeded Gong Kebyar and Gong Gede knowledge visibility
- contribution form validation and submission
- review queue visibility
- approval flow that promotes local contributions into searchable knowledge

## Development Roadmap

See `docs/FURTHER_DEVELOPMENT.md` for suggested next steps, including draft
persistence, real authentication, Laravel API integration, media handling,
provenance/versioning, ontology mapping, RDF publication, SPARQL-backed search,
and safe AI triage.

Start with:

- `AGENTS.md`
- `docs/README.md`
- `docs/PRODUCT_CONTEXT.md`
- `docs/ARCHITECTURE.md`
- `docs/KNOWLEDGE_MODEL.md`
- `docs/ONTOLOGY_GUIDE.md`
- `docs/CROWDSOURCING_WORKFLOW.md`
- `docs/FURTHER_DEVELOPMENT.md`
