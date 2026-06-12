/**
 * DAX queries the live provider runs against the flight semantic model
 * (Direct Lake over the Eventhouse `Flights` table / `LatestFlights()` snapshot).
 * Column order here defines the row[] index mapping used in fabricProvider.ts.
 */
export const LIVE_FLIGHTS_DAX = `
EVALUATE
SELECTCOLUMNS(
    Flights,
    "icao24", Flights[icao24],
    "callsign", Flights[callsign],
    "originCountry", Flights[originCountry],
    "longitude", Flights[longitude],
    "latitude", Flights[latitude],
    "geoAltitude", Flights[geoAltitude],
    "velocity", Flights[velocity],
    "heading", Flights[heading],
    "verticalRate", Flights[verticalRate],
    "onGround", Flights[onGround]
)
`.trim();
