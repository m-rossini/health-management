create schema IF NOT EXISTS health;
CREATE TABLE IF NOT EXISTS health.health_data (
    id SERIAL PRIMARY KEY,
    user_id INTEGER , --FOREIGN KEY REFERENCES health.users(id), if they were in the same database
    weight FLOAT NOT NULL,
    height FLOAT NOT NULL,
    bp_systolic INTEGER,
    bp_diastolic INTEGER,
    heart_rate INTEGER,
    date_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER SCHEMA health OWNER TO rossini;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA health TO rossini;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA health TO rossini;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA health TO rossini;