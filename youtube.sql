CREATE DATABASE youtube;
USE youtube;

CREATE TABLE user(
id INT AUTO_INCREMENT PRIMARY KEY,
email VARCHAR(100) NOT NULL,
user_password VARCHAR(30) NOT NULL,
username VARCHAR(50) NOT NULL,
birthdate DATE NOT NULL,
gender VARCHAR(1) NOT NULL CHECK (gender IN ('M', 'F')),
country VARCHAR(100) NOT NULL UNIQUE,
postal_code VARCHAR(20) NOT NULL
);

CREATE TABLE playlist(
id INT AUTO_INCREMENT PRIMARY KEY,
user_id INT NOT NULL,
name VARCHAR(100) NOT NULL,
created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
status ENUM('PUBLIC', 'PRIVATE') NOT NULL DEFAULT 'PUBLIC',
FOREIGN KEY (user_id) REFERENCES user(id)
);


CREATE TABLE video(
id INT AUTO_INCREMENT PRIMARY KEY,
user_id INT NOT NULL,
playlist_id INT,
publishing_date DATE NOT NULL,
title VARCHAR(200) NOT NULL,
video_description TEXT NOT NULL,
video_size DECIMAL(6,2) NOT NULL,
filename VARCHAR(100) NOT NULL,
video_duration TIME,
thumbnail_url TEXT,
playback_count BIGINT DEFAULT 0,
likes INT DEFAULT 0,
dislikes INT DEFAULT 0,
status ENUM('PUBLIC', 'HIDDEN', 'PRIVATE') NOT NULL DEFAULT 'PUBLIC',
FOREIGN KEY(user_id) REFERENCES user(id) ON DELETE CASCADE,
FOREIGN KEY(playlist_id) REFERENCES playlist(id)
);

CREATE TABLE tag(
id INT AUTO_INCREMENT PRIMARY KEY,
video_id INT NOT NULL,
name VARCHAR(100) NOT NULL UNIQUE,
FOREIGN KEY (video_id) REFERENCES video(id)
);

CREATE TABLE channel(
id INT AUTO_INCREMENT PRIMARY KEY,
user_id INT NOT NULL UNIQUE,
name VARCHAR(100) NOT NULL,
channel_description TEXT,
creation_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE
);

CREATE TABLE channel_subscription(
channel_id INT NOT NULL,
user_id INT NOT NULL,
subscribed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
PRIMARY KEY (channel_id, user_id),
FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE,
FOREIGN KEY (channel_id) REFERENCES channel(id) ON DELETE CASCADE
);

CREATE TABLE video_reaction(
video_id INT NOT NULL,
user_id INT NOT NULL,
reaction ENUM('LIKE', 'DISLIKE') NOT NULL,
reacted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
PRIMARY KEY (video_id, user_id),
FOREIGN KEY (user_id) REFERENCES user(id) ON DELETE CASCADE,
FOREIGN KEY (video_id) REFERENCES video(id) ON DELETE CASCADE
);

CREATE TABLE comment(
id INT AUTO_INCREMENT PRIMARY KEY,
video_id INT NOT NULL,
user_id INT NOT NULL,
comment_body TEXT NOT NULL,
created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
FOREIGN KEY (user_id) REFERENCES user(id),
FOREIGN KEY (video_id) REFERENCES video(id)
);

CREATE TABLE comment_reaction (
comment_id INT NOT NULL,
user_id INT NOT NULL,
reaction ENUM('LIKE', 'DISLIKE') NOT NULL,
reacted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
PRIMARY KEY(comment_id, user_id),
FOREIGN KEY (user_id) REFERENCES user(id),
FOREIGN KEY (comment_id) REFERENCES comment(id)
);

DELIMITER $$

CREATE TRIGGER trg_video_reaction_ai
AFTER INSERT ON video_reaction
FOR EACH ROW
BEGIN
  IF NEW.reaction = 'LIKE' THEN
    UPDATE video SET likes = likes + 1 WHERE id = NEW.video_id;
  ELSE
    UPDATE video SET dislikes = dislikes + 1 WHERE id = NEW.video_id;
  END IF;
END$$


CREATE TRIGGER trg_video_reaction_au
AFTER UPDATE ON video_reaction
FOR EACH ROW
BEGIN
  IF OLD.reaction <> NEW.reaction THEN
    IF NEW.reaction = 'LIKE' THEN
      UPDATE video SET likes = likes + 1, dislikes = GREATEST(dislikes - 1, 0) WHERE id = NEW.video_id;
    ELSE
      UPDATE video SET dislikes = dislikes + 1, likes = GREATEST(likes - 1, 0) WHERE id = NEW.video_id;
    END IF;
  END IF;
END$$

CREATE TRIGGER trg_video_reaction_ad
AFTER DELETE ON video_reaction
FOR EACH ROW
BEGIN
  IF OLD.reaction = 'LIKE' THEN
    UPDATE video SET likes = GREATEST(likes - 1, 0) WHERE id = OLD.video_id;
  ELSE
    UPDATE video SET dislikes = GREATEST(dislikes - 1, 0) WHERE id = OLD.video_id;
  END IF;
END$$

DELIMITER ;



