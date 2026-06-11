import query from "./kpi-summary.dax?raw";

const connection = "kombatModel";

export function kpiSummaryQuery() {
    return {
        connection,
        query,
    };
}
