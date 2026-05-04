SET FEEDBACK ON
SET SERVEROUTPUT ON SIZE 1000000
SET LINESIZE 220
SET PAGESIZE 300
SET DEFINE OFF

ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY HH24:MI:SS';

CONNECT XUANTINH/XUANTINH
SHOW USER
SET SERVEROUTPUT ON SIZE 1000000

SPOOL Test_BaiTH_Buoi4.log

PROMPT [RUN] CHAY FILE BAI LAM
@@BaiTH_Buoi4.sql
SET SERVEROUTPUT ON SIZE 1000000

PROMPT [CHECK] DOI TUONG INVALID
SELECT object_name, object_type, status
FROM user_objects
WHERE status = 'INVALID'
  AND object_name IN (
      'VW_COURSE_SUMMARY',
      'VW_STUDENT_STATUS',
      'VW_CLASS_AVAILABILITY',
      'VW_TOP_COURSES',
      'VW_PENDING_ENROLLMENT',
      'VW_INSTRUCTOR_WORKLOAD',
      'ENROLL_STUDENT',
      'UPDATE_FINAL_GRADE',
      'TRANSFER_STUDENT',
      'REPORT_CLASS_DETAIL',
      'SYNC_GRADE_FROM_ENROLLMENT',
      'PRINT_SYSTEM_REPORT',
      'TRG_CHECK_CAPACITY',
      'TRG_GRADE_AUDIT_LOG',
      'TRG_PREVENT_COURSE_DELETE',
      'TRG_UPDATE_GRADE_SUMMARY'
  )
ORDER BY object_type, object_name;

PROMPT [TEST CHUAN BI DU LIEU]
MERGE INTO student s
USING (
    SELECT 1991 AS studentid, 'Mr' AS salutation, 'Temp1' AS firstname, 'Test' AS lastname FROM dual
    UNION ALL
    SELECT 1992, 'Ms', 'Temp2', 'Test' FROM dual
    UNION ALL
    SELECT 1999, 'Mr', 'TempMain', 'Test' FROM dual
) src
ON (s.studentid = src.studentid)
WHEN MATCHED THEN
    UPDATE SET s.firstname = src.firstname,
               s.lastname = src.lastname,
               s.modified_by = USER,
               s.modified_date = SYSDATE
WHEN NOT MATCHED THEN
    INSERT (
        studentid, salutation, firstname, lastname, address, phone, employer,
        registrationdate, created_by, created_date, modified_by, modified_date
    )
    VALUES (
        src.studentid, src.salutation, src.firstname, src.lastname, 'Temp Address', NULL, NULL,
        SYSDATE, USER, SYSDATE, USER, SYSDATE
    );

BEGIN
    DELETE FROM grade WHERE studentid IN (1991, 1992, 1999);
    DELETE FROM enrollment WHERE studentid IN (1991, 1992, 1999);
    DELETE FROM class WHERE classid = 1901;
    COMMIT;
END;
/

PROMPT [CAU 1.1] TEST VW_COURSE_SUMMARY
SELECT courseno, description, cost, so_lop, tong_sv
FROM vw_course_summary
ORDER BY tong_sv DESC, courseno;

PROMPT [CAU 1.2] TEST VW_STUDENT_STATUS
SELECT studentid, ho_ten, so_lop_hoc, tong_hoc_phi, diem_tb
FROM vw_student_status
ORDER BY studentid;

PROMPT [CAU 1.3] TEST VW_CLASS_AVAILABILITY
SELECT classid, courseno, description, ten_giao_vien, capacity, so_da_dk, cho_trong, trang_thai
FROM vw_class_availability
ORDER BY classid;

PROMPT [CAU 1.4] TEST VW_TOP_COURSES + READ ONLY
SELECT courseno, description, cost, tong_dk, hang
FROM vw_top_courses
ORDER BY hang, courseno;

BEGIN
    INSERT INTO vw_top_courses (courseno, description, cost, tong_dk, hang)
    VALUES (9999, 'READONLY TEST', 1, 0, 1);
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('READ_ONLY_VIEW_ERROR: ' || SQLCODE || ' - ' || SQLERRM);
        ROLLBACK;
END;
/

PROMPT [CAU 1.5] TEST VW_PENDING_ENROLLMENT + CHECK OPTION
BEGIN
    DELETE FROM enrollment WHERE studentid = 1999 AND classid = 1008;
    COMMIT;
END;
/

INSERT INTO vw_pending_enrollment (
    studentid, classid, enrolldate, finalgrade,
    created_by, created_date, modified_by, modified_date
)
VALUES (1999, 1008, SYSDATE, NULL, USER, SYSDATE, USER, SYSDATE);
COMMIT;

BEGIN
    INSERT INTO vw_pending_enrollment (
        studentid, classid, enrolldate, finalgrade,
        created_by, created_date, modified_by, modified_date
    )
    VALUES (1999, 1007, SYSDATE, 85, USER, SYSDATE, USER, SYSDATE);
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('CHECK_OPTION_ERROR: ' || SQLCODE || ' - ' || SQLERRM);
        ROLLBACK;
END;
/

SELECT studentid, classid, finalgrade
FROM vw_pending_enrollment
WHERE studentid = 1999
ORDER BY classid;

PROMPT [CAU 2.1] TEST PROCEDURE ENROLL_STUDENT
BEGIN
    enroll_student(1999, 1007);
    enroll_student(99999, 1007);
    enroll_student(1999, 99999);
END;
/

PROMPT [CAU 2.2] TEST PROCEDURE UPDATE_FINAL_GRADE
BEGIN
    update_final_grade(1999, 1007, 88);
    update_final_grade(1999, 1007, 120);
    update_final_grade(1999, 99999, 50);
END;
/

SELECT studentid, classid, finalgrade
FROM enrollment
WHERE studentid = 1999
ORDER BY classid;

SELECT studentid, classid, grade
FROM grade
WHERE studentid = 1999
ORDER BY classid;

PROMPT [CAU 2.3] TEST PROCEDURE TRANSFER_STUDENT
BEGIN
    transfer_student(1999, 1007, 1006);
    transfer_student(1999, 1007, 1006);
END;
/

SELECT studentid, classid, finalgrade
FROM enrollment
WHERE studentid = 1999
ORDER BY classid;

PROMPT [CAU 2.4] TEST PROCEDURE REPORT_CLASS_DETAIL
BEGIN
    report_class_detail(1002);
END;
/

PROMPT [CAU 2.5] TEST PROCEDURE SYNC_GRADE_FROM_ENROLLMENT
BEGIN
    sync_grade_from_enrollment;
END;
/

PROMPT [CAU 3.1] TEST TRIGGER TRG_CHECK_CAPACITY
MERGE INTO class c
USING (
    SELECT 1901 AS classid, 10 AS courseno, 99 AS classno, 1 AS instructorid, 1 AS capacity FROM dual
) src
ON (c.classid = src.classid)
WHEN MATCHED THEN
    UPDATE SET c.courseno = src.courseno,
               c.classno = src.classno,
               c.startdatetime = SYSDATE,
               c.location = 'TEMP',
               c.instructorid = src.instructorid,
               c.capacity = src.capacity,
               c.modified_by = USER,
               c.modified_date = SYSDATE
WHEN NOT MATCHED THEN
    INSERT (
        classid, courseno, classno, startdatetime, location, instructorid, capacity,
        created_by, created_date, modified_by, modified_date
    )
    VALUES (
        src.classid, src.courseno, src.classno, SYSDATE, 'TEMP', src.instructorid, src.capacity,
        USER, SYSDATE, USER, SYSDATE
    );
COMMIT;

BEGIN
    enroll_student(1991, 1901);
END;
/

BEGIN
    INSERT INTO enrollment (
        studentid, classid, enrolldate, finalgrade,
        created_by, created_date, modified_by, modified_date
    )
    VALUES (1992, 1901, SYSDATE, NULL, USER, SYSDATE, USER, SYSDATE);
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('CAPACITY_TRIGGER_ERROR: ' || SQLCODE || ' - ' || SQLERRM);
        ROLLBACK;
END;
/

PROMPT [CAU 3.2] TEST TRIGGER TRG_GRADE_AUDIT_LOG
UPDATE enrollment
SET finalgrade = CASE WHEN NVL(finalgrade, -1) = 86 THEN 87 ELSE 86 END
WHERE studentid = 101
  AND classid = 1001;
COMMIT;

SELECT log_id, studentid, classid, grade_cu, grade_moi, nguoi_sua, thoi_gian
FROM grade_audit_log
ORDER BY log_id DESC FETCH FIRST 10 ROWS ONLY;

PROMPT [CAU 3.3] TEST TRIGGER TRG_PREVENT_COURSE_DELETE
BEGIN
    DELETE FROM course WHERE courseno = 10;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('PREVENT_DELETE_TRIGGER_ERROR: ' || SQLCODE || ' - ' || SQLERRM);
        ROLLBACK;
END;
/

PROMPT [CAU 3.4] TEST TRIGGER TRG_UPDATE_GRADE_SUMMARY
SELECT classid, so_sv, diem_tb, diem_cao_nhat, diem_thap_nhat, cap_nhat_luc
FROM class_grade_summary
WHERE classid IN (1001, 1002, 1006, 1007, 1008, 1901)
ORDER BY classid;

PROMPT [CAU 4.1A] TEST VW_INSTRUCTOR_WORKLOAD
SELECT instructorid, ho_ten, so_lop, tong_sv, diem_tb_chung, muc_ban
FROM vw_instructor_workload
ORDER BY so_lop DESC, instructorid;

PROMPT [CAU 4.1B] TEST PROCEDURE PRINT_SYSTEM_REPORT
BEGIN
    print_system_report;
END;
/

SPOOL OFF
EXIT
