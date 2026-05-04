SET FEEDBACK ON
SET SERVEROUTPUT ON
SET LINESIZE 220
SET PAGESIZE 300
SET VERIFY OFF
SET DEFINE OFF

ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY HH24:MI:SS';

CONNECT XUANTINH/XUANTINH
SHOW USER

SET SERVEROUTPUT ON

SELECT id, name
FROM cau1
ORDER BY id;

BEGIN
    p_check_or_insert_student(101, NULL, NULL, NULL);
END;
/

BEGIN
    p_check_or_insert_student(999, 'Test', 'Moi', 'Thu Duc');
END;
/

SELECT studentid, firstname, lastname, address
FROM student
WHERE studentid IN (101, 999)
ORDER BY studentid;

BEGIN
    p_instructor_workload(1);
    p_instructor_workload(9999);
END;
/

BEGIN
    p_print_letter_grade(101, 1002);
    p_print_letter_grade(101, 9999);
    p_print_letter_grade(9999, 1002);
    p_print_letter_grade(130, 1001);
END;
/

BEGIN
    p_course_class_report;
END;
/

DECLARE
    v_first  student.firstname%TYPE;
    v_last   student.lastname%TYPE;
BEGIN
    find_sname(101, v_first, v_last);
    DBMS_OUTPUT.PUT_LINE('find_sname(101) -> ' || v_first || ' ' || v_last);
END;
/

BEGIN
    print_student_name(102);
END;
/

SELECT courseno, description, cost
FROM course
ORDER BY courseno;

BEGIN
    discount;
END;
/

SELECT courseno, description, cost
FROM course
ORDER BY courseno;

SELECT total_cost_for_student(101) AS total_cost_sv_101 FROM dual;
SELECT total_cost_for_student(9999) AS total_cost_sv_9999 FROM dual;

INSERT INTO course (courseno, description, cost, prerequisite)
VALUES (60, 'Cloud Basics', 460, NULL);
COMMIT;

SELECT courseno,
       created_by,
       TO_CHAR(created_date, 'DD/MM/YYYY HH24:MI:SS') AS created_date,
       modified_by,
       TO_CHAR(modified_date, 'DD/MM/YYYY HH24:MI:SS') AS modified_date
FROM course
WHERE courseno = 60;

UPDATE course
SET cost = 470
WHERE courseno = 60;
COMMIT;

SELECT courseno,
       created_by,
       TO_CHAR(created_date, 'DD/MM/YYYY HH24:MI:SS') AS created_date,
       modified_by,
       TO_CHAR(modified_date, 'DD/MM/YYYY HH24:MI:SS') AS modified_date,
       cost
FROM course
WHERE courseno = 60;

BEGIN
    INSERT INTO enrollment (studentid, classid, enrolldate, finalgrade)
    VALUES (101, 1007, SYSDATE, 88);
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('FAIL: Trigger max enrollment khong chan insert vuot qua 3 lop.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('PASS: Trigger max enrollment da chan. ' || SQLERRM);
        ROLLBACK;
END;
/

SELECT studentid, COUNT(*) AS so_lop
FROM enrollment
WHERE studentid = 101
GROUP BY studentid;

BEGIN
    INSERT INTO enrollment (studentid, classid, enrolldate, finalgrade)
    VALUES (999, 1007, SYSDATE, 90);
    COMMIT;
END;
/

SELECT studentid,
       classid,
       created_by,
       TO_CHAR(created_date, 'DD/MM/YYYY HH24:MI:SS') AS created_date,
       modified_by,
       TO_CHAR(modified_date, 'DD/MM/YYYY HH24:MI:SS') AS modified_date
FROM enrollment
WHERE studentid = 999
ORDER BY classid;

SPOOL OFF
EXIT
