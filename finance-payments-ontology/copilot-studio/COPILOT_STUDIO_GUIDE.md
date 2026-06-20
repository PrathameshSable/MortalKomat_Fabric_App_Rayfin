# Publishing the Data Agent to Copilot Studio

Once the Fabric **Data Agent** answers well (see `../data-agent/`), surface it to
business users through **Microsoft Copilot Studio** so they can ask questions
from Teams, M365 Copilot, or a custom web chat.

## Architecture

```
ContosoBankLakehouse (14 Delta tables)
        │  bound by
        ▼
Ontology + Power BI Semantic Model  (entities, relationships, measures, rules)
        │  grounds
        ▼
Fabric Data Agent  ("Contoso Payments Analyst")
        │  published as a connector / knowledge source
        ▼
Copilot Studio agent  ──►  Teams · M365 Copilot · web chat · Rayfin app
```

## Steps

1. **Finish the Data Agent in Fabric.** Validate the example questions, then use
   the **"..." → Publish** action on the data agent. Note the published agent's
   workspace + item id.

2. **Create (or open) an agent in Copilot Studio** (`copilotstudio.microsoft.com`).

3. **Add the Fabric data agent as a knowledge source.**
   - In the agent, go to **Knowledge → Add knowledge → Microsoft Fabric**.
   - Sign in with an account that can read the Fabric workspace.
   - Select the published **Contoso Payments Analyst** data agent.
   - Authentication: use **"Authenticate with user identity"** so every query
     runs as the signed-in user and honors Fabric/RLS permissions.

4. **Add topic / starter prompts** mirroring `example-questions.md` so users see
   suggested questions (e.g. "Fraud rate this month", "Open critical alerts",
   "Fraud by country").

5. **Set the agent instructions** (Copilot Studio → Instructions) to the same
   tone/formatting block from `data-agent/DATA_AGENT_INSTRUCTIONS.md → section B`.

6. **Test in the Copilot Studio test pane**, then **Publish** and add channels:
   **Microsoft Teams** is the best webinar demo (ask a question from a Teams
   chat and watch it answer from the governed model).

## Governance notes (good to say out loud in the webinar)

- Answers are grounded in the **ontology + semantic model**, not the raw lake, so
  every number uses the *governed* definition of "fraud rate", "approval rate",
  etc.
- Queries execute **in the signed-in user's context** — Fabric permissions and
  row-level security apply, so the same agent shows different users different data.
- PII (full card numbers, IDs) is **masked at the source** (`CardNumberMasked`),
  so it can never be returned.

## Optional: also expose via Foundry / custom apps

The same data agent can be attached to an Azure AI **Foundry** agent via the
`fabric_iq_preview` tool (Fabric IQ), or queried directly from the Rayfin app's
data plane. The ontology is the single grounding layer behind all of them.
