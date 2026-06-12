export interface Settings {
  count: number;
  planeSize: number;
  speed: number;
  autoRotate: boolean;
}

interface ControlsPanelProps {
  settings: Settings;
  onChange: (next: Settings) => void;
  isLive: boolean;
}

export function ControlsPanel({ settings, onChange, isLive }: ControlsPanelProps) {
  const set = <K extends keyof Settings>(key: K, value: Settings[K]) =>
    onChange({ ...settings, [key]: value });

  return (
    <div className="panel panel--controls">
      <div className="panel__title">Controls</div>

      {!isLive && (
        <label className="ctl">
          <span>Aircraft <em>{settings.count.toLocaleString()}</em></span>
          <input
            type="range" min={100} max={6000} step={100}
            value={settings.count}
            onChange={(e) => set("count", Number(e.target.value))}
          />
        </label>
      )}

      <label className="ctl">
        <span>Animation speed <em>{settings.speed.toFixed(1)}×</em></span>
        <input
          type="range" min={0} max={6} step={0.5}
          value={settings.speed}
          onChange={(e) => set("speed", Number(e.target.value))}
        />
      </label>

      <label className="ctl">
        <span>Marker size <em>{settings.planeSize.toFixed(2)}</em></span>
        <input
          type="range" min={0.02} max={0.12} step={0.005}
          value={settings.planeSize}
          onChange={(e) => set("planeSize", Number(e.target.value))}
        />
      </label>

      <label className="ctl ctl--row">
        <span>Auto-orbit</span>
        <input
          type="checkbox"
          checked={settings.autoRotate}
          onChange={(e) => set("autoRotate", e.target.checked)}
        />
      </label>

      <div className="source-tag">{isLive ? "● LIVE · Fabric" : "● DEMO · sample data"}</div>
    </div>
  );
}
