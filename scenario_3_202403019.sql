-- ============================================
-- SCENARIO 3: STUDENT HOSTEL ROOM ALLOCATION
-- ============================================

DROP TABLE IF EXISTS allocations;
DROP TABLE IF EXISTS hostel_rooms;

-- Create hostel_rooms table
CREATE TABLE hostel_rooms (
    room_id SERIAL PRIMARY KEY,
    room_name VARCHAR(50) NOT NULL,
    available_bed_spaces INT NOT NULL
);

-- Create allocations table
CREATE TABLE allocations (
    allocation_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20) NOT NULL,
    room_id INT REFERENCES hostel_rooms(room_id),
    allocation_status VARCHAR(20) NOT NULL
);

INSERT INTO hostel_rooms (room_name, available_bed_spaces)
VALUES
('Room A', 4),
('Room B', 2),
('Room C', 1);

SELECT * FROM hostel_rooms;

DO $$
DECLARE
    room_record RECORD;
BEGIN

    FOR room_record IN
        SELECT *
        FROM hostel_rooms
    LOOP

        IF room_record.available_bed_spaces = 0 THEN

            RAISE NOTICE
                '% is FULL.',
                room_record.room_name;

        ELSIF room_record.available_bed_spaces = 1 THEN

            RAISE NOTICE
                '% has ONE space left.',
                room_record.room_name;

        ELSE

            RAISE NOTICE
                '% has several spaces. % spaces available.',
                room_record.room_name,
                room_record.available_bed_spaces;

        END IF;

    END LOOP;

END $$;

DO $$
DECLARE
    inspection_day INT := 1;
BEGIN

    -- WHILE loop
    WHILE inspection_day <= 3
    LOOP

        RAISE NOTICE
            'Hostel inspection day: %',
            inspection_day;

        inspection_day := inspection_day + 1;

    END LOOP;


    -- Numeric FOR loop
    FOR room_check IN 1..3
    LOOP

        RAISE NOTICE
            'Room check number: %',
            room_check;

    END LOOP;

END $$;

CREATE OR REPLACE PROCEDURE allocate_room(
    p_student_number VARCHAR(20),
    p_room_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_available INT;
BEGIN

    -- Get available spaces
    SELECT available_bed_spaces
    INTO v_available
    FROM hostel_rooms
    WHERE room_id = p_room_id;

    -- Check whether room exists
    IF v_available IS NULL THEN

        RAISE NOTICE
            'Room does not exist.';

    -- Check whether room is full
    ELSIF v_available <= 0 THEN

        RAISE NOTICE
            'Room is full.';

    ELSE

        -- Reduce available bed spaces by one
        UPDATE hostel_rooms
        SET available_bed_spaces =
            available_bed_spaces - 1
        WHERE room_id = p_room_id;

        -- Record student allocation
        INSERT INTO allocations (
            student_number,
            room_id,
            allocation_status
        )
        VALUES (
            p_student_number,
            p_room_id,
            'ALLOCATED'
        );

        RAISE NOTICE
            'Student allocated successfully.';

    END IF;

END;
$$;

CALL allocate_room('202405943', 3);
CALL allocate_room('202405944', 3);

CALL allocate_room('20246033', 1);

CALL allocate_room('202407027', 1);

SELECT * FROM hostel_rooms;

SELECT * FROM allocations;

CREATE OR REPLACE PROCEDURE check_out(
    p_allocation_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_room_id INT;
    v_status VARCHAR(20);
BEGIN

    -- Get allocation information
    SELECT room_id, allocation_status
    INTO v_room_id, v_status
    FROM allocations
    WHERE allocation_id = p_allocation_id;

    -- Check whether allocation exists
    IF v_room_id IS NULL THEN

        RAISE NOTICE
            'Allocation does not exist.';

    -- Check whether already checked out
    ELSIF v_status = 'CHECKED_OUT' THEN

        RAISE NOTICE
            'This student has already checked out.';

    ELSE

        -- Release the bed space
        UPDATE hostel_rooms
        SET available_bed_spaces =
            available_bed_spaces + 1
        WHERE room_id = v_room_id;

        -- Mark allocation as checked out
        UPDATE allocations
        SET allocation_status = 'CHECKED_OUT'
        WHERE allocation_id = p_allocation_id;

        RAISE NOTICE
            'Student checked out successfully.';

    END IF;

END;
$$;

CALL check_out(1);

SELECT * FROM hostel_rooms;

SELECT * FROM allocations;

DO $$
DECLARE
    room_record RECORD;

    room_cursor CURSOR FOR
        SELECT
            room_id,
            room_name,
            available_bed_spaces
        FROM hostel_rooms
        WHERE available_bed_spaces <= 1;

BEGIN

    OPEN room_cursor;

    LOOP

        FETCH room_cursor INTO room_record;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE
            'Room: % | Available spaces: %',
            room_record.room_name,
            room_record.available_bed_spaces;

    END LOOP;

    CLOSE room_cursor;

END $$;

DO $$
BEGIN

    IF TRIM('') = '' THEN

        RAISE EXCEPTION
            'Invalid student number: student number cannot be blank.';

    END IF;

EXCEPTION
    WHEN OTHERS THEN

        RAISE NOTICE
            'Error handled: %',
            SQLERRM;

END $$;

-- Final hostel rooms
SELECT
    room_id,
    room_name,
    available_bed_spaces
FROM hostel_rooms
ORDER BY room_id;


-- Final allocations
SELECT
    allocation_id,
    student_number,
    room_id,
    allocation_status
FROM allocations
ORDER BY allocation_id;

