import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { resolveFlightSource } from "./data/flightSource.js";
import { computeStats, type Flight, type FlightStats } from "./data/types.js";
import { DEFAULT_FILTER, makeFilterFn, type FlightFilter } from "./data/filter.js";
import { Scene } from "./three/Scene.js";
import {
  KpiStrip, TopCountries, FlightsTable, FlightDetails, InsightsPanel, HelpButton, HelpOverlay,
} from "./components/Hud.js";
import { ControlsPanel, type Settings } from "./components/ControlsPanel.js";
import { SearchPanel } from "./components/SearchPanel.js";

const EMPTY_STATS: FlightStats = {
  total: 0, airborne: 0, grounded: 0, countries: 0,
  avgAltitudeFt: 0, avgSpeedKmh: 0, topCountries: [], altitudeBins: [], manufacturers: [],
};

export default function App() {
  // Live Fabric data if a semantic-model client is injected; else sample fleet.
  const source = useMemo(() => resolveFlightSource(1200), []);
  const isLive = source.isLive;

  const [settings, setSettings] = useState<Settings>({
    count: 1200,
    planeSize: 0.035,
    speed: 1.5,
    autoRotate: true,
    showArcs: true,
    showAirports: true,
    lighting: "realtime",
    colorBy: "country",
  });
  const [filter, setFilter] = useState<FlightFilter>(DEFAULT_FILTER);
  const [selected, setSelected] = useState<Flight | null>(null);
  const [follow, setFollow] = useState(false);
  const [helpOpen, setHelpOpen] = useState(false);
  const [stats, setStats] = useState<FlightStats>(EMPTY_STATS);
  const [counts, setCounts] = useState({ shown: 0, total: 0 });
  const [countries, setCountries] = useState<string[]>([]);
  const [airlines, setAirlines] = useState<string[]>([]);
  const [manufacturers, setManufacturers] = useState<string[]>([]);
  const [visibleFlights, setVisibleFlights] = useState<Flight[]>([]);

  const filterFn = useMemo(() => makeFilterFn(filter), [filter]);
  // Keep a ref so the render loop always sees the latest predicate.
  const filterRef = useRef(filterFn);
  filterRef.current = filterFn;
  const stableFilterFn = useCallback((f: Flight) => filterRef.current(f), []);

  useEffect(() => {
    source.setCount?.(settings.count);
  }, [source, settings.count]);

  useEffect(() => {
    return () => source.stop?.();
  }, [source]);

  useEffect(() => {
    const update = () => {
      const all = source.current();
      const visible = all.filter(filterFn);
      setStats(computeStats(visible));
      setCounts({ shown: visible.length, total: all.length });
      setCountries([...new Set(all.map((f) => f.originCountry))].sort());
      setAirlines([...new Set(all.map((f) => f.airline).filter(Boolean) as string[])].sort());
      setManufacturers(
        [...new Set(all.map((f) => f.manufacturer).filter(Boolean) as string[])].sort(),
      );
      // Only build the table list when a country is picked (keeps it small).
      setVisibleFlights(filter.country ? visible.slice(0, 300) : []);
    };
    update();
    const id = setInterval(update, 700);
    return () => clearInterval(id);
  }, [source, filterFn, filter.country]);

  const clearFilters = useCallback(() => {
    setFilter(DEFAULT_FILTER);
    setSelected(null);
    setFollow(false);
  }, []);

  const getFlights = useCallback(() => source.current(), [source]);
  const advance = useCallback((dt: number) => source.advance(dt), [source]);

  return (
    <div className="stage">
      <Scene
        getFlights={getFlights}
        advance={advance}
        planeSize={settings.planeSize}
        speed={settings.speed}
        autoRotate={settings.autoRotate}
        showArcs={settings.showArcs}
        showAirports={settings.showAirports}
        lighting={settings.lighting}
        colorMode={settings.colorBy}
        follow={follow}
        frameKey={filter.country}
        filterFn={stableFilterFn}
        selected={selected}
        onSelect={setSelected}
        onClearSelection={() => {
          setSelected(null);
          setFollow(false);
        }}
      />

      <KpiStrip stats={stats} isLive={isLive} />
      {filter.country ? (
        <FlightsTable
          country={filter.country}
          flights={visibleFlights}
          onSelect={setSelected}
          selectedIcao={selected?.icao24}
        />
      ) : (
        <TopCountries stats={stats} />
      )}
      <SearchPanel
        filter={filter}
        onChange={setFilter}
        onClear={clearFilters}
        countries={countries}
        airlines={airlines}
        manufacturers={manufacturers}
        shown={counts.shown}
        total={counts.total}
      />
      <FlightDetails
        flight={selected}
        follow={follow}
        onToggleFollow={() => setFollow((v) => !v)}
      />
      <InsightsPanel
        stats={stats}
        activeBand={filter.band}
        onBand={(b) => setFilter({ ...filter, band: filter.band === b ? "all" : b })}
        activeMaker={filter.manufacturer}
        onMaker={(m) => setFilter({ ...filter, manufacturer: filter.manufacturer === m ? "" : m })}
      />
      <ControlsPanel settings={settings} onChange={setSettings} isLive={isLive} />
      <HelpButton onClick={() => setHelpOpen(true)} />
      {helpOpen && <HelpOverlay onClose={() => setHelpOpen(false)} />}

      <div className="legend">
        <span className="legend__title">Altitude</span>
        <span className="legend__ramp" />
        <span className="legend__lo">low</span>
        <span className="legend__hi">high</span>
      </div>
    </div>
  );
}
