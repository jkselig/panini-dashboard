\# Data Sources



\## Raw Data

\- Source: Panini America official checklists

\- Format: CSV/Excel files, one per brand/program/year

\- Not included in repo due to size (200 MB+ total)



\## Samples in Repo

\- `data/raw\_sample/panini\_checklists\_2020\_raw.csv` → Example raw file (23 MB)

\- `data/processed\_sample/panini\_checklists\_2020\_processed.csv` → Example processed file (37 MB)



\## Full Dataset

\- Combined 2020–2024 master (~205 MB) is too large for GitHub.

\- Download via \[Google Drive](https://drive.google.com/file/d/1AphuCNFdUUpgTVW3S1suG1-tJmZUU67u/view?usp=drive\_link)



\## Processed Data

\- Combined using `python/combine\_checklists\_by\_year.py` and `python/combine\_all\_years.py`

\- Loaded into MySQL via `sql/01\_create\_tables.sql` (data import handled with Workbench wizard)



\## Exports

\- `data/exports/players.csv` – enriched player master

\- `data/exports/Player\_level\_dashboard.csv` – player-level summary for Tableau

\- `data/exports/panini\_year\_summary.csv` – yearly summary for Tableau



