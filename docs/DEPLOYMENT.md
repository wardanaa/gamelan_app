# Deployment Guide

This document defines deployment and environment rules.

## Current Implementation

The current repository can be treated as a Flutter app repository. Backend,
database, queue worker, media storage, ontology deployment, and triplestore
deployment are target-system concerns and are not present here yet.

## Environments

Recommended:

| Environment | Purpose |
|---|---|
| Local | Development |
| Staging | QA and demo |
| Production | Public/field use |

## Services

The API deployment may require:

- Laravel API server
- relational database
- object/media storage
- queue worker
- scheduler/cron
- Apache Jena Fuseki or compatible triplestore
- reverse proxy
- HTTPS certificate

## Environment Variables

Backend should configure:

```txt
APP_ENV
APP_KEY
APP_URL
SANCTUM_STATEFUL_DOMAINS
SANCTUM_TOKEN_PREFIX
DB_CONNECTION
DB_HOST
DB_DATABASE
DB_USERNAME
DB_PASSWORD
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
MEDIA_DISK
AI_TRIAGE_ENABLED
AI_PROVIDER
AI_API_KEY
AI_TRIAGE_MODEL_NAME
AI_TRIAGE_DUPLICATE_LIMIT
AI_TRIAGE_DUPLICATE_MIN_SIMILARITY
```

Never commit secrets.

## RDF Deployment

Ontology deployment steps:

1. Validate ontology file.
2. Load ontology into triplestore.
3. Load sample RDF data.
4. Run competency question SPARQL tests against the query endpoint and published graph.
5. Verify REST semantic search integration.
6. Restrict SPARQL update endpoint.
7. Confirm queue workers can run RDF publication jobs.
8. Confirm failed RDF publication logs do not expose secrets or restricted cultural detail.

## Laravel Deployment Checklist

- [ ] `composer install --no-dev --optimize-autoloader`
- [ ] `.env` configured
- [ ] `php artisan key:generate` if new environment
- [ ] `php artisan migrate --force`
- [ ] Sanctum `personal_access_tokens` table migrated
- [ ] `php artisan storage:link` if needed
- [ ] queue worker running
- [ ] scheduler configured
- [ ] logs writable
- [ ] cache configured
- [ ] HTTPS active
- [ ] `php artisan gamelan:deployment-check` returns no failed checks

## Deployment Readiness Command

Run the safe readiness command before staging review and production release:

```txt
php artisan gamelan:deployment-check
php artisan gamelan:deployment-check --json
```

The command checks environment configuration, `APP_KEY`, `APP_DEBUG`, HTTPS `APP_URL` for staging and production, database connectivity, queue configuration and database queue tables, media disk safety, storage/log writability, SPARQL query and update endpoint configuration, RDF namespace and graph configuration, AI triage defaults, scheduler status, and safe logging posture.

The command does not print secret values, SPARQL credentials, raw triplestore responses, media storage paths, private notes, or user data. Missing SPARQL endpoints are warnings in local development but failures in staging and production. `MEDIA_DISK=public` is unsafe for staging and production because workflow media can contain private or culturally restricted evidence.

Scheduler status is reported as `warn` because the current MVP has no required recurring application task. If scheduled tasks are added later, configure external cron to run Laravel's scheduler and update this checklist.

## API Release Checklist

- [ ] `/api/v1` routes verified
- [ ] Sanctum bearer authentication and current-token revocation verified
- [ ] authorization policies verified
- [ ] validation responses checked for client-safe messages
- [ ] contribution workflow transitions tested
- [ ] provenance/version trace endpoints checked for authorization and safe metadata
- [ ] audit logs checked for private notes, raw AI prompts, media storage paths, file URLs, IP address, user agent, secrets, and restricted cultural content leakage
- [ ] media storage permissions checked
- [ ] `MEDIA_DISK` points to a private storage disk and does not expose restricted files through public links
- [ ] queue workers processing jobs
- [ ] scheduler configured if recurring jobs are used
- [ ] SPARQL query endpoint configured for backend REST semantic search
- [ ] SPARQL query endpoint network access restricted from public clients
- [ ] SPARQL update endpoint not publicly reachable
- [ ] RDF publication queue tested against staging triplestore
- [ ] `RDF_PUBLISHED_GRAPH_URI` and `RDF_PROVENANCE_GRAPH_URI` point to the intended named graphs
- [ ] `AI_TRIAGE_ENABLED` and `AI_PROVIDER=rules` verified for the target environment
- [ ] AI triage queue behavior tested without external provider calls
- [ ] application logs checked for secret, personal data, and restricted cultural content leakage
- [ ] login, browse list, semantic search, and contribution submission checked against the MVP response-time targets in `EVALUATION_QA.md`
