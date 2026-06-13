# ─────────────────────────────────────────────────────────────────────────────
# OpenSky → Fabric Eventstream — ingestion notebook
#
# Paste this into a Microsoft Fabric NOTEBOOK (Python). It pulls live aircraft
# from OpenSky and pushes them to your Eventstream's CUSTOM ENDPOINT, which then
# routes them to the Eventhouse `Flights` table (via the FlightsJson mapping).
#
# This is the in-Fabric alternative to running the Node `fabric-live-api-backend`
# locally — same data, same schema, no local machine required.
#
# HOW TO RUN
#   1. Fabric → your workspace → New → Notebook. Set language to PySpark/Python.
#   2. First cell:  %pip install azure-eventhub requests
#   3. Paste the rest below into a second cell, fill in the 4 CONFIG values, Run.
#   4. It ingests for RUN_MINUTES, then stops. Re-run (or schedule via a pipeline)
#      to keep going. Verify with:  LatestFlights() | count
# ─────────────────────────────────────────────────────────────────────────────

# %pip install azure-eventhub requests      # <-- run this in its own first cell

import json
import time
from datetime import datetime, timezone

import requests
from azure.eventhub import EventData, EventHubProducerClient

# ── CONFIG — fill these in ───────────────────────────────────────────────────
OPENSKY_CLIENT_ID = "prathameshsable-api-client"
OPENSKY_CLIENT_SECRET = "<paste your OpenSky secret (Reset Credential)>"
# Eventstream custom-endpoint connection string (source node → Keys tab).
# Must contain EntityPath=...
EVENTSTREAM_CONNECTION_STRING = "<paste from the custom endpoint Keys tab>"
# Bounding box: south, west, north, east (degrees).
#   Global  (-60, -180, 75, 180)  → ~4 credits/call  → use POLL_SECONDS >= 90
#   Region  (48, 2, 52, 8) ~24 sq°→  1 credit/call   → POLL_SECONDS 25 is fine
OPENSKY_BBOX = (-60, -180, 75, 180)   # whole world for the reference look

POLL_SECONDS = 90      # global ≈ 960 calls/day × 4 credits = 3,840 (under 4,000/day)
RUN_MINUTES = 120      # how long this notebook run keeps ingesting

# ── OpenSky endpoints ────────────────────────────────────────────────────────
TOKEN_URL = (
    "https://auth.opensky-network.org/auth/realms/opensky-network"
    "/protocol/openid-connect/token"
)
STATES_URL = "https://opensky-network.org/api/states/all"


def get_token() -> str:
    r = requests.post(
        TOKEN_URL,
        data={
            "grant_type": "client_credentials",
            "client_id": OPENSKY_CLIENT_ID,
            "client_secret": OPENSKY_CLIENT_SECRET,
        },
        timeout=30,
    )
    r.raise_for_status()
    return r.json()["access_token"]


def fetch_states(token: str):
    lamin, lomin, lamax, lomax = OPENSKY_BBOX
    r = requests.get(
        STATES_URL,
        headers={"Authorization": f"Bearer {token}"},
        params={"lamin": lamin, "lomin": lomin, "lamax": lamax, "lomax": lomax},
        timeout=30,
    )
    r.raise_for_status()
    return r.json().get("states") or []


def to_flight(s):
    """Map an OpenSky state vector → the Flights table schema. None if no position."""
    lon, lat = s[5], s[6]
    if lon is None or lat is None:
        return None
    now = datetime.now(timezone.utc).isoformat()
    callsign = (s[1] or "").strip() or None
    return {
        "icao24": s[0],
        "callsign": callsign,
        "originCountry": s[2],
        "longitude": lon,
        "latitude": lat,
        "geoAltitude": s[13],
        "baroAltitude": s[7],
        "velocity": s[9],
        "heading": s[10],
        "verticalRate": s[11],
        "onGround": s[8],
        "lastContact": datetime.fromtimestamp(s[4], tz=timezone.utc).isoformat(),
        "ingestedAt": now,
        # Route — filled in by enrich_routes() from the callsign (null if unknown).
        "originLat": None, "originLon": None, "originIata": None,
        "destLat": None, "destLon": None, "destIata": None,
    }


# ── Route enrichment (callsign → origin/destination airport) ──────────────────
# adsbdb.com is free, no key. We cache each callsign (including "unknown") so we
# only hit the API once per callsign, and cap new lookups per cycle to be polite.
ROUTE_CACHE: dict = {}
MAX_LOOKUPS_PER_CYCLE = 60


def lookup_route(callsign):
    if callsign in ROUTE_CACHE:
        return ROUTE_CACHE[callsign]
    route = None
    try:
        r = requests.get(f"https://api.adsbdb.com/v0/callsign/{callsign}", timeout=10)
        if r.status_code == 200:
            fr = (r.json().get("response") or {}).get("flightroute") if isinstance(r.json().get("response"), dict) else None
            if fr:
                o, d = fr.get("origin") or {}, fr.get("destination") or {}
                if o.get("latitude") is not None and d.get("latitude") is not None:
                    route = {
                        "originLat": o.get("latitude"), "originLon": o.get("longitude"),
                        "originIata": o.get("iata_code"),
                        "destLat": d.get("latitude"), "destLon": d.get("longitude"),
                        "destIata": d.get("iata_code"),
                    }
    except Exception:
        route = None
    ROUTE_CACHE[callsign] = route
    return route


def enrich_routes(flights):
    new = 0
    for f in flights:
        cs = f.get("callsign")
        if not cs:
            continue
        if cs in ROUTE_CACHE:
            route = ROUTE_CACHE[cs]
        elif new < MAX_LOOKUPS_PER_CYCLE:
            route = lookup_route(cs)
            new += 1
            time.sleep(0.05)
        else:
            route = None  # resolve on a later cycle
        if route:
            f.update(route)


def send(producer, flights):
    batch = producer.create_batch()
    for f in flights:
        try:
            batch.add(EventData(json.dumps(f)))
        except ValueError:  # batch full → flush and start a new one
            producer.send_batch(batch)
            batch = producer.create_batch()
            batch.add(EventData(json.dumps(f)))
    if len(batch) > 0:
        producer.send_batch(batch)


producer = EventHubProducerClient.from_connection_string(EVENTSTREAM_CONNECTION_STRING)
token = get_token()
deadline = time.time() + RUN_MINUTES * 60
print(f"Ingesting OpenSky → Eventstream for {RUN_MINUTES} min (bbox={OPENSKY_BBOX})")

try:
    while time.time() < deadline:
        try:
            states = fetch_states(token)
            flights = [f for f in (to_flight(s) for s in states) if f]
            if flights:
                enrich_routes(flights)
                routed = sum(1 for f in flights if f["originLat"] is not None)
                send(producer, flights)
                print(f"{datetime.now():%H:%M:%S}  sent {len(flights)} flights ({routed} with routes)")
        except requests.HTTPError as ex:
            if ex.response is not None and ex.response.status_code == 401:
                token = get_token()  # token expired → refresh
            else:
                print("HTTP error:", ex)
        time.sleep(POLL_SECONDS)
finally:
    producer.close()
    print("done — producer closed")
