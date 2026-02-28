-- ==============================================================================
-- database/schema.sql
-- MySQL / MariaDB schema for the FiveM local server
-- Run once: mysql -u root -p fivem_server < database/schema.sql
-- ==============================================================================

CREATE DATABASE IF NOT EXISTS `fivem_server`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE `fivem_server`;

-- ── players ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `players` (
    `id`          INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    `identifier`  VARCHAR(60)     NOT NULL,
    `name`        VARCHAR(64)     NOT NULL DEFAULT 'Unknown',
    `position`    JSON                     DEFAULT NULL COMMENT '{"x":0,"y":0,"z":0}',
    `metadata`    JSON                     DEFAULT NULL COMMENT 'arbitrary key-value store',
    `money`       INT UNSIGNED    NOT NULL DEFAULT 0,
    `bank`        INT UNSIGNED    NOT NULL DEFAULT 0,
    `created_at`  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `last_seen`   TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── items ─────────────────────────────────────────────────────────────────────
-- Master list of all items that can exist on the server.
CREATE TABLE IF NOT EXISTS `items` (
    `item_name`   VARCHAR(64)     NOT NULL,
    `label`       VARCHAR(128)    NOT NULL,
    `weight`      INT UNSIGNED    NOT NULL DEFAULT 0 COMMENT 'Weight in grams',
    `usable`      TINYINT(1)      NOT NULL DEFAULT 0,
    `stackable`   TINYINT(1)      NOT NULL DEFAULT 1,
    `created_at`  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`item_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Default items
INSERT IGNORE INTO `items` (`item_name`, `label`, `weight`, `usable`, `stackable`) VALUES
    ('water',    'Eau en bouteille',   500,  1, 1),
    ('bread',    'Pain',               200,  1, 1),
    ('bandage',  'Bandage',            100,  1, 1),
    ('phone',    'Téléphone',          150,  0, 0),
    ('id_card',  'Carte d\'identité',   50,  0, 0),
    ('money',    'Argent liquide',       0,  0, 1),
    ('lockpick', 'Crochet de serrure',  80,  1, 1);

-- ── inventory ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `inventory` (
    `id`          INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    `identifier`  VARCHAR(60)     NOT NULL,
    `item_name`   VARCHAR(64)     NOT NULL,
    `quantity`    INT UNSIGNED    NOT NULL DEFAULT 1,
    `created_at`  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_player_item` (`identifier`, `item_name`),
    CONSTRAINT `fk_inv_player` FOREIGN KEY (`identifier`) REFERENCES `players` (`identifier`) ON DELETE CASCADE,
    CONSTRAINT `fk_inv_item`   FOREIGN KEY (`item_name`)  REFERENCES `items`   (`item_name`)  ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
