# Fabric notebook source
# ============================================================================
# Contoso Bank — Build Lakehouse Tables
# ----------------------------------------------------------------------------
# Loads the 14 ontology CSVs into Delta tables in the attached Lakehouse and
# (optionally) rebases the transaction/alert stream to "now" so the demo looks
# live. Attach this notebook to `ContosoBankLakehouse` before running.
#
# Upload step (one time): in the Lakehouse, upload the contents of
#   finance-payments-ontology/data/   ->   Files/contoso_bank/
# (or use the `!wget`/`mssparkutils.fs.cp` of your choice).
# ============================================================================

# CELL ********************

from pyspark.sql import functions as F

SOURCE_DIR = "Files/contoso_bank"   # where the CSVs were uploaded
TABLES = [
    "dim_date", "dim_currency", "dim_channel", "dim_product", "dim_branch",
    "dim_merchant", "dim_customer", "dim_account", "dim_card",
    "fact_transaction", "fact_fraud_alert", "fact_account_balance_daily",
    "fact_customer_daily_snapshot", "fact_branch_daily_snapshot",
]

# CELL ********************

# Load each CSV (header + inferred schema) and write a managed Delta table.
for t in TABLES:
    path = f"{SOURCE_DIR}/{t}.csv"
    df = (
        spark.read.option("header", True)
        .option("inferSchema", True)
        .csv(path)
    )
    df.write.mode("overwrite").option("overwriteSchema", "true").format("delta").saveAsTable(t)
    print(f"  wrote {t:<32} {df.count():>8,} rows")

print("All 14 tables written.")

# CELL ********************

# --- Make the stream LIVE -------------------------------------------------
# Shift transaction & alert timestamps so the latest event is "now". Run this
# right before the webinar (or schedule it) so the map shows live activity.
from pyspark.sql import functions as F

now = F.current_timestamp()

for t, ts_col, date_col in [
    ("fact_transaction", "TransactionTs", "DateKey"),
    ("fact_fraud_alert", "AlertTs", "DateKey"),
]:
    df = spark.read.table(t)
    max_ts = df.agg(F.max(F.to_timestamp(ts_col)).alias("m")).collect()[0]["m"]
    if max_ts is None:
        continue
    shift = F.unix_timestamp(now) - F.lit(int(max_ts.timestamp()))
    shifted = (
        df.withColumn("_ts", F.from_unixtime(F.unix_timestamp(F.to_timestamp(ts_col)) + shift))
          .withColumn(ts_col, F.date_format("_ts", "yyyy-MM-dd'T'HH:mm:ss'Z'"))
          .withColumn(date_col, F.date_format("_ts", "yyyyMMdd").cast("int"))
          .drop("_ts")
    )
    shifted.write.mode("overwrite").option("overwriteSchema", "true").format("delta").saveAsTable(t)
    print(f"  rebased {t} so latest event = now")

# CELL ********************

# --- Sanity check ---------------------------------------------------------
spark.sql("""
SELECT 'transactions last 1h' AS metric, COUNT(*) AS value
FROM fact_transaction
WHERE to_timestamp(TransactionTs) >= current_timestamp() - INTERVAL 1 HOUR
UNION ALL
SELECT 'open critical alerts', COUNT(*)
FROM fact_fraud_alert WHERE Status='Open' AND Severity='Critical'
""").show()

# MARKDOWN ********************

# ## Next steps
# 1. Build a **semantic model** on these tables (default Lakehouse model or a
#    custom one). Create the relationships listed in `ontology/ontology.json`.
# 2. Run `fabric/semantic-model/measures.dax` in the DAX query view and update
#    the model to persist the KPI measures.
# 3. In the model, open **Prep data for AI**, select the AI data schema, add the
#    glossary/rules from `data-agent/DATA_AGENT_INSTRUCTIONS.md` as AI
#    instructions, and (optionally) add Verified Answers.
# 4. Create a **Data Agent**, add this semantic model as a data source, and
#    publish it to **Copilot Studio** (see `copilot-studio/COPILOT_STUDIO_GUIDE.md`).
