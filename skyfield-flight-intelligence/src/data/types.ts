/**
 * One aircraft, matching the backend's FlightEvent
 * (fabric-live-api-backend/src/flights/flightTypes.ts). This is the contract
 * shared by the sample provider and the live Fabric semantic-model provider.
 */
export interface Flight {
  icao24: string;
  callsign: string | null;
  originCountry: string;
  longitude: number;
  latitude: number;
  geoAltitude: number | null;
  velocity: number | null; // m/s
  heading: number | null; // degrees (true track)
  verticalRate: number | null; // m/s
  onGround: boolean;
  // Route (from callsign → adsbdb lookup; null when unknown).
  originLat: number | null;
  originLon: number | null;
  destLat: number | null;
  destLon: number | null;
  originIata: string | null;
  destIata: string | null;
}

/** True when a flight has a resolved origin→destination route. */
export function hasRoute(f: Flight): boolean {
  return (
    f.originLat != null && f.originLon != null && f.destLat != null && f.destLon != null
  );
}

/** A flight provider returns the current live set of aircraft. */
export interface FlightProvider {
  readonly name: string;
  /** Returns the latest known set of flights. */
  getFlights(): Promise<Flight[]>;
}

/** Aggregate stats derived from a flight set, for the HUD. */
export interface FlightStats {
  total: number;
  airborne: number;
  grounded: number;
  countries: number;
  avgAltitudeFt: number;
  avgSpeedKmh: number;
  topCountries: { country: string; count: number }[];
}

export function computeStats(flights: Flight[]): FlightStats {
  let airborne = 0;
  let altSum = 0;
  let altCount = 0;
  let spdSum = 0;
  let spdCount = 0;
  const byCountry = new Map<string, number>();

  for (const f of flights) {
    if (!f.onGround) airborne++;
    if (f.geoAltitude != null) {
      altSum += f.geoAltitude;
      altCount++;
    }
    if (f.velocity != null) {
      spdSum += f.velocity;
      spdCount++;
    }
    byCountry.set(f.originCountry, (byCountry.get(f.originCountry) ?? 0) + 1);
  }

  const topCountries = [...byCountry.entries()]
    .map(([country, count]) => ({ country, count }))
    .sort((a, b) => b.count - a.count)
    .slice(0, 6);

  return {
    total: flights.length,
    airborne,
    grounded: flights.length - airborne,
    countries: byCountry.size,
    avgAltitudeFt: altCount ? (altSum / altCount) * 3.28084 : 0,
    avgSpeedKmh: spdCount ? (spdSum / spdCount) * 3.6 : 0,
    topCountries,
  };
}
