# Deployment Guide

This document defines deployment and environment rules.

## Environments

Recommended:

| Environment | Purpose |
|---|---|
| Local | Development |
| Staging | QA and demo |
| Production | Public/field use |

## Services

The full system may require:

- mobile app build pipeline
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
DB_CONNECTION
DB_HOST
DB_DATABASE
DB_USERNAME
DB_PASSWORD
SPARQL_QUERY_ENDPOINT
SPARQL_UPDATE_ENDPOINT
SPARQL_USERNAME
SPARQL_PASSWORD
MEDIA_DISK
AI_TRIAGE_ENABLED
AI_PROVIDER
AI_API_KEY
```

Never commit secrets.

## RDF Deployment

Ontology deployment steps:

1. Validate ontology file.
2. Load ontology into triplestore.
3. Load sample RDF data.
4. Run competency question SPARQL tests.
5. Verify REST semantic search integration.
6. Restrict SPARQL update endpoint.

## Laravel Deployment Checklist

- [ ] `composer install --no-dev --optimize-autoloader`
- [ ] `.env` configured
- [ ] `php artisan key:generate` if new environment
- [ ] `php artisan migrate --force`
- [ ] `php artisan storage:link` if needed
- [ ] queue worker running
- [ ] scheduler configured
- [ ] logs writable
- [ ] cache configured
- [ ] HTTPS active

## Flutter Release Checklist

- [ ] API base URL configured
- [ ] app icon configured
- [ ] app name configured
- [ ] release signing configured
- [ ] debug logs removed
- [ ] permission texts reviewed
- [ ] offline sync tested
- [ ] accessibility checked
- [ ] real device testing completed
