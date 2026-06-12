import type { Flight, FlightProvider } from "./types.js";

/**
 * Generates a realistic-looking fleet of aircraft and advances them along their
 * heading each tick, so the globe is alive without Fabric. Swap this for the
 * Fabric provider (see ./fabric/) to render real OpenSky data.
 */
const COUNTRIES = [
  "United States", "Germany", "United Kingdom", "France", "Spain",
  "Italy", "Netherlands", "Canada", "Japan", "Brazil", "Australia",
  "India", "China", "United Arab Emirates", "Turkey", "Switzerland",
];

const AIRLINE_PREFIXES = ["UAL", "DLH", "BAW", "AFR", "KLM", "AAL", "SWR", "UAE", "QFA", "ANA", "THY"];

function rand(min: number, max: number): number {
  return min + Math.random() * (max - min);
}

function makeFlight(i: number): Flight {
  const onGround = Math.random() < 0.08;
  const prefix = AIRLINE_PREFIXES[i % AIRLINE_PREFIXES.length];
  return {
    icao24: (0x400000 + i).toString(16),
    callsign: `${prefix}${100 + (i % 900)}`,
    originCountry: COUNTRIES[i % COUNTRIES.length]!,
    longitude: rand(-180, 180),
    latitude: rand(-75, 75),
    geoAltitude: onGround ? 0 : rand(2000, 12500),
    velocity: onGround ? rand(0, 30) : rand(180, 280),
    heading: rand(0, 360),
    verticalRate: onGround ? 0 : rand(-6, 6),
    onGround,
  };
}

export class SampleFlightProvider implements FlightProvider {
  readonly name = "sample";
  private flights: Flight[];

  constructor(count = 900) {
    this.flights = Array.from({ length: count }, (_, i) => makeFlight(i));
  }

  setCount(count: number): void {
    if (count > this.flights.length) {
      const extra = Array.from({ length: count - this.flights.length }, (_, k) =>
        makeFlight(this.flights.length + k),
      );
      this.flights = [...this.flights, ...extra];
    } else {
      this.flights = this.flights.slice(0, count);
    }
  }

  /** Advance each airborne flight along its heading. dtSeconds scales motion. */
  advance(dtSeconds: number): void {
    for (const f of this.flights) {
      if (f.onGround || f.velocity == null || f.heading == null) continue;
      // Convert m/s → degrees; exaggerate so motion is visible.
      const degPerSec = (f.velocity / 111_320) * 60;
      const rad = (f.heading * Math.PI) / 180;
      f.latitude += Math.cos(rad) * degPerSec * dtSeconds;
      f.longitude += Math.sin(rad) * degPerSec * dtSeconds;
      if (f.latitude > 85 || f.latitude < -85) f.heading = (f.heading + 180) % 360;
      if (f.longitude > 180) f.longitude -= 360;
      if (f.longitude < -180) f.longitude += 360;
    }
  }

  async getFlights(): Promise<Flight[]> {
    return this.flights;
  }

  /** Synchronous accessor for the render loop. */
  current(): Flight[] {
    return this.flights;
  }
}
