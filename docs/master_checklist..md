\# Master Checklist – Panini Dashboard



\## Environment

\- MySQL 8.x + Workbench

\- Tableau Desktop / Public

\- Python 3.11+ (only needed for combining raw checklists, requires `pandas`)



---



\## Order of Operations



\### 1. Raw → Processed (Python)

\- Combine raw Panini checklist files per year with:

&nbsp; - `python/combine\_checklists\_by\_year.py`

\- Combine yearly masters into one multi-year file with:

&nbsp; - `python/combine\_all\_years.py`

\- Output: `data/processed\_sample/{year}\_master.csv` and `panini\_master.csv`



\### 2. Create Tables + Load Data

\- Run `sql/01\_create\_tables.sql` to create empty schema:

&nbsp; - `panini\_cards`

&nbsp; - `players`

\- Use \*\*MySQL Workbench Table Data Import Wizard\*\* to load `panini\_master.csv`

&nbsp; into the `panini\_cards` table.



\### 3. Clean + Normalize

\- Run `sql/02\_clean\_and\_normalize\_fixed.sql`

&nbsp; - Deduplicate rows

&nbsp; - Mark \& split multi-athlete rows

&nbsp; - Build and link `players` table



\### 4. Summaries

\- Run `sql/03\_summary\_and\_exports.sql`

&nbsp; - Builds summary tables:

&nbsp;   - `panini\_year\_summary`

&nbsp;   - `panini\_year\_program\_summary`

&nbsp;   - `panini\_program\_summary`

&nbsp;   - `panini\_card\_set\_summary`

&nbsp;   - `panini\_player\_summary`

&nbsp;   - `panini\_player\_yearly\_summary`



\### 5. EDA (Optional)

\- Run `sql/04\_eda\_queries.sql` to explore trends:

&nbsp; - Signed vs unsigned counts

&nbsp; - Top players per year

&nbsp; - Top QBs

&nbsp; - Print run distributions



\### 6. Export for Tableau

\- Export these CSVs from MySQL:

&nbsp; - `data/exports/players.csv`

&nbsp; - `data/exports/Player\_level\_dashboard.csv`

&nbsp; - `data/exports/panini\_year\_summary.csv`



\### 7. Tableau

\- Open dashboards in `tableau/`:

&nbsp; - `Player\_level\_dashboard.twbx` → connect to Player exports

&nbsp; - `Overall\_summary\_dashboard.twbx` → connect to Year summary exports



