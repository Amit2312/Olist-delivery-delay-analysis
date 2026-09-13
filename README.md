# Olist-delivery-delay-analysis
Does late delivery hurt customer satisfaction and repeat purchases?

# Delivery Delays & Customer Behavior: Olist E-Commerce Analysis

**Does late delivery hurt customer satisfaction and repeat purchases?**
An end-to-end SQL + Python analysis of ~100K orders from the Olist Brazilian e-commerce dataset — covering delay rates, their link to review scores and repeat purchases, where delays concentrate geographically, and an estimate of the revenue at risk.

## Tools & Stack

- **PostgreSQL** (via TablePlus) — data extraction and transformation
- **Python** (pandas, seaborn, statsmodels) — analysis, statistical testing, and visualization in Google Colab
- **Dataset:** https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
## Repository Structure

```
├── README.md
├── schema.sql                          # recreates the target schema (6 tables)
├── sql_code/                           
│   ├── q1_overall_late_share.sql
│   ├── q1_monthly_late_trend.sql
│   ├── q2_duplicate_reviews.sql
│   ├── q2_review_score_by_delay.sql
│   ├── q3_days_between_orders.sql
│   ├── q3_deciding_eligible_cust.sql
│   ├── q3_delay_vs_ontime_reorder_comparison.sql
│   ├── q3_orders_placed_under_30_secs.sql
│   ├── q3_total_eligible_cust_180.sql
│   ├── q4_state_wise_delay_rate.sql
│   ├── q5_avg_order_value.sql
│   ├── q5_num_eligible_delay_cust.sql
│   └── q5_num_all_delay_cust.sql
├── sql_result/                         
└── Superstore_Project.ipynb            # full analysis, charts, interpretation
```


## Business Questions & Key Findings

| # | Question | Finding |
|---|---|---|
| 1 | What share of orders arrive later than estimated? | **6.77%** overall — but concentrated in two spike months (Nov 2017, Feb–Mar 2018) rather than a stable baseline. Outside those, the typical month runs 3–5%. |
| 2 | Does late delivery correlate with lower review scores? | Yes, sharply: **4.29★ avg** on-time (n=89,443) vs **2.27★ avg** delayed (n=6,381). |
| 3 | Do delayed customers reorder less often? | **2.33%** (delayed) vs **2.75%** (on-time) reorder rate — a ~15% relative gap, directionally suggestive but not statistically significant (two-proportion z-test, p = 0.076). |
| 4 | Which states have the worst delay rates? | Delay rates range **2.76%–21.41%** across states with reliable order volume (n≥100). Worst: Alagoas, Maranhão, Sergipe, Piauí, Ceará (13–21%), concentrated in the North/Northeast. São Paulo and Minas Gerais — the two highest-volume states — stay close to the national baseline (~4.5%). |
| 5 | Revenue at risk from delay → reorder effect? | **R$3,837** (primary estimate, population Q3 actually observed) to **R$4,701** (sensitivity estimate, full delayed population) — modest, ~0.02–0.03% of total order value, consistent with Q3's inconclusive significance result. |

## Methodology Notes

A few judgment calls that shaped the analysis, documented here rather than buried in code comments:

- **Duplicate reviews (Q2):** ~547 orders had multiple review rows with genuinely different scores (not duplicate inserts). Used `ROW_NUMBER()` to keep the most recent review per order instead of averaging conflicting opinions into a meaningless number.
- **Text-stored dates:** Both `orders` and `order_reviews` store dates as plain text. Order dates required `NULLIF(TRIM(...))::date`; review timestamps needed explicit `TO_TIMESTAMP(..., 'DD/MM/YY HH24:MI')` parsing due to a non-standard format — an easy silent bug if cast naively.
- **Reorder comparison window, W=180 days (Q3):** A naive reorder-rate comparison unfairly penalizes customers near the end of the dataset who've had less time to reorder. Chose a fixed 180-day window after checking the empirical time-to-reorder distribution (median ~62 days, 90th percentile ~281 days) — it captures most reorder behavior while retaining 71% of customers, a better trade-off than the 90th-percentile window, which would drop to 47%.
- **Cart-splitting artifact:** Excluded ~740 order pairs placed under 60 seconds apart from reorder-timing analysis — these are almost certainly one checkout split into multiple order rows, not genuine repeat purchases.
- **State attribution (Q4):** Used `customer_state` (delivery destination), not `seller_state` — the question is about where delays are *experienced*, not where they originate.
- **Small-sample transparency (Q4):** States with fewer than 100 delivered orders are flagged rather than dropped — shown grayed-out on the chart and excluded only from ranking language, not from the dataset.
- **Reporting the null result honestly (Q3 → Q5):** Q3's reorder-rate gap didn't clear p<0.05. Rather than treating it as confirmed, Q5 carries that uncertainty forward with two labeled estimates — a primary figure that doesn't extrapolate past the observed population, and a sensitivity figure that assumes the effect generalizes.

## How to Reproduce

1. Load the Olist CSVs into PostgreSQL under a `target` schema — see `schema.sql`.
2. Run each file in `sql_code/`; filenames match their corresponding CSV export in `sql_result/`.
3. Open `Superstore_Project.ipynb` in Colab/Jupyter, point the `pd.read_csv` paths at your local `sql_result/` folder, and run top to bottom.

## Limitations

- Q3 and Q5's core effect (delay → lower reorder rate) is directionally suggestive, not statistically confirmed at conventional thresholds (p = 0.076).
- The Feb–Mar 2018 delay spike is attributed to logistics strikes based on external commentary on this dataset, not independently verified against a primary source.
- The Q5 revenue-at-risk figure is a simplified estimate (delayed customers × rate gap × avg order value), not a cohort-based or causal revenue model.

## Author

Amit Tyagi — https://www.linkedin.com/in/amit-tyagi-73a0b2135/
