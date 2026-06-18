# SPARQL Guide

This document defines SPARQL query rules and examples.

## Current Implementation

Direct SPARQL execution is not implemented in the current Flutter mobile
client. There is no triplestore configuration, raw SPARQL client, RDF dataset,
or ontology file in this repository.

The mobile client does consume backend knowledge search and ontology/RDF
publication contracts, and live integration tests can verify ontology/RDF and
protected SPARQL proxy behavior against a configured backend. A user-facing
semantic-search fallback UI is still not implemented.

This guide defines query behavior for backend and ontology integration consumed
through REST APIs.

## SPARQL Endpoint

Example:

```txt
http://localhost:3030/gamelan/query
```

Production endpoint should not be publicly writable.

The backend RDF publication job uses a backend-only SPARQL update endpoint configured through environment variables. API clients must not receive update credentials or call the triplestore directly.

MVP semantic search uses a backend-only SPARQL query endpoint configured through `SPARQL_QUERY_ENDPOINT`. REST endpoints build predefined `SELECT` queries and reconcile RDF bindings with public relational knowledge items before returning client responses.

## Public Query Policy

API clients should normally access semantic search through REST API endpoints.

Arbitrary SPARQL query execution should be restricted to admin, curator, developer, or internal services.

Implemented public semantic search:

```txt
GET /api/v1/search/semantic
```

Implemented protected predefined proxy:

```txt
POST /api/v1/sparql/query
```

The proxy accepts only `published_entities_by_type`, `related_entities`, and `instruments_in_ensemble`. It does not accept raw SPARQL text.

MVP 10 test coverage includes a safe competency-style check for `instruments_in_ensemble` using synthetic published fixtures and faked SPARQL responses. These tests verify that queries use `graph/published`, avoid `graph/draft`, and filter returned RDF bindings through public relational `knowledge_items` before a REST response is returned.

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

MVP 7 writes validated, non-sensitive entity triples to `graph/published` and publication provenance triples to `graph/provenance`. Draft, rejected, under-review, archived, and culturally sensitive contributions must not be inserted into `graph/published`.

Relevant environment variables:

```txt
SPARQL_QUERY_ENDPOINT
SPARQL_QUERY_USERNAME
SPARQL_QUERY_PASSWORD
SPARQL_QUERY_TIMEOUT
SPARQL_UPDATE_ENDPOINT
SPARQL_UPDATE_USERNAME
SPARQL_UPDATE_PASSWORD
SPARQL_UPDATE_TIMEOUT
RDF_BASE_URI
RDF_NAMESPACE
RDF_PUBLISHED_GRAPH_URI
RDF_PROVENANCE_GRAPH_URI
```
