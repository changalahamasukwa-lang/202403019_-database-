-- ============================================
-- SCENARIO 2: COMPUTER LABORATORY RESERVATIONS
-- ============================================

DROP TABLE IF EXISTS reservations;
DROP TABLE IF EXISTS lab_sessions;

-- Create lab_sessions table
CREATE TABLE lab_sessions (
    session_id SERIAL PRIMARY KEY,
    session_name VARCHAR(100) NOT NULL,
    available_workstations INT NOT NULL
);

-- Create reservations table
CREATE TABLE reservations (
    reservation_id SERIAL PRIMARY KEY,
    session_id INT REFERENCES lab_sessions(session_id),
    lecturer VARCHAR(100) NOT NULL,
    workstations INT NOT NULL,
    reservation_status VARCHAR(20) NOT NULL
);

-- Add at least three sessions
INSERT INTO lab_sessions (session_name, available_workstations)
VALUES
('Database Practical', 30),
('Networking Practical', 15),
('Programming Practical', 5);

-- Check the tables
SELECT * FROM lab_sessions;

SELECT * FROM reservations;

DO $$
DECLARE
    session_record RECORD;
BEGIN

    FOR session_record IN
        SELECT * FROM lab_sessions
    LOOP

        IF session_record.available_workstations = 0 THEN

            RAISE NOTICE
                '% is FULL.',
                session_record.session_name;

        ELSIF session_record.available_workstations <= 3 THEN

            RAISE NOTICE
                '% is nearly full. Only % workstations remaining.',
                session_record.session_name,
                session_record.available_workstations;

        ELSE

            RAISE NOTICE
                '% has enough workstations. % available.',
                session_record.session_name,
                session_record.available_workstations;

        END IF;

    END LOOP;

END $$;

CREATE OR REPLACE PROCEDURE reserve_workstations(
    p_session_id INT,
    p_lecturer VARCHAR(100),
    p_workstations INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_available INT;
BEGIN

    -- Get available workstations
    SELECT available_workstations
    INTO v_available
    FROM lab_sessions
    WHERE session_id = p_session_id;

    -- Check whether session exists
    IF v_available IS NULL THEN

        RAISE NOTICE 'Lab session does not exist.';

    -- Check capacity
    ELSIF p_workstations > v_available THEN

        RAISE NOTICE
            'Not enough workstations available.';

    ELSE

        -- Reduce available workstations
        UPDATE lab_sessions
        SET available_workstations =
            available_workstations - p_workstations
        WHERE session_id = p_session_id;

        -- Record reservation
        INSERT INTO reservations (
            session_id,
            lecturer,
            workstations,
            reservation_status
        )
        VALUES (
            p_session_id,
            p_lecturer,
            p_workstations,
            'RESERVED'
        );

        RAISE NOTICE
            'Workstations reserved successfully.';

    END IF;

END;
$$;

-- Valid reservation 1
CALL reserve_workstations(
    1,
    'Dr. Banda',
    10
);

-- Valid reservation 2
CALL reserve_workstations(
    2,
    'Mr. Phiri',
    8
);

-- Invalid reservation
-- Session 3 only has 5 available
CALL reserve_workstations(
    3,
    'Mrs. Zulu',
    10
);

SELECT * FROM lab_sessions;

SELECT * FROM reservations;

CREATE OR REPLACE PROCEDURE cancel_reservation(
    p_reservation_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_session_id INT;
    v_workstations INT;
    v_status VARCHAR(20);
BEGIN

    -- Get reservation information
    SELECT session_id, workstations, reservation_status
    INTO v_session_id, v_workstations, v_status
    FROM reservations
    WHERE reservation_id = p_reservation_id;

    -- Check if reservation exists
    IF v_session_id IS NULL THEN

        RAISE NOTICE
            'Reservation does not exist.';

    -- Check if already cancelled
    ELSIF v_status = 'CANCELLED' THEN

        RAISE NOTICE
            'This reservation has already been cancelled.';

    ELSE

        -- Release workstations
        UPDATE lab_sessions
        SET available_workstations =
            available_workstations + v_workstations
        WHERE session_id = v_session_id;

        -- Mark reservation cancelled
        UPDATE reservations
        SET reservation_status = 'CANCELLED'
        WHERE reservation_id = p_reservation_id;

        RAISE NOTICE
            'Reservation cancelled successfully.';

    END IF;

END;
$$;

-- Cancel reservation 1
CALL cancel_reservation(1);

-- Try cancelling the SAME reservation again
CALL cancel_reservation(1);

SELECT * FROM lab_sessions;

SELECT * FROM reservations;

DO $$
DECLARE
    session_record RECORD;

    session_cursor CURSOR FOR
        SELECT
            session_id,
            session_name,
            available_workstations
        FROM lab_sessions
        WHERE available_workstations <= 3;

BEGIN

    OPEN session_cursor;

    LOOP

        FETCH session_cursor INTO session_record;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE
            'Session: % | Workstations remaining: %',
            session_record.session_name,
            session_record.available_workstations;

    END LOOP;

    CLOSE session_cursor;

END $$;

DO $$
BEGIN

    IF 0 <= 0 THEN

        RAISE EXCEPTION
            'Invalid quantity: number of workstations must be greater than zero.';

    END IF;

EXCEPTION
    WHEN OTHERS THEN

        RAISE NOTICE
            'Error handled: %',
            SQLERRM;

END $$;

-- Final lab sessions
SELECT
    session_id,
    session_name,
    available_workstations
FROM lab_sessions
ORDER BY session_id;


-- Final reservations
SELECT
    reservation_id,
    session_id,
    lecturer,
    workstations,
    reservation_status
FROM reservations
ORDER BY reservation_id;