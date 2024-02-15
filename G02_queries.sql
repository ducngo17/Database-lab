--1. search book according to title 

select bookID
from book 
where title='120';

--2. search book according to language

SELECT bookID 
FROM book
WHERE language ='English';

--3. search book according to publisher

SELECT b.bookID  
FROM book b
JOIN publisher p ON p.publisherID=b.publisherID
WHERE p.name='Collins-O''Conner';


--4. search book according to author

SELECT b.bookID
FROM book b
JOIN write w ON w.bookID=b.bookID
JOIN author a ON a.authorID=w.authorID
WHERE a.name='Rebekah Brosius';

--5. search book according to year publish

SELECT bookID 
FROM book
WHERE year_published = 1035;


--6. search book according to category

SELECT b.bookID 
FROM book b
JOIN category c ON c.catID=b.catID
WHERE c.name ='Romance';

--7. print position of a particular book

SELECT Location  
FROM book
WHERE title ='120';

--8. search borrowers according to their names

SELECT borrowerID 
FROM borrower
WHERE name ='Adan Fricke';

--9. search borrowers according to their dobs

SELECT borrowerID  
FROM borrower
WHERE DOB ='1986-12-13';


--10. search borrower according to gender

SELECT borrowerID  
FROM borrower
WHERE gender ='F';

--11. List borrowers who have visited in a period (function).
SELECT b.borrowerID, b.name
FROM borrower b JOIN visit v USING (borrowerID)
WHERE date = '2023-01-01'
    AND time >= '09:00:00'
    AND time <= '20:00:00'; 


--12 List borrowers that make the most visits.
--solution 1: WITH
WITH tmp AS (
    SELECT borrowerID, COUNT(visitID) as visits
    FROM visit v
    GROUP BY borrowerID
)
SELECT borrowerID, visits
FROM tmp
WHERE visits = (SELECT MAX(visits) FROM tmp);

--solution 2 (subqueries)
SELECT borrowerID, COUNT(visitID) as visits
FROM visit
GROUP BY borrowerID
HAVING COUNT(visitID) = (SELECT MAX(visits) 
                        FROM (SELECT COUNT(visitID) as visits
                                FROM visit
                                GROUP BY borrowerID));

--> solution 1 is better because solution 2 seq scan visit table 2 times, while table 1 only once.



--13 List how many books a borrower borrows in a year 
SELECT COUNT(loanID)
FROM loan JOIN borrower USING (borrowerID)
WHERE name = 'Yul Bramer'
    AND EXTRACT(year from date_out) = 2023;

create index idx_borrower_name ON borrower(name);
create index idx_loan_date_out ON loan(date_out);

SELECT COUNT (loanID)
FROM (SELECT borrowerID, loanID FROM loan WHERE EXTRACT(year from date_out) = 2023) l 
    JOIN (SELECT borrowerID FROM borrower where name = 'Yul Bramer') b USING (borrowerID);


--14 Search employees by name.
SELECT * FROM employee
WHERE name = 'Xylia Aberkirdo';



--15 Search employees by role.
SELECT * FROM employee
WHERE role = 'Manager';
SELECT * FROM employee
WHERE role = 'Employee';



--16 List all the books in the library.
SELECT * FROM book;



--17 Count the number of copies of a book (function).
CREATE OR REPLACE FUNCTION count_bookcopies (IN bookID_ INT) RETURNS INT 
AS
$$
DECLARE res INT;
BEGIN
    SELECT INTO RES COUNT(*)
    FROM book_copy
    WHERE book_copy.bookID = bookID_;
    RETURN res;
END;
$$
LANGUAGE plpgsql;

ALTER TABLE book 
ADD COLUMN total_copies INT;

CREATE OR REPLACE FUNCTION update_total_bookcopies() RETURNS void
AS
$$
BEGIN  
    UPDATE book
    SET total_copies = count_bookcopies(bookID);
END;
$$
LANGUAGE plpgsql;

SELECT update_total_bookcopies();
SELECT * FROM book;



--18 trigger: mỗi lần thêm, xóa 1 book copy thì sẽ update cột no_of_bookcopies
CREATE OR REPLACE FUNCTION add_update_book_copies() RETURNS TRIGGER
AS
$$
BEGIN 
    UPDATE book
    SET total_copies = total_copies + 1
    WHERE bookID = NEW.bookID;
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER add_book_copies
AFTER INSERT ON book_copy
FOR EACH ROW
EXECUTE PROCEDURE add_update_book_copies();
    
INSERT INTO book_copy (copyID, bookID, price, location, status) VALUES ('00000051', '00000001', 20, 'Shelf A1', 'available');
SELECT * FROM book;


CREATE OR REPLACE FUNCTION remove_update_book_copies() RETURNS TRIGGER
AS
$$
BEGIN 
    UPDATE book
    SET total_copies = total_copies - 1
    WHERE bookID = OLD.bookID;
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;
    
CREATE OR REPLACE TRIGGER remove_book_copies
AFTER DELETE ON book_copy
FOR EACH ROW
EXECUTE PROCEDURE remove_update_book_copies();

DELETE FROM book_copy WHERE copyID = '00000051';
SELECT * FROM book;



--19 Count number of copies loaned in a period.
CREATE OR REPLACE FUNCTION count_bookcopy_borrowed (IN from_date date, IN to_date date) RETURNS integer
AS
$$
DECLARE res INT;
BEGIN
    SELECT INTO res COUNT(*)
    FROM loan
    WHERE date_out >= from_date
        AND date_out <= to_date
        AND (return_date <= to_date OR return_date = NULL);
    RETURN res;
END;
$$
LANGUAGE plpgsql;

SELECT count_bookcopy_borrowed('2023-03-01', '2023-04-12');



--20 List the most borrowed categories in 2023.
WITH cat_detail AS (
    SELECT b.catID, count(b.catID) AS num_cat
    FROM book b, book_copy bc, loan l
    WHERE b.bookID = bc.bookID   
        AND bc.book_copyID = l.book_copyID
        AND extract(year from l.date_out) = 2023
    GROUP BY b.catID   
)
SELECT catID, num_cat
FROM cat_detail
WHERE num_cat = (SELECT MAX(num_cat) FROM cat_detail);

SELECT 

--21. list number of borrower by gender 

SELECT gender, count(*) FROM borrower GROUP BY gender;

--22. list number of people that have borrowed book by age group: < 18, 18 – 25, 25 – 40, 40 – 55, > 55

SELECT 
  CASE 
    WHEN DATE_PART('year', CURRENT_DATE) - DATE_PART('year', dob) < 18 THEN 'Under 18'
    WHEN DATE_PART('year', CURRENT_DATE) - DATE_PART('year', dob) BETWEEN 18 AND 25 THEN '18-25'
    WHEN DATE_PART('year', CURRENT_DATE) - DATE_PART('year', dob) BETWEEN 25 AND 40 THEN '25-40'
    WHEN DATE_PART('year', CURRENT_DATE) - DATE_PART('year', dob) BETWEEN 40 AND 55 THEN '40-55'
    ELSE '55 and over'
  END AS AgeGroup, -- find age group of people that have borrowed book
  COUNT(loanID) AS NumberOfLoans -- count number of people in each age group
FROM loan JOIN borrower using(borrowerID)
GROUP BY 
  CASE 
    WHEN DATE_PART('year', CURRENT_DATE) - DATE_PART('year', dob) < 18 THEN 'Under 18'
    WHEN DATE_PART('year', CURRENT_DATE) - DATE_PART('year', dob) BETWEEN 18 AND 25 THEN '18-25'
    WHEN DATE_PART('year', CURRENT_DATE) - DATE_PART('year', dob) BETWEEN 25 AND 40 THEN '25-40'
    WHEN DATE_PART('year', CURRENT_DATE) - DATE_PART('year', dob) BETWEEN 40 AND 55 THEN '40-55'
    ELSE '55 and over'
  END;

--23. return how many times a book is loan in a given year

CREATE OR REPLACE FUNCTION loans_a_year(IN year integer) RETURNS TABLE (id integer, count bigint) AS
$$
BEGIN 
    RETURN QUERY SELECT bookID, COUNT(*) as loan_count
    FROM loan JOIN book_copy using(book_copyID) 
    WHERE EXTRACT(YEAR FROM date_out) = year
    GROUP BY bookID;
END;
$$ LANGUAGE plpgsql;

--24. count number of book retruned damanged

SELECT count(*) FROM compensate WHERE paid = false;

--25. find the employee verify a given loan

CREATE OR REPLACE FUNCTION employee_verify_loan(IN id integer) RETURNS integer AS
$$ DECLARE rsl integer;
BEGIN 
    SELECT into rsl employeeID 
    FROM loan 
    WHERE loanID = id;
    return rsl;
END;
$$ LANGUAGE plpgsql;

--26. list all over due book (current_date > date_out + 90 AND return_date = NULL) 

SELECT DISTINCT borrowerID, name
FROM loan JOIN borrower using(borrowerID) 
WHERE CURRENT_DATE > date_out + 90 AND return_date IS NULL;

--27. trigger to update table book, book_copy, borrower when new loan record is inserted in loan table

CREATE OR REPLACE FUNCTION loan_book() RETURNS TRIGGER AS 
$$ 
BEGIN
    -- check if borrower is allowed to borrow more book
    IF EXISTS(SELECT 1 FROM borrower WHERE borrowerID = NEW.borrowerID AND no_book_allowed <= 0) THEN
        RAISE NOTICE 'you already have borrowed 5 books';
        RETURN NULL; -- not insert in loan if borrower is not allowed to borrow more book 
    END IF;
    IF EXISTS(SELECT 1 FROM book_copy WHERE book_copyID = NEW.book_copyID AND status != 'available') THEN
        RAISE NOTICE 'invalid book copy id';
        RETURN NULL; -- not insert  
    END IF;
    UPDATE book_copy SET status = 'unavailable' WHERE book_copyID = NEW.book_copyID; -- update status of the borrowed book_copy to 'unavailable'
    UPDATE book SET no_copy = no_copy - 1 
    WHERE bookID IN (SELECT bookID FROM book_copy WHERE book_copyID = NEW.book_copyID); -- decrease the number of copy of borrowed book by 1
    UPDATE borrower SET no_book_allowed = no_book_allowed - 1 WHERE borrowerID = NEW.borrowerID; -- decrease number of book allowed to loan of the borrower by 1
    RAISE NOTICE 'loan successful';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER loan_book
BEFORE INSERT ON loan
FOR EACH ROW
EXECUTE FUNCTION loan_book();

--28. trigger to update table book, book_copy, borrower when a book is returned

CREATE OR REPLACE FUNCTION return_book() RETURNS TRIGGER AS 
$$ 
BEGIN

    IF NEW.damaged = true THEN -- check if the book is damaged
        RAISE NOTICE 'book is returned damaged, borrower need to compensate';
        RETURN NEW;
    END IF;

    IF EXISTS(SELECT 1 FROM book_copy WHERE book_copyID = NEW.book_copyID AND status = 'removed') THEN -- check if the book is removed
        UPDATE borrower SET no_book_allowed = no_book_allowed + 1 WHERE borrowerID = NEW.borrowerID; -- no_book_allowed of the borrower += 1
        RAISE NOTICE 'book is sucessfully returned';
        RETURN NEW;
    END IF;

    UPDATE book_copy SET status = 'available' WHERE book_copyID = NEW.book_copyID; -- change book copy status to 'available'
    UPDATE book SET no_copy = no_copy + 1 
    WHERE bookID IN (SELECT bookID FROM book_copy WHERE book_copyID = NEW.book_copyID); -- increase number of copy of the returned book by 1
    UPDATE borrower SET no_book_allowed = no_book_allowed + 1 WHERE borrowerID = NEW.borrowerID; -- increase number of book allowed to loan of the borrower by 1
    RAISE NOTICE 'book is sucessfully returned';
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER return_book
AFTER UPDATE ON loan
FOR EACH ROW
EXECUTE FUNCTION return_book();

--29. trigger to insert into table compensate when the returned book is damaged  

CREATE OR REPLACE FUNCTION insert_into_compensate() RETURNS TRIGGER AS 
$$ DECLARE p integer;
BEGIN
    SELECT INTO p price
    FROM book_copy 
    WHERE book_copyID = NEW.book_copyID; -- find the price of the book copy
    IF NEW.damaged = true THEN 
        INSERT INTO compensate (amount, date, paid, book_copyID, borrowerID) 
        VALUES (p + 10, CURRENT_DATE, false, NEW.book_copyID, NEW.borrowerID); -- insert compensation information into table compensation
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER loan_damaged
AFTER UPDATE ON loan
FOR EACH ROW
EXECUTE FUNCTION insert_into_compensate();

--30. trigger to notify borrower when the books they have been waiting are available

CREATE OR REPLACE FUNCTION insert_into_notification() RETURNS TRIGGER AS 
$$ DECLARE id integer;
BEGIN
    IF NEW.no_copy > 0 THEN 
        FOR id IN SELECT borrowerID FROM wait WHERE bookID = NEW.bookID AND notified = false -- find all borrowers that are waiting for this book
        LOOP
            INSERT INTO notification (borrowerID, message, send_at)
            VALUES (id, 'your book is available', CURRENT_TIMESTAMP); -- send notification
            UPDATE wait SET notified = true WHERE bookID = NEW.bookID;
        END LOOP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER book_available
AFTER UPDATE ON book
FOR EACH ROW
EXECUTE FUNCTION insert_into_notification();