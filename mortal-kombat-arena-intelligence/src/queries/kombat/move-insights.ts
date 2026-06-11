import query from "./move-insights.dax?raw";

const connection = "kombatModel";

export function moveInsightsQuery() {
    return {
        connection,
        query,
    };
}
