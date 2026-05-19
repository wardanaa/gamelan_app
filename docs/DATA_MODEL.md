# Data Model

This document defines the relational data model used for workflow and operational data.

## Core Tables

Recommended tables:

```txt
users
roles
role_user
knowledge_items
contributions
contribution_versions
contribution_relations
reviews
expert_validations
media_assets
provenance_records
rdf_publications
ontology_entities
ontology_mappings
notifications
audit_logs
```

## Contribution Status

Recommended status enum:

```txt
draft
submitted
needs_revision
under_review
curator_approved
expert_required
expert_approved
published
rejected
archived
```

## Knowledge Item

Represents validated, public knowledge.

Suggested fields:

```txt
id
uuid
title
slug
description
knowledge_type
gamelan_type
publish_status
source_summary
created_by
approved_by
published_at
created_at
updated_at
```

## Contribution

Represents user-submitted draft or candidate knowledge.

Suggested fields:

```txt
id
uuid
user_id
title
description
knowledge_type
gamelan_type
status
source_note
cultural_sensitivity
ai_triage_status
duplicate_score
submitted_at
created_at
updated_at
```

## Review

Suggested fields:

```txt
id
contribution_id
reviewer_id
role
decision
note
created_at
updated_at
```

Possible decisions:

```txt
approve
reject
request_revision
mark_expert_required
```

## RDF Publication

Tracks publication to the triplestore.

Suggested fields:

```txt
id
contribution_id
knowledge_item_id
rdf_subject_uri
rdf_graph_uri
status
published_at
published_by
error_message
created_at
updated_at
```

## Important Rule

The relational database stores workflow truth.

The triplestore stores validated semantic knowledge.

Do not use the triplestore as the only place to track review status.
