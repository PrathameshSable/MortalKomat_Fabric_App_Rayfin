import type { Flight } from "./types.js";

export type AltitudeBand = "all" | "low" | "mid" | "high";

export interface FlightFilter {
  text: string;
  band: AltitudeBand;
  airborneOnly: boolean;
}

export const EMPTY_FILTER: FlightFilter = { text: "", band: "all", airborneOnly: false };

export function isFilterActive(f: FlightFilter): boolean {
  return f.text.trim() !== "" || f.band !== "all" || f.airborneOnly;
}

const FT = 3.28084;

export function matchesFilter(flight: Flight, filter: FlightFilter): boolean {
  if (filter.airborneOnly && flight.onGround) return false;

  if (filter.band !== "all") {
    const ft = (flight.geoAltitude ?? 0) * FT;
    if (filter.band === "low" && ft >= 10_000) return false;
    if (filter.band === "mid" && (ft < 10_000 || ft > 30_000)) return false;
    if (filter.band === "high" && ft <= 30_000) return false;
  }

  const q = filter.text.trim().toLowerCase();
  if (q) {
    const hay = `${flight.callsign ?? ""} ${flight.originCountry} ${flight.icao24}`.toLowerCase();
    if (!hay.includes(q)) return false;
  }
  return true;
}

/** Build a stable predicate for the current filter. */
export function makeFilterFn(filter: FlightFilter): (f: Flight) => boolean {
  return (f) => matchesFilter(f, filter);
}
