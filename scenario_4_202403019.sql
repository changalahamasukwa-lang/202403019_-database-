-- ============================================
-- SCENARIO 4: CAMPUS CLINIC MEDICINE DISPENSING
-- ============================================

DROP TABLE IF EXISTS dispensing_records;
DROP TABLE IF EXISTS medicines;

-- Create medicines table
CREATE TABLE medicines (
    medicine_id SERIAL PRIMARY KEY,
    medicine_name VARCHAR(100) NOT NULL,
    stock_quantity INT NOT NULL
);

-- Create dispensing_records table
CREATE TABLE dispensing_records (
    dispensing_id SERIAL PRIMARY KEY,
    medicine_id INT REFERENCES medicines(medicine_id),
    student_number VARCHAR(20) NOT NULL,
    quantity INT NOT NULL,
    dispensing_status VARCHAR(20) NOT NULL
); 

INSERT INTO medicines (medicine_name, stock_quantity)
VALUES
('Paracetamol', 50),
('Amoxicillin', 20),
('Ibuprofen', 5);

SELECT * FROM medicines;

DO $$
DECLARE
    medicine_record RECORD;
BEGIN

    FOR medicine_record IN
        SELECT *
        FROM medicines
    LOOP

        IF medicine_record.stock_quantity = 0 THEN

            RAISE NOTICE
                '% is OUT OF STOCK.',
                medicine_record.medicine_name;

        ELSIF medicine_record.stock_quantity <= 5 THEN

            RAISE NOTICE
                '% is LOW ON STOCK. Only % remaining.',
                medicine_record.medicine_name,
                medicine_record.stock_quantity;

        ELSE

            RAISE NOTICE
                '% is SUFFICIENTLY STOCKED. % available.',
                medicine_record.medicine_name,
                medicine_record.stock_quantity;

        END IF;

    END LOOP;

END $$;

DO $$
DECLARE
    review_day INT := 1;
BEGIN

    -- WHILE loop
    WHILE review_day <= 3
    LOOP

        RAISE NOTICE
            'Stock review day: %',
            review_day;

        review_day := review_day + 1;

    END LOOP;


    -- Numeric FOR loop
    FOR shelf_inspection IN 1..3
    LOOP

        RAISE NOTICE
            'Shelf inspection number: %',
            shelf_inspection;

    END LOOP;

END $$;

CREATE OR REPLACE PROCEDURE dispense_medicine(
    p_medicine_id INT,
    p_student_number VARCHAR(20),
    p_quantity INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_stock INT;
BEGIN

    -- Get current stock
    SELECT stock_quantity
    INTO v_stock
    FROM medicines
    WHERE medicine_id = p_medicine_id;

    -- Check whether medicine exists
    IF v_stock IS NULL THEN

        RAISE NOTICE
            'Medicine does not exist.';

    -- Check whether enough stock exists
    ELSIF p_quantity > v_stock THEN

        RAISE NOTICE
            'Not enough medicine in stock.';

    ELSE

        -- Reduce stock
        UPDATE medicines
        SET stock_quantity =
            stock_quantity - p_quantity
        WHERE medicine_id = p_medicine_id;

        -- Record dispensing
        INSERT INTO dispensing_records (
            medicine_id,
            student_number,
            quantity,
            dispensing_status
        )
        VALUES (
            p_medicine_id,
            p_student_number,
            p_quantity,
            'DISPENSED'
        );

        RAISE NOTICE
            'Medicine dispensed successfully.';

    END IF;

END;
$$;

CALL dispense_medicine(
    1,
    '202407027',
    10
);

CALL dispense_medicine(
    2,
    '2026033',
    5
);

CALL dispense_medicine(
    3,
    '202405943',
    10
);

SELECT * FROM medicines;

SELECT * FROM dispensing_records;

CREATE OR REPLACE PROCEDURE reverse_dispensing(
    p_dispensing_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_medicine_id INT;
    v_quantity INT;
    v_status VARCHAR(20);
BEGIN

    -- Get dispensing information
    SELECT medicine_id, quantity, dispensing_status
    INTO v_medicine_id, v_quantity, v_status
    FROM dispensing_records
    WHERE dispensing_id = p_dispensing_id;

    -- Check whether record exists
    IF v_medicine_id IS NULL THEN

        RAISE NOTICE
            'Dispensing record does not exist.';

    -- Check whether already reversed
    ELSIF v_status = 'REVERSED' THEN

        RAISE NOTICE
            'This dispensing record has already been reversed.';

    ELSE

        -- Restore medicine stock
        UPDATE medicines
        SET stock_quantity =
            stock_quantity + v_quantity
        WHERE medicine_id = v_medicine_id;

        -- Mark record as reversed
        UPDATE dispensing_records
        SET dispensing_status = 'REVERSED'
        WHERE dispensing_id = p_dispensing_id;

        RAISE NOTICE
            'Dispensing reversed successfully.';

    END IF;

END;
$$;

CALL reverse_dispensing(1);

SELECT * FROM medicines;

SELECT * FROM dispensing_records;

DO $$
DECLARE
    medicine_record RECORD;

    medicine_cursor CURSOR FOR
        SELECT
            medicine_id,
            medicine_name,
            stock_quantity
        FROM medicines
        WHERE stock_quantity <= 5;

BEGIN

    OPEN medicine_cursor;

    LOOP

        FETCH medicine_cursor INTO medicine_record;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE
            'Low-stock medicine: % | Stock remaining: %',
            medicine_record.medicine_name,
            medicine_record.stock_quantity;

    END LOOP;

    CLOSE medicine_cursor;

END $$;

DO $$
BEGIN

    IF -5 < 0 THEN

        RAISE EXCEPTION
            'Invalid quantity: dispensing quantity cannot be negative.';

    END IF;

EXCEPTION
    WHEN OTHERS THEN

        RAISE NOTICE
            'Error handled: %',
            SQLERRM;

END $$;

-- Final medicine stock
SELECT
    medicine_id,
    medicine_name,
    stock_quantity
FROM medicines
ORDER BY medicine_id;


-- Final dispensing records
SELECT
    dispensing_id,
    medicine_id,
    student_number,
    quantity,
    dispensing_status
FROM dispensing_records
ORDER BY dispensing_id;
