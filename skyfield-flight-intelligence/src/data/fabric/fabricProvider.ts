import type { Flight, FlightProvider } from "../types.js";
import { LIVE_FLIGHTS_DAX } from "./flightQueries.js";

/**
 * Minimal shape of the Fabric semantic-model client. The real Microsoft Fabric
 * SDK (`@microsoft/fabric-app-data`, via `getFabricClient()` — the same one the
 * MK Arena app uses) satisfies this. Keeping it as a narrow interface lets this
 * app build and run standalone, and you inject the real client when deploying
 * as a Rayfin item.
 */
export interface SemanticModelQueryResult {
  status: "success" | "error";
  table?: { rows: unknown[][] };
  error?: { message: string };
}

export interface SemanticModelClient {
  semanticModel(connection: string): {
    query(dax: string, opts?: { bypassCache?: boolean }): Promise<SemanticModelQueryResult>;
  };
}

/** row[] index → Flight field, matching LIVE_FLIGHTS_DAX column order. */
function rowToFlight(row: unknown[]): Flight {
  const num = (v: unknown): number | null =>
    v == null ? null : Number(v);
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
 * Live provider backed by the Fabric semantic model. Pass the connection alias
 * from fabric.yaml (e.g. "flightsModel") and the SDK client.
 */
export function createFabricFlightProvider(
  client: SemanticModelClient,
  connection = "flightsModel",
): FlightProvider {
  return {
    name: "fabric",
    async getFlights(): Promise<Flight[]> {
      const result = await client.semanticModel(connection).query(LIVE_FLIGHTS_DAX);
      if (result.status === "error" || !result.table) {
        throw new Error(result.error?.message ?? "semantic model query failed");
      }
      return result.table.rows.map(rowToFlight);
    },
  };
}
