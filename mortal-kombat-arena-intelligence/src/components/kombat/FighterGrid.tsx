import { useEffect, useMemo, useRef, useState } from "react";
import { useSemanticModelQuery } from "@/hooks/use-semantic-model-query";
import { fighterGridQuery } from "@/queries/kombat";
import { FighterCard3D } from "./FighterCard3D";
import { FighterProfilePanel } from "./FighterProfilePanel";
import type { FighterRow } from "./types";

function mapFighterRow(row: unknown[]): FighterRow {
    return {
        fighterName: String(row[0] ?? ""),
        rosterGroup: String(row[1] ?? ""),
        realm: String(row[2] ?? ""),
        element: String(row[3] ?? ""),
        combatStyle: String(row[4] ?? ""),
        alignment: String(row[5] ?? ""),
        difficulty: String(row[6] ?? ""),
        primaryColor: String(row[7] ?? "#ff5a1f"),
        secondaryColor: String(row[8] ?? "#120705"),
        portraitImagePath: String(row[9] ?? ""),
        fullBodyImagePath: String(row[10] ?? ""),
        cardBackgroundPath: String(row[11] ?? ""),
        model3DPath: String(row[12] ?? ""),
        matchesPlayed: Number(row[13] ?? 0),
        wins: Number(row[14] ?? 0),
        losses: Number(row[15] ?? 0),
        winRate: Number(row[16] ?? 0),
        totalXP: Number(row[17] ?? 0),
        totalScore: Number(row[18] ?? 0),
        totalKOs: Number(row[19] ?? 0),
        fatalities: Number(row[20] ?? 0),
        brutalities: Number(row[21] ?? 0),
        damageEfficiency: Number(row[22] ?? 0),
        rank: Number(row[23] ?? 0),
    };
}

export function FighterGrid() {
    const [selectedFighter, setSelectedFighter] = useState<FighterRow | null>(null);
    const profileRef = useRef<HTMLDivElement | null>(null);

    const { connection, query } = fighterGridQuery();

    const { data, isLoading, error } = useSemanticModelQuery({
        connection,
        query,
    });

    const result = data as any;

    const fighters = useMemo(() => {
        if (!result || result.status !== "success") {
            return [];
        }

        return (result.table.rows as unknown[][]).map(mapFighterRow);
    }, [result]);

    useEffect(() => {
        if (selectedFighter && profileRef.current) {
            profileRef.current.scrollIntoView({
                behavior: "smooth",
                block: "start",
            });
        }
    }, [selectedFighter?.fighterName]);

    if (isLoading) {
        return <div className="mk-loading">Loading fighter roster...</div>;
    }

    if (error || result?.status === "error") {
        return <div className="mk-error">Unable to load fighter roster.</div>;
    }

    return (
        <section>
            <div className="mk-section-header">
                <span>Choose Your Fighter</span>
                <h2>Roster Intelligence</h2>
                <p>
                    Select a fighter to inspect wins, losses, XP, KOs, fatalities, damage
                    efficiency, and rank — all coming from your Fabric semantic model.
                </p>
            </div>

            {selectedFighter ? (
                <div ref={profileRef} className="mk-profile-shell">
                    <FighterProfilePanel
                        key={selectedFighter.fighterName}
                        fighter={selectedFighter}
                        onClose={() => setSelectedFighter(null)}
                    />
                </div>
            ) : null}

            <div className="mk-fighter-grid">
                {fighters.map((fighter) => (
                    <FighterCard3D
                        key={fighter.fighterName}
                        fighter={fighter}
                        isSelected={selectedFighter?.fighterName === fighter.fighterName}
                        onSelect={() => setSelectedFighter(fighter)}
                    />
                ))}
            </div>
        </section>
    );
}
