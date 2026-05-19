# SPARQL Guide

This document defines SPARQL query rules and examples.

## Current Implementation

SPARQL is not implemented in the current local Flutter MVP. There is no
triplestore configuration, SPARQL client, semantic search screen, RDF dataset,
or ontology file in the repository yet.

This guide defines target query behavior for future backend and ontology
integration.

## SPARQL Endpoint

Example:

```txt
http://localhost:3030/gamelan/query
```

Production endpoint should not be publicly writable.

## Public Query Policy

Mobile app users should normally access semantic search through REST API endpoints.

Arbitrary SPARQL query execution should be restricted to admin, curator, developer, or internal services.

## Common Prefixes

```sparql
PREFIX gamelan: <https://example.org/gamelan#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX dcterms: <http://purl.org/dc/terms/>
PREFIX prov: <http://www.w3.org/ns/prov#>
```

## Competency Questions

The ontology should answer questions such as:

1. What instruments are used in Gong Kebyar?
2. Which compositions are associated with Gong Gede?
3. Which media assets document a certain instrument?
4. Which knowledge items were validated by an expert?
5. What terms are related to a specific performance context?
6. Which instruments are shared across different ensembles?
7. What sources support a knowledge item?

## Example: Instruments in Gong Kebyar

```sparql
PREFIX gamelan: <https://example.org/gamelan#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>

SELECT ?instrument ?label
WHERE {
  gamelan:GongKebyar gamelan:hasInstrument ?instrument .
  ?instrument skos:prefLabel ?label .
  FILTER (lang(?label) = "id")
}
ORDER BY ?label
```

## Example: Expert-Validated Knowledge

```sparql
PREFIX gamelan: <https://example.org/gamelan#>

SELECT ?item ?validator
WHERE {
  ?item gamelan:validatedBy ?validator ;
        gamelan:validationStatus "expert_approved" .
}
```

## Named Graphs

Recommended named graphs:

```txt
graph/published
graph/draft
graph/provenance
graph/deprecated
```

Only `graph/published` should power public semantic search unless explicitly configured otherwise.
