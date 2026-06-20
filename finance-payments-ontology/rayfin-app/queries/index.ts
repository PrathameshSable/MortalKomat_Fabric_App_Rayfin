// Rayfin query layer for the Contoso Bank Payments & Fraud ontology.
// Each export pairs a DAX file with the `bankModel` connection alias
// (defined in fabric.yaml). Mirrors the MK app's src/queries pattern.
export { kpiSummaryQuery } from "./kpi-summary";
export { transactionsLiveQuery } from "./transactions-live";
export { fraudByCountryQuery } from "./fraud-by-country";
export { channelFraudQuery } from "./channel-fraud";
export { merchantRiskQuery } from "./merchant-risk";
export { openAlertsQuery } from "./open-alerts";
export { customerWatchlistQuery } from "./customer-watchlist";
