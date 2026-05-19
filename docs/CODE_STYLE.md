# Code Style Guide

This document defines general code style rules.

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

Recommended file names:

```txt
knowledge_item_model.dart
contribution_repository.dart
contribution_controller.dart
review_queue_screen.dart
semantic_search_screen.dart
```

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
