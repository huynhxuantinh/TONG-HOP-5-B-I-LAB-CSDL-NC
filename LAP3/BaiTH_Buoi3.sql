SET FEEDBACK ON
SET SERVEROUTPUT ON
SET LINESIZE 220
SET PAGESIZE 200
SET DEFINE OFF

ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY HH24:MI:SS';

CONNECT XUANTINH/XUANTINH
SHOW USER

CREATE TABLE cau1 (
    id    NUMBER,
    name  VARCHAR2(20)
);

CREATE SEQUENCE cau1seq
START WITH 5
INCREMENT BY 5;

DECLARE
    v_name  VARCHAR2(50);
    v_id    NUMBER;
BEGIN
    SELECT s.firstname || ' ' || s.lastname
    INTO v_name
    FROM student s
    WHERE s.studentid = (
        SELECT studentid
        FROM (
            SELECT e.studentid, COUNT(*) AS cnt
            FROM enrollment e
            GROUP BY e.studentid
            ORDER BY cnt DESC, e.studentid
        )
        WHERE ROWNUM = 1
    );

    INSERT INTO cau1 (id, name)
    VALUES (cau1seq.NEXTVAL, v_name);
    SAVEPOINT sp_a;

    SELECT s.firstname || ' ' || s.lastname
    INTO v_name
    FROM student s
    WHERE s.studentid = (
        SELECT studentid
        FROM (
            SELECT e.studentid, COUNT(*) AS cnt
            FROM enrollment e
            GROUP BY e.studentid
            ORDER BY cnt ASC, e.studentid
        )
        WHERE ROWNUM = 1
    );

    INSERT INTO cau1 (id, name)
    VALUES (cau1seq.NEXTVAL, v_name);
    SAVEPOINT sp_b;

    SELECT i.firstname || ' ' || i.lastname
    INTO v_name
    FROM instructor i
    WHERE i.instructorid = (
        SELECT instructorid
        FROM (
            SELECT c.instructorid, COUNT(*) AS cnt
            FROM class c
            GROUP BY c.instructorid
            ORDER BY cnt DESC, c.instructorid
        )
        WHERE ROWNUM = 1
    );

    SAVEPOINT sp_c;
    INSERT INTO cau1 (id, name)
    VALUES (cau1seq.NEXTVAL, v_name);

    SELECT id
    INTO v_id
    FROM (
        SELECT id
        FROM cau1
        WHERE name = v_name
        ORDER BY id DESC
    )
    WHERE ROWNUM = 1;

    ROLLBACK TO sp_c;

    SELECT i.firstname || ' ' || i.lastname
    INTO v_name
    FROM instructor i
    WHERE i.instructorid = (
        SELECT instructorid
        FROM (
            SELECT c.instructorid, COUNT(*) AS cnt
            FROM class c
            GROUP BY c.instructorid
            ORDER BY cnt ASC, c.instructorid
        )
        WHERE ROWNUM = 1
    );

    INSERT INTO cau1 (id, name)
    VALUES (v_id, v_name);

    SELECT i.firstname || ' ' || i.lastname
    INTO v_name
    FROM instructor i
    WHERE i.instructorid = (
        SELECT instructorid
        FROM (
            SELECT c.instructorid, COUNT(*) AS cnt
            FROM class c
            GROUP BY c.instructorid
            ORDER BY cnt DESC, c.instructorid
        )
        WHERE ROWNUM = 1
    );

    INSERT INTO cau1 (id, name)
    VALUES (cau1seq.NEXTVAL, v_name);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Bai 1 C1c->C1j: Hoan tat');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Bai 1 C1c->C1j loi: ' || SQLERRM);
END;
/

CREATE OR REPLACE PROCEDURE p_check_or_insert_student (
    p_student_id   IN student.studentid%TYPE,
    p_first_name   IN student.firstname%TYPE DEFAULT NULL,
    p_last_name    IN student.lastname%TYPE DEFAULT NULL,
    p_address      IN student.address%TYPE DEFAULT NULL
)
IS
    v_found_name  VARCHAR2(60);
    v_classes     NUMBER;
BEGIN
    SELECT firstname || ' ' || lastname
    INTO v_found_name
    FROM student
    WHERE studentid = p_student_id;

    SELECT COUNT(*)
    INTO v_classes
    FROM enrollment
    WHERE studentid = p_student_id;

    DBMS_OUTPUT.PUT_LINE('Ton tai SV: ' || v_found_name);
    DBMS_OUTPUT.PUT_LINE('So lop dang hoc: ' || v_classes);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        IF p_first_name IS NULL OR p_last_name IS NULL OR p_address IS NULL THEN
            DBMS_OUTPUT.PUT_LINE('SV chua ton tai. Can truyen ho, ten, dia chi de them moi.');
            RETURN;
        END IF;

        INSERT INTO student (
            studentid, salutation, firstname, lastname, address, phone, employer,
            registrationdate, created_by, created_date, modified_by, modified_date
        )
        VALUES (
            p_student_id, 'Mr', p_first_name, p_last_name, p_address, NULL, NULL,
            SYSDATE, USER, SYSDATE, USER, SYSDATE
        );

        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Da them moi SV: ' || p_first_name || ' ' || p_last_name);
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('p_check_or_insert_student loi: ' || SQLERRM);
END p_check_or_insert_student;
/

CREATE OR REPLACE PROCEDURE p_instructor_workload (
    p_instructor_id  IN instructor.instructorid%TYPE
)
IS
    v_exists   NUMBER;
    v_so_lop   NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_exists
    FROM instructor
    WHERE instructorid = p_instructor_id;

    IF v_exists = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Loi: Ma giao vien ' || p_instructor_id || ' khong ton tai!');
        RETURN;
    END IF;

    SELECT COUNT(*)
    INTO v_so_lop
    FROM class
    WHERE instructorid = p_instructor_id;

    IF v_so_lop >= 5 THEN
        DBMS_OUTPUT.PUT_LINE('Giao vien nay nen nghi ngoi!');
    ELSE
        DBMS_OUTPUT.PUT_LINE('So lop giao vien dang day: ' || v_so_lop);
    END IF;
END p_instructor_workload;
/

CREATE OR REPLACE PROCEDURE p_print_letter_grade (
    p_student_id  IN student.studentid%TYPE,
    p_class_id    IN class.classid%TYPE
)
IS
    v_check  NUMBER;
    v_score  enrollment.finalgrade%TYPE;
    v_grade  VARCHAR2(2);
BEGIN
    SELECT COUNT(*)
    INTO v_check
    FROM student
    WHERE studentid = p_student_id;

    IF v_check = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Loi: Ma sinh vien ' || p_student_id || ' khong ton tai!');
        RETURN;
    END IF;

    SELECT COUNT(*)
    INTO v_check
    FROM class
    WHERE classid = p_class_id;

    IF v_check = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Loi: Ma lop ' || p_class_id || ' khong ton tai!');
        RETURN;
    END IF;

    SELECT finalgrade
    INTO v_score
    FROM enrollment
    WHERE studentid = p_student_id
      AND classid = p_class_id;

    IF v_score IS NULL THEN
        DBMS_OUTPUT.PUT_LINE('Sinh vien chua co diem tong ket cho lop nay.');
        RETURN;
    END IF;

    CASE
        WHEN v_score >= 90 THEN v_grade := 'A';
        WHEN v_score >= 80 THEN v_grade := 'B';
        WHEN v_score >= 70 THEN v_grade := 'C';
        WHEN v_score >= 50 THEN v_grade := 'D';
        ELSE v_grade := 'F';
    END CASE;

    DBMS_OUTPUT.PUT_LINE(
        'SV ' || p_student_id || ', lop ' || p_class_id ||
        ': diem so = ' || v_score || ', diem chu = ' || v_grade
    );
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Sinh vien chua dang ky lop nay hoac chua co diem!');
END p_print_letter_grade;
/

CREATE OR REPLACE PROCEDURE p_course_class_report
IS
    CURSOR cur_course IS
        SELECT courseno, description
        FROM course
        ORDER BY courseno;

    CURSOR cur_class (p_courseno NUMBER) IS
        SELECT c.classid,
               COUNT(e.studentid) AS so_sv
        FROM class c
        LEFT JOIN enrollment e
               ON e.classid = c.classid
        WHERE c.courseno = p_courseno
        GROUP BY c.classid
        ORDER BY c.classid;
BEGIN
    FOR r_course IN cur_course LOOP
        DBMS_OUTPUT.PUT_LINE(r_course.courseno || ' ' || r_course.description);

        FOR r_class IN cur_class(r_course.courseno) LOOP
            DBMS_OUTPUT.PUT_LINE(
                'Lop: ' || r_class.classid ||
                ' co so luong sinh vien dang ki: ' || r_class.so_sv
            );
        END LOOP;
    END LOOP;
END p_course_class_report;
/

BEGIN
    p_course_class_report;
END;
/

CREATE OR REPLACE PROCEDURE find_sname (
    i_student_id  IN student.studentid%TYPE,
    o_first_name  OUT student.firstname%TYPE,
    o_last_name   OUT student.lastname%TYPE
)
IS
BEGIN
    SELECT firstname, lastname
    INTO o_first_name, o_last_name
    FROM student
    WHERE studentid = i_student_id;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        o_first_name := NULL;
        o_last_name := NULL;
        DBMS_OUTPUT.PUT_LINE('Khong tim thay sinh vien ID: ' || i_student_id);
END find_sname;
/

CREATE OR REPLACE PROCEDURE print_student_name (
    i_student_id IN student.studentid%TYPE
)
IS
    v_first  student.firstname%TYPE;
    v_last   student.lastname%TYPE;
BEGIN
    find_sname(i_student_id, v_first, v_last);

    IF v_first IS NOT NULL OR v_last IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('Ho ten sinh vien: ' || v_first || ' ' || v_last);
    END IF;
END print_student_name;
/

CREATE OR REPLACE PROCEDURE discount
IS
BEGIN
    FOR rec IN (
        SELECT c.courseno, c.description, c.cost
        FROM course c
        WHERE (
            SELECT COUNT(*)
            FROM enrollment e
            JOIN class cl
              ON cl.classid = e.classid
            WHERE cl.courseno = c.courseno
        ) > 15
    )
    LOOP
        UPDATE course
        SET cost = ROUND(cost * 0.95, 2)
        WHERE courseno = rec.courseno;

        DBMS_OUTPUT.PUT_LINE(
            'Da giam gia mon: ' || rec.description ||
            ' | Gia cu: ' || rec.cost ||
            ' | Gia moi: ' || ROUND(rec.cost * 0.95, 2)
        );
    END LOOP;

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('discount loi: ' || SQLERRM);
END discount;
/

CREATE OR REPLACE FUNCTION total_cost_for_student (
    p_student_id IN student.studentid%TYPE
)
RETURN NUMBER
IS
    v_check  NUMBER;
    v_total  NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_check
    FROM student
    WHERE studentid = p_student_id;

    IF v_check = 0 THEN
        RETURN NULL;
    END IF;

    SELECT SUM(c.cost)
    INTO v_total
    FROM enrollment e
    JOIN class cl
      ON cl.classid = e.classid
    JOIN course c
      ON c.courseno = cl.courseno
    WHERE e.studentid = p_student_id;

    RETURN v_total;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END total_cost_for_student;
/

CREATE OR REPLACE TRIGGER trg_course_audit
BEFORE INSERT OR UPDATE ON course
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_by := USER;
        :NEW.created_date := SYSDATE;
    END IF;

    :NEW.modified_by := USER;
    :NEW.modified_date := SYSDATE;
END;
/

CREATE OR REPLACE TRIGGER trg_class_audit
BEFORE INSERT OR UPDATE ON class
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_by := USER;
        :NEW.created_date := SYSDATE;
    END IF;

    :NEW.modified_by := USER;
    :NEW.modified_date := SYSDATE;
END;
/

CREATE OR REPLACE TRIGGER trg_student_audit
BEFORE INSERT OR UPDATE ON student
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_by := USER;
        :NEW.created_date := SYSDATE;
    END IF;

    :NEW.modified_by := USER;
    :NEW.modified_date := SYSDATE;
END;
/

CREATE OR REPLACE TRIGGER trg_enrollment_audit
BEFORE INSERT OR UPDATE ON enrollment
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_by := USER;
        :NEW.created_date := SYSDATE;
    END IF;

    :NEW.modified_by := USER;
    :NEW.modified_date := SYSDATE;
END;
/

CREATE OR REPLACE TRIGGER trg_instructor_audit
BEFORE INSERT OR UPDATE ON instructor
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_by := USER;
        :NEW.created_date := SYSDATE;
    END IF;

    :NEW.modified_by := USER;
    :NEW.modified_date := SYSDATE;
END;
/

CREATE OR REPLACE TRIGGER trg_grade_audit
BEFORE INSERT OR UPDATE ON grade
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        :NEW.created_by := USER;
        :NEW.created_date := SYSDATE;
    END IF;

    :NEW.modified_by := USER;
    :NEW.modified_date := SYSDATE;
END;
/

CREATE OR REPLACE TRIGGER trg_max_enrollment
BEFORE INSERT ON enrollment
FOR EACH ROW
DECLARE
    v_so_lop  NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_so_lop
    FROM enrollment
    WHERE studentid = :NEW.studentid;

    IF v_so_lop >= 3 THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Sinh vien ' || :NEW.studentid || ' da dang ky du 3 lop! Khong the dang ky them.'
        );
    END IF;
END trg_max_enrollment;
/
