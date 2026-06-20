# Contoso Bank — Real-Time Payments & Fraud Intelligence

A **webinar-ready Fabric IQ ontology demo** for financial services. It models a
retail & commercial bank's payment activity as a governed ontology, grounds a
**Fabric Data Agent**, publishes that agent to **Copilot Studio**, and exposes
the same model to a **Rayfin** data app — with a live, geo-located transaction
stream as the "things moving on a map" moment.

> This is a self-contained sibling to the Mortal Kombat app in this repo. It does
> **not** touch the MK app — it reuses the same architecture (Lakehouse →
> semantic model → Rayfin) for a finance use case.

## The story in one diagram

```
                     ┌─────────────────────────────────────────────┐
 data/ (14 CSVs) ──► │ Fabric Lakehouse  (14 Delta tables)          │
                     └───────────────┬─────────────────────────────┘
                                     │ bound by ontology.json
                     ┌───────────────▼─────────────────────────────┐
                     │ Ontology + Semantic Model                    │
                     │  entities · relationships · rules · measures │
                     └───────────────┬─────────────────────────────┘
              ┌──────────────────────┼───────────────────────────┐
              ▼                      ▼                            ▼
       Fabric Data Agent      Rayfin data app             Copilot Studio
       (NL Q&A, DAX)          (live map, KPIs)            (Teams / M365)
```

## What's in the box

| Folder | Contents |
|---|---|
| `ontology/` | `ontology.json` (machine-readable: 14 entity types, 20 relationships, 6 rules, glossary) + `ONTOLOGY.md` (spec + Mermaid ER diagram). |
| `data/` | 14 generated CSVs (~62k rows) — the sample data, ready to upload. |
| `tools/generate_data.py` | Deterministic generator (pure stdlib, seed 42) — re-run to refresh / roll the live window. |
| `fabric/notebooks/` | `01_build_lakehouse_tables.py` (load Delta + make the stream live) and `02_validate_tables.sql`. |
| `fabric/semantic-model/` | `measures.dax` + `measures.tmdl` — the governed KPI bindings. |
| `data-agent/` | `DATA_AGENT_INSTRUCTIONS.md` (where each instruction goes) + `example-questions.md` (demo script + verified answers). |
| `copilot-studio/` | `COPILOT_STUDIO_GUIDE.md` — publish the agent to Teams / M365. |
| `rayfin-app/` | `.dax` queries + typed wrappers + config to bind a Rayfin app. |

## The 14 entities

**Dimensions (9):** Customer · Account · Card · Merchant · Channel · Product ·
Branch · Currency · Date
**Facts (5):** Transaction (live stream) · FraudAlert · AccountBalanceSnapshot ·
CustomerSnapshot · BranchSnapshot

See `ontology/ONTOLOGY.md` for the full ER diagram, properties and rules.

## Headline numbers in the sample data (seed 42, anchored 2026-06-20)

| Metric | Value |
|---|---|
| Transactions | **9,000** ( ~2,640 in the live 48h window ) |
| Total value | **$27.9M** |
| Approval rate | **96.8%** |
| Fraud rate | **0.60%** by count · **3.9%** by value ($1.1M) |
| High-risk transactions (score ≥ 0.75) | **84** |
| International share | **34.5%** |
| Fraud alerts | **110** (35 open, 12 critical-open, 52 confirmed) |
| Top fraud corridors | Nigeria · Malta · Costa Rica (high-risk merchant categories) |

## Build order (≈ 30–45 min in Fabric, first time)

1. **Generate / refresh data** (optional — CSVs are already committed):
   ```bash
   python3 tools/generate_data.py
   ```
2. **Lakehouse:** create `ContosoBankLakehouse`, upload `data/*.csv` to
   `Files/contoso_bank/`, run `fabric/notebooks/01_build_lakehouse_tables.py`.
   Run `02_validate_tables.sql` to confirm row counts + integrity.
3. **Semantic model:** build a model on the 14 tables, create the relationships
   from `ontology/ontology.json`, run `fabric/semantic-model/measures.dax` in the
   DAX query view, and update the model to persist the measures.
4. **Prep for AI:** on the model, set the AI data schema, paste the AI
   instructions from `data-agent/DATA_AGENT_INSTRUCTIONS.md §A`, add verified
   answers from `data-agent/example-questions.md`.
5. **Data Agent:** create it, add the semantic model, paste the agent
   instructions (`§B`), and test with the demo script.
6. **Copilot Studio:** follow `copilot-studio/COPILOT_STUDIO_GUIDE.md` to publish
   to Teams / M365.
7. **Rayfin app:** use `rayfin-app/` — copy the queries + config into the Fabric
   App and bind the live-map / command-center screens.

## Webinar tip

Run the "make the stream live" cell in the notebook (or re-run
`generate_data.py`) shortly before you present so `fact_transaction` /
`fact_fraud_alert` timestamps land at "now" — the live map and "transactions in
the last hour" questions will look real-time.

---
*Synthetic demo data. "Contoso" is Microsoft's fictional sample company;
customer/merchant records are fabricated for demonstration only.*
