import type { Flight, FlightStats } from "../data/types.js";

function Kpi({ label, value, accent }: { label: string; value: string; accent?: boolean }) {
  return (
    <div className={`kpi${accent ? " kpi--accent" : ""}`}>
      <div className="kpi__value">{value}</div>
      <div className="kpi__label">{label}</div>
    </div>
  );
}

export function KpiStrip({ stats, isLive }: { stats: FlightStats; isLive: boolean }) {
  return (
    <div className="hud hud--top">
      <div className="brand">
        <span className={`brand__dot${isLive ? " brand__dot--live" : ""}`} />
        SKYFIELD
        <span className="brand__sub">{isLive ? "live · fabric" : "demo · sample"}</span>
        {isLive && <span className="live-badge">● LIVE</span>}
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

export function AltitudeChart({ stats }: { stats: FlightStats }) {
  const max = Math.max(1, ...stats.altitudeBins.map((b) => b.count));
  return (
    <div className="panel panel--alt">
      <div className="panel__title">Altitude profile</div>
      <div className="altbars">
        {stats.altitudeBins.map((b) => (
          <div className="altbar" key={b.label}>
            <span className="altbar__col">
              <span className="altbar__fill" style={{ height: `${(b.count / max) * 100}%` }} />
            </span>
            <span className="altbar__n">{b.count}</span>
            <span className="altbar__label">{b.label}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

interface FlightsTableProps {
  country: string;
  flights: Flight[];
  onSelect: (f: Flight) => void;
  selectedIcao?: string;
}

export function FlightsTable({ country, flights, onSelect, selectedIcao }: FlightsTableProps) {
  // Show flights that have a known route first.
  const sorted = [...flights].sort(
    (a, b) => Number(Boolean(b.originIata)) - Number(Boolean(a.originIata)),
  );
  const withRoute = flights.filter((f) => f.originIata).length;
  return (
    <div className="panel panel--table">
      <div className="panel__title">
        {country} · {flights.length} flights · {withRoute} routed
      </div>
      <div className="flights-list">
        {sorted.length === 0 && <p className="hint">No matching flights right now.</p>}
        {sorted.map((f) => {
          const hasR = f.originIata && f.destIata;
          const alt = f.geoAltitude != null ? `${Math.round((f.geoAltitude * 3.28084) / 1000)}k` : "—";
          return (
            <button
              key={f.icao24}
              className={`flight-row${selectedIcao === f.icao24 ? " flight-row--on" : ""}`}
              onClick={() => onSelect(f)}
              title={hasR ? `${f.originIata} → ${f.destIata}` : "route pending"}
            >
              <span className="fr-cs">{f.callsign ?? f.icao24}</span>
              <span className={`fr-route${hasR ? "" : " fr-route--none"}`}>
                {hasR ? `${f.originIata} → ${f.destIata}` : "route pending…"}
              </span>
              <span className="fr-alt">{alt}</span>
            </button>
          );
        })}
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

interface FlightDetailsProps {
  flight: Flight | null;
  follow: boolean;
  onToggleFollow: () => void;
}

export function FlightDetails({ flight, follow, onToggleFollow }: FlightDetailsProps) {
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
  const route =
    flight.originIata && flight.destIata ? `${flight.originIata} → ${flight.destIata}` : null;
  return (
    <div className="panel panel--right">
      <div className="panel__head">
        <div className="panel__title">{flight.callsign ?? flight.icao24}</div>
        <button className={`follow-btn${follow ? " follow-btn--on" : ""}`} onClick={onToggleFollow}>
          {follow ? "● Following" : "Follow"}
        </button>
      </div>
      <div className="detail-grid">
        {route && <><span>Route</span><b className="route">{route}</b></>}
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
