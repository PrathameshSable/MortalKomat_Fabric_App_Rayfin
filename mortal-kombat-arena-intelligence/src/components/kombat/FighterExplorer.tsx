import { useMemo, useState } from "react";
import type { CSSProperties } from "react";
import { useSemanticModelQuery } from "@/hooks/use-semantic-model-query";
import { fighterGridQuery, matchupMatrixQuery } from "@/queries/kombat";
import { FighterShowcaseVisual } from "./FighterShowcaseVisual";
import { mapFighterRow } from "./fighterRowMapper";
import type { FighterRow } from "./types";

function formatNumber(value: number) {
    return value.toLocaleString();
}

function formatPercent(value: number) {
    return `${(value * 100).toFixed(1)}%`;
}

function formatCompact(value: number) {
    return new Intl.NumberFormat("en", { notation: "compact", maximumFractionDigits: 2 }).format(value);
}

type MatchupEdge = {
    opponent: string;
    matches: number;
    wins: number;
    losses: number;
};

export function FighterExplorer() {
    const fighterRequest = fighterGridQuery();
    const matchupRequest = matchupMatrixQuery();

    const { data: fighterData, isLoading, error } = useSemanticModelQuery({
        connection: fighterRequest.connection,
        query: fighterRequest.query,
    });

    const { data: matchupData } = useSemanticModelQuery({
        connection: matchupRequest.connection,
        query: matchupRequest.query,
    });

    const [search, setSearch] = useState("");
    const [selectedName, setSelectedName] = useState<string | null>(null);

    const fighters = useMemo<FighterRow[]>(() => {
        if (fighterData?.status !== "success") {
            return [];
        }
        return (fighterData.table.rows as unknown[][])
            .map(mapFighterRow)
            .sort((a, b) => b.totalScore - a.totalScore);
    }, [fighterData]);

    const matchups = useMemo<Map<string, MatchupEdge[]>>(() => {
        const byFighter = new Map<string, MatchupEdge[]>();
        if (matchupData?.status !== "success") {
            return byFighter;
        }
        for (const row of matchupData.table.rows as unknown[][]) {
            const fighter = String(row[0] ?? "");
            const edge: MatchupEdge = {
                opponent: String(row[1] ?? ""),
                matches: Number(row[2] ?? 0),
                wins: Number(row[3] ?? 0),
                losses: Number(row[4] ?? 0),
            };
            const list = byFighter.get(fighter);
            if (list) {
                list.push(edge);
            } else {
                byFighter.set(fighter, [edge]);
            }
        }
        return byFighter;
    }, [matchupData]);

    const searchText = search.trim().toLowerCase();
    const visibleFighters = fighters.filter(
        (fighter) =>
            !searchText ||
            fighter.fighterName.toLowerCase().includes(searchText) ||
            fighter.realm.toLowerCase().includes(searchText) ||
            fighter.element.toLowerCase().includes(searchText),
    );

    const selected = selectedName
        ? fighters.find((fighter) => fighter.fighterName === selectedName) ?? null
        : null;

    const selectedRank = selected ? fighters.indexOf(selected) + 1 : 0;

    const rivalry = useMemo(() => {
        if (!selected) {
            return null;
        }
        const edges = matchups.get(selected.fighterName) ?? [];
        if (edges.length === 0) {
            return null;
        }
        const prey = edges.reduce((best, edge) => (edge.wins > best.wins ? edge : best), edges[0]);
        const nemesis = edges.reduce((best, edge) => (edge.losses > best.losses ? edge : best), edges[0]);
        return { prey, nemesis };
    }, [selected, matchups]);

    const fighterByName = (name: string) =>
        fighters.find((fighter) => fighter.fighterName === name) ?? null;

    if (isLoading) {
        return <div className="mk-loading">Loading fighter roster...</div>;
    }

    if (error || fighterData?.status === "error") {
        return <div className="mk-error">Unable to load fighter roster.</div>;
    }

    const renderMatchupRow = (
        kind: "prey" | "nemesis",
        edge: MatchupEdge,
    ) => {
        const rival = fighterByName(edge.opponent);
        return (
            <button
                type="button"
                className={`mk-matchup-row ${kind === "prey" ? "is-prey" : "is-nemesis"}`}
                onClick={() => rival && setSelectedName(rival.fighterName)}
                title={rival ? `Open ${rival.fighterName}` : undefined}
            >
                <span className="mk-mu-label">
                    {kind === "prey" ? "Defeats most" : "Defeated by"}
                </span>
                <span className="mk-mu-thumb">
                    {rival ? (
                        <FighterShowcaseVisual
                            fighterName={rival.fighterName}
                            imagePath={rival.fullBodyImagePath}
                        />
                    ) : null}
                </span>
                <span className="mk-mu-who">
                    <strong>{edge.opponent}</strong>
                    <span>{formatNumber(edge.matches)} encounters</span>
                </span>
                <span className="mk-mu-count">
                    {kind === "prey" ? `${formatNumber(edge.wins)} W` : `${formatNumber(edge.losses)} L`}
                </span>
            </button>
        );
    };

    return (
        <section className="mk-roster">
            <div className="mk-filter-row">
                <span className="mk-eyebrow">Choose Your Fighter</span>
                <input
                    className="mk-mini-input"
                    value={search}
                    onChange={(event) => setSearch(event.target.value)}
                    placeholder="Search fighter, realm, element..."
                    aria-label="Search fighters"
                />
                <span className="mk-count-note">
                    <strong>{visibleFighters.length}</strong> / {fighters.length}
                </span>
            </div>

            <div className="mk-select-grid">
                {visibleFighters.map((fighter) => (
                    <button
                        type="button"
                        key={fighter.fighterName}
                        className={`mk-tile${selected?.fighterName === fighter.fighterName ? " is-selected" : ""}`}
                        style={{ "--tc": fighter.primaryColor || "#ff5a1f" } as CSSProperties}
                        onClick={() => setSelectedName(fighter.fighterName)}
                        aria-label={`Open profile for ${fighter.fighterName}`}
                    >
                        <FighterShowcaseVisual
                            fighterName={fighter.fighterName}
                            imagePath={fighter.fullBodyImagePath}
                            className="mk-tile__img"
                            fallbackClassName="mk-tile__fallback"
                        />
                        <span className="mk-tile__win">{formatPercent(fighter.winRate)}</span>
                        <span className="mk-tile__name">{fighter.fighterName}</span>
                    </button>
                ))}
            </div>

            <aside
                className={`mk-profile-pane${selected ? " is-open" : ""}`}
                style={{ "--pc": selected?.primaryColor || "#f8b84e" } as CSSProperties}
                aria-hidden={!selected}
            >
                {selected ? (
                    <>
                        <div className="mk-profile-pane__head">
                            <div>
                                <span className="mk-plate__rank">
                                    Rank #{selectedRank} · {selected.realm}
                                </span>
                                <h3>{selected.fighterName}</h3>
                                <p>
                                    {selected.combatStyle} · {selected.difficulty}
                                </p>
                            </div>
                            <button
                                type="button"
                                className="mk-profile-pane__close"
                                onClick={() => setSelectedName(null)}
                                aria-label="Close profile"
                            >
                                ✕
                            </button>
                        </div>

                        <div className="mk-profile-pane__render">
                            <FighterShowcaseVisual
                                fighterName={selected.fighterName}
                                imagePath={selected.fullBodyImagePath}
                                className="mk-profile-pane__img"
                                mode="profile"
                                isActive
                            />
                        </div>

                        <div className="mk-profile-pane__stats">
                            <div>
                                <span>XP</span>
                                <strong>{formatNumber(selected.totalXP)}</strong>
                            </div>
                            <div>
                                <span>KOs</span>
                                <strong>{formatNumber(selected.totalKOs)}</strong>
                            </div>
                            <div>
                                <span>Win</span>
                                <strong>{formatPercent(selected.winRate)}</strong>
                            </div>
                            <div>
                                <span>Matches</span>
                                <strong>{formatNumber(selected.matchesPlayed)}</strong>
                            </div>
                            <div>
                                <span>Wins</span>
                                <strong>{formatNumber(selected.wins)}</strong>
                            </div>
                            <div>
                                <span>Score</span>
                                <strong>{formatCompact(selected.totalScore)}</strong>
                            </div>
                        </div>

                        <div className="mk-matchups">
                            {rivalry ? (
                                <>
                                    {renderMatchupRow("prey", rivalry.prey)}
                                    {renderMatchupRow("nemesis", rivalry.nemesis)}
                                </>
                            ) : (
                                <span className="mk-count-note">Loading head-to-head data...</span>
                            )}
                        </div>
                    </>
                ) : null}
            </aside>
        </section>
    );
}
