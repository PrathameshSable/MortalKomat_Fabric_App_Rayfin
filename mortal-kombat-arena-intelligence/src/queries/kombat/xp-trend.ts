import query from "./xp-trend.dax?raw";

const connection = "kombatModel";

export function xpTrendQuery() {
    return {
        connection,
        query,
    };
}
