# Skyfield — YouTube / Demo Script

**Title idea:** *"I built a live 3D flight tracker on Microsoft Fabric — every plane on Earth, in real time"*
**Runtime:** ~7 minutes
**Format:** screen capture of the app + VS Code + the Fabric portal, voiceover.

Legend: 🎙️ = voiceover · 🖥️ = what's on screen · ✂️ = edit/cut note.

---

## 0:00 — COLD OPEN (the hook)

🖥️ Full-screen the spinning globe, planes streaming, day/night terminator visible.
🎙️ "Right now, about ten thousand aircraft are in the sky. This is every one of them —
live — rendered on a photoreal Earth, in the browser. No game engine. This is a
**Microsoft Fabric data app**, and the data is real ADS-B traffic, seconds old.
Let me show you how it works — and how it's built."

✂️ Punch in on a plane as it crosses a route arc. Hold 2s.

---

## 0:25 — WHAT IS SKYFIELD

🖥️ Slow orbit; hover the KPI strip (Aircraft tracked / Airborne / Countries / Avg altitude).
🎙️ "This is **Skyfield**. It pulls live aircraft positions from the OpenSky Network,
enriches each flight with its route and aircraft type, streams it through Fabric's
real-time pipeline, and visualizes it as a 3D intelligence dashboard. Every glyph is a
real plane — its nose points along its true heading, and its colour tells you its
country of origin or its altitude."

---

## 0:50 — THE ARCHITECTURE (the money shot)

🖥️ Cut to a simple pipeline diagram (build this slide):
```
OpenSky API ──► Fabric Notebook ──► Eventstream ──► Eventhouse (KQL) ──► Semantic Model ──► Skyfield app
 (ADS-B)        (Python: poll +      (real-time      (Flights table)     (DirectQuery)      (React + three.js,
                 enrich + push)       ingestion)                                              Rayfin data app)
```
🎙️ "Here's the whole pipeline. A Python notebook in Fabric polls OpenSky every 90
seconds, enriches each flight with its origin and destination airport, then pushes it
into an **Eventstream**. The Eventstream lands it in an **Eventhouse** — that's Fabric's
real-time KQL database. A **semantic model** sits on top, and the app queries that model
with DAX. The front end is a **Rayfin data app** — React and three.js — that runs
*inside* Fabric and talks to the model through the official SDK. Real-time in, 3D out."

✂️ Animate each arrow lighting up as you say it.

---

## 1:40 — LIVE DEMO: THE GLOBE

🖥️ Back in the app. Drag to rotate. Toggle **Lighting: Auto → Day → Night**.
🎙️ "The Earth has a live day/night terminator — the lit half tracks the real sun
position right now. Switch to Night and the city lights come up. These aren't sprites —
it's a custom GLSL shader blending a day texture and a night texture along the terminator."

🖥️ Toggle **Flight paths** on. Show the glowing arcs.
🎙️ "Turn on flight paths and you get great-circle routes from origin to destination —
the actual shortest path over the curved Earth, not a straight line on a flat map."

🖥️ Toggle **Airports**. Zoom toward Europe; show the heat-coloured airport dots + labels.
🎙️ "Airports light up by how busy they are — a live heatmap of global traffic."

---

## 2:40 — DRILLING IN: SEARCH, SLICERS, FOLLOW

🖥️ Open **Search & filter**. Pick a country (e.g. Spain) from the slicer.
🎙️ "Pick a country and the view reframes to its airspace, and the panel becomes a live
flight list — callsign, route, altitude."

🖥️ Note the airline + aircraft-maker slicers narrowing to that country.
🎙️ "The airline and aircraft-maker filters automatically scope to that country's fleet.
Pick an airline — say Iberia — and you're down to their aircraft."

🖥️ Click a plane → the **Aircraft detail** panel. Click **Follow**.
🎙️ "Click any aircraft for its live telemetry — route, airline, aircraft type, altitude,
speed, heading, climb or descent. Hit **Follow** and the camera locks on and tracks it
across the globe."

🖥️ Click an **Altitude** bar and a **maker** bar to show cross-filtering.
🎙️ "The altitude histogram and the Boeing-versus-Airbus breakdown are both clickable —
they filter the entire scene."

✂️ Quick montage of clicking through these, upbeat.

---

## 3:50 — UNDER THE HOOD: THE CODE TOUR

🖥️ Switch to VS Code. Open these files in order (keep each on screen ~10–15s):

**1. `fabric-notebooks/opensky_to_eventstream.py`** — the producer.
🎙️ "This notebook is the data source. It authenticates to OpenSky, polls aircraft for a
bounding box, and for each flight looks up its route and aircraft type from a free API —
caching every lookup so it only pays for it once. Then it pushes the enriched records to
the Eventstream."

**2. `src/data/fabric/flightQueries.ts`** — the query.
🎙️ "On the app side, this is the entire live query — one DAX statement that grabs the
6,000 most-recent rows from the Flights table. We return the whole row, so adding a
column to the table flows through automatically."

**3. `src/data/fabric/fabricProvider.ts`** — the bridge.
🎙️ "This maps the query result into the app's flight objects — by column *name*, and it
keeps only the newest record per aircraft. This is where Fabric meets the 3D scene."

**4. `src/three/Globe.tsx`** — the Earth.
🎙️ "The globe — the day/night shader and the live sun position live here."

**5. `src/three/Scene.tsx` + `src/three/Aircraft.tsx`** — the planes.
🎙️ "And this is the scene: the aircraft glyphs, the route arcs, the airport heatmap, the
follow-camera — all instanced for performance, so thousands of planes stay at 60fps."

**6. `src/fabric.generated.ts`** — the connection.
🎙️ "One generated file wires the app to the exact Fabric workspace and semantic model.
That's the only thing that changes between sample mode and live."

---

## 5:30 — HOW IT STAYS LIVE (recap on the running app)

🖥️ Split screen: notebook log (`sent 12494 flights …`) next to the app updating.
🎙️ "So the loop is: the notebook sends a fresh batch every 90 seconds, it lands in the
Eventhouse, the semantic model serves it, and the app re-queries on an interval — bypassing
the cache so the globe never freezes. Producer on the left, planes moving on the right."

---

## 6:10 — WHY FABRIC (the takeaway)

🎙️ "What I love about this: it's not a bespoke server farm. The ingestion, the real-time
database, the semantic layer, and the hosted app all live inside **Microsoft Fabric**.
The same platform you'd use for BI dashboards is running a live, interactive 3D app — and
because it's a semantic model underneath, every number on screen is governed, queryable,
and reusable."

---

## 6:40 — OUTRO / CTA

🖥️ Pull back to the full spinning globe, planes streaming.
🎙️ "That's Skyfield — every plane on Earth, live, on Microsoft Fabric. Code and the full
deployment runbook are linked below. If you want to see the route-enrichment or the shader
broken down in detail, tell me in the comments. Thanks for watching."

✂️ End card: app name + repo link + "Built on Microsoft Fabric + Rayfin".

---

## Shot list / B-roll checklist
- [ ] Globe spin, day → night toggle
- [ ] Route arcs appearing
- [ ] Airport heatmap zoom
- [ ] Country pick → reframe + flight list
- [ ] Airline / maker slicer narrowing
- [ ] Click plane → detail → Follow camera
- [ ] Altitude + maker bar cross-filter
- [ ] VS Code file tour (6 files above)
- [ ] Notebook log + app side-by-side
- [ ] Fabric portal: Eventstream + Eventhouse `Flights | count`

## One-line elevator pitch (for the video description)
> Skyfield renders every aircraft on Earth in real time on a photoreal 3D globe — powered
> end-to-end by Microsoft Fabric: OpenSky ADS-B → Fabric notebook → Eventstream → Eventhouse
> → semantic model → a Rayfin React + three.js data app.
