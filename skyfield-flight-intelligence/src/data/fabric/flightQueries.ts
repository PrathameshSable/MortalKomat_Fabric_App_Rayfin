/**
 * DAX the live provider runs against the flight semantic model (DirectQuery /
 * Direct Lake over the Eventhouse `Flights` table). `Flights` is append-only, so
 * we pull the most-recent rows and the app keeps the latest one per aircraft
 * (rows arrive newest-first; see rowsToLatestFlights in fabricProvider.ts).
 * Column order here defines the row[] index mapping used by rowToFlight.
 */
export const LIVE_FLIGHTS_DAX = `
EVALUATE
SELECTCOLUMNS(
    TOPN ( 6000, Flights, Flights[ingestedAt], DESC ),
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
    "ingestedAt", Flights[ingestedAt]
)
ORDER BY [ingestedAt] DESC
`.trim();
