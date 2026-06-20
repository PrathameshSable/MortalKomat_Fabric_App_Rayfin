# Fabric Data Agent — configuration

This is the grounding for the **Contoso Bank Payments & Fraud** data agent. It
turns the ontology + semantic model into a natural-language analyst that you can
demo live and publish to Copilot Studio.

## Where each piece of guidance goes

Microsoft's guidance is specific about *where* instructions live:

| Guidance | Put it in… | Why |
|---|---|---|
| Business terminology, metric definitions, analysis defaults, which table/measure to use | **Semantic model → Prep data for AI → AI instructions** | Only these are passed to the DAX-generation tool. |
| Which tables/columns/measures are in scope | **Prep data for AI → AI data schema** | Keeps the model lean = more accurate DAX. |
| Common, exact questions + the visual that answers them | **Prep data for AI → Verified answers** | Deterministic answers for demo-critical questions. |
| Cross-source routing, tone, formatting, abbreviations | **Data agent → Instructions** | Applies across all sources; *not* passed to DAX gen. |

> ⚠️ Don't put semantic-model-specific rules in the *data agent* instructions —
> they're ignored by the DAX tool. Keep them in **Prep for AI**.

---

## A. Paste into: Semantic model → Prep data for AI → AI instructions

```
You are the analytics brain for Contoso Bank's payments and fraud operation.
Always answer using the governed measures on the _Measures table; do not invent
ad-hoc aggregations when a measure exists.

Business definitions:
- "Fraud rate" = [Fraud Rate] (count) unless the user says "by value", then use
  [Fraud Value Rate].
- "Approval rate" = [Approval Rate].
- "High-value transaction" = AmountUsd > 3000; use [High Value Transactions].
- "High-risk transaction" = FraudScore >= 0.75; use [High Risk Transactions].
- "Active customer" = [Active Customers (30d)] (an approved transaction in the
  last 30 days).
- "Card-not-present / CNP" = transactions where dim_channel[IsCardPresent] = 0.
- "Open critical alerts" = [Critical Open Alerts].
- Monetary values are in USD ([... ]AmountUsd / measures already convert).

Analysis defaults:
- Default time grain is the last 30 days unless the user gives a period.
- When asked "where", group by dim_merchant[Country] or dim_branch[Region].
- When asked about a customer by name, match dim_customer[CustomerName].
- Round currency to whole dollars and rates to one decimal percent.

Risk rules to apply when asked about suspicious activity:
- Activity on a Dormant account, or any transaction on a Blocked card that was
  not Declined, is critical and should be surfaced.
- Wires over $10,000 by politically-exposed persons (dim_customer
  [IsPoliticallyExposed]=1) require enhanced due diligence.
```

## B. Paste into: Data agent → Instructions

```
You answer questions about Contoso Bank's payments, customers, accounts, cards,
merchants, branches and fraud alerts. Be concise and lead with the number, then
one sentence of context. Format money as USD and rates as percentages. If a
question is about live activity ("right now", "today", "last hour"), prefer the
most recent timestamps in fact_transaction. If a request needs personal data
beyond what's modeled (full PAN, government IDs), refuse and explain it's masked
for compliance. When unsure between two metrics, state the assumption you made.
```

## C. AI data schema (select these in Prep for AI)

Include: all `_Measures`, plus `dim_customer`, `dim_account`, `dim_card`,
`dim_merchant`, `dim_channel`, `dim_product`, `dim_branch`, `dim_currency`,
`dim_date`, `fact_transaction`, `fact_fraud_alert`,
`fact_account_balance_daily`, `fact_branch_daily_snapshot`.
Exclude raw key/ID columns the user will never ask about (e.g. surrogate keys)
to reduce noise.

See `example-questions.md` for the verified-answer set and a demo script.
