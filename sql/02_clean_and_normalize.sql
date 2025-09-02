-- =========================================
-- 02_clean_and_normalize_fixed.sql
-- Panini Dashboard Project – Clean, Dedupe, Split, Capitalize, Link
-- Target: MySQL 8.x
-- =========================================

USE panini_dashboard_clean;

-- -----------------------------------------
-- STEP 1: Trim + normalize spaces
-- -----------------------------------------
UPDATE panini_cards
SET
  athlete       = TRIM(athlete),
  team          = TRIM(team),
  position      = TRIM(position),
  brand         = TRIM(brand),
  program       = TRIM(program),
  card_set      = TRIM(card_set),
  set_file_name = TRIM(set_file_name);

UPDATE panini_cards
SET
  athlete       = REGEXP_REPLACE(athlete, '\\s+', ' '),
  team          = REGEXP_REPLACE(team, '\\s+', ' '),
  position      = REGEXP_REPLACE(position, '\\s+', ' '),
  brand         = REGEXP_REPLACE(brand, '\\s+', ' '),
  program       = REGEXP_REPLACE(program, '\\s+', ' '),
  card_set      = REGEXP_REPLACE(card_set, '\\s+', ' '),
  set_file_name = REGEXP_REPLACE(set_file_name, '\\s+', ' ');

-- -----------------------------------------
-- STEP 2: Dedupe – keep lowest id per unique card signature
-- -----------------------------------------
DROP TABLE IF EXISTS keepers;
CREATE TABLE keepers AS
SELECT MIN(id) AS id
FROM panini_cards
GROUP BY
  sport, year, brand, program, card_set,
  athlete, team, position, card_number, sequence, set_file_name;

DROP TABLE IF EXISTS panini_cards_dedup;
CREATE TABLE panini_cards_dedup LIKE panini_cards;

INSERT INTO panini_cards_dedup
SELECT pc.*
FROM panini_cards pc
JOIN keepers k USING (id);

RENAME TABLE
  panini_cards TO panini_cards_with_dupes,
  panini_cards_dedup TO panini_cards;

DROP TABLE IF EXISTS keepers;

-- -----------------------------------------
-- STEP 3: Mark multi-athlete rows (split uses "/")
-- -----------------------------------------
UPDATE panini_cards
SET has_multiple_athletes = (
       athlete  LIKE '%/%'
    OR team     LIKE '%/%'
    OR position LIKE '%/%'
  );

UPDATE panini_cards
SET source_id = id;

-- -----------------------------------------
-- STEP 4: Split multi-athlete rows on "/"
-- -----------------------------------------
DROP TABLE IF EXISTS panini_cards_normalized;
CREATE TABLE panini_cards_normalized LIKE panini_cards;

ALTER TABLE panini_cards_normalized
  ADD COLUMN norm_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST;

-- Copy single-athlete rows
INSERT INTO panini_cards_normalized (
  id, sport, year, brand, program, card_set, athlete, team, position,
  card_number, sequence, set_file_name, source_id, has_multiple_athletes, is_signed, player_id
)
SELECT
  id, sport, year, brand, program, card_set, athlete, team, position,
  card_number, sequence, set_file_name, source_id, has_multiple_athletes, is_signed, player_id
FROM panini_cards
WHERE has_multiple_athletes = FALSE;

-- Split multi-athlete rows with recursive CTE
DROP TEMPORARY TABLE IF EXISTS tmp_split_rows;
CREATE TEMPORARY TABLE tmp_split_rows AS
WITH RECURSIVE split_rows AS (
  SELECT
    source_id,
    TRIM(SUBSTRING_INDEX(athlete, '/', 1))   AS athlete,
    TRIM(SUBSTRING_INDEX(team, '/', 1))      AS team,
    TRIM(SUBSTRING_INDEX(position, '/', 1))  AS position,
    TRIM(SUBSTRING(athlete, LOCATE('/', athlete) + 1))   AS rem_athlete,
    TRIM(SUBSTRING(team, LOCATE('/', team) + 1))         AS rem_team,
    TRIM(SUBSTRING(position, LOCATE('/', position) + 1)) AS rem_position,
    sport, year, brand, program, card_set, card_number, sequence, set_file_name,
    is_signed, player_id
  FROM panini_cards
  WHERE has_multiple_athletes = TRUE

  UNION ALL

  SELECT
    source_id,
    TRIM(SUBSTRING_INDEX(rem_athlete, '/', 1)),
    TRIM(SUBSTRING_INDEX(rem_team, '/', 1)),
    TRIM(SUBSTRING_INDEX(rem_position, '/', 1)),
    TRIM(CASE WHEN rem_athlete LIKE '%/%'
         THEN SUBSTRING(rem_athlete, LOCATE('/', rem_athlete) + 1) ELSE NULL END),
    TRIM(CASE WHEN rem_team LIKE '%/%'
         THEN SUBSTRING(rem_team, LOCATE('/', rem_team) + 1) ELSE NULL END),
    TRIM(CASE WHEN rem_position LIKE '%/%'
         THEN SUBSTRING(rem_position, LOCATE('/', rem_position) + 1) ELSE NULL END),
    sport, year, brand, program, card_set, card_number, sequence, set_file_name,
    is_signed, player_id
  FROM split_rows
  WHERE rem_athlete IS NOT NULL
)
SELECT
  sport, year, brand, program, card_set, athlete, team, position,
  card_number, sequence, set_file_name, source_id, is_signed, player_id
FROM split_rows;

-- Insert split results
INSERT INTO panini_cards_normalized (
  id, sport, year, brand, program, card_set, athlete, team, position,
  card_number, sequence, set_file_name, source_id, has_multiple_athletes, is_signed, player_id
)
SELECT
  source_id, sport, year, brand, program, card_set, athlete, team, position,
  card_number, sequence, set_file_name, source_id, TRUE, is_signed, player_id
FROM tmp_split_rows;

-- Swap normalized table in
RENAME TABLE panini_cards TO panini_cards_backup_split;
RENAME TABLE panini_cards_normalized TO panini_cards;

-- -----------------------------------------
-- STEP 5: Build players + link
-- -----------------------------------------
UPDATE panini_cards SET player_id = NULL;

DROP TABLE IF EXISTS players;

CREATE TABLE IF NOT EXISTS players (
  player_id INT AUTO_INCREMENT PRIMARY KEY,
  athlete VARCHAR(55) NOT NULL,
  default_position VARCHAR(50),
  default_team VARCHAR(50),
  rookie_year INT,
  draft_team VARCHAR(50),
  draft_round INT,
  draft_pick INT,
  college VARCHAR(100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

TRUNCATE TABLE players;

INSERT INTO players (athlete)
SELECT DISTINCT athlete
FROM panini_cards
WHERE athlete IS NOT NULL
  AND athlete <> ''
  AND LOWER(athlete) NOT IN ('n/a', 'unknown')
ORDER BY athlete;

CREATE INDEX idx_pc_athlete ON panini_cards (athlete);
CREATE INDEX idx_p_athlete  ON players (athlete);

SET SESSION innodb_lock_wait_timeout = 800;
SET autocommit = 1;

DROP TEMPORARY TABLE IF EXISTS to_link;
CREATE TEMPORARY TABLE to_link (
  id BIGINT UNSIGNED PRIMARY KEY,
  player_id INT NOT NULL
) ENGINE=MEMORY;

DROP PROCEDURE IF EXISTS link_players_2phase;
DELIMITER $$
CREATE PROCEDURE link_players_2phase(IN batch_size INT)
BEGIN
  DECLARE n INT DEFAULT 1;

  WHILE n > 0 DO
    -- Phase 1: stage the next batch of id→player_id pairs
    INSERT IGNORE INTO to_link (id, player_id)
    SELECT pc.id, p.player_id
    FROM panini_cards pc
    JOIN players p FORCE INDEX (idx_p_athlete)
      ON p.athlete = pc.athlete
    WHERE pc.player_id IS NULL
    LIMIT batch_size;

    SET n = ROW_COUNT();

    -- Phase 2: apply the staged links
    UPDATE panini_cards pc
    JOIN to_link t USING (id)
    SET pc.player_id = t.player_id;

    -- clear the stage table for the next loop
    TRUNCATE TABLE to_link;
  END WHILE;
END$$
DELIMITER ;

CALL link_players_2phase(5000);
DROP PROCEDURE IF EXISTS link_players_2phase;

UPDATE panini_cards pc
JOIN players p ON p.athlete = pc.athlete
SET pc.player_id = p.player_id;

-- -----------------------------------------
-- STEP 8: Sanity check for bad multi-athlete formatting
-- -----------------------------------------
SELECT COUNT(*) AS bad_groups
FROM panini_cards
WHERE athlete LIKE '%|%'
   OR team LIKE '%|%'
   OR position LIKE '%|%';
