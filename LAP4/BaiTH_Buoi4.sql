SET FEEDBACK ON
SET SERVEROUTPUT ON SIZE 1000000
SET LINESIZE 220
SET PAGESIZE 200
SET DEFINE OFF

ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY HH24:MI:SS';

CONNECT XUANTINH/XUANTINH
SHOW USER
SET SERVEROUTPUT ON SIZE 1000000

PROMPT [PHAN 2 - BAI 1 VIEW]
PROMPT [CAU 1.1] Tao view vw_course_summary

CREATE OR REPLACE VIEW vw_course_summary AS
SELECT co.courseno,
       co.description,
       co.cost,
       COUNT(DISTINCT cl.classid) AS so_lop,
       COUNT(e.studentid) AS tong_sv
FROM course co
LEFT JOIN class cl
       ON co.courseno = cl.courseno
LEFT JOIN enrollment e
       ON cl.classid = e.classid
GROUP BY co.courseno, co.description, co.cost;

PROMPT [CAU 1.2] Tao view vw_student_status

CREATE OR REPLACE VIEW vw_student_status AS
SELECT s.studentid,
       s.firstname || ' ' || s.lastname AS ho_ten,
       COUNT(e.classid) AS so_lop_hoc,
       NVL(SUM(co.cost), 0) AS tong_hoc_phi,
       ROUND(AVG(e.finalgrade), 2) AS diem_tb
FROM student s
JOIN enrollment e
  ON s.studentid = e.studentid
JOIN class cl
  ON e.classid = cl.classid
JOIN course co
  ON cl.courseno = co.courseno
GROUP BY s.studentid, s.firstname, s.lastname
HAVING COUNT(e.classid) >= 1;

PROMPT [CAU 1.3] Tao view vw_class_availability

CREATE OR REPLACE VIEW vw_class_availability AS
SELECT cl.classid,
       cl.courseno,
       co.description,
       i.firstname || ' ' || i.lastname AS ten_giao_vien,
       cl.capacity,
       COUNT(e.studentid) AS so_da_dk,
       cl.capacity - COUNT(e.studentid) AS cho_trong,
       CASE
           WHEN cl.capacity - COUNT(e.studentid) > 0 THEN 'Con cho'
           ELSE 'Het cho'
       END AS trang_thai
FROM class cl
JOIN course co
  ON cl.courseno = co.courseno
JOIN instructor i
  ON cl.instructorid = i.instructorid
LEFT JOIN enrollment e
       ON cl.classid = e.classid
GROUP BY cl.classid,
         cl.courseno,
         co.description,
         i.firstname,
         i.lastname,
         cl.capacity
HAVING cl.capacity - COUNT(e.studentid) > 0;

PROMPT [CAU 1.4] Tao view vw_top_courses WITH READ ONLY

CREATE OR REPLACE VIEW vw_top_courses AS
SELECT courseno, description, cost, tong_dk, hang
FROM (
    SELECT co.courseno,
           co.description,
           co.cost,
           COUNT(e.studentid) AS tong_dk,
           RANK() OVER (ORDER BY COUNT(e.studentid) DESC) AS hang
    FROM course co
    LEFT JOIN class cl
           ON co.courseno = cl.courseno
    LEFT JOIN enrollment e
           ON cl.classid = e.classid
    GROUP BY co.courseno, co.description, co.cost
)
WHERE hang <= 5
WITH READ ONLY;

PROMPT [CAU 1.5] Tao view vw_pending_enrollment WITH CHECK OPTION

CREATE OR REPLACE VIEW vw_pending_enrollment AS
SELECT studentid,
       classid,
       enrolldate,
       finalgrade,
       created_by,
       created_date,
       modified_by,
       modified_date
FROM enrollment
WHERE finalgrade IS NULL
WITH CHECK OPTION;

PROMPT [PHAN 3 - BAI 2 STORED PROCEDURE]
PROMPT [CAU 2.1] Procedure enroll_student

CREATE OR REPLACE PROCEDURE enroll_student (
    p_studentid IN NUMBER,
    p_classid IN NUMBER
)
IS
    v_check NUMBER;
    v_capacity NUMBER;
    v_enrolled NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_check
    FROM student
    WHERE studentid = p_studentid;

    IF v_check = 0 THEN
        DBMS_OUTPUT.PUT_LINE('[LOI] Sinh vien ' || p_studentid || ' khong ton tai!');
        RETURN;
    END IF;

    SELECT COUNT(*)
    INTO v_check
    FROM class
    WHERE classid = p_classid;

    IF v_check = 0 THEN
        DBMS_OUTPUT.PUT_LINE('[LOI] Lop hoc ' || p_classid || ' khong ton tai!');
        RETURN;
    END IF;

    SELECT capacity
    INTO v_capacity
    FROM class
    WHERE classid = p_classid;

    SELECT COUNT(*)
    INTO v_enrolled
    FROM enrollment
    WHERE classid = p_classid;

    IF v_capacity IS NOT NULL AND v_enrolled >= v_capacity THEN
        DBMS_OUTPUT.PUT_LINE('[LOI] Lop ' || p_classid || ' da day! (' || v_enrolled || '/' || v_capacity || ')');
        RETURN;
    END IF;

    SELECT COUNT(*)
    INTO v_check
    FROM enrollment
    WHERE studentid = p_studentid
      AND classid = p_classid;

    IF v_check > 0 THEN
        DBMS_OUTPUT.PUT_LINE('[LOI] Sinh vien da dang ky lop nay roi!');
        RETURN;
    END IF;

    SELECT COUNT(*)
    INTO v_check
    FROM enrollment
    WHERE studentid = p_studentid;

    IF v_check >= 3 THEN
        DBMS_OUTPUT.PUT_LINE('[LOI] Sinh vien da dang ky du 3 lop!');
        RETURN;
    END IF;

    INSERT INTO enrollment (
        studentid, classid, enrolldate, finalgrade,
        created_by, created_date, modified_by, modified_date
    )
    VALUES (
        p_studentid, p_classid, SYSDATE, NULL,
        USER, SYSDATE, USER, SYSDATE
    );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('[OK] Dang ky thanh cong! SV ' || p_studentid || ' -> Lop ' || p_classid);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[LOI HE THONG] ' || SQLERRM);
END enroll_student;
/

PROMPT [CAU 2.2] Procedure update_final_grade

CREATE OR REPLACE PROCEDURE update_final_grade (
    p_studentid IN NUMBER,
    p_classid IN NUMBER,
    p_grade IN NUMBER
)
IS
    v_check NUMBER;
    v_old_grade NUMBER;
BEGIN
    IF p_grade < 0 OR p_grade > 100 THEN
        DBMS_OUTPUT.PUT_LINE('[LOI] Diem khong hop le! Phai tu 0 den 100.');
        RETURN;
    END IF;

    SELECT COUNT(*)
    INTO v_check
    FROM enrollment
    WHERE studentid = p_studentid
      AND classid = p_classid;

    IF v_check = 0 THEN
        DBMS_OUTPUT.PUT_LINE('[LOI] Sinh vien chua dang ky lop nay!');
        RETURN;
    END IF;

    SELECT finalgrade
    INTO v_old_grade
    FROM enrollment
    WHERE studentid = p_studentid
      AND classid = p_classid;

    UPDATE enrollment
    SET finalgrade = p_grade,
        modified_by = USER,
        modified_date = SYSDATE
    WHERE studentid = p_studentid
      AND classid = p_classid;

    MERGE INTO grade g
    USING (
        SELECT p_studentid AS studentid,
               p_classid AS classid,
               p_grade AS finalgrade
        FROM dual
    ) src
    ON (g.studentid = src.studentid AND g.classid = src.classid)
    WHEN MATCHED THEN
        UPDATE SET g.grade = src.finalgrade,
                   g.modified_by = USER,
                   g.modified_date = SYSDATE
    WHEN NOT MATCHED THEN
        INSERT (
            studentid, classid, grade, comments,
            created_by, created_date, modified_by, modified_date
        )
        VALUES (
            src.studentid, src.classid, src.finalgrade, NULL,
            USER, SYSDATE, USER, SYSDATE
        );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('[OK] Cap nhat diem thanh cong. Cu: ' || NVL(TO_CHAR(v_old_grade), 'NULL') || ' -> Moi: ' || p_grade);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[LOI] ' || SQLERRM);
END update_final_grade;
/

PROMPT [CAU 2.3] Procedure transfer_student

CREATE OR REPLACE PROCEDURE transfer_student (
    p_studentid IN NUMBER,
    p_old_classid IN NUMBER,
    p_new_classid IN NUMBER
)
IS
    v_check NUMBER;
    v_capacity NUMBER;
    v_enrolled NUMBER;
BEGIN
    IF p_old_classid = p_new_classid THEN
        DBMS_OUTPUT.PUT_LINE('[LOI] Lop cu va lop moi phai khac nhau.');
        RETURN;
    END IF;

    SELECT COUNT(*)
    INTO v_check
    FROM enrollment
    WHERE studentid = p_studentid
      AND classid = p_old_classid;

    IF v_check = 0 THEN
        DBMS_OUTPUT.PUT_LINE('[LOI] Sinh vien khong dang hoc lop ' || p_old_classid);
        RETURN;
    END IF;

    SELECT COUNT(*)
    INTO v_check
    FROM class
    WHERE classid = p_new_classid;

    IF v_check = 0 THEN
        DBMS_OUTPUT.PUT_LINE('[LOI] Lop moi ' || p_new_classid || ' khong ton tai.');
        RETURN;
    END IF;

    SELECT capacity
    INTO v_capacity
    FROM class
    WHERE classid = p_new_classid;

    SELECT COUNT(*)
    INTO v_enrolled
    FROM enrollment
    WHERE classid = p_new_classid;

    IF v_capacity IS NOT NULL AND v_enrolled >= v_capacity THEN
        DBMS_OUTPUT.PUT_LINE('[LOI] Lop moi ' || p_new_classid || ' da day!');
        RETURN;
    END IF;

    SELECT COUNT(*)
    INTO v_check
    FROM enrollment
    WHERE studentid = p_studentid
      AND classid = p_new_classid;

    IF v_check > 0 THEN
        DBMS_OUTPUT.PUT_LINE('[LOI] Sinh vien da o trong lop moi roi!');
        RETURN;
    END IF;

    SAVEPOINT sp_truoc_chuyen;

    DELETE FROM grade
    WHERE studentid = p_studentid
      AND classid = p_old_classid;

    DELETE FROM enrollment
    WHERE studentid = p_studentid
      AND classid = p_old_classid;

    SAVEPOINT sp_sau_xoa;

    INSERT INTO enrollment (
        studentid, classid, enrolldate, finalgrade,
        created_by, created_date, modified_by, modified_date
    )
    VALUES (
        p_studentid, p_new_classid, SYSDATE, NULL,
        USER, SYSDATE, USER, SYSDATE
    );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('[OK] Da chuyen SV ' || p_studentid || ' tu lop ' || p_old_classid || ' sang lop ' || p_new_classid);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO sp_truoc_chuyen;
        DBMS_OUTPUT.PUT_LINE('[LOI] Chuyen lop that bai: ' || SQLERRM);
END transfer_student;
/

PROMPT [CAU 2.4] Procedure report_class_detail

CREATE OR REPLACE PROCEDURE report_class_detail (
    p_classid IN NUMBER
)
IS
    v_check NUMBER;
    v_course VARCHAR2(50);
    v_courseno NUMBER;
    v_gv VARCHAR2(50);
    v_loc VARCHAR2(50);
    v_cap NUMBER;
    v_stt NUMBER := 0;
    v_tong NUMBER := 0;
    v_sum_d NUMBER := 0;
    v_co_d NUMBER := 0;
    v_grade_txt VARCHAR2(15);
BEGIN
    SELECT COUNT(*)
    INTO v_check
    FROM class
    WHERE classid = p_classid;

    IF v_check = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Lop hoc ' || p_classid || ' khong ton tai!');
        RETURN;
    END IF;

    SELECT co.description,
           co.courseno,
           i.firstname || ' ' || i.lastname,
           cl.location,
           cl.capacity
    INTO v_course, v_courseno, v_gv, v_loc, v_cap
    FROM class cl
    JOIN course co
      ON cl.courseno = co.courseno
    JOIN instructor i
      ON cl.instructorid = i.instructorid
    WHERE cl.classid = p_classid;

    DBMS_OUTPUT.PUT_LINE('=== BAO CAO LOP HOC: ' || p_classid || ' ===');
    DBMS_OUTPUT.PUT_LINE('Mon hoc : ' || v_courseno || ' - ' || v_course);
    DBMS_OUTPUT.PUT_LINE('Giao vien: ' || v_gv);
    DBMS_OUTPUT.PUT_LINE('Phong hoc: ' || NVL(v_loc, 'Chua xep phong'));
    DBMS_OUTPUT.PUT_LINE('Suc chua : ' || v_cap || ' cho');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 62, '-'));
    DBMS_OUTPUT.PUT_LINE(RPAD('STT', 4) || ' | ' || RPAD('Ho Ten', 24) || ' | ' || LPAD('Diem TK', 8) || ' | Xep loai');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 62, '-'));

    FOR rec IN (
        SELECT s.firstname || ' ' || s.lastname AS ho_ten,
               e.finalgrade
        FROM enrollment e
        JOIN student s
          ON e.studentid = s.studentid
        WHERE e.classid = p_classid
        ORDER BY s.lastname, s.firstname
    )
    LOOP
        v_stt := v_stt + 1;
        v_tong := v_tong + 1;

        IF rec.finalgrade IS NULL THEN
            v_grade_txt := 'Chua co diem';
        ELSIF rec.finalgrade >= 90 THEN
            v_grade_txt := 'A';
            v_sum_d := v_sum_d + rec.finalgrade;
            v_co_d := v_co_d + 1;
        ELSIF rec.finalgrade >= 80 THEN
            v_grade_txt := 'B';
            v_sum_d := v_sum_d + rec.finalgrade;
            v_co_d := v_co_d + 1;
        ELSIF rec.finalgrade >= 70 THEN
            v_grade_txt := 'C';
            v_sum_d := v_sum_d + rec.finalgrade;
            v_co_d := v_co_d + 1;
        ELSIF rec.finalgrade >= 50 THEN
            v_grade_txt := 'D';
            v_sum_d := v_sum_d + rec.finalgrade;
            v_co_d := v_co_d + 1;
        ELSE
            v_grade_txt := 'F';
            v_sum_d := v_sum_d + rec.finalgrade;
            v_co_d := v_co_d + 1;
        END IF;

        DBMS_OUTPUT.PUT_LINE(
            LPAD(v_stt, 3) || ' | ' ||
            RPAD(rec.ho_ten, 24) || ' | ' ||
            LPAD(NVL(TO_CHAR(rec.finalgrade), 'NULL'), 8) || ' | ' ||
            v_grade_txt
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(RPAD('-', 62, '-'));
    DBMS_OUTPUT.PUT_LINE('Tong so sinh vien : ' || v_tong);

    IF v_co_d > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Diem trung binh lop: ' || ROUND(v_sum_d / v_co_d, 2));
    ELSE
        DBMS_OUTPUT.PUT_LINE('Diem trung binh lop: Chua co diem');
    END IF;
END report_class_detail;
/

PROMPT [CAU 2.5] Procedure sync_grade_from_enrollment

CREATE OR REPLACE PROCEDURE sync_grade_from_enrollment
IS
    v_check NUMBER;
    v_dem_insert NUMBER := 0;
    v_dem_update NUMBER := 0;
BEGIN
    FOR rec IN (
        SELECT studentid, classid, finalgrade
        FROM enrollment
        WHERE finalgrade IS NOT NULL
    )
    LOOP
        SELECT COUNT(*)
        INTO v_check
        FROM grade
        WHERE studentid = rec.studentid
          AND classid = rec.classid;

        IF v_check = 0 THEN
            INSERT INTO grade (
                studentid, classid, grade, comments,
                created_by, created_date, modified_by, modified_date
            )
            VALUES (
                rec.studentid, rec.classid, rec.finalgrade, NULL,
                USER, SYSDATE, USER, SYSDATE
            );
            v_dem_insert := v_dem_insert + 1;
        ELSE
            UPDATE grade
            SET grade = rec.finalgrade,
                modified_by = USER,
                modified_date = SYSDATE
            WHERE studentid = rec.studentid
              AND classid = rec.classid;
            v_dem_update := v_dem_update + 1;
        END IF;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('[OK] Dong bo hoan tat!');
    DBMS_OUTPUT.PUT_LINE('INSERT: ' || v_dem_insert);
    DBMS_OUTPUT.PUT_LINE('UPDATE: ' || v_dem_update);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('[LOI] ' || SQLERRM);
END sync_grade_from_enrollment;
/

PROMPT [PHAN 4 - BAI 3 TRIGGER]
PROMPT [CAU 3.2 - BANG PHU] Tao bang grade_audit_log

CREATE TABLE grade_audit_log (
    log_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    studentid NUMBER(8),
    classid NUMBER(8),
    grade_cu NUMBER(3),
    grade_moi NUMBER(3),
    nguoi_sua VARCHAR2(30),
    thoi_gian DATE
);

PROMPT [CAU 3.1] Trigger trg_check_capacity

CREATE OR REPLACE TRIGGER trg_check_capacity
BEFORE INSERT ON enrollment
FOR EACH ROW
DECLARE
    v_capacity NUMBER;
    v_enrolled NUMBER;
BEGIN
    SELECT capacity
    INTO v_capacity
    FROM class
    WHERE classid = :NEW.classid;

    SELECT COUNT(*)
    INTO v_enrolled
    FROM enrollment
    WHERE classid = :NEW.classid;

    IF v_capacity IS NOT NULL AND v_enrolled >= v_capacity THEN
        RAISE_APPLICATION_ERROR(
            -20010,
            'LOI: Lop ' || :NEW.classid || ' da day! (' || v_enrolled || '/' || v_capacity || ' cho)'
        );
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20011, 'LOI: Lop hoc ' || :NEW.classid || ' khong ton tai.');
END trg_check_capacity;
/

PROMPT [CAU 3.2] Trigger trg_grade_audit_log

CREATE OR REPLACE TRIGGER trg_grade_audit_log
AFTER UPDATE OF finalgrade ON enrollment
FOR EACH ROW
BEGIN
    IF NVL(:OLD.finalgrade, -999) <> NVL(:NEW.finalgrade, -999) THEN
        INSERT INTO grade_audit_log (
            studentid, classid, grade_cu, grade_moi, nguoi_sua, thoi_gian
        )
        VALUES (
            :OLD.studentid, :OLD.classid, :OLD.finalgrade, :NEW.finalgrade, USER, SYSDATE
        );
    END IF;
END trg_grade_audit_log;
/

PROMPT [CAU 3.3] Trigger trg_prevent_course_delete

CREATE OR REPLACE TRIGGER trg_prevent_course_delete
BEFORE DELETE ON course
FOR EACH ROW
DECLARE
    v_so_lop NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_so_lop
    FROM class
    WHERE courseno = :OLD.courseno;

    IF v_so_lop > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20020,
            'Khong the xoa mon hoc ' || :OLD.courseno || ' (' || :OLD.description || ') vi con ' || v_so_lop || ' lop hoc dang ton tai!'
        );
    END IF;
END trg_prevent_course_delete;
/

PROMPT [CAU 3.4 - BANG PHU] Tao bang class_grade_summary

CREATE TABLE class_grade_summary (
    classid NUMBER(8) PRIMARY KEY,
    so_sv NUMBER,
    diem_tb NUMBER(5, 2),
    diem_cao_nhat NUMBER(3),
    diem_thap_nhat NUMBER(3),
    cap_nhat_luc DATE
);

PROMPT [CAU 3.4] Trigger trg_update_grade_summary

CREATE OR REPLACE TRIGGER trg_update_grade_summary
FOR INSERT OR UPDATE OR DELETE ON enrollment
COMPOUND TRIGGER
    TYPE t_seen IS TABLE OF BOOLEAN INDEX BY VARCHAR2(50);
    TYPE t_list IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    g_seen t_seen;
    g_list t_list;
    g_count PLS_INTEGER := 0;

    PROCEDURE add_class(p_classid NUMBER) IS
        v_key VARCHAR2(50);
    BEGIN
        IF p_classid IS NULL THEN
            RETURN;
        END IF;

        v_key := TO_CHAR(p_classid);

        IF NOT g_seen.EXISTS(v_key) THEN
            g_count := g_count + 1;
            g_list(g_count) := p_classid;
            g_seen(v_key) := TRUE;
        END IF;
    END add_class;

    AFTER EACH ROW IS
    BEGIN
        IF INSERTING OR UPDATING THEN
            add_class(:NEW.classid);
        END IF;

        IF DELETING OR UPDATING THEN
            add_class(:OLD.classid);
        END IF;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
        v_so_sv NUMBER;
        v_diem_tb NUMBER;
        v_max_d NUMBER;
        v_min_d NUMBER;
    BEGIN
        FOR i IN 1 .. g_count LOOP
            SELECT COUNT(finalgrade),
                   ROUND(AVG(finalgrade), 2),
                   MAX(finalgrade),
                   MIN(finalgrade)
            INTO v_so_sv, v_diem_tb, v_max_d, v_min_d
            FROM enrollment
            WHERE classid = g_list(i)
              AND finalgrade IS NOT NULL;

            MERGE INTO class_grade_summary cgs
            USING (SELECT g_list(i) AS cid FROM dual) src
            ON (cgs.classid = src.cid)
            WHEN MATCHED THEN
                UPDATE SET so_sv = v_so_sv,
                           diem_tb = v_diem_tb,
                           diem_cao_nhat = v_max_d,
                           diem_thap_nhat = v_min_d,
                           cap_nhat_luc = SYSDATE
            WHEN NOT MATCHED THEN
                INSERT (
                    classid, so_sv, diem_tb, diem_cao_nhat, diem_thap_nhat, cap_nhat_luc
                )
                VALUES (
                    g_list(i), v_so_sv, v_diem_tb, v_max_d, v_min_d, SYSDATE
                );
        END LOOP;
    END AFTER STATEMENT;
END trg_update_grade_summary;
/

PROMPT [PHAN 5 - BAI 4 TONG HOP]
PROMPT [CAU 4.1A] Tao view vw_instructor_workload

CREATE OR REPLACE VIEW vw_instructor_workload AS
SELECT i.instructorid,
       i.firstname || ' ' || i.lastname AS ho_ten,
       COUNT(DISTINCT cl.classid) AS so_lop,
       COUNT(e.studentid) AS tong_sv,
       ROUND(AVG(e.finalgrade), 2) AS diem_tb_chung,
       CASE
           WHEN COUNT(DISTINCT cl.classid) >= 3 THEN 'Ban nhieu'
           WHEN COUNT(DISTINCT cl.classid) = 2 THEN 'Binh thuong'
           ELSE 'Nhe nhang'
       END AS muc_ban
FROM instructor i
LEFT JOIN class cl
       ON i.instructorid = cl.instructorid
LEFT JOIN enrollment e
       ON cl.classid = e.classid
GROUP BY i.instructorid, i.firstname, i.lastname;

PROMPT [CAU 4.1B] Procedure print_system_report

CREATE OR REPLACE PROCEDURE print_system_report
IS
    v_so_mon NUMBER;
    v_so_lop NUMBER;
    v_so_sv NUMBER;
    v_so_gv NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_so_mon FROM course;
    SELECT COUNT(*) INTO v_so_lop FROM class;
    SELECT COUNT(*) INTO v_so_sv FROM student;
    SELECT COUNT(*) INTO v_so_gv FROM instructor;

    DBMS_OUTPUT.PUT_LINE('==============================================');
    DBMS_OUTPUT.PUT_LINE('BAO CAO TOAN HE THONG QUAN LY KHOA HOC');
    DBMS_OUTPUT.PUT_LINE('==============================================');
    DBMS_OUTPUT.PUT_LINE('Tong so mon hoc : ' || v_so_mon);
    DBMS_OUTPUT.PUT_LINE('Tong so lop hoc : ' || v_so_lop);
    DBMS_OUTPUT.PUT_LINE('Tong so sinh vien: ' || v_so_sv);
    DBMS_OUTPUT.PUT_LINE('Tong so giao vien: ' || v_so_gv);
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 70, '-'));
    DBMS_OUTPUT.PUT_LINE('THONG KE GIAO VIEN');

    FOR rec IN (
        SELECT *
        FROM vw_instructor_workload
        ORDER BY so_lop DESC, instructorid
    )
    LOOP
        DBMS_OUTPUT.PUT_LINE(
            RPAD(rec.ho_ten, 25) ||
            ' | ' || LPAD(rec.so_lop, 2) || ' lop' ||
            ' | ' || LPAD(rec.tong_sv, 3) || ' SV' ||
            ' | DTB: ' || NVL(TO_CHAR(rec.diem_tb_chung), '--') ||
            ' | ' || rec.muc_ban
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(RPAD('-', 70, '-'));
    DBMS_OUTPUT.PUT_LINE('TOP 3 MON HOC DUOC DANG KY NHIEU NHAT');

    FOR rec IN (
        SELECT *
        FROM vw_top_courses
        WHERE hang <= 3
        ORDER BY hang, courseno
    )
    LOOP
        DBMS_OUTPUT.PUT_LINE(
            rec.hang || '. ' || RPAD(rec.description, 30) || ' - ' || rec.tong_dk || ' luot dang ky'
        );
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('==============================================');
END print_system_report;
/
