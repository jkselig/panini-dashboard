-- =========================================
-- 01_create_tables.sql
-- Panini Dashboard Project - Base Table Creation
-- Target: MySQL 8.x
-- =========================================

USE panini_dashboard_clean;

-- =========================================
-- Drop existing tables if re-running script
-- =========================================
DROP TABLE IF EXISTS panini_cards;
DROP TABLE IF EXISTS players;

-- =========================================
-- Create panini_cards table
-- =========================================
CREATE TABLE panini_cards (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sport VARCHAR(50),
    year INT,
    brand VARCHAR(100),
    program VARCHAR(100),
    card_set VARCHAR(255),
    athlete VARCHAR(350),
    team VARCHAR(436),
    position VARCHAR(72),
    card_number VARCHAR(50),
    sequence INT,
    set_file_name VARCHAR(255),

    -- Added during project
    source_id INT NOT NULL DEFAULT 0,
    has_multiple_athletes BOOLEAN NOT NULL DEFAULT FALSE,
    is_signed BOOLEAN NOT NULL DEFAULT FALSE,
    player_id INT,

    -- Indexes for performance
    INDEX idx_year (year),
    INDEX idx_program (program),
    INDEX idx_card_set (card_set),
    INDEX idx_athlete (athlete),
    INDEX idx_is_signed (is_signed),
    INDEX idx_player_id (player_id),
    INDEX idx_source_id (source_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================
-- Create players table
-- =========================================
CREATE TABLE players (
    player_id INT AUTO_INCREMENT PRIMARY KEY,
    athlete VARCHAR(255) NOT NULL,
    default_position VARCHAR(50),
    default_team VARCHAR(100),
    rookie_year INT,
    draft_team VARCHAR(100),
    draft_round INT,
    draft_pick INT,
    college VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =========================================
-- Notes:
-- 1. Run this script first in the clean schema.
-- 2. After running, import your processed CSV into `panini_cards`.
-- 3. Ensure CSV columns match table definition exactly (column order can be mapped in Import Wizard).
-- =========================================
