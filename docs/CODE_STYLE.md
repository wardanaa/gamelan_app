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

## Flutter

Current file naming examples:

```txt
contribution_model.dart
contribution_repository.dart
contribution_list_screen.dart
review_queue_screen.dart
api_endpoints.dart
token_storage.dart
```

Target file names as features grow:

```txt
knowledge_item_model.dart
contribution_repository.dart
contribution_controller.dart
review_queue_screen.dart
semantic_search_screen.dart
```

Current repository-backed local state uses repository interfaces with local
implementations:

```txt
ContributionRepository
LocalContributionRepository
ReviewRepository
LocalReviewRepository
KnowledgeRepository
LocalKnowledgeRepository
```

Keep future API-backed implementations behind the same interface pattern rather
than reading API or storage concerns directly from screens.

Recommended class names:

```dart
KnowledgeItem
ContributionRepository
ReviewQueueScreen
SemanticSearchController
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
