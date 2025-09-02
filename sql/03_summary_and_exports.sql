-- =========================================
-- 03_summary_and_exports.sql
-- Panini Dashboard – Summary Tables for Tableau (MySQL 8.x)
-- Run AFTER 02_clean_and_normalize.sql
-- =========================================
USE panini_dashboard_clean;

-- -----------------------------------------
-- 0) Refresh is_signed
-- -----------------------------------------
UPDATE panini_cards
SET is_signed = 1
WHERE is_signed <> 1
  AND LOWER(card_set) REGEXP 'auto|autograph|signature|sig([^a-z]|$)|penmanship|scripts|signed|([^a-z]|^)ink([^a-z]|$)';

UPDATE panini_cards
SET is_signed = 0
WHERE is_signed <> 0
  AND NOT (LOWER(card_set) REGEXP 'auto|autograph|signature|sig([^a-z]|$)|penmanship|scripts|signed|([^a-z]|^)ink([^a-z]|$)');

-- =========================================
-- 1) YEAR SUMMARY
-- =========================================
DROP TABLE IF EXISTS panini_year_summary;
CREATE TABLE panini_year_summary AS
SELECT
  year,
  COUNT(*) AS total_cards,
  COUNT(CASE WHEN is_signed = 1 THEN 1 END) AS signed_cards,
  COUNT(CASE WHEN is_signed = 1 AND sequence IS NOT NULL THEN 1 END) AS known_autos,
  COUNT(CASE WHEN is_signed = 1 AND sequence IS NULL     THEN 1 END) AS unknown_autos,
  SUM(CASE WHEN is_signed = 1 THEN COALESCE(sequence,0) ELSE 0 END) AS total_known_signed_cards
FROM panini_cards
GROUP BY year;

-- =========================================
-- 2) YEAR + PROGRAM SUMMARY
-- =========================================
DROP TABLE IF EXISTS panini_year_program_summary;
CREATE TABLE panini_year_program_summary AS
SELECT
  year,
  program,
  COUNT(*) AS total_cards,
  COUNT(CASE WHEN is_signed = 1 THEN 1 END) AS signed_cards,
  COUNT(CASE WHEN is_signed = 1 AND sequence IS NOT NULL THEN 1 END) AS known_autos,
  COUNT(CASE WHEN is_signed = 1 AND sequence IS NULL THEN 1 END) AS unknown_autos,
  SUM(CASE WHEN is_signed = 1 THEN COALESCE(sequence,0) ELSE 0 END) AS total_known_signed_cards
FROM panini_cards
GROUP BY year, program;

-- =========================================
-- 3) PROGRAM SUMMARY
-- =========================================
DROP TABLE IF EXISTS panini_program_summary;
CREATE TABLE panini_program_summary AS
SELECT
  program,
  COUNT(*) AS total_cards,
  COUNT(CASE WHEN is_signed = 1 THEN 1 END) AS signed_cards,
  COUNT(CASE WHEN is_signed = 1 AND sequence IS NOT NULL THEN 1 END) AS known_autos,
  COUNT(CASE WHEN is_signed = 1 AND sequence IS NULL THEN 1 END) AS unknown_autos,
  SUM(CASE WHEN is_signed = 1 THEN COALESCE(sequence,0) ELSE 0 END) AS total_known_signed_cards
FROM panini_cards
GROUP BY program;

-- =========================================
-- 4) CARD SET SUMMARY
-- =========================================
DROP TABLE IF EXISTS panini_card_set_summary;
CREATE TABLE panini_card_set_summary AS
SELECT
  card_set,
  COUNT(*) AS total_cards,
  COUNT(CASE WHEN is_signed = 1 THEN 1 END) AS signed_cards,
  COUNT(CASE WHEN is_signed = 1 AND sequence IS NOT NULL THEN 1 END) AS known_autos,
  COUNT(CASE WHEN is_signed = 1 AND sequence IS NULL THEN 1 END) AS unknown_autos,
  SUM(CASE WHEN is_signed = 1 THEN COALESCE(sequence,0) ELSE 0 END) AS total_known_signed_cards
FROM panini_cards
GROUP BY card_set;

-- =========================================
-- 5) PLAYER SUMMARY
-- =========================================
DROP TABLE IF EXISTS panini_player_summary;
CREATE TABLE panini_player_summary AS
SELECT
  p.player_id,
  p.athlete,
  COUNT(*) AS total_cards,
  COUNT(CASE WHEN pc.is_signed = 1 THEN 1 END) AS signed_cards,
  COUNT(CASE WHEN pc.is_signed = 1 AND pc.sequence IS NOT NULL THEN 1 END) AS known_autos,
  COUNT(CASE WHEN pc.is_signed = 1 AND pc.sequence IS NULL THEN 1 END) AS unknown_autos
FROM panini_cards pc
JOIN players p ON pc.player_id = p.player_id
GROUP BY p.player_id, p.athlete;

-- =========================================
-- 6) PLAYER YEARLY SUMMARY
-- =========================================
DROP TABLE IF EXISTS panini_player_yearly_summary;
CREATE TABLE panini_player_yearly_summary AS
SELECT
  p.player_id,
  p.athlete,
  pc.year,
  COUNT(*) AS total_cards,
  COUNT(CASE WHEN pc.is_signed = 1 THEN 1 END) AS signed_cards,
  COUNT(CASE WHEN pc.is_signed = 1 AND pc.sequence IS NOT NULL THEN 1 END) AS known_autos,
  COUNT(CASE WHEN pc.is_signed = 1 AND pc.sequence IS NULL THEN 1 END) AS unknown_autos
FROM panini_cards pc
JOIN players p ON pc.player_id = p.player_id
GROUP BY p.player_id, p.athlete, pc.year;

-- =========================================
-- 7) Quick verification
-- =========================================
SELECT COUNT(*) FROM panini_year_summary;
SELECT COUNT(*) FROM panini_program_summary;
SELECT COUNT(*) FROM panini_card_set_summary;
SELECT COUNT(*) FROM panini_player_summary;
SELECT COUNT(*) FROM panini_player_yearly_summary;