import { useEffect, useMemo, useState } from "react";
import { animate } from "framer-motion";
import { useSemanticModelQuery } from "@/hooks/use-semantic-model-query";
import { arenaInsightsQuery, kameoInsightsQuery, kpiSummaryQuery } from "@/queries/kombat";

function formatNumber(value: unknown) {
    return Number(value ?? 0).toLocaleString();
}

function formatPercent(value: unknown) {
    return `${(Number(value ?? 0) * 100).toFixed(1)}%`;
}

type CountUpProps = {
    value: number;
    format: (value: number) => string;
};

function CountUpValue({ value, format }: CountUpProps) {
    const [display, setDisplay] = useState(0);

    useEffect(() => {
        const controls = animate(0, value, {
            duration: 1,
            ease: "easeOut",
            onUpdate: (latest) => setDisplay(latest),
        });
        return () => controls.stop();
    }, [value]);

    return <strong className="mk-num">{format(display)}</strong>;
}

type ArenaRow = {
    name: string;
    realm: string;
    hazard: string;
    matches: number;
    winRate: number;
    kos: number;
};

type KameoRow = {
    name: string;
    group: string;
    element: string;
    assist: string;
    matches: number;
    winRate: number;
};

export function DashboardTab() {
    const kpiRequest = kpiSummaryQuery();
    const arenaRequest = arenaInsightsQuery();
    const kameoRequest = kameoInsightsQuery();

    const { data: kpiData, isLoading: kpiLoading } = useSemanticModelQuery({
        connection: kpiRequest.connection,
        query: kpiRequest.query,
    });

    const { data: arenaData } = useSemanticModelQuery({
        connection: arenaRequest.connection,
        query: arenaRequest.query,
    });

    const { data: kameoData } = useSemanticModelQuery({
        connection: kameoRequest.connection,
        query: kameoRequest.query,
    });

    const [realmFilter, setRealmFilter] = useState("");
    const [minMatches, setMinMatches] = useState(0);
    const [kameoSearch, setKameoSearch] = useState("");

    const kpiRow = kpiData?.status === "success" ? ((kpiData.table.rows[0] ?? []) as unknown[]) : null;

    const kpiCards = kpiRow
        ? [
              { label: "Total Matches", value: Number(kpiRow[0] ?? 0), icon: "⚔", format: (v: number) => Math.round(v).toLocaleString() },
              { label: "Total XP", value: Number(kpiRow[5] ?? 0), icon: "✦", format: (v: number) => Math.round(v).toLocaleString() },
              { label: "Total Score", value: Number(kpiRow[7] ?? 0), icon: "♛", format: (v: number) => Math.round(v).toLocaleString() },
              { label: "KOs", value: Number(kpiRow[9] ?? 0), icon: "☠", format: (v: number) => Math.round(v).toLocaleString() },
              { label: "Win Rate", value: Number(kpiRow[4] ?? 0) * 100, icon: "◈", format: (v: number) => `${v.toFixed(1)}%` },
              { label: "Fatalities", value: Number(kpiRow[11] ?? 0), icon: "🔥", format: (v: number) => Math.round(v).toLocaleString() },
          ]
        : [];

    const arenas = useMemo<ArenaRow[]>(() => {
        if (arenaData?.status !== "success") {
            return [];
        }
        return (arenaData.table.rows as unknown[][]).map((row) => ({
            name: String(row[0] ?? ""),
            realm: String(row[1] ?? ""),
            hazard: String(row[2] ?? ""),
            matches: Number(row[4] ?? 0),
            winRate: Number(row[5] ?? 0),
            kos: Number(row[6] ?? 0),
        }));
    }, [arenaData]);

    const kameos = useMemo<KameoRow[]>(() => {
        if (kameoData?.status !== "success") {
            return [];
        }
        return (kameoData.table.rows as unknown[][]).map((row) => ({
            name: String(row[0] ?? ""),
            group: String(row[1] ?? ""),
            element: String(row[2] ?? ""),
            assist: String(row[3] ?? ""),
            matches: Number(row[5] ?? 0),
            winRate: Number(row[7] ?? 0),
        }));
    }, [kameoData]);

    const realms = useMemo(
        () => Array.from(new Set(arenas.map((arena) => arena.realm).filter(Boolean))).sort(),
        [arenas],
    );

    const filteredArenas = arenas.filter(
        (arena) => (!realmFilter || arena.realm === realmFilter) && arena.matches >= minMatches,
    );

    const kameoText = kameoSearch.trim().toLowerCase();
    const filteredKameos = kameos.filter(
        (kameo) =>
            !kameoText ||
            kameo.name.toLowerCase().includes(kameoText) ||
            kameo.assist.toLowerCase().includes(kameoText),
    );

    const hasFilters = Boolean(realmFilter || minMatches > 0 || kameoText);

    const clearFilters = () => {
        setRealmFilter("");
        setMinMatches(0);
        setKameoSearch("");
    };

    return (
        <section className="mk-cmd">
            <div className="mk-cmd-title">
                <span className="mk-eyebrow">Command Center</span>
                <h2>Combat Performance</h2>
            </div>

            <div className="mk-kpi-strip">
                {kpiCards.length > 0
                    ? kpiCards.map((card) => (
                          <div className="mk-kpi-chip" key={card.label}>
                              <div className="mk-kpi-chip__icon">{card.icon}</div>
                              <div>
                                  <span>{card.label}</span>
                                  <CountUpValue value={card.value} format={card.format} />
                              </div>
                          </div>
                      ))
                    : Array.from({ length: 6 }, (_, index) => (
                          <div
                              className={`mk-kpi-chip${kpiLoading ? " is-loading" : ""}`}
                              key={index}
                          >
                              <div className="mk-kpi-chip__icon">·</div>
                              <div>
                                  <span>Loading</span>
                                  <strong className="mk-num">—</strong>
                              </div>
                          </div>
                      ))}
            </div>

            <div className="mk-slicers">
                <span className="mk-eyebrow">Slicers</span>
                <select
                    className="mk-mini-select"
                    value={realmFilter}
                    onChange={(event) => setRealmFilter(event.target.value)}
                    aria-label="Filter arenas by realm"
                >
                    <option value="">All realms</option>
                    {realms.map((realm) => (
                        <option key={realm}>{realm}</option>
                    ))}
                </select>
                <select
                    className="mk-mini-select"
                    value={String(minMatches)}
                    onChange={(event) => setMinMatches(Number(event.target.value))}
                    aria-label="Filter arenas by minimum matches"
                >
                    <option value="0">Any matches</option>
                    <option value="2450">2,450+ matches</option>
                    <option value="2500">2,500+ matches</option>
                </select>
                <input
                    className="mk-mini-input"
                    value={kameoSearch}
                    onChange={(event) => setKameoSearch(event.target.value)}
                    placeholder="Search kameo or assist..."
                    aria-label="Search kameos"
                />
                {hasFilters ? (
                    <button type="button" className="mk-slicer-chip" onClick={clearFilters}>
                        ✕ Clear filters
                    </button>
                ) : null}
            </div>

            <div className="mk-cmd-tables">
                <div className="mk-panel2">
                    <div className="mk-panel2__head">
                        <h3>Battlefield Performance</h3>
                        <span className="mk-eyebrow">
                            {filteredArenas.length} of {arenas.length} arenas
                        </span>
                    </div>
                    <div className="mk-scroll">
                        <table className="mk-table2">
                            <thead>
                                <tr>
                                    <th>Arena</th>
                                    <th>Realm</th>
                                    <th>Hazard</th>
                                    <th className="r">Matches</th>
                                    <th className="r">Win rate</th>
                                    <th className="r">KOs</th>
                                </tr>
                            </thead>
                            <tbody>
                                {filteredArenas.map((arena) => (
                                    <tr key={arena.name}>
                                        <td>{arena.name}</td>
                                        <td>{arena.realm}</td>
                                        <td>{arena.hazard}</td>
                                        <td className="r">{formatNumber(arena.matches)}</td>
                                        <td className="r">{formatPercent(arena.winRate)}</td>
                                        <td className="r">{formatNumber(arena.kos)}</td>
                                    </tr>
                                ))}
                                {filteredArenas.length === 0 ? (
                                    <tr>
                                        <td colSpan={6} style={{ color: "var(--mk-muted)" }}>
                                            {arenas.length === 0
                                                ? "Loading arena insights..."
                                                : "No arenas match the slicers."}
                                        </td>
                                    </tr>
                                ) : null}
                            </tbody>
                        </table>
                    </div>
                </div>

                <div className="mk-panel2">
                    <div className="mk-panel2__head">
                        <h3>Best Assist Fighters</h3>
                        <span className="mk-eyebrow">Kameo Intelligence</span>
                    </div>
                    <div className="mk-scroll">
                        <table className="mk-table2">
                            <thead>
                                <tr>
                                    <th>Kameo</th>
                                    <th>Group</th>
                                    <th>Assist</th>
                                    <th className="r">Matches</th>
                                    <th className="r">Win rate</th>
                                </tr>
                            </thead>
                            <tbody>
                                {filteredKameos.map((kameo) => (
                                    <tr key={kameo.name}>
                                        <td>{kameo.name}</td>
                                        <td>{kameo.group}</td>
                                        <td>{kameo.assist}</td>
                                        <td className="r">{formatNumber(kameo.matches)}</td>
                                        <td className="r">{formatPercent(kameo.winRate)}</td>
                                    </tr>
                                ))}
                                {filteredKameos.length === 0 ? (
                                    <tr>
                                        <td colSpan={5} style={{ color: "var(--mk-muted)" }}>
                                            {kameos.length === 0
                                                ? "Loading kameo insights..."
                                                : "No kameos match the search."}
                                        </td>
                                    </tr>
                                ) : null}
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </section>
    );
}
