import { getFabricClient } from "@/lib/fabric-client";
import type { Flight, FlightProvider } from "../types.js";
import { LIVE_FLIGHTS_DAX } from "./flightQueries.js";

const num = (v: unknown): number | null => (v == null ? null : Number(v));

/** row[] index → Flight, matching LIVE_FLIGHTS_DAX column order. */
function rowToFlight(row: unknown[]): Flight {
  return {
    icao24: String(row[0] ?? ""),
    callsign: row[1] == null ? null : String(row[1]),
    originCountry: String(row[2] ?? "Unknown"),
    longitude: Number(row[3] ?? 0),
    latitude: Number(row[4] ?? 0),
    geoAltitude: num(row[5]),
    velocity: num(row[6]),
    heading: num(row[7]),
    verticalRate: num(row[8]),
    onGround: Boolean(row[9]),
  };
}

/**
 * Rows come newest-first (ORDER BY ingestedAt DESC), so the first row seen for
 * each aircraft is its latest position — keep that, skip the older duplicates.
 */
function rowsToLatestFlights(rows: unknown[][]): Flight[] {
  const seen = new Set<string>();
  const flights: Flight[] = [];
  for (const row of rows) {
    const flight = rowToFlight(row);
    if (!flight.icao24 || seen.has(flight.icao24)) continue;
    seen.add(flight.icao24);
    flights.push(flight);
  }
  return flights;
}

/**
 * Live provider backed by the Fabric semantic model. Runs LIVE_FLIGHTS_DAX and
 * returns the latest known position per aircraft.
 */
export function createFabricFlightProvider(connection = "flightsModel"): FlightProvider {
  return {
    name: "fabric",
    async getFlights(): Promise<Flight[]> {
      const result = await getFabricClient().semanticModel(connection).query(LIVE_FLIGHTS_DAX);
      if (result.status !== "success") {
        throw new Error(result.error.message);
      }
      return rowsToLatestFlights(result.table.rows);
    },
  };
}
