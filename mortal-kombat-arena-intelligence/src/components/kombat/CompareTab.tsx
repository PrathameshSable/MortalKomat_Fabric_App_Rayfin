import { useEffect, useMemo, useState } from "react";
import type { CSSProperties } from "react";
import { motion } from "framer-motion";
import { useSemanticModelQuery } from "@/hooks/use-semantic-model-query";
import { fighterGridQuery } from "@/queries/kombat";
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

type SideProps = {
    fighter: FighterRow;
    rank: number;
};

function VsSide({ fighter, rank }: SideProps) {
    return (
        <div
            className="mk-vs-side"
            style={{ "--fc": fighter.primaryColor || "#f8b84e" } as CSSProperties}
        >
            <div className="mk-vs-side__render">
                <FighterShowcaseVisual
                    key={fighter.fighterName}
                    fighterName={fighter.fighterName}
                    imagePath={fighter.fullBodyImagePath}
                    className="mk-vs-side__img"
                    mode="compare"
                />
            </div>
            <div className="mk-vs-side__plate">
                <h3>{fighter.fighterName}</h3>
                <p>
                    {fighter.realm} · {fighter.combatStyle} · Rank #{rank}
                </p>
                <div className="mk-vs-side__mini">
                    <div>
                        <span>XP</span>
                        <strong>{formatCompact(fighter.totalXP)}</strong>
                    </div>
                    <div>
                        <span>KOs</span>
                        <strong>{formatNumber(fighter.totalKOs)}</strong>
                    </div>
                    <div>
                        <span>Win</span>
                        <strong>{formatPercent(fighter.winRate)}</strong>
                    </div>
                    <div>
                        <span>Score</span>
                        <strong>{formatCompact(fighter.totalScore)}</strong>
                    </div>
                </div>
            </div>
        </div>
    );
}

export function CompareTab() {
    const fighterRequest = fighterGridQuery();

    const { data, isLoading, error } = useSemanticModelQuery({
        connection: fighterRequest.connection,
        query: fighterRequest.query,
    });

    const fighters = useMemo<FighterRow[]>(() => {
        if (data?.status !== "success") {
            return [];
        }
        return (data.table.rows as unknown[][])
            .map(mapFighterRow)
            .sort((a, b) => b.totalScore - a.totalScore);
    }, [data]);

    const [nameA, setNameA] = useState("");
    const [nameB, setNameB] = useState("");

    useEffect(() => {
        if (fighters.length >= 2 && !nameA && !nameB) {
            setNameA(fighters[0].fighterName);
            setNameB(fighters[1].fighterName);
        }
    }, [fighters, nameA, nameB]);

    const fighterA = fighters.find((fighter) => fighter.fighterName === nameA) ?? null;
    const fighterB = fighters.find((fighter) => fighter.fighterName === nameB) ?? null;

    if (isLoading) {
        return <div className="mk-loading">Loading fighters...</div>;
    }

    if (error || data?.status === "error") {
        return <div className="mk-error">Unable to load fighters.</div>;
    }

    const metrics =
        fighterA && fighterB
            ? [
                  { label: "Matches", a: fighterA.matchesPlayed, b: fighterB.matchesPlayed, fa: formatNumber(fighterA.matchesPlayed), fb: formatNumber(fighterB.matchesPlayed) },
                  { label: "Wins", a: fighterA.wins, b: fighterB.wins, fa: formatNumber(fighterA.wins), fb: formatNumber(fighterB.wins) },
                  { label: "Win rate", a: fighterA.winRate, b: fighterB.winRate, fa: formatPercent(fighterA.winRate), fb: formatPercent(fighterB.winRate) },
                  { label: "Total XP", a: fighterA.totalXP, b: fighterB.totalXP, fa: formatCompact(fighterA.totalXP), fb: formatCompact(fighterB.totalXP) },
                  { label: "KOs", a: fighterA.totalKOs, b: fighterB.totalKOs, fa: formatNumber(fighterA.totalKOs), fb: formatNumber(fighterB.totalKOs) },
                  { label: "Score", a: fighterA.totalScore, b: fighterB.totalScore, fa: formatCompact(fighterA.totalScore), fb: formatCompact(fighterB.totalScore) },
              ]
            : [];

    return (
        <section className="mk-vs">
            <div className="mk-vs-selectors">
                <select
                    className="mk-mini-select"
                    value={nameA}
                    onChange={(event) => setNameA(event.target.value)}
                    aria-label="Fighter A"
                >
                    {fighters.map((fighter, index) => (
                        <option key={fighter.fighterName} value={fighter.fighterName}>
                            {fighter.fighterName} — rank #{index + 1}
                        </option>
                    ))}
                </select>
                <div className="mk-vs-chip">VS</div>
                <select
                    className="mk-mini-select"
                    value={nameB}
                    onChange={(event) => setNameB(event.target.value)}
                    aria-label="Fighter B"
                >
                    {fighters.map((fighter, index) => (
                        <option key={fighter.fighterName} value={fighter.fighterName}>
                            {fighter.fighterName} — rank #{index + 1}
                        </option>
                    ))}
                </select>
            </div>

            {fighterA && fighterB ? (
                <div className="mk-vs-arena">
                    <VsSide fighter={fighterA} rank={fighters.indexOf(fighterA) + 1} />

                    <div className="mk-panel2 mk-vs-center">
                        <h3>Tale of the Tape</h3>
                        <div className="mk-vs-metrics">
                            {metrics.map((metric, index) => {
                                const max = Math.max(metric.a, metric.b) || 1;
                                const aWins = metric.a >= metric.b;
                                return (
                                    <div className="mk-metric-row2" key={metric.label}>
                                        <div className={`mk-metric-val mk-num${aWins ? " is-win" : ""}`}>
                                            {metric.fa}
                                        </div>
                                        <div className="mk-bar is-left">
                                            <motion.span
                                                className="mk-bar__fill"
                                                key={`${nameA}-${nameB}-${metric.label}-a`}
                                                initial={{ width: 0 }}
                                                animate={{ width: `${(metric.a / max) * 100}%` }}
                                                transition={{ duration: 0.8, delay: index * 0.04, ease: [0.22, 1, 0.36, 1] }}
                                            />
                                        </div>
                                        <div className="mk-metric-label">{metric.label}</div>
                                        <div className="mk-bar is-right">
                                            <motion.span
                                                className="mk-bar__fill"
                                                key={`${nameA}-${nameB}-${metric.label}-b`}
                                                initial={{ width: 0 }}
                                                animate={{ width: `${(metric.b / max) * 100}%` }}
                                                transition={{ duration: 0.8, delay: index * 0.04, ease: [0.22, 1, 0.36, 1] }}
                                            />
                                        </div>
                                        <div className={`mk-metric-val mk-num is-right${!aWins ? " is-win" : ""}`}>
                                            {metric.fb}
                                        </div>
                                    </div>
                                );
                            })}
                        </div>
                    </div>

                    <VsSide fighter={fighterB} rank={fighters.indexOf(fighterB) + 1} />
                </div>
            ) : (
                <div className="mk-loading">Pick two fighters to compare.</div>
            )}
        </section>
    );
}
