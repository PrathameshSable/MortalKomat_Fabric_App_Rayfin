import query from "./kameo-insights.dax?raw";

const connection = "kombatModel";

export function kameoInsightsQuery() {
    return {
        connection,
        query,
    };
}
