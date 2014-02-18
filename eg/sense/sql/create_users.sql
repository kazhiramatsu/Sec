drop table if exists users;
create table users (
    user_id VARCHAR(50) BINARY NOT NULL COMMENT 'user_id',
    username VARCHAR(50) BINARY NOT NULL COMMENT 'username',
    password VARCHAR(100) BINARY NOT NULL COMMENT 'password',
    email VARCHAR(255) BINARY NOT NULL COMMENT 'email',
    created_on DATETIME  NOT NULL COMMENT '',
    updated_on TIMESTAMP  NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT ''
    ,PRIMARY KEY (user_id)
);
