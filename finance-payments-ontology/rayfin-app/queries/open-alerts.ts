import query from "./open-alerts.dax?raw";

const connection = "bankModel";

export function openAlertsQuery() {
    return { connection, query };
}
