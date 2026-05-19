# Backend Guide

This document defines backend development rules for the Laravel API.

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
