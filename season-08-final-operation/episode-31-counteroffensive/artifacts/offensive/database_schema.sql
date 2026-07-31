-- Nova Era Operations Database Schema
-- Extracted: 2025-10-15 08:30 UTC

-- Table: operations
CREATE TABLE operations (
    id SERIAL PRIMARY KEY,
    target VARCHAR(255),
    type VARCHAR(50),
    start_date DATE,
    status VARCHAR(20),
    priority VARCHAR(20)
);

-- Table: architects (CRITICAL)
CREATE TABLE architects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(255),
    role VARCHAR(50),
    organization VARCHAR(255),
    joined_date DATE,
    motivation TEXT
);

-- Sample data (The Architect)
INSERT INTO architects VALUES (
    1,
    'Кирилл Соболев',
    'k.sobolev@nova-era.onion',
    'leader',
    'ex-FSB Управление К',
    '2020-08-15',
    'Revenge against Krylov + Alex'
);

-- Table: compromised_hosts (Botnet)
CREATE TABLE compromised_hosts (
    id SERIAL PRIMARY KEY,
    ip_address VARCHAR(45),
    device_type VARCHAR(100),
    infection_date TIMESTAMP,
    status VARCHAR(20)
);

-- 5,247 rows total
