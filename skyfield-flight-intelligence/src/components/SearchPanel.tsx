import type { AltitudeBand, FlightFilter } from "../data/filter.js";

interface SearchPanelProps {
  filter: FlightFilter;
  onChange: (next: FlightFilter) => void;
  shown: number;
  total: number;
}

const BANDS: { id: AltitudeBand; label: string }[] = [
  { id: "all", label: "All" },
  { id: "low", label: "Low" },
  { id: "mid", label: "Mid" },
  { id: "high", label: "High" },
];

export function SearchPanel({ filter, onChange, shown, total }: SearchPanelProps) {
  return (
    <div className="panel panel--search">
      <div className="panel__title">Search &amp; filter</div>

      <input
        className="search-input"
        type="text"
        placeholder="Callsign, country, ICAO24…"
        value={filter.text}
        onChange={(e) => onChange({ ...filter, text: e.target.value })}
      />

      <div className="band-row">
        {BANDS.map((b) => (
          <button
            key={b.id}
            className={`band${filter.band === b.id ? " band--on" : ""}`}
            onClick={() => onChange({ ...filter, band: b.id })}
          >
            {b.label}
          </button>
        ))}
      </div>

      <label className="ctl ctl--row">
        <span>Airborne only</span>
        <input
          type="checkbox"
          checked={filter.airborneOnly}
          onChange={(e) => onChange({ ...filter, airborneOnly: e.target.checked })}
        />
      </label>

      <div className="shown-tag">
        Showing <b>{shown.toLocaleString()}</b> of {total.toLocaleString()}
      </div>
    </div>
  );
}
