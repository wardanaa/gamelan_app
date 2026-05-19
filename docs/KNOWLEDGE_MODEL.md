# Knowledge Model

This document defines the core Balinese gamelan knowledge concepts used by the application.

## Current Implementation

The current Flutter app has placeholder knowledge entity list and detail
screens. It does not yet include knowledge entity models, ontology mappings,
semantic relations, local datasets, RDF files, or SPARQL-backed browsing.

The concepts below define the target knowledge model that future app, backend,
and ontology work should follow.

## Initial Domain Scope

Initial scope:

- Gong Kebyar
- Gong Gede
- Traditional Balinese gamelan in Bali

Future expansion may include other ensembles after ontology and curation rules are extended.

## Core Entity Types

| Entity Type | Description |
|---|---|
| Instrument | Musical instrument used in gamelan |
| Ensemble | Gamelan ensemble type or group arrangement |
| Composition | Musical work, piece, or repertoire |
| Performance | Specific performance event or context |
| Technique | Playing technique or performance method |
| Person | Practitioner, composer, teacher, maker, contributor |
| Group | Sekaa/group/institution/community |
| Place | Village, region, temple, venue, or cultural location |
| Term | Technical or cultural term |
| Media Asset | Audio, video, image, or document |
| Source | Literature, interview, observation, archive, recording |

## Example Entity Labels

### Instrument

Examples:

```txt
gangsa
ugal
jegogan
jublag
reyong
kendang
ceng-ceng
gong
kajar
kempli
```

### Ensemble

Examples:

```txt
Gong Kebyar
Gong Gede
```

## Core Relations

| Relation | Meaning |
|---|---|
| `hasInstrument` | Ensemble has instrument |
| `usedInEnsemble` | Instrument is used in ensemble |
| `performedBy` | Composition/performance performed by person or group |
| `performedAt` | Performance occurred at place/event |
| `originRegion` | Entity associated with region |
| `hasTechnique` | Instrument/composition uses technique |
| `documents` | Media documents entity |
| `createdBy` | Composition or media created by person/group |
| `taughtBy` | Knowledge or technique taught by person |
| `validatedBy` | Knowledge validated by curator/expert |
| `derivedFromSource` | Knowledge derived from source |
| `similarTo` | Entity similar to another entity |
| `partOf` | Entity is part of larger structure |

## Contribution Types

Suggested contribution intent:

```txt
new_entity
correction
additional_relation
media_upload
terminology_definition
source_reference
local_variant
expert_note
```

## Cultural Sensitivity

Contributions may be marked culturally sensitive when they involve:

- sacred or restricted knowledge
- ritual context
- community-specific knowledge
- unpublished local practice
- identifiable elders or practitioners
- media requiring consent

Sensitive content requires curator review and may require expert validation.
