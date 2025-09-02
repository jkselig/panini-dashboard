-- =========================================
-- 04_eda_queries.sql  (MySQL 8.x)
-- =========================================

USE panini_dashboard_clean;

-- Signed vs unsigned counts
SELECT is_signed, COUNT(*) AS total_rows
FROM panini_cards
GROUP BY is_signed;

-- Yearly summary table
SELECT * FROM panini_year_summary ORDER BY year;

-- Program summary table
SELECT * FROM panini_program_summary ORDER BY program;

-- Card set summary table
SELECT * FROM panini_card_set_summary ORDER BY card_set;

-- Year + Program summary table
SELECT * FROM panini_year_program_summary ORDER BY year, program;

-- Player summary table
SELECT * FROM panini_player_summary ORDER BY athlete;

-- Players table (spot check)
SELECT * FROM players ORDER BY player_id LIMIT 100;

-- Unique signed cards (by brand/program/set/number/sequence)

SELECT 
  COUNT(DISTINCT CONCAT_WS('|', brand, program, card_set, card_number, sequence)) AS unique_signature_cards
FROM panini_cards
WHERE is_signed = 1;

-- Unique signed cards by year
SELECT 
  year,
  COUNT(DISTINCT CONCAT_WS('|', brand, program, card_set, card_number, sequence)) AS unique_signature_cards
FROM panini_cards
WHERE is_signed = 1
GROUP BY year
ORDER BY year;

-- Total known signed card copies (sequence is INT now)

SELECT
  SUM(CASE WHEN is_signed = 1 THEN COALESCE(sequence, 0) ELSE 0 END) AS total_known_signed_card_copies
FROM panini_cards;

-- Top 10 signed cards per year (by unique signed cards, tie‑break by copies)

WITH per_player AS (
  SELECT
    pc.year,
    pc.athlete,
    COUNT(DISTINCT CONCAT_WS('|', pc.brand, pc.program, pc.card_set, pc.card_number, pc.sequence)) AS unique_signed_cards,
    SUM(CASE WHEN pc.is_signed = 1 THEN COALESCE(pc.sequence,0) ELSE 0 END) AS total_known_signed_card_copies
  FROM panini_cards pc
  WHERE pc.is_signed = 1
  GROUP BY pc.year, pc.athlete
)
SELECT *
FROM (
  SELECT
    year, athlete, unique_signed_cards, total_known_signed_card_copies,
    ROW_NUMBER() OVER (
      PARTITION BY year
      ORDER BY unique_signed_cards DESC, total_known_signed_card_copies DESC, athlete ASC
    ) AS player_rank
  FROM per_player
) ranked
WHERE player_rank <= 10
ORDER BY year, player_rank;

-- Top 10 by position per year (change WHERE to target any position)

WITH per_player_pos AS (
  SELECT
    pc.year,
    pc.athlete,
    pc.position,
    COUNT(DISTINCT CONCAT_WS('|', pc.brand, pc.program, pc.card_set, pc.card_number, pc.sequence)) AS unique_signed_cards,
    SUM(CASE WHEN pc.is_signed = 1 THEN COALESCE(pc.sequence,0) ELSE 0 END) AS total_known_signed_card_copies
  FROM panini_cards pc
  WHERE pc.is_signed = 1
  GROUP BY pc.year, pc.athlete, pc.position
)
SELECT *
FROM (
  SELECT
    year, athlete, position, unique_signed_cards, total_known_signed_card_copies,
    ROW_NUMBER() OVER (
      PARTITION BY year
      ORDER BY total_known_signed_card_copies DESC, unique_signed_cards DESC, athlete ASC
    ) AS player_rank
  FROM per_player_pos
) ranked
WHERE player_rank <= 10
ORDER BY year, player_rank;

-- Top 5 QBs per year (edit the position in the WHERE to reuse)

WITH per_qb AS (
  SELECT
    pc.year,
    pc.athlete,
    pc.position,
    COUNT(DISTINCT CONCAT_WS('|', pc.brand, pc.program, pc.card_set, pc.card_number, pc.sequence)) AS unique_signed_cards,
    SUM(CASE WHEN pc.is_signed = 1 THEN COALESCE(pc.sequence,0) ELSE 0 END) AS total_known_signed_card_copies
  FROM panini_cards pc
  WHERE pc.is_signed = 1
    AND pc.position = 'QB'
  GROUP BY pc.year, pc.athlete, pc.position
)
SELECT *
FROM (
  SELECT
    year, athlete, position, unique_signed_cards, total_known_signed_card_copies,
    ROW_NUMBER() OVER (
      PARTITION BY year
      ORDER BY total_known_signed_card_copies DESC, unique_signed_cards DESC, athlete ASC
    ) AS qb_rank
  FROM per_qb
) ranked
WHERE qb_rank <= 5
ORDER BY year, qb_rank;

SELECT p.rookie_year, COUNT(DISTINCT pc.id) AS rookie_signed_cards
FROM panini_cards pc
JOIN players p ON pc.player_id = p.player_id
WHERE pc.is_signed = 1
GROUP BY p.rookie_year
ORDER BY p.rookie_year;