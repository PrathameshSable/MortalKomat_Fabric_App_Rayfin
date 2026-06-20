# Sample data — data dictionary

14 CSV files (header row + UTF-8). Generated deterministically by
`../tools/generate_data.py` (seed 42, anchored to 2026-06-20). Surrogate keys
are integers; `*Key` columns are foreign keys into the matching dimension.

## Dimensions

| File | Grain | Key columns |
|---|---|---|
| `dim_date.csv` | one row per calendar day (~18 months + 30d) | `DateKey` (yyyymmdd) |
| `dim_currency.csv` | one per currency | `CurrencyKey`, `CurrencyCode`, `UsdRate` |
| `dim_channel.csv` | one per payment channel | `ChannelKey`, `IsCardPresent`, `RiskWeight` |
| `dim_product.csv` | one per banking product | `ProductKey`, `Category`, `InterestRate` |
| `dim_branch.csv` | one per branch / ATM / digital | `BranchKey`, `Latitude`, `Longitude` |
| `dim_merchant.csv` | one per merchant | `MerchantKey`, `Category`, `Latitude`, `Longitude`, `BaseRiskScore` |
| `dim_customer.csv` | one per customer | `CustomerKey`, `RiskBand`, `ChurnScore`, `IsPoliticallyExposed`, `HomeBranchKey`→branch |
| `dim_account.csv` | one per account | `AccountKey`, `CustomerKey`→customer, `ProductKey`→product, `CreditLimit` |
| `dim_card.csv` | one per card | `CardKey`, `AccountKey`→account, `CustomerKey`→customer, `Status` |

## Facts

| File | Grain | Foreign keys |
|---|---|---|
| `fact_transaction.csv` | one per payment/authorization (**live stream**) | Customer, Account, Card, Merchant, Channel, Currency, Date |
| `fact_fraud_alert.csv` | one per alert | Transaction, Customer, Account, Date |
| `fact_account_balance_daily.csv` | account × week | Account, Customer, Date |
| `fact_customer_daily_snapshot.csv` | customer × week | Customer, Date |
| `fact_branch_daily_snapshot.csv` | branch × day (90d) | Branch, Date |

## Key fact columns

**`fact_transaction`**: `TransactionTs` (ISO-8601 UTC), `AmountUsd`,
`TransactionType`, `Status` (Approved/Declined/Flagged), `FraudScore` (0–1),
`IsFraud` (0/1), `IsInternational`, `MerchantLatitude`/`MerchantLongitude`
(for the map).

**`fact_fraud_alert`**: `RuleCode`/`RuleName`, `Severity`
(Low/Medium/High/Critical), `Status` (Open/Closed), `Disposition`
(Confirmed Fraud / False Positive / Under Review), `Analyst`.

> ~30% of transactions fall in the trailing 48h with second-level timestamps so
> a stream/map visual looks live. Re-run the generator or the notebook's
> "make live" cell to roll the window to the current time.
