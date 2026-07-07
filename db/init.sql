-- Cria os bancos de catalog e notifications na primeira subida do Postgres.
-- O banco 'fcgdb' (users) ja nasce via POSTGRES_DB no docker-compose.
CREATE DATABASE catalogdb;
CREATE DATABASE notificationsdb;
