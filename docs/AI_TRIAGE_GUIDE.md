# AI Triage Guide

This document defines safe AI-assisted preprocessing rules.

## Current Implementation

AI triage in the mobile app is review-only and non-authoritative. The Flutter
client renders backend-provided `triage_suggestion` payloads on the review
detail screen when the API includes them, but it never shows those suggestions
on contributor-facing screens and never treats them as workflow decisions.

This guide defines boundaries for the backend triage pipeline and for the
review-only mobile display.

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

MVP 9 uses rule-based preprocessing only. It does not call an external AI provider, does not store raw prompts, and does not store raw model responses. Triage runs automatically after successful contribution submission only when `AI_TRIAGE_ENABLED=true`; the default is disabled.

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

Curator and review UI must clearly label AI output:

```txt
AI suggestion, not validated.
```

## Implemented MVP 9 Behavior

Implemented rule-based triage may suggest:

- duplicate candidates from published public knowledge items and non-sensitive submitted review candidates
- entity type and ontology class hints from the submitted `knowledge_type`
- relation hints using only documented MVP ontology properties
- missing metadata such as related entities, source strength, language, media license, media credit, consent, and recording place
- language normalization for simple spacing and language metadata defaults
- curator summaries extracted from submitted text only

The backend stores one `triage_results` record per run and mirrors the latest suggestion into `contributions.ai_*` fields for operational convenience. Review-facing resources expose `triage_suggestion` only to authorized non-owner review roles. The mobile review detail screen renders that suggestion as `AI suggestion, not validated.` and keeps it subordinate to human validation. Public endpoints, normal contributor contribution endpoints, RDF publication responses, and SPARQL responses do not expose triage suggestions.

Triage must not:

- change contribution workflow status
- create review decisions
- create approved ontology mappings
- queue or publish RDF
- create public knowledge items
- override curator or expert decisions
