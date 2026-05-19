# Evaluation and QA Guide

This document defines software, ontology, and research evaluation rules.

## Current Implementation

The current test suite contains a Flutter widget test that verifies the app shell
renders the contribution screen. Backend, ontology, SPARQL, offline sync, media,
and AI triage tests are not applicable until those capabilities are implemented.

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

- app shell renders `Contributions` and `Contribution list`

Target scenarios:

- user registration
- login/logout
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
