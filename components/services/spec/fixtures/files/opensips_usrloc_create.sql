-- From: https://github.com/OpenSIPS/opensips/blob/master/scripts/postgres/usrloc-create.sql

CREATE TABLE location (
    contact_id BIGSERIAL PRIMARY KEY NOT NULL,
    username VARCHAR(64) DEFAULT '' NOT NULL,
    domain VARCHAR(64) DEFAULT NULL,
    contact TEXT NOT NULL,
    received VARCHAR(255) DEFAULT NULL,
    path VARCHAR(255) DEFAULT NULL,
    expires INTEGER NOT NULL,
    q REAL DEFAULT 1.0 NOT NULL,
    callid VARCHAR(255) DEFAULT 'Default-Call-ID' NOT NULL,
    cseq INTEGER DEFAULT 13 NOT NULL,
    last_modified TIMESTAMP WITHOUT TIME ZONE DEFAULT '1900-01-01 00:00:01' NOT NULL,
    flags INTEGER DEFAULT 0 NOT NULL,
    cflags VARCHAR(255) DEFAULT NULL,
    user_agent VARCHAR(255) DEFAULT '' NOT NULL,
    socket VARCHAR(64) DEFAULT NULL,
    methods INTEGER DEFAULT NULL,
    sip_instance VARCHAR(255) DEFAULT NULL,
    kv_store TEXT DEFAULT NULL,
    attr VARCHAR(255) DEFAULT NULL
);

ALTER SEQUENCE location_contact_id_seq MAXVALUE 2147483647 CYCLE;
