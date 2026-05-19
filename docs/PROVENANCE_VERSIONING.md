# Provenance and Versioning

This document defines provenance and versioning rules.

## Current Implementation

The current Flutter scaffold does not persist contribution versions,
provenance records, review history, RDF publication status, or ontology mapping
history. These concepts are target requirements for the future backend and
semantic publication workflow.

## Why Provenance Matters

Balinese gamelan knowledge may come from practitioners, elders, literature, observation, recordings, community memory, or institutional archives.

The system must record where knowledge came from, who contributed it, who reviewed it, and how it changed.

## Provenance Must Track

For each contribution:

- contributor
- source note
- submitted time
- review history
- curator decisions
- expert validation
- media assets
- RDF publication status
- ontology mapping
- version changes

## Versioning Rule

Every important edit must create a version record.

Version snapshot should include:

```txt
title
description
knowledge_type
gamelan_type
related_entities
source_note
media_assets
status
editor_id
edited_at
change_note
```

## RDF Provenance

Use PROV-O where suitable.

Example:

```turtle
gamelan:Statement123 a prov:Entity ;
    prov:wasAttributedTo gamelan:Contributor456 ;
    prov:wasGeneratedBy gamelan:Validation789 ;
    prov:generatedAtTime "2026-05-19T10:00:00+08:00"^^xsd:dateTime .
```

## Deleting vs Deprecating

Published semantic knowledge should normally be deprecated, not hard-deleted.

Use:

```txt
active
deprecated
superseded
removed_from_public_view
```

Hard delete only for:

- legal removal
- privacy violation
- accidental sensitive exposure
- duplicate technical error before publication
