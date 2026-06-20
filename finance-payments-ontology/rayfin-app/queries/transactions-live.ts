import query from "./transactions-live.dax?raw";

const connection = "bankModel";

export function transactionsLiveQuery() {
    return { connection, query };
}
