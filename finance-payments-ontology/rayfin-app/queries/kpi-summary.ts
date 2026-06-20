import query from "./kpi-summary.dax?raw";

const connection = "bankModel";

export function kpiSummaryQuery() {
    return { connection, query };
}
