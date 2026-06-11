# fabric-live-api-backend

A Node + TypeScript backend service that ingests an **external live REST API**,
streams events into a **Microsoft Fabric Eventstream → Eventhouse (KQL)**, and
exposes a small **write-back API** for a Fabric **Rayfin** data app to call.

> This is a standalone project intended to live in **its own repo**. It is
> currently scaffolded inside the `MortalKomat_Fabric_App_Rayfin` repo only so
> the work persists; everything here is self-contained and git-init-ready.

## Why this shape

Rayfin data apps render inside the Microsoft Fabric portal and read their data
through a Power BI **semantic model** (DAX) — they **can't write directly** to a
data store. So this backend is the **single write path** for both directions:

```
External REST API
      │  poll (or receive webhooks)
      ▼
┌──────────────────────────────┐        Fabric (Rayfin) app
│  fabric-live-api-backend     │◀── HTTP write-back ── (POST /api/events)
│  • ingest + validate         │
│  • batch → Eventstream       │
│  • app-facing write-back API │
└──────────────────────────────┘
      │  Event Hubs-compatible custom-app endpoint
      ▼
Fabric Eventstream ──▶ Eventhouse (KQL DB)
      │
      ▼
Power BI semantic model ──DAX──▶ Rayfin app reads (near-real-time)
```

Real-time ingestion (Eventstream custom-app source → Eventhouse) is the
Microsoft-recommended path for high-frequency live data, and batched sends are
recommended over per-row writes — both are reflected in the code.

## Project layout

```
src/
  config.ts                  env loading + validation (fail-fast)
  logger.ts                  pino logger
  types.ts                   Zod schemas + LiveEvent model  ⚠️ adapt to your API
  ingest/
    apiClient.ts             external REST client (retry + backoff + validation)
    poller.ts                non-overlapping poll loop → Eventstream
  stream/
    eventstreamProducer.ts   batched Event Hubs producer (Eventstream custom app)
  kql/
    eventhouseClient.ts      optional KQL read client (service-principal auth)
  api/
    server.ts                Express API: /api/events, /api/events/recent, /webhooks/ingest, /healthz
  index.ts                   wires it all together + graceful shutdown
scripts/
  eventhouse-setup.kql       KQL table + JSON ingestion mapping (run in Fabric)
tests/
  transform.test.ts          vitest unit tests for the transform layer
```

## Prerequisites in Fabric (one-time)

1. **Eventhouse + KQL DB** — Real-Time Intelligence → create an Eventhouse.
   Run [`scripts/eventhouse-setup.kql`](scripts/eventhouse-setup.kql) to create
   the `LiveEvents` table and JSON ingestion mapping.
2. **Eventstream** with a **Custom App source** and a **KQL Database destination**
   pointing at that table. Copy the custom-app **connection string** (Keys tab) —
   it's Event Hubs-compatible and carries `EntityPath=…`.
3. *(Optional, for the read API)* a **Microsoft Entra ID app registration**
   (service principal) granted **Viewer** on the KQL database.
4. Point a **Power BI semantic model** at the KQL DB and have your Rayfin app
   query it via DAX (the read path — unchanged from the MK Arena app pattern).

## Run it

```bash
npm install
cp .env.example .env     # fill in EVENTSTREAM_CONNECTION_STRING + external API details
npm run dev              # poller + API with hot reload
# or
npm run build && npm start
```

Useful scripts: `npm run typecheck`, `npm run lint`, `npm test`.

## Configuration

All config is environment-driven and validated at startup — see
[`.env.example`](.env.example) for the full annotated list. Key ones:

| Variable | Purpose |
|---|---|
| `EXTERNAL_API_BASE_URL` / `EXTERNAL_API_PATH` / `EXTERNAL_API_KEY` | the live REST API you ingest |
| `INGEST_POLL_INTERVAL_MS` / `INGEST_POLL_ENABLED` | poll cadence (disable if webhook-only) |
| `EVENTSTREAM_CONNECTION_STRING` | Fabric Eventstream custom-app endpoint |
| `EVENTSTREAM_BATCH_MAX_SIZE` / `_MAX_WAIT_MS` | batching behavior |
| `KUSTO_*` + `AZURE_*` | optional KQL read API (service principal) |
| `CORS_ALLOWED_ORIGINS` | Fabric portal origin(s) allowed to call write-back |

## API

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/healthz` | liveness + whether KQL is configured |
| `POST` | `/api/events` | **write-back from the Fabric app** (validated → Eventstream) |
| `GET` | `/api/events/recent?limit=50` | recent rows from the Eventhouse (debug/read) |
| `POST` | `/webhooks/ingest` | receive pushes from the external API (verify signatures before prod) |

## Adapt before production

- **`src/types.ts`** — `ExternalRecordSchema` is an example "metric reading".
  Replace its fields with your real API payload; the rest of the pipeline keys
  off the normalized `LiveEvent`.
- **Webhook auth** — `/webhooks/ingest` is unauthenticated in the scaffold. Add
  signature verification / a shared secret before exposing it.
- **App write-back auth** — consider validating the Fabric user's token on
  `/api/events` rather than relying on CORS alone.
- **Secrets** — never commit `.env`. In Azure, prefer Managed Identity /
  Key Vault over inline client secrets.

## Splitting into its own repo

```bash
# from this folder:
git init && git add . && git commit -m "Initial scaffold"
# create an empty GitHub repo, then:
git remote add origin git@github.com:<you>/fabric-live-api-backend.git
git push -u origin main
```
