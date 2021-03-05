CREATE TABLE users (
  id serial PRIMARY KEY,
  username text NOT NULL UNIQUE,
  bio text,
  password text NOT NULL
);

CREATE TABLE posts (
  id serial PRIMARY KEY,
  content text,
  user_id int NOT NULL REFERENCES users (id)
);

CREATE TABLE comments (
  id serial PRIMARY KEY,
  content text,
  post_id int NOT NULL REFERENCES posts (id)
);

INSERT INTO users VALUES
(DEFAULT, 'carl', 'password'),
(DEFAULT, 'graham', '123456');