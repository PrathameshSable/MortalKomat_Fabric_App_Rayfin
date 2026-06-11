import { useEffect, useMemo, useState } from "react";
import type { CSSProperties } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { useSemanticModelQuery } from "@/hooks/use-semantic-model-query";
import { fighterGridQuery, kpiSummaryQuery } from "@/queries/kombat";
import { mapFighterRow } from "./fighterRowMapper";
import { FighterShowcaseVisual } from "./FighterShowcaseVisual";
import type { FighterRow } from "./types";
import type { AppTab } from "./AppNavigation";

const SPOTLIGHT_SIZE = 5;
const SPOTLIGHT_INTERVAL_MS = 5000;

type HomeLandingProps = {
    onNavigate: (tab: AppTab) => void;
};

function formatNumber(value: unknown) {
    return Number(value ?? 0).toLocaleString();
}

function formatPercent(value: unknown) {
    return `${(Number(value ?? 0) * 100).toFixed(1)}%`;
}

function formatCompact(value: number) {
    return new Intl.NumberFormat("en", { notation: "compact", maximumFractionDigits: 2 }).format(value);
}

export function HomeLanding({ onNavigate }: HomeLandingProps) {
    const fighterRequest = fighterGridQuery();
    const kpiRequest = kpiSummaryQuery();

    const { data: fighterData } = useSemanticModelQuery({
        connection: fighterRequest.connection,
        query: fighterRequest.query,
    });

    const { data: kpiData } = useSemanticModelQuery({
        connection: kpiRequest.connection,
        query: kpiRequest.query,
    });

    const topFive = useMemo<FighterRow[]>(() => {
        if (fighterData?.status !== "success") {
            return [];
        }

        return (fighterData.table.rows as unknown[][])
            .map(mapFighterRow)
            .sort((a, b) => b.totalScore - a.totalScore)
            .slice(0, SPOTLIGHT_SIZE);
    }, [fighterData]);

    const totalFighters =
        fighterData?.status === "success" ? fighterData.table.rows.length : 0;

    const [spotIndex, setSpotIndex] = useState(0);
    const [cycleResetKey, setCycleResetKey] = useState(0);

    useEffect(() => {
        if (topFive.length < 2) {
            return;
        }

        const interval = window.setInterval(() => {
            setSpotIndex((current) => (current + 1) % topFive.length);
        }, SPOTLIGHT_INTERVAL_MS);

        return () => window.clearInterval(interval);
    }, [topFive.length, cycleResetKey]);

    const fighter = topFive.length > 0 ? topFive[spotIndex % topFive.length] : null;
    const maxScore = topFive.length > 0 ? topFive[0].totalScore : 1;

    const selectFighter = (index: number) => {
        setSpotIndex(index);
        setCycleResetKey((key) => key + 1); // restart the cycle so the chosen fighter stays a while
    };

    const tickerItems = useMemo(() => {
        const items: Array<[string, string]> = [];

        if (kpiData?.status === "success") {
            const row = (kpiData.table.rows[0] ?? []) as unknown[];
            items.push(
                ["Total Matches", formatNumber(row[0])],
                ["Win Rate", formatPercent(row[4])],
                ["Total XP", formatNumber(row[5])],
                ["Total Score", formatNumber(row[7])],
                ["KOs", formatNumber(row[9])],
                ["Fatalities", formatNumber(row[11])],
            );
        }

        if (topFive.length > 0) {
            items.push(
                ["#1 Fighter", topFive[0].fighterName],
                ["Fighters Loaded", String(totalFighters || topFive.length)],
            );
        }

        return items;
    }, [kpiData, topFive, totalFighters]);

    const stageStyle = {
        "--sc": fighter?.primaryColor || "#f8b84e",
    } as CSSProperties;

    return (
        <section className="mk-home">
            <div className="mk-stage" style={stageStyle}>
                <video
                    className="mk-stage__video"
                    autoPlay
                    muted
                    loop
                    playsInline
                    poster="/assets/backgrounds/home-arena.png"
                    src="/assets/backgrounds/landing-video.mp4"
                />
                <div className="mk-stage__shade" />

                {fighter ? (
                    <AnimatePresence>
                        <motion.div
                            key={fighter.fighterName}
                            className="mk-stage__ghost"
                            initial={{ opacity: 0 }}
                            animate={{ opacity: 1 }}
                            exit={{ opacity: 0 }}
                            transition={{ duration: 0.45 }}
                        >
                            {fighter.fighterName}
                        </motion.div>
                    </AnimatePresence>
                ) : null}

                <div className="mk-stage__copy">
                    <div>
                        <span className="mk-eyebrow">Live Fabric Data App</span>
                        <h1>
                            Arena
                            <br />
                            Intelligence
                        </h1>
                        <p>
                            Live combat analytics from Microsoft Fabric semantic models, DAX and
                            Rayfin. 35 fighters. 15,000 matches. One champion.
                        </p>

                        <div className="mk-home-actions">
                            <button type="button" onClick={() => onNavigate("roster")}>
                                Choose Your Fighter
                            </button>
                            <button type="button" onClick={() => onNavigate("compare")}>
                                Compare
                            </button>
                        </div>
                    </div>

                    {fighter ? (
                        <div className="mk-plate">
                            <motion.div
                                key={fighter.fighterName}
                                initial={{ opacity: 0, y: 10 }}
                                animate={{ opacity: 1, y: 0 }}
                                transition={{ duration: 0.48, ease: [0.22, 1, 0.36, 1] }}
                            >
                                <span className="mk-plate__rank">
                                    Rank #{spotIndex % topFive.length + 1} · {fighter.realm}
                                </span>
                                <h2>{fighter.fighterName}</h2>
                                <p className="mk-plate__style">
                                    {fighter.combatStyle} · {fighter.difficulty}
                                </p>
                                <div className="mk-plate__stats">
                                    <div>
                                        <span>XP</span>
                                        <strong>{fighter.totalXP.toLocaleString()}</strong>
                                    </div>
                                    <div>
                                        <span>KOs</span>
                                        <strong>{fighter.totalKOs.toLocaleString()}</strong>
                                    </div>
                                    <div>
                                        <span>Win</span>
                                        <strong>{(fighter.winRate * 100).toFixed(1)}%</strong>
                                    </div>
                                    <div>
                                        <span>Matches</span>
                                        <strong>{fighter.matchesPlayed.toLocaleString()}</strong>
                                    </div>
                                </div>
                            </motion.div>
                        </div>
                    ) : (
                        <div className="mk-loading">Summoning the champions...</div>
                    )}
                </div>

                <div className="mk-stage__spotlight">
                    {fighter ? (
                        <AnimatePresence>
                            <motion.div
                                key={fighter.fighterName}
                                className="mk-stage__visual"
                                initial={{ opacity: 0, y: 18, scale: 0.97 }}
                                animate={{ opacity: 1, y: 0, scale: 1 }}
                                exit={{ opacity: 0, y: 18, scale: 0.97 }}
                                transition={{ duration: 0.55, ease: "easeOut" }}
                            >
                                <FighterShowcaseVisual
                                    fighterName={fighter.fighterName}
                                    imagePath={fighter.fullBodyImagePath}
                                    className="mk-stage__render"
                                    mode="profile"
                                />
                            </motion.div>
                        </AnimatePresence>
                    ) : null}
                </div>

                <aside className="mk-stage__rail">
                    <span className="mk-eyebrow">Top 5 · Total Score</span>
                    {topFive.map((row, index) => (
                        <button
                            type="button"
                            key={row.fighterName}
                            className={`mk-lead-row${index === spotIndex % topFive.length ? " is-active" : ""}`}
                            style={{ "--rc": row.primaryColor || "#f8b84e" } as CSSProperties}
                            onClick={() => selectFighter(index)}
                            aria-label={`Spotlight ${row.fighterName}`}
                        >
                            <span className="mk-lead-row__rank">#{index + 1}</span>
                            <span className="mk-lead-row__thumb">
                                <FighterShowcaseVisual
                                    fighterName={row.fighterName}
                                    imagePath={row.fullBodyImagePath}
                                />
                            </span>
                            <span className="mk-lead-row__who">
                                <strong>{row.fighterName}</strong>
                                <span>
                                    {formatCompact(row.totalScore)} score · {(row.winRate * 100).toFixed(1)}% win
                                </span>
                            </span>
                            <span className="mk-lead-row__bar">
                                <i style={{ width: `${(row.totalScore / maxScore) * 100}%` }} />
                            </span>
                        </button>
                    ))}
                </aside>
            </div>

            {tickerItems.length > 0 ? (
                <div className="mk-ticker">
                    <div className="mk-ticker__track">
                        {[...tickerItems, ...tickerItems].map(([label, value], index) => (
                            <span className="mk-ticker__item" key={`${label}-${index}`}>
                                <span className="mk-ticker__dot">◆</span> {label}{" "}
                                <strong>{value}</strong>
                            </span>
                        ))}
                    </div>
                </div>
            ) : null}
        </section>
    );
}
