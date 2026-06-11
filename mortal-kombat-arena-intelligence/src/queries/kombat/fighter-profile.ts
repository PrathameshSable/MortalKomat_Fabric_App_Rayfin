const connection = "kombatModel";

function escapeDaxString(value: string) {
    return value.replace(/"/g, "\"\"");
}

export function fighterProfileQuery(fighterName: string) {
    const safeFighterName = escapeDaxString(fighterName);

    const query = `
EVALUATE
CALCULATETABLE (
    ROW (
        "Matches Played", [Matches Played],
        "Wins", [Wins],
        "Losses", [Losses],
        "Win Rate", [Win Rate],
        "Total XP", [Total XP],
        "Average XP Per Match", [Average XP Per Match],
        "Total Score", [Total Score],
        "Average Score", [Average Score],
        "Total KOs", [Total KOs],
        "KO Rate", [KO Rate],
        "Fatalities", [Fatalities],
        "Brutalities", [Brutalities],
        "Perfect Rounds", [Perfect Rounds],
        "Damage Efficiency", [Damage Efficiency],
        "Max Combo Hits", [Max Combo Hits],
        "Average Combo Hits", [Average Combo Hits],
        "Special Moves Landed", [Special Moves Landed],
        "Fighter Rank by Score", [Fighter Rank by Score],
        "Fighter Rank by XP", [Fighter Rank by XP],
        "Fighter Rank by Win Rate", [Fighter Rank by Win Rate]
    ),
    dimfighter[FighterName] = "${safeFighterName}"
)
`;

    return {
        connection,
        query,
    };
}
