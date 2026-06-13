/**
 * DAX the live provider runs against the flight semantic model (DirectQuery /
 * Direct Lake over the Eventhouse `Flights` table). `Flights` is append-only, so
 * we pull the most-recent rows and the app keeps the latest one per aircraft
 * (rows arrive newest-first; see rowsToLatestFlights in fabricProvider.ts).
 *
 * Columns are mapped by NAME (not position), and the provider falls back from
 * the full query to the base query if the model doesn't yet have the route
 * columns (originLat … destIata) — so the app works before and after you add
 * route enrichment.
 */
const BASE_COLUMNS = `
    "icao24", Flights[icao24],
    "callsign", Flights[callsign],
    "originCountry", Flights[originCountry],
    "longitude", Flights[longitude],
    "latitude", Flights[latitude],
    "geoAltitude", Flights[geoAltitude],
    "velocity", Flights[velocity],
    "heading", Flights[heading],
    "verticalRate", Flights[verticalRate],
    "onGround", Flights[onGround],
    "ingestedAt", Flights[ingestedAt]`;

const ROUTE_COLUMNS = `
    "originLat", Flights[originLat],
    "originLon", Flights[originLon],
    "destLat", Flights[destLat],
    "destLon", Flights[destLon],
    "originIata", Flights[originIata],
    "destIata", Flights[destIata],`;

const build = (cols: string) =>
  `EVALUATE
SELECTCOLUMNS(
    TOPN ( 6000, Flights, Flights[ingestedAt], DESC ),${cols}
)
ORDER BY [ingestedAt] DESC`;

/** Full query — includes route columns. Tried first. */
export const LIVE_FLIGHTS_DAX = build(ROUTE_COLUMNS + BASE_COLUMNS);

/** Fallback — no route columns, for a model that hasn't added them yet. */
export const LIVE_FLIGHTS_DAX_BASE = build(BASE_COLUMNS);
