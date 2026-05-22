# Backend Guide

This document defines backend development rules for the Laravel API.

## Current Implementation

No Laravel backend exists in this repository yet. The current codebase contains
only the Flutter app scaffold and lightweight mobile endpoint constants.

Use this guide when adding a backend service or when aligning the mobile API
client with the future backend contract.

## Backend Stack

Recommended:

- Laravel
- PHP 8.3 or project-approved PHP version
- MySQL or PostgreSQL
- Laravel Sanctum or Passport for API authentication
- Queue workers for RDF publication and media processing
- Storage disk abstraction for media files

## Backend Responsibilities

The backend owns:

- Authentication
- Authorization
- Role-based access control
- Contribution workflow
- Review workflow
- Validation rules
- Relational persistence
- Media metadata
- Audit log
- Provenance
- RDF mapping orchestration
- SPARQL integration
- Retry-safe write behavior for offline-capable clients
- Client-safe response and validation error shape

## Recommended Laravel Structure

```txt
app/
├── Http/
│   ├── Controllers/Api/V1/
│   ├── Requests/
│   └── Resources/
├── Models/
├── Services/
│   ├── Contribution/
│   ├── Review/
│   ├── Ontology/
│   ├── Sparql/
│   └── Media/
├── Policies/
├── Actions/
├── Jobs/
├── Events/
└── Exceptions/
```

This structure is rooted in this repository. Do not assume a separate `backend/` subdirectory.

## Controller Rule

Controllers should be thin.

Good:

```php
public function store(StoreContributionRequest $request)
{
    $contribution = $this->contributionService->submit(
        $request->user(),
        $request->validated()
    );

    return new ContributionResource($contribution);
}
```

## Service Responsibilities

Services should contain domain logic.

Examples:

```txt
ContributionService
ReviewService
OntologyMappingService
SparqlQueryService
MediaAssetService
ProvenanceService
```

`ProvenanceService` is the shared service for contribution version snapshots, provenance records, and sensitive-operation audit logs. Workflow services should call it instead of creating trace records directly.

## Authorization

Use policies or explicit service-level checks.

Examples:

- contributor can edit own draft
- contributor cannot approve own contribution
- curator can review submitted contributions
- expert can validate assigned expert review
- admin can manage users and roles

## Queue Jobs

Use queue jobs for:

- media processing
- RDF generation
- SPARQL triplestore insert
- AI triage call
- notification sending

Queue jobs that publish RDF or process media must record provenance and must not expose unpublished or restricted content through public endpoints.

Implemented MVP 9 triage uses `RunContributionTriageJob` after contribution submission when `AI_TRIAGE_ENABLED=true`. The default provider is `rules`; external AI providers are not called in this MVP. The job stores suggestions only, records `ai_triage_suggested`, and must not change workflow status, reviews, ontology mappings, RDF publications, or public knowledge items.

## RDF Publication Rule

Only approved contributions may be mapped to RDF and published to the triplestore.

Implemented MVP job flow:

```txt
POST /api/v1/contributions/{uuid}/rdf-publications
    -> authorize curator/admin publisher
    -> require curator_approved or expert_approved contribution
    -> reject culturally sensitive content for public RDF in MVP 7
    -> create approved ontology_mapping
    -> create pending rdf_publication
    -> record rdf_publication_queued provenance
    -> dispatch PublishContributionToRdfJob
        -> build SPARQL INSERT DATA for graph/published and graph/provenance
        -> insert into Fuseki through backend-only SPARQL update credentials
        -> create/update ontology_entity and knowledge_item on success
        -> mark ontology_mapping and rdf_publication as published
        -> mark contribution as published
        -> record rdf_publication_published provenance
```

External clients must never publish RDF directly. They submit contributions and review decisions through REST endpoints only.

Failed publication jobs mark `rdf_publication.status` as `failed`, store a sanitized error message, record `rdf_publication_failed`, and leave the contribution and knowledge item unpublished.

## Published Browsing and Search Rule

Public browsing, keyword search, semantic search, and predefined SPARQL proxy responses must use the backend public-knowledge filter before returning records:

```txt
knowledge_items.publish_status = published
knowledge_items.cultural_sensitivity = false
linked ontology_entities.status = published
linked ontology_entities.cultural_sensitivity = false
```

Semantic search may query the SPARQL query endpoint, but REST responses must be reconciled with public relational `knowledge_items`. Public clients must not execute raw SPARQL. The protected `/api/v1/sparql/query` endpoint accepts predefined query keys only and is restricted to curators and admins.

## Logging

Log technical errors without exposing sensitive data.

Good:

```php
Log::error('RDF publication failed', [
    'contribution_id' => $contribution->id,
    'error' => $exception->getMessage(),
]);
```

Audit and provenance metadata must be sanitized before storage or API exposure. Do not include private review notes, storage paths, file URLs, IP address, user agent, raw AI prompts, raw AI responses, credentials, or restricted cultural details in client-facing trace responses.
