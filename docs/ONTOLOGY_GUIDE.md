# Ontology Guide

This document defines RDF/OWL ontology modeling rules.

## Ontology Method

Use Methontology as the ontology development method.

Recommended steps:

1. Specification
2. Knowledge acquisition
3. Conceptualization
4. Formalization
5. Implementation
6. Evaluation
7. Maintenance

## Tools

Recommended:

- Protégé for ontology editing
- RDF/Turtle for version-controlled ontology files
- OWL for ontology semantics
- SKOS for controlled vocabulary and labels
- Apache Jena Fuseki or compatible triplestore
- SPARQL for semantic queries

## Namespace

Example namespace:

```txt
https://example.org/gamelan#
```

Production namespace must use the official project domain.

Suggested prefixes:

```turtle
@prefix gamelan: <https://example.org/gamelan#> .
@prefix skos:    <http://www.w3.org/2004/02/skos/core#> .
@prefix dcterms: <http://purl.org/dc/terms/> .
@prefix prov:    <http://www.w3.org/ns/prov#> .
@prefix owl:     <http://www.w3.org/2002/07/owl#> .
@prefix rdf:     <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs:    <http://www.w3.org/2000/01/rdf-schema#> .
```

## Core Classes

Recommended classes:

```txt
gamelan:Instrument
gamelan:Ensemble
gamelan:Composition
gamelan:Performance
gamelan:Technique
gamelan:Person
gamelan:Group
gamelan:Place
gamelan:MediaAsset
gamelan:Source
gamelan:Term
gamelan:Contribution
gamelan:Validation
```

## Object Properties

Recommended properties:

```txt
gamelan:hasInstrument
gamelan:usedInEnsemble
gamelan:performedBy
gamelan:performedAt
gamelan:originRegion
gamelan:hasTechnique
gamelan:documents
gamelan:createdBy
gamelan:validatedBy
gamelan:derivedFromSource
gamelan:similarTo
gamelan:partOf
```

## Example Turtle

```turtle
gamelan:GongKebyar a gamelan:Ensemble ;
    skos:prefLabel "Gong Kebyar"@id ;
    skos:altLabel "Kebyar"@id ;
    gamelan:hasInstrument gamelan:Gangsa ;
    dcterms:description "A Balinese gamelan ensemble known for dynamic and expressive musical style."@en .

gamelan:Gangsa a gamelan:Instrument ;
    skos:prefLabel "Gangsa"@id ;
    gamelan:usedInEnsemble gamelan:GongKebyar .
```

## URI Rules

Use stable URIs.

Recommended pattern:

```txt
https://example.org/gamelan/entity/{slug-or-uuid}
```

Do not use database auto-increment IDs as permanent public ontology identifiers unless there is no alternative.

## Evaluation

Ontology evaluation should include:

- expert review
- competency question testing
- SPARQL query testing
- OOPS! pitfall scan
- consistency check with reasoner if applicable
