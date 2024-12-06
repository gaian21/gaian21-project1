-- Example queries for panini_mega_collection.db

-- Show tables
SELECT name FROM sqlite_master WHERE type='table';

-- Show cards table structure
SELECT sql FROM sqlite_master WHERE name='cards';

-- Sample entries from cards table
SELECT * FROM cards LIMIT 5;

-- Sample sets
SELECT DISTINCT set_name FROM cards ORDER BY set_name LIMIT 5;

-- Count cards per set
SELECT set_name, COUNT(*) as card_count 
FROM cards 
GROUP BY set_name 
ORDER BY card_count DESC 
LIMIT 5;
