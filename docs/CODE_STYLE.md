# Code Style Guide

This document defines general code style rules.

## Current Implementation Notes

The current Flutter code uses simple feature folders under `lib/features` and
core helpers under `lib/core`. Keep documentation and future code aligned with
the current plural feature names where they already exist, such as
`contributions`.

Do not introduce backend, ontology, SPARQL, or storage naming as implemented
code unless those modules are added.

## General Principles

1. Use clear names.
2. Keep modules focused.
3. Avoid cleverness where clarity works.
4. Validate at boundaries.
5. Keep domain terms consistent.
6. Document assumptions.

## Naming

Use consistent domain terms.

Preferred:

```txt
contribution
review
curation
validation
knowledge_item
ontology_entity
rdf_publication
media_asset
provenance_record
```

Avoid random synonyms such as:

```txt
post
thing
data
item2
stuff
```

## API Client References

Client-related docs should describe API expectations, not Flutter implementation details.

```txt
api_client
idempotency_key
validation_error
allowed_action
localized_label
```

Avoid documenting frontend framework internals in this API repository, such as:

```txt
widget tree
state management provider
screen routing
local UI component hierarchy
```

## Laravel

Recommended class names:

```txt
ContributionController
ContributionService
ReviewService
OntologyMappingService
SparqlQueryService
PublishContributionToRdfJob
ContributionPolicy
StoreContributionRequest
```

## API

Use snake_case JSON keys.

Good:

```json
{
  "knowledge_type": "instrument",
  "gamelan_type": "gong_kebyar"
}
```

## RDF

Use stable URI-friendly slugs.

Examples:

```txt
gong-kebyar
gong-gede
gangsa
ceng-ceng
```

## Git Commit Examples

```txt
feat(contribution): add draft submission endpoint
fix(search): exclude unpublished RDF graph from results
docs(ontology): add Gong Kebyar competency question
test(review): cover curator approval transition
```
