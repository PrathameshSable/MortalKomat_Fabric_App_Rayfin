import query from "./customer-watchlist.dax?raw";

const connection = "bankModel";

export function customerWatchlistQuery() {
    return { connection, query };
}
