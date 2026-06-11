import query from "./arena-insights.dax?raw";

const connection = "kombatModel";

export function arenaInsightsQuery() {
    return {
        connection,
        query,
    };
}
