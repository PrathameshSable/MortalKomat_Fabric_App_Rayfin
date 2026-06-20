# Rayfin app binding layer — Contoso Bank

This folder is the **data-plane contract** for a Rayfin data app built on the
Contoso Bank ontology. It is intentionally UI-free: it provides the `.dax`
queries, typed wrappers, and config so you can drop them into the existing MK
Rayfin app (or a fresh Fabric App starter) and wire up screens.

## What's here

| File | Purpose |
|---|---|
| `queries/*.dax` | One DAX query per screen need (KPIs, live stream, fraud-by-country, channel split, merchant risk, alert queue, watchlist). |
| `queries/*.ts` | Thin typed wrappers; each returns `{ connection: "bankModel", query }`. |
| `queries/index.ts` | Barrel export. |
| `fabric.yaml.example` | Semantic-model connection (`bankModel` alias). |
| `rayfin.yml.example` | Rayfin app manifest. |

## How to use it in a Rayfin app

1. Copy `queries/` into your app under `src/queries/bank/`.
2. Copy `fabric.yaml.example` → `fabric.yaml`, fill in your workspace + model
   GUIDs, then `npx fabric-app-data generate -o src/fabric.generated.ts`.
3. Call a query through the existing `useSemanticModelQuery` hook:

   ```ts
   import { transactionsLiveQuery } from "@/queries/bank";

   const { data, isLoading } = useSemanticModelQuery(transactionsLiveQuery());
   if (data?.status === "success") {
     // data.table.rows -> [TransactionId, Ts, AmountUsd, Status, Type,
     //                      FraudScore, IsFraud, Country, Lat, Lon]
     // plot rows on a world map; color by FraudScore, pulse newest first.
   }
   ```

4. `cp rayfin.yml.example rayfin.yml`, then `npx rayfin login && npx rayfin up`.

## Suggested screens (the "ships moving" equivalent)

- **Live Map** — `transactionsLiveQuery` + `fraudByCountryQuery`: pins light up
  across the world as transactions arrive; red pulses = fraud. Poll with
  `bypassCache: true` on an interval for the streaming effect.
- **Command Center** — `kpiSummaryQuery` KPI strip + `channelFraudQuery` and
  `merchantRiskQuery` charts.
- **Fraud Desk** — `openAlertsQuery` analyst queue + `customerWatchlistQuery`.

> The column order in each `.dax` is fixed and documented inline — bind UI to
> row indexes the same way the MK app's `fighterRowMapper.ts` does.
