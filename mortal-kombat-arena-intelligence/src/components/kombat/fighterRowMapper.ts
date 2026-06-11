import type { FighterRow } from "./types";

export function mapFighterRow(row: unknown[]): FighterRow {
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
