# API Contract

This document defines REST API standards.

## Current Implementation

The current Flutter app has endpoint constants but does not perform real HTTP
requests yet. Existing mobile constants are:

```txt
/auth/login
/auth/register
/contributions
/reviews
/knowledge
/admin/audit-logs
/admin/users
```

`ApiClient.endpoint(path)` currently builds a `Uri` from a configured base URL
and path. Repository methods call this helper but return placeholder results.
The local MVP uses `GamelanMvpStore` for local data instead of calling these API
helpers. Only non-sensitive draft contributions are persisted locally; API
integration remains target architecture.

The contract below is the target REST API contract for the future backend.

## Base URL

```txt
/api/v1
```

## Response Format

### Success

```json
{
  "success": true,
  "message": "Data retrieved successfully.",
  "data": {}
}
```

### Error

```json
{
  "success": false,
  "message": "Validation failed.",
  "errors": {}
}
```

### Pagination

```json
{
  "success": true,
  "message": "Data retrieved successfully.",
  "data": [],
  "meta": {
    "current_page": 1,
    "per_page": 10,
    "total": 100
  }
}
```

## Core Endpoints

### Authentication

```txt
POST /auth/register
POST /auth/login
POST /auth/logout
GET  /me
```

### Knowledge Browsing

The current Flutter constant is `/knowledge`. The target backend should expose
resource-oriented knowledge endpoints:

```txt
GET /knowledge-items
GET /knowledge-items/{id}
GET /knowledge-items/{id}/relations
GET /knowledge-types
GET /gamelan-types
```

### Semantic Search

```txt
GET /search
GET /search/semantic
GET /search/suggestions
```

### Contributions

The current Flutter constant is `/contributions`. The target backend should
support:

```txt
GET    /contributions
POST   /contributions
GET    /contributions/{id}
PUT    /contributions/{id}
DELETE /contributions/{id}
POST   /contributions/{id}/submit
POST   /contributions/{id}/media
```

### Review

The current Flutter constant is `/reviews`. The target backend should support:

```txt
GET  /reviews/queue
POST /reviews/{contribution}/approve
POST /reviews/{contribution}/reject
POST /reviews/{contribution}/request-revision
POST /reviews/{contribution}/expert-validate
```

### Ontology

```txt
GET /ontology/classes
GET /ontology/properties
GET /ontology/entities
GET /ontology/entities/{id}
GET /ontology/entities/{id}/graph
```

### SPARQL Proxy

```txt
POST /sparql/query
```

This endpoint should be protected or restricted. Public users should normally use predefined semantic search endpoints, not arbitrary SPARQL.

## Example Contribution Payload

```json
{
  "title": "Gangsa in Gong Kebyar",
  "description": "Gangsa is a metallophone instrument used in Gong Kebyar ensemble.",
  "knowledge_type": "instrument",
  "gamelan_type": "gong_kebyar",
  "source_note": "Community interview and local practice note.",
  "cultural_sensitivity": false,
  "related_entities": [
    {
      "type": "ensemble",
      "label": "Gong Kebyar",
      "relation": "used_in"
    }
  ]
}
```
