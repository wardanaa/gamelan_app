# AI Triage Guide

This document defines safe AI-assisted preprocessing rules.

## Current Implementation

AI triage is not implemented in the current local Flutter MVP. There is no AI
provider configuration, prompt workflow, triage result model, or curator UI for
AI suggestions yet.

This guide defines boundaries for future AI-assisted preprocessing.

## Purpose

AI can assist curators by reducing repetitive work.

AI must not replace cultural authority, community consensus, or expert validation.

## Allowed AI Tasks

AI may be used for:

- entity type suggestion
- relation suggestion
- duplicate candidate detection
- spelling normalization suggestion
- summarization of long submissions
- metadata completion suggestion
- cultural sensitivity flag suggestion
- source note cleanup
- translation draft
- contributor feedback draft

## Forbidden AI Tasks

AI must not:

- automatically publish knowledge
- automatically validate cultural claims
- generate final RDF triples without review
- invent sources
- fabricate expert notes
- override a curator/expert decision
- train models on user-submitted sensitive content without consent
- expose private submissions to public prompts or logs

## AI Output Status

All AI output must be stored as suggestion.

Suggested fields:

```txt
ai_suggested_entity_type
ai_suggested_relations
ai_duplicate_candidates
ai_confidence_score
ai_triage_note
ai_model_name
ai_processed_at
```

## Example Output Schema

```json
{
  "suggested_entity_type": "instrument",
  "suggested_relations": [
    {
      "subject_label": "Gangsa",
      "predicate": "usedInEnsemble",
      "object_label": "Gong Kebyar",
      "confidence": 0.78
    }
  ],
  "duplicate_candidates": [],
  "uncertainty_note": "The submission does not include a source reference."
}
```

## Human Review Requirement

Curator UI must clearly label AI output:

```txt
AI suggestion, not validated.
```
