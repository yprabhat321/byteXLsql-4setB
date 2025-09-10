-- StudentEnrollments Concurrency Demonstration

-- ===============================================
-- Part A: Prevent Duplicate Enrollments Using Locking
-- ===============================================

CREATE TABLE IF NOT EXISTS StudentEnrollments (
    enrollment_id INT PRIMARY KEY AUTO_INCREMENT,
    student_name VARCHAR(100),
    course_id VARCHAR(10),
    enrollment_date DATE,
    UNIQUE(student_name, course_id)
);

-- User A
START TRANSACTION;
INSERT INTO StudentEnrollments(student_name, course_id, enrollment_date)
VALUES ('Ashish', 'CSE101', '2024-07-01');
COMMIT;

-- User B (Concurrent)
START TRANSACTION;
INSERT INTO StudentEnrollments(student_name, course_id, enrollment_date)
VALUES ('Ashish', 'CSE101', '2024-07-01'); -- Will FAIL due to unique constraint
COMMIT;


-- ===============================================
-- Part B: Use SELECT FOR UPDATE to Lock Student Record
-- ===============================================

-- User A
START TRANSACTION;
SELECT * FROM StudentEnrollments
WHERE student_name = 'Ashish' AND course_id = 'CSE101'
FOR UPDATE;

-- Row locked by User A

-- User B (while User A has not committed)
UPDATE StudentEnrollments
SET enrollment_date = '2024-08-01'
WHERE student_name = 'Ashish' AND course_id = 'CSE101';
-- This update will BLOCK until User A COMMITs or ROLLBACKs

-- User A
COMMIT; -- Releases lock

-- User B (unblocked, now succeeds)
-- Enrollment date updated to '2024-08-01'


-- ===============================================
-- Part C: Demonstrate Locking Preserving Consistency
-- ===============================================

-- Initial data
INSERT INTO StudentEnrollments(student_name, course_id, enrollment_date)
VALUES ('Smaran', 'CSE102', '2024-07-01')
ON DUPLICATE KEY UPDATE enrollment_date = VALUES(enrollment_date);

-- User A
START TRANSACTION;
UPDATE StudentEnrollments
SET enrollment_date = '2024-09-01'
WHERE student_name = 'Ashish' AND course_id = 'CSE101';
-- Row locked until commit

-- User B (tries to update at the same time)
UPDATE StudentEnrollments
SET enrollment_date = '2024-10-01'
WHERE student_name = 'Ashish' AND course_id = 'CSE101';
-- BLOCKED until User A commits

-- User A commits
COMMIT;

-- User B update executes after User A
COMMIT;

-- Final Result:
-- Ashish in CSE101 has enrollment_date = '2024-10-01'
-- Only the last committed update is visible, ensuring consistency
