# Data Agent — demo script & verified answers

Questions to ask the agent on stage, the measure/entities each should resolve
to, and a one-line "expected shape" so you can tell at a glance it's right.
The headline numbers come from the generated sample data (seed 42).

## Tier 1 — KPI questions (configure as Verified Answers)

| # | Ask the agent | Resolves to | Expected shape |
|---|---|---|---|
| 1 | "What's our total transaction value and approval rate?" | `[Total Transaction Value]`, `[Approval Rate]` | ~$ multi-million, approval ≈ 88–92% |
| 2 | "What is the fraud rate, by count and by value?" | `[Fraud Rate]`, `[Fraud Value Rate]` | low single-digit % by count; higher by value |
| 3 | "How many open critical fraud alerts do we have?" | `[Critical Open Alerts]` | a small integer |
| 4 | "How many high-risk transactions in the last 30 days?" | `[High Risk Transactions]` + date filter | a few hundred |
| 5 | "How many active customers do we have?" | `[Active Customers (30d)]` | < total customers (220) |

## Tier 2 — "slice & dice" (shows the relationships working)

| # | Ask the agent | Crosses entities |
|---|---|---|
| 6 | "Which merchant categories have the highest fraud value?" | Transaction → Merchant |
| 7 | "Show fraud transactions by country on a map." | Transaction (geo) → Merchant |
| 8 | "What's the fraud rate for card-not-present vs card-present?" | Transaction → Channel |
| 9 | "Which customer segment has the highest average churn score?" | Customer (snapshot) |
| 10 | "Top 5 branches by fraud cases caught this month." | BranchSnapshot → Branch |

## Tier 3 — "investigate" (rules + drilldown, the wow moment)

| # | Ask the agent |
|---|---|
| 11 | "List wires over $10,000 made by politically-exposed customers." |
| 12 | "Are there any transactions on blocked cards that were approved?" |
| 13 | "Show me any activity on dormant accounts in the last week." |
| 14 | "Who are the top 10 customers by total fraud exposure, with their risk band?" |
| 15 | "Walk me through alert ALERT0000002 — customer, amount, rule, disposition." |

## Suggested 4-minute live flow

1. **Q1 + Q2** — establish the KPIs the agent knows (governed measures).
2. **Q7** — "show fraud by country on a map" → the live geo moment.
3. **Q8** — CNP vs card-present fraud → relationships across entities.
4. **Q11 or Q12** — a *rule-driven* investigation → this is the ontology paying
   off (the agent reasons in business terms, not table joins).
5. Switch to the **Copilot Studio** agent and ask Q3 again from Teams to show
   the same brain, published to a different surface.

> Tip: open the agent's **DAX inspection** panel during the demo so the audience
> sees the natural-language question compile to a governed DAX query against the
> ontology-bound model.
