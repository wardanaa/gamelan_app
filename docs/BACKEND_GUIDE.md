# Backend Guide

This document defines backend development rules for the target Laravel API.

## Current Implementation

No Laravel backend exists in this repository yet. The current codebase contains
only the Flutter app scaffold and lightweight mobile endpoint constants.

Use this guide when adding a backend service or when aligning the mobile API
client with the future backend contract.

## Backend Stack

Recommended:

- Laravel
- PHP 8.4 or project-approved PHP version
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

## Authorization

Use policies or explicit service-level checks.

Examples:

- contributor can edit own draft
- contributor cannot approve own contribution
- curator can review submitted contributions
- expert can validate assigned expert review
- admin can manage users and roles

The Flutter app uses `/me` roles and permissions only to hide or show local
workflows. Laravel policies must remain authoritative for protected endpoints,
including contribution ownership, review decisions, admin operations, workflow
status transitions, media visibility, and culturally sensitive data. Return
`401` for unauthenticated requests and `403` for authenticated users who are not
allowed to perform an action.

## Queue Jobs

Use queue jobs for:

- media processing
- RDF generation
- SPARQL triplestore insert
- AI triage call
- notification sending

## RDF Publication Rule

Only approved contributions may be mapped to RDF and published to the triplestore.

Recommended job flow:

```txt
PublishContributionToRdfJob
    -> build RDF triples
    -> validate against ontology mapping rules
    -> write provenance
    -> insert into Fuseki
    -> mark rdf_publication as published
```

## Logging

Log technical errors without exposing sensitive data.

Good:

```php
Log::error('RDF publication failed', [
    'contribution_id' => $contribution->id,
    'error' => $exception->getMessage(),
]);
```
