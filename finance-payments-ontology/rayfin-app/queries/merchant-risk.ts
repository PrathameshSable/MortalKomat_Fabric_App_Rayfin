import query from "./merchant-risk.dax?raw";

const connection = "bankModel";

export function merchantRiskQuery() {
    return { connection, query };
}
