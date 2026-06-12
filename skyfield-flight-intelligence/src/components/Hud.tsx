import type { Flight, FlightStats } from "../data/types.js";

function Kpi({ label, value, accent }: { label: string; value: string; accent?: boolean }) {
  return (
    <div className={`kpi${accent ? " kpi--accent" : ""}`}>
      <div className="kpi__value">{value}</div>
      <div className="kpi__label">{label}</div>
    </div>
  );
}

export function KpiStrip({ stats }: { stats: FlightStats }) {
  return (
    <div className="hud hud--top">
      <div className="brand">
        <span className="brand__dot" />
        SKYFIELD<span className="brand__sub">live flight intelligence</span>
      </div>
      <div className="kpi-row">
        <Kpi label="Aircraft tracked" value={stats.total.toLocaleString()} accent />
        <Kpi label="Airborne" value={stats.airborne.toLocaleString()} />
        <Kpi label="On ground" value={stats.grounded.toLocaleString()} />
        <Kpi label="Countries" value={stats.countries.toLocaleString()} />
        <Kpi label="Avg altitude" value={`${Math.round(stats.avgAltitudeFt).toLocaleString()} ft`} />
        <Kpi label="Avg speed" value={`${Math.round(stats.avgSpeedKmh)} km/h`} />
      </div>
    </div>
  );
}

export function TopCountries({ stats }: { stats: FlightStats }) {
  const max = stats.topCountries[0]?.count ?? 1;
  return (
    <div className="panel panel--left">
      <div className="panel__title">Busiest airspace</div>
      <ul className="bars">
        {stats.topCountries.map((c) => (
          <li key={c.country}>
            <span className="bars__label">{c.country}</span>
            <span className="bars__track">
              <span className="bars__fill" style={{ width: `${(c.count / max) * 100}%` }} />
            </span>
            <span className="bars__count">{c.count}</span>
          </li>
        ))}
      </ul>
    </div>
  );
}

export function FlightDetails({ flight }: { flight: Flight | null }) {
  if (!flight) {
    return (
      <div className="panel panel--right panel--muted">
        <div className="panel__title">Aircraft detail</div>
        <p className="hint">Click an aircraft to inspect its live telemetry.</p>
      </div>
    );
  }
  const alt = flight.geoAltitude != null ? `${Math.round(flight.geoAltitude * 3.28084).toLocaleString()} ft` : "—";
  const spd = flight.velocity != null ? `${Math.round(flight.velocity * 3.6)} km/h` : "—";
  const vr = flight.verticalRate;
  const trend = vr == null ? "level" : vr > 0.5 ? "climbing" : vr < -0.5 ? "descending" : "cruising";
  return (
    <div className="panel panel--right">
      <div className="panel__title">{flight.callsign ?? flight.icao24}</div>
      <div className="detail-grid">
        <span>Origin</span><b>{flight.originCountry}</b>
        <span>ICAO24</span><b>{flight.icao24}</b>
        <span>Position</span><b>{flight.latitude.toFixed(2)}°, {flight.longitude.toFixed(2)}°</b>
        <span>Altitude</span><b>{alt}</b>
        <span>Ground speed</span><b>{spd}</b>
        <span>Heading</span><b>{flight.heading != null ? `${Math.round(flight.heading)}°` : "—"}</b>
        <span>State</span><b className={`state state--${trend}`}>{flight.onGround ? "on ground" : trend}</b>
      </div>
    </div>
  );
}
