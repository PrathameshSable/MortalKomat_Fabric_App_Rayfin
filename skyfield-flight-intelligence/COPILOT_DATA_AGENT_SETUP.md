# "Ask Skyfield" — Copilot Studio + Fabric Data Agent setup

This wires the in-app chat overlay (`src/components/ChatOverlay.tsx`) to a
**Microsoft Copilot Studio** agent that has a **Fabric data agent** connected — so
users can ask natural-language questions ("busiest country right now?", "how many
aircraft are airborne?") and get answers grounded on the same live flight data the
globe uses.

```
Skyfield app  ──Direct Line token──►  Copilot Studio agent  ──connected agent──►  Fabric data agent  ──►  Eventhouse / flightsModel
 (Web Chat)                            (orchestration + chat)                      (NL → governed query)     (live Flights data)
```

> ⚠️ **Preview / requirements.** Fabric data agent ↔ Copilot Studio is in **preview**.
> It needs an **F2+ (or P1+) Fabric capacity**, a **Microsoft 365 Copilot license**, both
> resources on the **same tenant** signed in with the **same account**, and the
> **cross-geo processing/storing for AI** tenant settings enabled. The connected-data-agent
> setup is formally validated for **Microsoft Teams**; a website embed (what this app uses)
> *may* work but isn't officially validated yet. Responses can leave Fabric's compliance
> boundary. Treat this as an experimental/demo feature.

---

## 1. Build & publish the Fabric data agent

1. In Fabric, open your workspace → **New → Data agent** (Data Science).
2. Add a data source — your **Eventhouse KQL database** (the `Flights` table) and/or the
   **`flightsModel` semantic model**. You only need **read** access.
3. Give it clear **instructions/examples**, e.g. *"You answer questions about live aircraft.
   Flights are in the `Flights` table: originCountry, callsign, airline, manufacturer,
   onGround, geoAltitude, ingestedAt. Use LatestFlights() for current state."*
4. Test it in the data-agent chat until answers look right.
5. **Publish** the data agent with a **rich description** (required for it to appear in
   Copilot Studio).

## 2. Connect it inside a Copilot Studio agent

1. Go to [copilotstudio.microsoft.com](https://copilotstudio.microsoft.com) → pick your
   environment → **Create → New agent**. Name it (e.g. *Skyfield Assistant*) and describe it.
2. Open the agent → top pane **Agents → + Add → Microsoft Fabric**.
3. Create/choose the **Fabric connection**, then select your **published data agent → Add agent**.
4. (Optional) set the data agent's auth to **User authentication** or **Agent author
   authentication** depending on whether each end user has Fabric access.
5. **Settings → Orchestration → enable generative (AI) orchestration** — this lets the agent
   decide to call the Fabric data agent.
6. Use the test pane on the right to confirm it routes questions to the data agent.

## 3. Expose a web channel + grab the token endpoint

1. **Publish** the Copilot Studio agent.
2. **Settings → Security → Authentication.** For the simple in-app embed used here, choose
   **No authentication** (makes the Direct Line token endpoint publicly callable). If you need
   the agent gated, use the M365 Agents SDK / Direct Line with your own token relay instead.
3. **Settings → Channels →** enable a web channel ("Custom website" / "Mobile app").
4. Copy the **Token Endpoint** (looks like
   `https://<region>.directline.botframework.com/v3/directline/tokens/generate`, or a
   `…/powervirtualagents/…/directline/token` URL for Copilot Studio).

## 4. Point the app at it

In `skyfield-flight-intelligence/.env.local` (or your Rayfin/host env):

```
VITE_COPILOT_TOKEN_ENDPOINT=<the token endpoint you copied>
```

Then `npm run dev` (or rebuild/redeploy). The **✦ button** appears bottom-right; click it to
open **Ask Skyfield**. If the var is unset, the overlay shows a "not wired up" hint and the
globe is unaffected.

---

## How the app uses it (code)

`src/components/ChatOverlay.tsx`:
1. Loads the Bot Framework **Web Chat** bundle from the CDN (kept out of the JS bundle).
2. `fetch(VITE_COPILOT_TOKEN_ENDPOINT)` → `{ token }`.
3. `WebChat.createDirectLine({ token })` → `WebChat.renderWebChat({ directLine, styleOptions })`.
4. `styleOptions` theme the canvas to Skyfield's dark glassmorphism look.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| Overlay says "not wired up" | `VITE_COPILOT_TOKEN_ENDPOINT` unset / not rebuilt after setting it |
| "Token endpoint returned 401/403" | Agent not set to **No authentication**, or wrong endpoint |
| "Failed to load the Web Chat script" | CDN blocked by network/CSP — allow `cdn.botframework.com` |
| Chat works but ignores flight data | Data agent not **connected** in Copilot Studio, or **generative orchestration** off, or the data agent isn't **published** |
| Data agent missing in Copilot Studio's list | Not published, different tenant/account, or missing permissions |
