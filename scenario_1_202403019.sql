-- ============================================
-- SCENARIO 1: UNIVERSITY LIBRARY BOOK LOANS
-- ============================================

-- Remove old tables if they already exist
DROP TABLE IF EXISTS book_loans;
DROP TABLE IF EXISTS books;

-- Create books table
CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    available_copies INT NOT NULL
);

-- Create book_loans table
CREATE TABLE book_loans (
    loan_id SERIAL PRIMARY KEY,
    book_id INT REFERENCES books(book_id),
    student_number VARCHAR(20) NOT NULL,
    quantity INT NOT NULL,
    loan_status VARCHAR(20) NOT NULL
);

-- Add at least three books
INSERT INTO books (title, available_copies)
VALUES
('Database Systems', 10),
('Computer Networks', 5),
('Operating Systems', 2);

-- Check the tables
SELECT * FROM books;

SELECT * FROM book_loans;

DO $$
DECLARE
    book_record RECORD;
BEGIN

    FOR book_record IN
        SELECT * FROM books
    LOOP

        IF book_record.available_copies = 0 THEN

            RAISE NOTICE '% is unavailable.',
                book_record.title;

        ELSIF book_record.available_copies <= 2 THEN

            RAISE NOTICE '% is low on copies. Only % remaining.',
                book_record.title,
                book_record.available_copies;

        ELSE

            RAISE NOTICE '% is sufficiently stocked. % copies available.',
                book_record.title,
                book_record.available_copies;

        END IF;

    END LOOP;

END $$;

DO $$
DECLARE
    reminder_number INT := 1;
BEGIN

    -- WHILE loop
    WHILE reminder_number <= 3
    LOOP

        RAISE NOTICE 'Overdue reminder number: %',
            reminder_number;

        reminder_number := reminder_number + 1;

    END LOOP;


    -- Numeric FOR loop
    FOR shelf_number IN 1..3
    LOOP

        RAISE NOTICE 'Library shelf number: %',
            shelf_number;

    END LOOP;

END $$;

CREATE OR REPLACE PROCEDURE borrow_book(
    p_book_id INT,
    p_student_number VARCHAR(20),
    p_quantity INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_available INT;
BEGIN

    -- Get current available copies
    SELECT available_copies
    INTO v_available
    FROM books
    WHERE book_id = p_book_id;

    -- Check if the book exists
    IF v_available IS NULL THEN

        RAISE NOTICE 'Book does not exist.';

    -- Check whether enough copies are available
    ELSIF p_quantity > v_available THEN

        RAISE NOTICE 'Not enough copies available.';

    ELSE

        -- Reduce available copies
        UPDATE books
        SET available_copies = available_copies - p_quantity
        WHERE book_id = p_book_id;

        -- Record the loan
        INSERT INTO book_loans (
            book_id,
            student_number,
            quantity,
            loan_status
        )
        VALUES (
            p_book_id,
            p_student_number,
            p_quantity,
            'BORROWED'
        );

        RAISE NOTICE 'Book borrowed successfully.';

    END IF;

END;
$$;

-- Valid loan 1
CALL borrow_book(1, '2026001', 2);

-- Valid loan 2
CALL borrow_book(2, '2026002', 3);

-- Invalid loan: requests more than available
CALL borrow_book(3, '2026003', 5);

SELECT * FROM books;

SELECT * FROM book_loans;

CREATE OR REPLACE PROCEDURE return_book(
    p_loan_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_book_id INT;
    v_quantity INT;
    v_status VARCHAR(20);
BEGIN

    -- Get loan information
    SELECT book_id, quantity, loan_status
    INTO v_book_id, v_quantity, v_status
    FROM book_loans
    WHERE loan_id = p_loan_id;

    -- Check if loan exists
    IF v_book_id IS NULL THEN

        RAISE NOTICE 'Loan does not exist.';

    -- Check if already returned
    ELSIF v_status = 'RETURNED' THEN

        RAISE NOTICE 'This loan has already been returned.';

    ELSE

        -- Restore available copies
        UPDATE books
        SET available_copies = available_copies + v_quantity
        WHERE book_id = v_book_id;

        -- Mark loan as returned
        UPDATE book_loans
        SET loan_status = 'RETURNED'
        WHERE loan_id = p_loan_id;

        RAISE NOTICE 'Book returned successfully.';

    END IF;

END;
$$;

-- First return
CALL return_book(1);

-- Second return of the SAME loan
CALL return_book(1);

-- Check results
SELECT * FROM books;

SELECT * FROM book_loans;

DO $$
DECLARE
    book_record RECORD;

    book_cursor CURSOR FOR
        SELECT book_id, title, available_copies
        FROM books
        WHERE available_copies <= 2;

BEGIN

    OPEN book_cursor;

    LOOP

        FETCH book_cursor INTO book_record;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE
            'Low stock book: % | Copies remaining: %',
            book_record.title,
            book_record.available_copies;

    END LOOP;

    CLOSE book_cursor;

END $$;

DO $$
BEGIN

    IF 0 <= 0 THEN
        RAISE EXCEPTION 'Invalid quantity: quantity must be greater than zero.';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error handled: %', SQLERRM;
END $$;

-- Final books
SELECT
    book_id,
    title,
    available_copies
FROM books
ORDER BY book_id;

-- Final loans
SELECT
    loan_id,
    book_id,
    student_number,
    quantity,
    loan_status
FROM book_loans
ORDER BY loan_id;