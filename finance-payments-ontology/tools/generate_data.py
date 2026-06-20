#!/usr/bin/env python3
"""
Contoso Bank — Real-Time Payments & Fraud Intelligence
======================================================
Deterministic sample-data generator for the Fabric IQ ontology demo.

Produces 14 CSV files (9 dimensions + 5 facts) under ../data that line up
1:1 with the ontology entity types and their data bindings. Pure standard
library only (csv / random / math / datetime) so it runs anywhere — no
pandas / numpy required.

Run:
    python3 tools/generate_data.py

The same logic is mirrored in fabric/notebooks/01_build_lakehouse_tables.py
for loading straight into a Fabric Lakehouse as Delta tables.

NOTE ON "REAL-TIME": fact_transaction and fact_fraud_alert are anchored to
NOW (see ANCHOR below). The trailing ~48h carry second-level timestamps so a
map/stream visual shows transactions "flowing" and fraud alerts firing live.
Re-run (or re-run the notebook) to roll the window forward to the new NOW.
"""

import csv
import math
import os
import random
from datetime import datetime, timedelta, timezone

# --------------------------------------------------------------------------
# Configuration
# --------------------------------------------------------------------------
SEED = 42
ANCHOR = datetime(2026, 6, 20, 12, 0, 0, tzinfo=timezone.utc)  # "now" for the demo
HISTORY_DAYS = 540           # ~18 months of history for trends
LIVE_WINDOW_HOURS = 48       # trailing window with high-resolution timestamps
N_CUSTOMERS = 220
N_TRANSACTIONS = 9000        # total across full history
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "data")

random.seed(SEED)
os.makedirs(OUT_DIR, exist_ok=True)


def write_csv(name, header, rows):
    path = os.path.join(OUT_DIR, name)
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(header)
        w.writerows(rows)
    print(f"  {name:<34} {len(rows):>7,} rows")
    return rows


def iso(dt):
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def datekey(dt):
    return int(dt.strftime("%Y%m%d"))


def haversine_km(a_lat, a_lon, b_lat, b_lon):
    r = 6371.0
    p1, p2 = math.radians(a_lat), math.radians(b_lat)
    dphi = math.radians(b_lat - a_lat)
    dl = math.radians(b_lon - a_lon)
    h = math.sin(dphi / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(h))


# ==========================================================================
# 1. dim_date
# ==========================================================================
print("Generating dimensions...")
date_rows = []
start_date = (ANCHOR - timedelta(days=HISTORY_DAYS)).date()
end_date = (ANCHOR + timedelta(days=30)).date()  # a little forward room
d = start_date
while d <= end_date:
    dt = datetime(d.year, d.month, d.day, tzinfo=timezone.utc)
    q = (d.month - 1) // 3 + 1
    date_rows.append([
        datekey(dt), d.isoformat(), d.year, q, f"Q{q} {d.year}", d.month,
        d.strftime("%B"), d.strftime("%Y-%m"), d.isocalendar()[1],
        d.day, d.strftime("%A"), 1 if d.weekday() >= 5 else 0,
        1 if d == ANCHOR.date() else 0,
    ])
    d += timedelta(days=1)
write_csv("dim_date.csv",
          ["DateKey", "Date", "Year", "Quarter", "QuarterLabel", "MonthNumber",
           "MonthName", "YearMonth", "WeekOfYear", "DayOfMonth", "DayName",
           "IsWeekend", "IsToday"],
          date_rows)

# ==========================================================================
# 2. dim_currency
# ==========================================================================
currencies = [
    # code, name, symbol, usd_rate (1 unit = x USD)
    ("USD", "US Dollar", "$", 1.00),
    ("EUR", "Euro", "€", 1.09),
    ("GBP", "Pound Sterling", "£", 1.27),
    ("INR", "Indian Rupee", "₹", 0.012),
    ("JPY", "Japanese Yen", "¥", 0.0064),
    ("AED", "UAE Dirham", "د.إ", 0.27),
    ("SGD", "Singapore Dollar", "S$", 0.74),
    ("CAD", "Canadian Dollar", "C$", 0.73),
]
currency_rows = [[i + 1, c[0], c[1], c[2], c[3]] for i, c in enumerate(currencies)]
write_csv("dim_currency.csv",
          ["CurrencyKey", "CurrencyCode", "CurrencyName", "Symbol", "UsdRate"],
          currency_rows)
currency_by_code = {c[1]: c[0] for c in currency_rows}

# ==========================================================================
# 3. dim_channel
# ==========================================================================
channels = [
    # name, type, is_card_present, is_online, risk_weight
    ("In-Store POS", "POS", 1, 0, 0.6),
    ("ATM Withdrawal", "ATM", 1, 0, 0.8),
    ("E-Commerce", "Online", 0, 1, 1.4),
    ("Mobile App", "Mobile", 0, 1, 1.0),
    ("Online Banking", "Web", 0, 1, 0.9),
    ("Wire Transfer", "Wire", 0, 1, 1.6),
    ("ACH Direct Debit", "ACH", 0, 1, 0.7),
    ("Contactless Tap", "POS", 1, 0, 0.5),
]
channel_rows = [[i + 1, c[0], c[1], c[2], c[3], c[4]] for i, c in enumerate(channels)]
write_csv("dim_channel.csv",
          ["ChannelKey", "ChannelName", "ChannelType", "IsCardPresent",
           "IsOnline", "RiskWeight"],
          channel_rows)

# ==========================================================================
# 4. dim_product
# ==========================================================================
products = [
    # name, category, segment, monthly_fee, interest_rate
    ("Everyday Checking", "Deposit", "Retail", 0.0, 0.001),
    ("Premier Savings", "Deposit", "Retail", 0.0, 0.041),
    ("Student Checking", "Deposit", "Retail", 0.0, 0.000),
    ("Contoso Cashback Credit", "Credit Card", "Retail", 0.0, 0.2199),
    ("Contoso Platinum Credit", "Credit Card", "Affluent", 95.0, 0.1899),
    ("Business Operating Account", "Deposit", "Business", 25.0, 0.005),
    ("Business Line of Credit", "Lending", "Business", 0.0, 0.0975),
    ("Auto Loan", "Lending", "Retail", 0.0, 0.0689),
    ("Home Mortgage", "Lending", "Retail", 0.0, 0.0599),
    ("Wealth Brokerage", "Investment", "Affluent", 0.0, 0.0),
]
product_rows = [[i + 1, *p] for i, p in enumerate(products)]
write_csv("dim_product.csv",
          ["ProductKey", "ProductName", "Category", "Segment",
           "MonthlyFee", "InterestRate"],
          product_rows)

# ==========================================================================
# 5. dim_branch (branches + ATMs, geo-located)
# ==========================================================================
branch_seed = [
    # name, type, city, country, region, lat, lon
    ("Contoso NYC Flagship", "Branch", "New York", "USA", "North America", 40.7549, -73.9840),
    ("Contoso SF Financial District", "Branch", "San Francisco", "USA", "North America", 37.7946, -122.3999),
    ("Contoso Chicago Loop", "Branch", "Chicago", "USA", "North America", 41.8819, -87.6278),
    ("Contoso Dallas Uptown", "Branch", "Dallas", "USA", "North America", 32.7980, -96.8060),
    ("Contoso Miami Brickell", "Branch", "Miami", "USA", "North America", 25.7617, -80.1918),
    ("Contoso Toronto King St", "Branch", "Toronto", "Canada", "North America", 43.6489, -79.3817),
    ("Contoso London Canary Wharf", "Branch", "London", "UK", "Europe", 51.5054, -0.0235),
    ("Contoso Frankfurt Banken", "Branch", "Frankfurt", "Germany", "Europe", 50.1109, 8.6821),
    ("Contoso Paris La Defense", "Branch", "Paris", "France", "Europe", 48.8924, 2.2360),
    ("Contoso Dubai DIFC", "Branch", "Dubai", "UAE", "Middle East", 25.2110, 55.2796),
    ("Contoso Singapore Marina", "Branch", "Singapore", "Singapore", "APAC", 1.2806, 103.8505),
    ("Contoso Mumbai BKC", "Branch", "Mumbai", "India", "APAC", 19.0670, 72.8690),
    ("Contoso Bengaluru MG Road", "Branch", "Bengaluru", "India", "APAC", 12.9750, 77.6060),
    ("Contoso Tokyo Marunouchi", "Branch", "Tokyo", "Japan", "APAC", 35.6812, 139.7671),
    ("Contoso LAX Terminal ATM", "ATM", "Los Angeles", "USA", "North America", 33.9416, -118.4085),
    ("Contoso Times Square ATM", "ATM", "New York", "USA", "North America", 40.7580, -73.9855),
    ("Contoso Heathrow T5 ATM", "ATM", "London", "UK", "Europe", 51.4700, -0.4543),
    ("Contoso Changi ATM", "ATM", "Singapore", "Singapore", "APAC", 1.3644, 103.9915),
    ("Contoso Online (Digital)", "Digital", "—", "Global", "Global", 0.0, 0.0),
]
branch_rows = [[i + 1, *b] for i, b in enumerate(branch_seed)]
write_csv("dim_branch.csv",
          ["BranchKey", "BranchName", "BranchType", "City", "Country",
           "Region", "Latitude", "Longitude"],
          branch_rows)
physical_branches = [b for b in branch_rows if b[2] != "Digital"]

# ==========================================================================
# 6. dim_merchant (where card transactions happen, geo-located, with MCC)
# ==========================================================================
merchant_seed = [
    # name, mcc_category, city, country, lat, lon, base_risk
    ("Amazon Marketplace", "E-Commerce", "Seattle", "USA", 47.6062, -122.3321, 0.5),
    ("Walmart Supercenter", "Grocery", "Bentonville", "USA", 36.3729, -94.2088, 0.2),
    ("Shell Fuel", "Fuel", "Houston", "USA", 29.7604, -95.3698, 0.6),
    ("Starbucks", "Dining", "Seattle", "USA", 47.5810, -122.3360, 0.2),
    ("Apple Store", "Electronics", "Cupertino", "USA", 37.3318, -122.0312, 0.4),
    ("Uber Rides", "Transport", "San Francisco", "USA", 37.7749, -122.4194, 0.5),
    ("Netflix Subscription", "Digital Goods", "Los Gatos", "USA", 37.2266, -121.9747, 0.3),
    ("Marriott Hotels", "Travel", "Bethesda", "USA", 38.9847, -77.0947, 0.7),
    ("British Airways", "Airline", "London", "UK", 51.4700, -0.4543, 0.9),
    ("Tesco Express", "Grocery", "London", "UK", 51.5074, -0.1278, 0.2),
    ("Zara", "Apparel", "Madrid", "Spain", 40.4168, -3.7038, 0.4),
    ("Carrefour", "Grocery", "Paris", "France", 48.8566, 2.3522, 0.3),
    ("Lufthansa", "Airline", "Frankfurt", "Germany", 50.0379, 8.5622, 0.9),
    ("Emirates", "Airline", "Dubai", "UAE", 25.2532, 55.3657, 1.0),
    ("Dubai Mall Retail", "Retail", "Dubai", "UAE", 25.1972, 55.2796, 0.6),
    ("Flipkart", "E-Commerce", "Bengaluru", "India", 12.9716, 77.5946, 0.6),
    ("Reliance Fresh", "Grocery", "Mumbai", "India", 19.0760, 72.8777, 0.3),
    ("Singapore Airlines", "Airline", "Singapore", "Singapore", 1.3644, 103.9915, 0.9),
    ("Grab Transport", "Transport", "Singapore", "Singapore", 1.2966, 103.7764, 0.5),
    ("Rakuten", "E-Commerce", "Tokyo", "Japan", 35.6655, 139.7300, 0.6),
    ("CryptoX Exchange", "Crypto", "Valletta", "Malta", 35.8989, 14.5146, 1.8),
    ("FastCash Wire Co", "Money Transfer", "Lagos", "Nigeria", 6.5244, 3.3792, 1.9),
    ("GlobalBet Online", "Gambling", "San Jose", "Costa Rica", 9.9281, -84.0907, 1.7),
    ("LuxWatch Boutique", "Luxury", "Geneva", "Switzerland", 46.2044, 6.1432, 1.2),
    ("QuickGadget Deals", "E-Commerce", "Shenzhen", "China", 22.5431, 114.0579, 1.5),
]
merchant_rows = [[i + 1, *m] for i, m in enumerate(merchant_seed)]
write_csv("dim_merchant.csv",
          ["MerchantKey", "MerchantName", "Category", "City", "Country",
           "Latitude", "Longitude", "BaseRiskScore"],
          merchant_rows)

# ==========================================================================
# 7. dim_customer
# ==========================================================================
first_names = ["Olivia", "Liam", "Emma", "Noah", "Ava", "Arjun", "Priya", "Wei",
               "Mei", "Mohammed", "Fatima", "James", "Sophia", "Lucas", "Isabella",
               "Hiroshi", "Yuki", "Carlos", "Sofia", "Anika", "Daniel", "Grace",
               "Ethan", "Chloe", "Omar", "Layla", "Ben", "Hannah", "Raj", "Nina"]
last_names = ["Smith", "Johnson", "Patel", "Chen", "Garcia", "Müller", "Tanaka",
              "Khan", "Brown", "Wang", "Singh", "Rossi", "Dubois", "Kim", "Nguyen",
              "Silva", "Andersson", "Okafor", "Ali", "Martin", "Lee", "Sharma"]
segments = [("Mass Retail", 0.55), ("Affluent", 0.18), ("Student", 0.12),
            ("Business", 0.10), ("Private Wealth", 0.05)]
risk_bands = ["Low", "Low", "Low", "Medium", "Medium", "High"]
home_countries = ["USA", "USA", "USA", "UK", "Germany", "France", "UAE",
                  "India", "India", "Singapore", "Japan", "Canada"]


def weighted_choice(pairs):
    r = random.random()
    cum = 0.0
    for value, w in pairs:
        cum += w
        if r <= cum:
            return value
    return pairs[-1][0]


customer_rows = []
for i in range(1, N_CUSTOMERS + 1):
    seg = weighted_choice(segments)
    onboard = ANCHOR - timedelta(days=random.randint(60, 3600))
    country = random.choice(home_countries)
    # home branch roughly matches country when possible
    candidates = [b for b in physical_branches if b[5] == country] or physical_branches
    home_branch = random.choice(candidates)
    credit_score = random.randint(540, 840)
    churn = round(random.random(), 3)
    customer_rows.append([
        i, f"CUST{i:05d}",
        f"{random.choice(first_names)} {random.choice(last_names)}",
        seg, country, home_branch[0], iso(onboard), datekey(onboard),
        credit_score, random.choice(risk_bands), churn,
        1 if random.random() < 0.07 else 0,  # IsPoliticallyExposed
    ])
write_csv("dim_customer.csv",
          ["CustomerKey", "CustomerId", "CustomerName", "Segment",
           "Country", "HomeBranchKey", "OnboardedAt", "OnboardedDateKey",
           "CreditScore", "RiskBand", "ChurnScore", "IsPoliticallyExposed"],
          customer_rows)

# ==========================================================================
# 8. dim_account  (customers own 1..n accounts; each maps to a product)
# ==========================================================================
account_rows = []
accounts_by_customer = {}
acct_key = 0
for cust in customer_rows:
    ckey, seg = cust[0], cust[3]
    n_acct = random.choices([1, 2, 3, 4], weights=[0.35, 0.4, 0.18, 0.07])[0]
    chosen_products = random.sample(product_rows, k=min(n_acct, len(product_rows)))
    accts = []
    for p in chosen_products:
        acct_key += 1
        opened = ANCHOR - timedelta(days=random.randint(30, 3000))
        status = random.choices(["Active", "Active", "Active", "Dormant", "Frozen"],
                                weights=[0.8, 0.08, 0.05, 0.05, 0.02])[0]
        credit_limit = 0.0
        if p[2] == "Credit Card":
            credit_limit = random.choice([2000, 5000, 10000, 15000, 25000, 50000])
        account_rows.append([
            acct_key, f"ACCT{acct_key:06d}", ckey, p[0], p[1], p[2],
            random.choice(["USD", "USD", "EUR", "GBP", "INR", "AED", "SGD"]),
            iso(opened), datekey(opened), status, credit_limit,
        ])
        accts.append(account_rows[-1])
    accounts_by_customer[ckey] = accts
write_csv("dim_account.csv",
          ["AccountKey", "AccountNumber", "CustomerKey", "ProductKey",
           "ProductName", "Category", "CurrencyCode", "OpenedAt",
           "OpenedDateKey", "Status", "CreditLimit"],
          account_rows)

# ==========================================================================
# 9. dim_card  (cards belong to card-type accounts + some debit on deposits)
# ==========================================================================
card_rows = []
cards_by_account = {}
card_key = 0
card_networks = ["Visa", "Mastercard", "Amex"]
for acct in account_rows:
    akey, cat = acct[0], acct[5]
    make_card = cat == "Credit Card" or (cat == "Deposit" and random.random() < 0.8)
    if not make_card:
        continue
    card_key += 1
    card_type = "Credit" if cat == "Credit Card" else "Debit"
    expiry = ANCHOR + timedelta(days=random.randint(120, 1500))
    status = random.choices(["Active", "Active", "Active", "Blocked", "Expired"],
                            weights=[0.86, 0.06, 0.02, 0.04, 0.02])[0]
    card_rows.append([
        card_key, f"{random.randint(4,5)}{random.randint(100,999)}-XXXX-XXXX-{random.randint(1000,9999)}",
        akey, acct[2], card_type, random.choice(card_networks),
        iso(expiry), status,
        1 if random.random() < 0.9 else 0,  # ContactlessEnabled
        1 if random.random() < 0.65 else 0,  # InternationalEnabled
    ])
    cards_by_account.setdefault(akey, []).append(card_rows[-1])
write_csv("dim_card.csv",
          ["CardKey", "CardNumberMasked", "AccountKey", "CustomerKey",
           "CardType", "Network", "ExpiresAt", "Status",
           "ContactlessEnabled", "InternationalEnabled"],
          card_rows)

# ==========================================================================
# FACTS
# ==========================================================================
print("Generating facts...")

# Lookup helpers
cust_by_key = {c[0]: c for c in customer_rows}
acct_by_key = {a[0]: a for a in account_rows}
branch_by_key = {b[0]: b for b in branch_rows}
merch_by_key = {m[0]: m for m in merchant_rows}
channel_by_key = {c[0]: c for c in channel_rows}
cardable_accounts = [a for a in account_rows if a[0] in cards_by_account]

# Index merchants by country so most spend is domestic (realistic ~25-30% intl)
merchants_by_country = {}
for m in merchant_rows:
    merchants_by_country.setdefault(m[4], []).append(m)

txn_types = {
    "POS": "Purchase", "ATM": "Withdrawal", "Online": "Purchase",
    "Mobile": "Transfer", "Web": "Transfer", "Wire": "Wire",
    "ACH": "Direct Debit",
}

# ----- fact_transaction (the live stream) ---------------------------------
transaction_rows = []
fraud_alert_rows = []
txn_key = 0
alert_key = 0
fraud_rules = [
    ("R01", "High-risk merchant category", "High"),
    ("R02", "Impossible travel velocity", "Critical"),
    ("R03", "Amount exceeds 6x customer average", "High"),
    ("R04", "Card-not-present + international", "Medium"),
    ("R05", "Rapid-fire authorizations", "High"),
    ("R06", "First transaction in new country", "Medium"),
    ("R07", "Dormant account suddenly active", "Critical"),
]
analysts = ["Maya Iyer", "Tom Becker", "Sara Lopez", "Ken Watanabe", "auto-cleared"]

for _ in range(N_TRANSACTIONS):
    txn_key += 1
    # Bias timestamps: ~30% in the live 48h window, rest across history
    if random.random() < 0.30:
        ts = ANCHOR - timedelta(seconds=random.randint(0, LIVE_WINDOW_HOURS * 3600))
    else:
        ts = ANCHOR - timedelta(
            seconds=random.randint(LIVE_WINDOW_HOURS * 3600, HISTORY_DAYS * 86400)
        )
    acct = random.choice(cardable_accounts)
    akey = acct[0]
    ckey = acct[2]
    cust = cust_by_key[ckey]
    card = random.choice(cards_by_account[akey])
    channel = random.choice(channel_rows)
    ch_type = channel[2]
    # ~72% of spend is domestic (a merchant in the customer's country if one
    # exists), the rest is cross-border travel / e-commerce.
    domestic = merchants_by_country.get(cust[4])
    if domestic and random.random() < 0.72:
        merch = random.choice(domestic)
    else:
        merch = random.choice(merchant_rows)
    mkey = merch[0]
    m_lat, m_lon, m_risk = merch[5], merch[6], merch[7]

    # Amount profile by channel/category
    if ch_type == "ATM":
        amount = random.choice([40, 60, 100, 200, 300, 500])
    elif ch_type == "Wire":
        amount = round(random.uniform(1500, 60000), 2)
    elif merch[2] in ("Airline", "Travel", "Luxury"):
        amount = round(random.uniform(180, 4200), 2)
    else:
        amount = round(random.uniform(4, 650), 2)

    cur_code = acct[6]
    usd_rate = next(c[4] for c in currency_rows if c[1] == cur_code)
    amount_usd = round(amount * usd_rate, 2)

    # Fraud scoring — combine signals
    risk = m_risk * channel[5]
    if cust[9] == "High":
        risk *= 1.4
    if card[9] == 1 and merch[4] != cust[4]:  # international card used abroad
        risk *= 1.2
    if amount_usd > 3000:
        risk *= 1.3
    fraud_score = round(min(0.99, risk / 5.0 + random.uniform(0, 0.22)), 3)
    is_fraud = 1 if fraud_score > 0.80 and random.random() < 0.8 else 0

    if is_fraud:
        status = random.choice(["Declined", "Declined", "Flagged", "Approved"])
    else:
        status = random.choices(["Approved", "Approved", "Approved", "Declined"],
                                weights=[0.9, 0.04, 0.03, 0.03])[0]

    transaction_rows.append([
        txn_key, f"TXN{txn_key:08d}", iso(ts), datekey(ts), ts.strftime("%H:%M:%S"),
        ckey, akey, card[0], mkey, channel[0],
        currency_by_code[cur_code], txn_types.get(ch_type, "Purchase"),
        amount, cur_code, amount_usd, status, fraud_score, is_fraud,
        merch[4], round(m_lat, 4), round(m_lon, 4),
        1 if merch[4] != cust[4] else 0,  # IsInternational
    ])

    # Raise an alert for high-score or fraud transactions
    if fraud_score > 0.70 or is_fraud:
        alert_key += 1
        rule = random.choice(fraud_rules)
        if is_fraud:
            disposition = random.choice(["Confirmed Fraud", "Confirmed Fraud",
                                         "Under Review"])
        else:
            disposition = random.choice(["False Positive", "False Positive",
                                         "Under Review", "Confirmed Fraud"])
        a_status = "Open" if disposition == "Under Review" else "Closed"
        fraud_alert_rows.append([
            alert_key, f"ALERT{alert_key:07d}", txn_key, iso(ts), datekey(ts),
            ckey, akey, rule[0], rule[1], rule[2], fraud_score,
            amount_usd, a_status, disposition,
            random.choice(analysts) if a_status == "Closed" else "unassigned",
        ])

write_csv("fact_transaction.csv",
          ["TransactionKey", "TransactionId", "TransactionTs", "DateKey",
           "TimeOfDay", "CustomerKey", "AccountKey", "CardKey", "MerchantKey",
           "ChannelKey", "CurrencyKey", "TransactionType", "Amount",
           "CurrencyCode", "AmountUsd", "Status", "FraudScore", "IsFraud",
           "MerchantCountry", "MerchantLatitude", "MerchantLongitude",
           "IsInternational"],
          transaction_rows)

write_csv("fact_fraud_alert.csv",
          ["AlertKey", "AlertId", "TransactionKey", "AlertTs", "DateKey",
           "CustomerKey", "AccountKey", "RuleCode", "RuleName", "Severity",
           "FraudScore", "AmountUsd", "Status", "Disposition", "Analyst"],
          fraud_alert_rows)

# ----- fact_account_balance_daily (month-end-ish snapshots, weekly grain) --
balance_rows = []
bal_key = 0
# weekly snapshots to keep file size reasonable
snapshot_days = list(range(0, HISTORY_DAYS + 1, 7))
opening_balance = {}
for acct in account_rows:
    base = {
        "Deposit": random.uniform(500, 45000),
        "Credit Card": -random.uniform(0, 0.6) * (acct[10] or 5000),
        "Lending": -random.uniform(5000, 350000),
        "Investment": random.uniform(20000, 500000),
    }.get(acct[5], 1000.0)
    opening_balance[acct[0]] = base

for off in snapshot_days:
    snap_dt = ANCHOR - timedelta(days=off)
    for acct in account_rows:
        bal_key += 1
        drift = random.uniform(-0.06, 0.07)
        bal = opening_balance[acct[0]] * (1 + drift * (off / 30.0 + 1))
        bal = round(bal, 2)
        limit = acct[10] or 0
        utilization = round(abs(bal) / limit, 3) if (acct[5] == "Credit Card" and limit) else 0.0
        available = round((limit + bal) if acct[5] == "Credit Card" else max(bal, 0), 2)
        balance_rows.append([
            bal_key, acct[0], acct[2], datekey(snap_dt), snap_dt.date().isoformat(),
            bal, available, utilization, acct[6],
        ])
write_csv("fact_account_balance_daily.csv",
          ["BalanceKey", "AccountKey", "CustomerKey", "DateKey", "SnapshotDate",
           "Balance", "AvailableBalance", "CreditUtilization", "CurrencyCode"],
          balance_rows)

# ----- fact_customer_daily_snapshot (weekly KPI snapshot per customer) -----
# aggregate txns per customer for richer snapshot numbers
txn_count_by_cust = {}
txn_sum_by_cust = {}
for t in transaction_rows:
    txn_count_by_cust[t[5]] = txn_count_by_cust.get(t[5], 0) + 1
    txn_sum_by_cust[t[5]] = txn_sum_by_cust.get(t[5], 0.0) + t[14]

cust_snap_rows = []
csnap_key = 0
for off in snapshot_days:
    snap_dt = ANCHOR - timedelta(days=off)
    decay = 1 - off / (HISTORY_DAYS * 1.5)
    for cust in customer_rows:
        csnap_key += 1
        ckey = cust[0]
        n_acct = len(accounts_by_customer.get(ckey, []))
        total_bal = round(sum(opening_balance[a[0]] for a in accounts_by_customer.get(ckey, [])), 2)
        mtd_txn = int(txn_count_by_cust.get(ckey, 0) * 0.06 * max(decay, 0.2) * random.uniform(0.7, 1.3))
        mtd_spend = round(txn_sum_by_cust.get(ckey, 0.0) * 0.06 * max(decay, 0.2) * random.uniform(0.7, 1.3), 2)
        cust_snap_rows.append([
            csnap_key, ckey, datekey(snap_dt), snap_dt.date().isoformat(),
            n_acct, total_bal, mtd_txn, mtd_spend,
            cust[8], cust[9], round(min(0.99, cust[10] * random.uniform(0.8, 1.2)), 3),
        ])
write_csv("fact_customer_daily_snapshot.csv",
          ["SnapshotKey", "CustomerKey", "DateKey", "SnapshotDate",
           "AccountsHeld", "TotalBalanceUsd", "MtdTransactions", "MtdSpendUsd",
           "CreditScore", "RiskBand", "ChurnScore"],
          cust_snap_rows)

# ----- fact_branch_daily_snapshot (daily branch KPIs) ----------------------
branch_snap_rows = []
bsnap_key = 0
for off in range(0, 91):  # last 90 days, daily
    snap_dt = ANCHOR - timedelta(days=off)
    is_weekend = snap_dt.weekday() >= 5
    for br in physical_branches:
        bsnap_key += 1
        base_vol = 220 if br[2] == "Branch" else 90
        vol = int(base_vol * (0.6 if is_weekend else 1.0) * random.uniform(0.7, 1.3))
        value = round(vol * random.uniform(120, 480), 2)
        new_accts = random.randint(0, 6 if br[2] == "Branch" else 1)
        fraud_caught = random.randint(0, 3)
        branch_snap_rows.append([
            bsnap_key, br[0], datekey(snap_dt), snap_dt.date().isoformat(),
            vol, value, new_accts, fraud_caught,
            round(random.uniform(3.6, 4.9), 1),  # CustomerSatScore
        ])
write_csv("fact_branch_daily_snapshot.csv",
          ["SnapshotKey", "BranchKey", "DateKey", "SnapshotDate",
           "TransactionVolume", "TransactionValueUsd", "NewAccountsOpened",
           "FraudCasesCaught", "CustomerSatScore"],
          branch_snap_rows)

print("\nDone. 14 entities written to:", os.path.abspath(OUT_DIR))
