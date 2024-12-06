-- NBA Cards Database Schema

-- Sets table
CREATE TABLE sets (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    year VARCHAR(7) NOT NULL,
    release_date DATE,
    manufacturer VARCHAR(50) DEFAULT 'Panini'
);

-- Base cards
CREATE TABLE base_cards (
    id SERIAL PRIMARY KEY,
    set_id INTEGER REFERENCES sets(id),
    card_number VARCHAR(10),
    player_name VARCHAR(100),
    team VARCHAR(50),
    rookie BOOLEAN DEFAULT false
);

-- Parallels
CREATE TABLE parallels (
    id SERIAL PRIMARY KEY,
    set_id INTEGER REFERENCES sets(id),
    name VARCHAR(50),
    numbered_to INTEGER NULL
);

-- Inserts
CREATE TABLE insert_sets (
    id SERIAL PRIMARY KEY,
    set_id INTEGER REFERENCES sets(id),
    name VARCHAR(100),
    total_cards INTEGER
);

-- Autographs
CREATE TABLE autographs (
    id SERIAL PRIMARY KEY,
    set_id INTEGER REFERENCES sets(id),
    name VARCHAR(100),
    player_name VARCHAR(100),
    card_number VARCHAR(10),
    numbered_to INTEGER NULL
);

-- Sample data for 2015-16 Panini Complete
INSERT INTO sets (name, year, release_date) 
VALUES ('Complete', '2015-16', '2015-10-01');

-- Continue with your specific checklist data
