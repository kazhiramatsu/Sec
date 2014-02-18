drop table if exists sessions;
create table sessions (
    session_id VARCHAR(70) BINARY NOT NULL COMMENT 'session_id',
    session_data TEXT BINARY NOT NULL COMMENT 'session_data',
    session_expire DATETIME NOT NULL COMMENT 'session_expire',
    created_on DATETIME  NOT NULL COMMENT '',
    updated_on TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT ''
    ,PRIMARY KEY (session_id)
);
