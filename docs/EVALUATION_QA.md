# Evaluation and QA Guide

This document defines software, ontology, and research evaluation rules.

## Current Implementation

The current test suite contains Flutter widget tests for the local MVP. Backend,
ontology, SPARQL, offline sync, media, and AI triage tests are not applicable
until those capabilities are implemented.

## Evaluation Dimensions

The project should be evaluated across:

1. Functional correctness
2. Usability
3. Ontology quality
4. SPARQL competency question coverage
5. Curation workflow reliability
6. Security and privacy
7. Performance

## Functional Testing

Current implemented scenario:

- user registration, login, `/me` profile loading, logout, and expired-token
  clearing
- reviewer role gating for the local Review workflow
- app shell renders the Material 3 bottom navigation
- Search shows seeded Gong Kebyar and Gong Gede knowledge
- contribution form validates title, description, source note, and consent
- submitted contribution appears in the contribution list and review queue
- culturally sensitive contribution shows a warning marker
- approving a contribution moves it into searchable knowledge

Target scenarios:

- browse knowledge items
- semantic search
- create draft
- submit contribution
- upload media
- curator review
- request revision
- expert validation
- publish to RDF
- query published knowledge
- reject contribution
- offline draft sync

## Ontology Evaluation

Ontology evaluation should include:

- expert review
- OOPS! pitfall checking
- competency question testing
- SPARQL query testing
- consistency checking if reasoner is used
- sample RDF instance review

## Usability Evaluation

Recommended methods:

- SUS questionnaire
- task-based testing
- interview
- observation

Suggested participants:

```txt
12–15 participants including general users, contributors, practitioners, curators, experts, and admins
```

Target:

```txt
SUS score >= 70
```

## Performance Targets

Suggested MVP targets:

| Operation | Target |
|---|---|
| Login | < 2 seconds |
| Browse list | < 2 seconds |
| Semantic search common query | < 2 seconds |
| Contribution submit without media | < 2 seconds |
| Contribution submit with media | progress visible |
| RDF publication job | async |
