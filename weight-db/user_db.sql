
create schema IF NOT EXISTS  users;
-- Health Data table
CREATE TABLE IF NOT EXISTS users.users (
    id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    preferred_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    email VARCHAR(100) UNIQUE,
    password_hash VARCHAR(256) NOT NULL
);
