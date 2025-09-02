\# Data Dictionary



\## panini\_cards

\- `id` (BIGINT) – unique row id

\- `source\_id` (BIGINT) – original id for multi-athlete splits

\- `year` (INT) – release year

\- `brand` (VARCHAR)

\- `program` (VARCHAR)

\- `card\_set` (VARCHAR)

\- `athlete` (VARCHAR)

\- `team` (VARCHAR)

\- `position` (VARCHAR)

\- `card\_number` (VARCHAR)

\- `sequence` (INT, NULL) – known print-run size (e.g., 25 for "/25")

\- `is\_signed` (TINYINT) – flag set by regex on card\_set

\- `player\_id` (INT, FK → players)



\## players

\- `player\_id` (INT, PK)

\- `athlete` (VARCHAR)

\- `default\_team` (VARCHAR)

\- `default\_position` (VARCHAR)

\- `rookie\_year` (INT)

\- `draft\_team` (VARCHAR)

\- `draft\_round` (INT)

\- `draft\_pick` (INT)

\- `college` (VARCHAR)



\## Summary Tables

\- \*\*panini\_year\_summary\*\* – totals per year

\- \*\*panini\_year\_program\_summary\*\* – totals per year + program

\- \*\*panini\_program\_summary\*\* – totals per program

\- \*\*panini\_card\_set\_summary\*\* – totals per set

\- \*\*panini\_player\_summary\*\* – totals per player

\- \*\*panini\_player\_yearly\_summary\*\* – totals per player per year



