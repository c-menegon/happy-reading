-- Insert data into the authors table
INSERT INTO authors (name, birth_date, nationality)
VALUES ('Sarah J. Maas', '1986-03-05', 'USA');

-- Insert data into the books table
INSERT INTO books (title, book_description, pages, publication_date, publisher)
VALUES ('A Court of Thorns and Roses',
'When nineteen-year-old huntress Feyre kills a wolf in the woods, a terrifying creature arrives to demand retribution. Dragged to a treacherous magical land she knows about only from legends, Feyre discovers that her captor is not truly a beast, but one of the lethal, immortal faeries who once ruled her world.',
'419', '2015-05-05', 'Bloomsbury USA Childrens');

-- Insert data into the joined table with books and authors
INSERT INTO book_authors (author_id, book_id)
SELECT
    (SELECT id FROM authors WHERE name = 'Sarah J. Maas'),
    (SELECT id FROM books WHERE title = 'A Court of Thorns and Roses');

-- Insert data into the ratings table
INSERT INTO ratings (book_id, rating)
VALUES ((SELECT id FROM books WHERE title = 'A Court of Thorns and Roses'), 5.0);

-- Insert data into the users table
INSERT INTO users (name, birth_date, nationality, gender, username)
VALUES ('Jane Doe', '1995-03-05', 'USA', 'female', 'jane_doe');

-- Insert data into the library table (and include it in the reading_status table using a trigger)
INSERT INTO library (user_id, book_id)
SELECT
	(SELECT id FROM users WHERE username = 'jane_doe'),
    (SELECT id FROM books WHERE title = 'A Court of Thorns and Roses');

-- Update a book as finished in the library table (and including in the reading_status using the trigger)
UPDATE library
SET finished = 1
WHERE user_id = (SELECT id FROM users WHERE username = 'jane_doe')
AND book_id = (SELECT id FROM books WHERE title = 'A Court of Thorns and Roses');

-- Deleted added books from the library table (and including in the reading_status using the trigger)
DELETE FROM library
WHERE user_id =
    (SELECT id FROM users WHERE username = 'jane_doe')
AND book_id =
    (SELECT id FROM books WHERE title = 'A Court of Silver Flames');

-- Visualize all the authors and their respective books (with names and titles)
SELECT authors.name, books.title FROM book_authors
JOIN authors
ON book_authors.author_id = authors.id
JOIN books
ON book_authors.book_id = books.id;

-- See all the books written by a specific author
SELECT books.title FROM books
JOIN book_authors
ON books.id = book_authors.book_id
JOIN authors
ON book_authors.author_id = authors.id
WHERE authors.name = 'Sarah J. Maas';

-- See all the authors with a specific nationality
SELECT * FROM authors
WHERE nationality = 'USA';

-- See all the books published after 2020
SELECT title FROM books
WHERE publication_date >= '2020-01-01';

-- See all the books published between 2015 and 2020
SELECT * FROM books
WHERE publication_date BETWEEN '2015-01-01' AND '2020-12-31';

-- Query number of female users
SELECT COUNT(*) FROM users
WHERE gender = 'female';

-- See all the books read by a specific user using a view
SELECT * FROM finished_books
WHERE username = 'jane_doe';

-- Count all books read by a specific user using a view
SELECT COUNT(*) FROM finished_books
WHERE username = 'jane_doe';

-- Count how many books are in the library of a specific user
SELECT COUNT(*) FROM library
WHERE user_id = (
    SELECT id FROM users WHERE username = 'jane_doe'
);

-- Count how many books are not read in the library of a specific user
SELECT COUNT(*) FROM library
WHERE user_id = (SELECT id FROM users WHERE username = 'jane_doe')
AND finished = 0;

-- Find out users who have finished the most books
SELECT username, COUNT(*) FROM finished_books
GROUP BY username
ORDER BY COUNT(*) DESC;

-- Select all the users that finished a specific book
SELECT username FROM finished_books
WHERE book_title = 'A Court of Thorns and Roses';

-- List all the users that have read books by a specific author
SELECT DISTINCT username FROM finished_books
WHERE author_name = 'Sarah J. Maas';

-- List users who haven't finished a book yet
SELECT username
FROM users
WHERE id NOT IN (
    SELECT DISTINCT user_id FROM library WHERE finished = 1
);

-- List the total number of books read users from specific nationalities
SELECT users.nationality, COUNT(*) AS books_read
FROM library
JOIN users ON library.user_id = users.id
WHERE library.finished = 1
GROUP BY users.nationality;

-- Find books with a specific range of pages
SELECT * FROM books
WHERE pages BETWEEN 300 AND 500;

-- Filter books by publisher
SELECT title FROM books
WHERE publisher = 'Bloomsbury USA Childrens';

-- Find the oldest books in the database
SELECT * FROM BOOKS
ORDER BY publication_date
LIMIT 1;

-- List of authors who have the most books in the database
SELECT authors.name, COUNT(book_authors.book_id) AS book_count FROM book_authors
JOIN authors
ON book_authors.author_id = authors.id
GROUP BY authors.name
ORDER BY book_count DESC, authors.name;

-- See the book with the highest rating
SELECT book_title, author_name, MAX(average_rating) FROM average_book_ratings;

-- See the book with the lowest rating
SELECT book_title, author_name, MIN(average_rating) FROM average_book_ratings;

-- Visualize the average rating for each book (rounded to two decimal places), sorted from highest to lowest
SELECT books.title, ROUND(AVG(rating), 2) AS average_rating FROM ratings
JOIN books
ON ratings.book_id = books.id
GROUP BY books.id, books.title
ORDER BY average_rating DESC;

-- Visualize the average rating for each book using the created view
SELECT * FROM average_book_ratings
ORDER BY average_rating DESC;

-- Find out the average rating of books by a specific author
SELECT book_title, ROUND(AVG(average_rating ), 2) AS overall_average_rating
FROM average_book_ratings
WHERE author_name = 'Sarah J. Mass'
GROUP BY author_name;

-- List of books that have a rating higher than the average rating
SELECT * FROM average_book_ratings
WHERE average_rating >= (
    SELECT AVG(average_rating) FROM average_book_ratings
);

-- See how many ratings a book received
SELECT COUNT(*) FROM ratings
JOIN books
ON ratings.book_id = books.id
WHERE books.title = 'A Court of Thorns and Roses';

-- See the books and the ratings given by a specific user
SELECT books.title, ratings.rating FROM ratings
JOIN books
ON ratings.book_id = books.id
JOIN users
ON ratings.user_id = users.id
WHERE users.username = 'jane_doe';

-- Most recent book published by a specific author
SELECT books.title, books.publication_date FROM books
JOIN book_authors
ON books.id = book_authors.book_id
JOIN authors
ON book_authors.author_id = authors.id
WHERE authors.name = 'Sarah J. Maas'
ORDER BY books.publication_date DESC
LIMIT 1;

-- See the book with the highest number of pages
SELECT title, MAX(pages) AS number_of_pages FROM books;

-- See the book with the lowest number of pages
SELECT title, MIN(pages) AS number_of_pages FROM books;

-- Count all the pages written by specific authors
SELECT authors.name, SUM(pages) AS pages_written FROM authors
JOIN book_authors
ON authors.id = book_authors.author_id
JOIN books
ON book_authors.book_id = books.id
GROUP BY authors.name
ORDER BY pages_written DESC;

-- See users that already finished more than two books
SELECT username, COUNT(book_title) AS finished_books
FROM finished_books
GROUP BY username
HAVING COUNT(book_title) >= 2
ORDER BY finished_books DESC;
