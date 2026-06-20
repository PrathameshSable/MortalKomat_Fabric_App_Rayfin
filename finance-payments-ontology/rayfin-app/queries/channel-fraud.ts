import query from "./channel-fraud.dax?raw";

const connection = "bankModel";

export function channelFraudQuery() {
    return { connection, query };
}
