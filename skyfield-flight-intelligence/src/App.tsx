import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { resolveFlightSource } from "./data/flightSource.js";
import { computeStats, type Flight, type FlightStats } from "./data/types.js";
import { DEFAULT_FILTER, makeFilterFn, type FlightFilter } from "./data/filter.js";
import { Scene } from "./three/Scene.js";
import { KpiStrip, TopCountries, FlightDetails, AltitudeChart } from "./components/Hud.js";
import { ControlsPanel, type Settings } from "./components/ControlsPanel.js";
import { SearchPanel } from "./components/SearchPanel.js";

const EMPTY_STATS: FlightStats = {
  total: 0, airborne: 0, grounded: 0, countries: 0,
  avgAltitudeFt: 0, avgSpeedKmh: 0, topCountries: [], altitudeBins: [],
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
  const [stats, setStats] = useState<FlightStats>(EMPTY_STATS);
  const [counts, setCounts] = useState({ shown: 0, total: 0 });
  const [countries, setCountries] = useState<string[]>([]);

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
    };
    update();
    const id = setInterval(update, 700);
    return () => clearInterval(id);
  }, [source, filterFn]);

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
        filterFn={stableFilterFn}
        selected={selected}
        onSelect={setSelected}
        onClearSelection={() => {
          setSelected(null);
          setFollow(false);
        }}
      />

      <KpiStrip stats={stats} isLive={isLive} />
      <TopCountries stats={stats} />
      <SearchPanel
        filter={filter}
        onChange={setFilter}
        countries={countries}
        shown={counts.shown}
        total={counts.total}
      />
      <FlightDetails
        flight={selected}
        follow={follow}
        onToggleFollow={() => setFollow((v) => !v)}
      />
      <AltitudeChart stats={stats} />
      <ControlsPanel settings={settings} onChange={setSettings} isLive={isLive} />

      <div className="legend">
        <span className="legend__title">Altitude</span>
        <span className="legend__ramp" />
        <span className="legend__lo">low</span>
        <span className="legend__hi">high</span>
      </div>
    </div>
  );
}
