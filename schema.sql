-- Create database
CREATE DATABASE happy_reading;

-- Create table for authors
CREATE TABLE authors (
    id INT AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    birth_date DATE,
    nationality VARCHAR(50),
    PRIMARY KEY (id)
);

-- Create table for books
CREATE TABLE books (
    id INT AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    book_description TEXT,
    pages INT,
    publication_date DATE NOT NULL,
    publisher VARCHAR(50) NOT NULL,
    PRIMARY KEY (id)
);

-- Create table to relate books and authors
CREATE TABLE book_authors (
    id INT AUTO_INCREMENT,
    author_id INT,
    book_id INT,
    PRIMARY KEY (id),
    FOREIGN KEY (author_id) REFERENCES authors(id),
    FOREIGN KEY (book_id) REFERENCES books(id)
);

-- Create table for users
CREATE TABLE users (
    id INT AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    birth_date DATE,
    nationality VARCHAR(50),
    gender ENUM('female', 'male', 'other', 'prefer_not_to_say') NOT NULL,
    gender_custom VARCHAR(32),
    username VARCHAR(32) UNIQUE NOT NULL,
    PRIMARY KEY (id)
);

-- Create table to relate books and users
CREATE TABLE library (
    id INT AUTO_INCREMENT,
    user_id INT,
    book_id INT,
    finished BOOLEAN DEFAULT 0,
    UNIQUE (user_id, book_id),
    PRIMARY KEY (id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (book_id) REFERENCES books(id)
);

-- Create table for ratings
CREATE TABLE ratings (
    id INT AUTO_INCREMENT,
    book_id INT,
    user_id INT,
    rating DECIMAL (2,1) NOT NULL,
    CHECK (rating >= 0.0 AND rating <= 5.0),
    UNIQUE (user_id, book_id),
    PRIMARY KEY (id),
    FOREIGN KEY (book_id) REFERENCES books(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Create table for reading_status
CREATE TABLE reading_status (
    id INT AUTO_INCREMENT,
    user_id INT,
    book_id INT,
    action ENUM('added', 'finished', 'deleted'),
    timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY(id)
);


-- Create trigger to ensure gender_custom column is filled only if gender = 'other' (insert)
DELIMITER //
CREATE TRIGGER check_custom_gender_insert
BEFORE INSERT ON users
FOR EACH ROW
BEGIN
    IF NEW.gender != 'other' AND NEW.gender_custom IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Custom gender can only be set if gender is "other"';
    END IF;

    IF NEW.gender = 'other' AND (NEW.gender_custom IS NULL OR NEW.gender_custom = '') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Custom gender must be provided if gender is "other"';
    END IF;
END//
DELIMITER ;

-- Create trigger to ensure gender_custom column is filled only if gender = 'other' (update)
DELIMITER //
CREATE TRIGGER check_custom_gender_update
BEFORE UPDATE ON users
FOR EACH ROW
BEGIN
    IF NEW.gender != 'other' AND NEW.gender_custom IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Custom gender can only be set if gender is "other"';
    END IF;

    IF NEW.gender = 'other' AND (NEW.gender_custom IS NULL OR NEW.gender_custom = '') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Custom gender must be provided if gender is "other"';
    END IF;
END//

DELIMITER ;

-- Creates a trigger to log books added to the library table into the reading_status table
delimiter //
CREATE TRIGGER added_book
AFTER INSERT ON library
FOR EACH ROW
BEGIN
    INSERT INTO reading_status (user_id, book_id, action, timestamp)
    VALUES (NEW.user_id, NEW.book_id, 'added', DEFAULT);
END//
delimiter ;

-- Creates a trigger to log books marked as finished in the library table to the reading_status table
delimiter //
CREATE TRIGGER finished_book
AFTER UPDATE ON library
FOR EACH ROW
BEGIN
    IF NEW.finished = 1 AND OLD.finished = 0 THEN
        INSERT INTO reading_status (user_id, book_id, action, timestamp)
        VALUES (NEW.user_id, NEW.book_id, 'finished', DEFAULT);
    END IF;
END//
delimiter ;

-- Creates a trigger to log deleted books from the library table to the reading_status table
delimiter //
CREATE TRIGGER deleted_book
BEFORE DELETE ON library
FOR EACH ROW
BEGIN
    INSERT INTO reading_status (user_id, book_id, action, timestamp)
    VALUES (OLD.user_id, OLD.book_id, 'deleted', DEFAULT);
END//
delimiter ;

-- Create a trigger to ensure that a book can only be rated if it has been added to the user's library
DELIMITER //
CREATE TRIGGER prevent_rating_without_library
BEFORE INSERT ON ratings
FOR EACH ROW
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM library WHERE user_id = NEW.user_id AND book_id = NEW.book_id
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User must add the book to their library before rating it';
    END IF;
END//
DELIMITER ;

-- Create view for finished books
CREATE VIEW finished_books AS
SELECT users.username AS username, books.title AS book_title, authors.name AS author_name
FROM library
JOIN users
ON library.user_id = users.id
JOIN books
ON library.book_id = books.id
JOIN book_authors
ON books.id = book_authors.book_id
JOIN authors
ON book_authors.author_id = authors.id
WHERE library.finished = 1;

-- Create view for the average rating for each book (rounded to two decimal places)
CREATE VIEW average_book_ratings AS
SELECT books.title AS book_title, authors.name AS author_name, ROUND(AVG(rating), 2) AS average_rating FROM ratings
JOIN books
ON ratings.book_id = books.id
JOIN book_authors
ON books.id = book_authors.book_id
JOIN authors
ON book_authors.author_id = authors.id
GROUP BY books.id, books.title;

CREATE INDEX index_book_id
ON book_authors (book_id);

CREATE INDEX index_author_id
ON book_authors (author_id);

CREATE INDEX library_book_id
ON library(book_id);

CREATE INDEX library_user_id
ON library(user_id);

CREATE INDEX ratings_book_id
ON ratings(book_id);

CREATE INDEX ratings_user_id
ON ratings(user_id);

CREATE INDEX authors_name
ON authors (name(100));

CREATE INDEX books_title
ON books (title(100));

CREATE INDEX users_username
ON users (username);
