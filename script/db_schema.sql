SET FOREIGN_KEY_CHECKS=0;

DROP TABLE IF EXISTS Knowhow;
CREATE TABLE Knowhow 
(
    record_id INT AUTO_INCREMENT, 
    user_id VARCHAR(20),
    know VARCHAR(80),
    how VARCHAR(80),
    example VARCHAR(500),
    created_at DATETIME,
    PRIMARY KEY (record_id),
    FULLTEXT INDEX (know),
    FULLTEXT INDEX (how),
    FULLTEXT INDEX (example)
) ENGINE = mroonga COMMENT = 'engine "innodb"' DEFAULT CHARSET utf8;

DROP TABLE IF EXISTS User;
CREATE TABLE User 
(
    user_id VARCHAR(20),
    screen_name VARCHAR(24),
    oauth_token VARCHAR(64),
    oauth_token_secret VARCHAR(64),
    PRIMARY KEY(user_id)
);

DROP TABLE IF EXISTS Tag;
CREATE TABLE Tag 
(
    tag_id INT AUTO_INCREMENT, 
    tag_name VARCHAR(20),
    PRIMARY KEY (tag_id)
);

DROP TABLE IF EXISTS MyKnowhow;
CREATE TABLE MyKnowhow 
(
    record_id INT AUTO_INCREMENT, 
    user_id VARCHAR(20),
    knowhow_record_id INT,
    INDEX (user_id),
    PRIMARY KEY (record_id),
    FOREIGN KEY (knowhow_record_id) REFERENCES Knowhow(record_id)
      ON DELETE CASCADE
) ENGINE=INNODB;

DROP TABLE IF EXISTS TagLink;
CREATE TABLE TagLink 
(
    record_id INT AUTO_INCREMENT,
    knowhow_record_id INT,
    tag_id INT,
    PRIMARY KEY (record_id),
    FOREIGN KEY (knowhow_record_id) REFERENCES Knowhow(record_id)
      ON DELETE CASCADE
) ENGINE=INNODB;

SET FOREIGN_KEY_CHECKS=1;
