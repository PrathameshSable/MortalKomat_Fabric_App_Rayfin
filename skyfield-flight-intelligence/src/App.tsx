import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { SampleFlightProvider } from "./data/sampleFlights.js";
import { computeStats, type Flight, type FlightStats } from "./data/types.js";
import { Scene } from "./three/Scene.js";
import { KpiStrip, TopCountries, FlightDetails } from "./components/Hud.js";
import { ControlsPanel, type Settings } from "./components/ControlsPanel.js";

const EMPTY_STATS: FlightStats = {
  total: 0, airborne: 0, grounded: 0, countries: 0,
  avgAltitudeFt: 0, avgSpeedKmh: 0, topCountries: [],
};

export default function App() {
  // Demo data engine. To go live, swap this for createFabricFlightProvider(...)
  // (see src/data/fabric/) and feed positions from the semantic model.
  const provider = useMemo(() => new SampleFlightProvider(1200), []);
  const isLive = false;

  const [settings, setSettings] = useState<Settings>({
    count: 1200,
    planeSize: 0.05,
    speed: 1.5,
    autoRotate: true,
  });
  const [selected, setSelected] = useState<Flight | null>(null);
  const [stats, setStats] = useState<FlightStats>(EMPTY_STATS);

  // Keep selection in a ref so it survives re-renders of the scene.
  const selectedRef = useRef<Flight | null>(null);
  selectedRef.current = selected;

  useEffect(() => {
    provider.setCount(settings.count);
  }, [provider, settings.count]);

  useEffect(() => {
    const update = () => setStats(computeStats(provider.current()));
    update();
    const id = setInterval(update, 800);
    return () => clearInterval(id);
  }, [provider]);

  const getFlights = useCallback(() => provider.current(), [provider]);
  const advance = useCallback((dt: number) => provider.advance(dt), [provider]);

  return (
    <div className="stage">
      <Scene
        getFlights={getFlights}
        advance={advance}
        planeSize={settings.planeSize}
        speed={settings.speed}
        autoRotate={settings.autoRotate}
        selected={selected}
        onSelect={setSelected}
        onClearSelection={() => setSelected(null)}
      />

      <KpiStrip stats={stats} />
      <TopCountries stats={stats} />
      <FlightDetails flight={selected} />
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
