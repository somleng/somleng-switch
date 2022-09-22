-- From: https://github.com/OpenSIPS/opensips/blob/master/scripts/postgres/domain-create.sql

CREATE TABLE domain (
    id SERIAL PRIMARY KEY NOT NULL,
    domain VARCHAR(64) DEFAULT '' NOT NULL,
    attrs VARCHAR(255) DEFAULT NULL,
    last_modified TIMESTAMP WITHOUT TIME ZONE DEFAULT '1900-01-01 00:00:01' NOT NULL,
    CONSTRAINT domain_domain_idx UNIQUE (domain)
);

ALTER SEQUENCE domain_id_seq MAXVALUE 2147483647 CYCLE;
