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
 * Live provider backed by the Fabric semantic model (Direct Lake over the
 * Eventhouse `Flights` table). Runs LIVE_FLIGHTS_DAX through the SDK and maps
 * the result rows to the Flight contract.
 */
export function createFabricFlightProvider(connection = "flightsModel"): FlightProvider {
  return {
    name: "fabric",
    async getFlights(): Promise<Flight[]> {
      const result = await getFabricClient().semanticModel(connection).query(LIVE_FLIGHTS_DAX);
      if (result.status !== "success") {
        throw new Error(result.error.message);
      }
      return result.table.rows.map(rowToFlight);
    },
  };
}
