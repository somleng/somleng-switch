-- From: https://github.com/OpenSIPS/opensips/blob/master/scripts/postgres/load_balancer-create.sql

CREATE TABLE load_balancer (
    id SERIAL PRIMARY KEY NOT NULL,
    group_id INTEGER DEFAULT 0 NOT NULL,
    dst_uri VARCHAR(128) NOT NULL,
    resources VARCHAR(255) NOT NULL,
    probe_mode INTEGER DEFAULT 0 NOT NULL,
    attrs VARCHAR(255) DEFAULT NULL,
    description VARCHAR(128) DEFAULT NULL
);

ALTER SEQUENCE load_balancer_id_seq MAXVALUE 2147483647 CYCLE;
CREATE INDEX load_balancer_dsturi_idx ON load_balancer (dst_uri);
