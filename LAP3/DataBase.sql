SET FEEDBACK ON
SET SERVEROUTPUT ON
SET LINESIZE 220
SET PAGESIZE 200
SET DEFINE OFF

ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY HH24:MI:SS';

CONNECT XUANTINH/XUANTINH
SHOW USER

CREATE TABLE course (
    courseno       NUMBER(8, 0)    CONSTRAINT pk_course PRIMARY KEY,
    description    VARCHAR2(50),
    cost           NUMBER(9, 2),
    prerequisite   NUMBER(8, 0),
    created_by     VARCHAR2(30)    NOT NULL,
    created_date   DATE            NOT NULL,
    modified_by    VARCHAR2(30)    NOT NULL,
    modified_date  DATE            NOT NULL,
    CONSTRAINT fk_course_prerequisite FOREIGN KEY (prerequisite) REFERENCES course (courseno)
);

CREATE TABLE instructor (
    instructorid   NUMBER(8, 0)    CONSTRAINT pk_instructor PRIMARY KEY,
    salutation     VARCHAR2(5),
    firstname      VARCHAR2(25),
    lastname       VARCHAR2(25),
    address        VARCHAR2(50),
    phone          VARCHAR2(15),
    created_by     VARCHAR2(30)    NOT NULL,
    created_date   DATE            NOT NULL,
    modified_by    VARCHAR2(30)    NOT NULL,
    modified_date  DATE            NOT NULL
);

CREATE TABLE student (
    studentid          NUMBER(8, 0)    CONSTRAINT pk_student PRIMARY KEY,
    salutation         VARCHAR2(5),
    firstname          VARCHAR2(25),
    lastname           VARCHAR2(25)    NOT NULL,
    address            VARCHAR2(50),
    phone              VARCHAR2(15),
    employer           VARCHAR2(50),
    registrationdate   DATE            NOT NULL,
    created_by         VARCHAR2(30)    NOT NULL,
    created_date       DATE            NOT NULL,
    modified_by        VARCHAR2(30)    NOT NULL,
    modified_date      DATE            NOT NULL
);

CREATE TABLE class (
    classid         NUMBER(8, 0)    CONSTRAINT pk_class PRIMARY KEY,
    courseno        NUMBER(8, 0)    NOT NULL,
    classno         NUMBER(3, 0)    NOT NULL,
    startdatetime   DATE,
    location        VARCHAR2(50),
    instructorid    NUMBER(8, 0)    NOT NULL,
    capacity        NUMBER(3, 0),
    created_by      VARCHAR2(30)    NOT NULL,
    created_date    DATE            NOT NULL,
    modified_by     VARCHAR2(30)    NOT NULL,
    modified_date   DATE            NOT NULL,
    CONSTRAINT fk_class_course FOREIGN KEY (courseno) REFERENCES course (courseno),
    CONSTRAINT fk_class_instructor FOREIGN KEY (instructorid) REFERENCES instructor (instructorid)
);

CREATE TABLE enrollment (
    studentid       NUMBER(8, 0)    NOT NULL,
    classid         NUMBER(8, 0)    NOT NULL,
    enrolldate      DATE            NOT NULL,
    finalgrade      NUMBER(3, 0),
    created_by      VARCHAR2(30)    NOT NULL,
    created_date    DATE            NOT NULL,
    modified_by     VARCHAR2(30)    NOT NULL,
    modified_date   DATE            NOT NULL,
    CONSTRAINT pk_enrollment PRIMARY KEY (studentid, classid),
    CONSTRAINT fk_enrollment_student FOREIGN KEY (studentid) REFERENCES student (studentid),
    CONSTRAINT fk_enrollment_class FOREIGN KEY (classid) REFERENCES class (classid)
);

CREATE TABLE grade (
    studentid       NUMBER(8, 0)    NOT NULL,
    classid         NUMBER(8, 0)    NOT NULL,
    grade           NUMBER(3, 0)    NOT NULL,
    comments        VARCHAR2(2000),
    created_by      VARCHAR2(30)    NOT NULL,
    created_date    DATE            NOT NULL,
    modified_by     VARCHAR2(30)    NOT NULL,
    modified_date   DATE            NOT NULL,
    CONSTRAINT pk_grade PRIMARY KEY (studentid, classid),
    CONSTRAINT fk_grade_enrollment FOREIGN KEY (studentid, classid) REFERENCES enrollment (studentid, classid)
);

INSERT INTO course (courseno, description, cost, prerequisite, created_by, created_date, modified_by, modified_date)
VALUES (10, 'DP Overview', 300, NULL, USER, SYSDATE, USER, SYSDATE);

INSERT INTO course (courseno, description, cost, prerequisite, created_by, created_date, modified_by, modified_date)
VALUES (20, 'Intro to Computers', 500, NULL, USER, SYSDATE, USER, SYSDATE);

INSERT INTO course (courseno, description, cost, prerequisite, created_by, created_date, modified_by, modified_date)
VALUES (30, 'PLSQL Basics', 700, 20, USER, SYSDATE, USER, SYSDATE);

INSERT INTO course (courseno, description, cost, prerequisite, created_by, created_date, modified_by, modified_date)
VALUES (40, 'Advanced SQL', 650, 20, USER, SYSDATE, USER, SYSDATE);

INSERT INTO course (courseno, description, cost, prerequisite, created_by, created_date, modified_by, modified_date)
VALUES (50, 'Data Warehousing', 800, 40, USER, SYSDATE, USER, SYSDATE);

INSERT INTO instructor (instructorid, salutation, firstname, lastname, address, phone, created_by, created_date, modified_by, modified_date)
VALUES (1, 'Mr', 'An', 'Nguyen', 'District 1', '0901000001', USER, SYSDATE, USER, SYSDATE);

INSERT INTO instructor (instructorid, salutation, firstname, lastname, address, phone, created_by, created_date, modified_by, modified_date)
VALUES (2, 'Mr', 'Binh', 'Tran', 'District 3', '0901000002', USER, SYSDATE, USER, SYSDATE);

INSERT INTO instructor (instructorid, salutation, firstname, lastname, address, phone, created_by, created_date, modified_by, modified_date)
VALUES (3, 'Ms', 'Chi', 'Le', 'District 5', '0901000003', USER, SYSDATE, USER, SYSDATE);

INSERT INTO instructor (instructorid, salutation, firstname, lastname, address, phone, created_by, created_date, modified_by, modified_date)
VALUES (4, 'Mr', 'Dung', 'Pham', 'District 7', '0901000004', USER, SYSDATE, USER, SYSDATE);

INSERT INTO class (classid, courseno, classno, startdatetime, location, instructorid, capacity, created_by, created_date, modified_by, modified_date)
VALUES (1001, 10, 2, TO_DATE('10/04/2026 08:00', 'DD/MM/YYYY HH24:MI'), 'R101', 1, 40, USER, SYSDATE, USER, SYSDATE);

INSERT INTO class (classid, courseno, classno, startdatetime, location, instructorid, capacity, created_by, created_date, modified_by, modified_date)
VALUES (1002, 20, 2, TO_DATE('11/04/2026 08:00', 'DD/MM/YYYY HH24:MI'), 'R102', 1, 40, USER, SYSDATE, USER, SYSDATE);

INSERT INTO class (classid, courseno, classno, startdatetime, location, instructorid, capacity, created_by, created_date, modified_by, modified_date)
VALUES (1003, 20, 4, TO_DATE('11/04/2026 13:30', 'DD/MM/YYYY HH24:MI'), 'R103', 2, 40, USER, SYSDATE, USER, SYSDATE);

INSERT INTO class (classid, courseno, classno, startdatetime, location, instructorid, capacity, created_by, created_date, modified_by, modified_date)
VALUES (1004, 30, 1, TO_DATE('12/04/2026 08:00', 'DD/MM/YYYY HH24:MI'), 'R201', 2, 35, USER, SYSDATE, USER, SYSDATE);

INSERT INTO class (classid, courseno, classno, startdatetime, location, instructorid, capacity, created_by, created_date, modified_by, modified_date)
VALUES (1005, 30, 2, TO_DATE('12/04/2026 13:30', 'DD/MM/YYYY HH24:MI'), 'R202', 3, 35, USER, SYSDATE, USER, SYSDATE);

INSERT INTO class (classid, courseno, classno, startdatetime, location, instructorid, capacity, created_by, created_date, modified_by, modified_date)
VALUES (1006, 40, 1, TO_DATE('13/04/2026 08:00', 'DD/MM/YYYY HH24:MI'), 'R301', 2, 30, USER, SYSDATE, USER, SYSDATE);

INSERT INTO class (classid, courseno, classno, startdatetime, location, instructorid, capacity, created_by, created_date, modified_by, modified_date)
VALUES (1007, 50, 1, TO_DATE('13/04/2026 13:30', 'DD/MM/YYYY HH24:MI'), 'R302', 4, 30, USER, SYSDATE, USER, SYSDATE);

INSERT INTO class (classid, courseno, classno, startdatetime, location, instructorid, capacity, created_by, created_date, modified_by, modified_date)
VALUES (1008, 40, 2, TO_DATE('14/04/2026 08:00', 'DD/MM/YYYY HH24:MI'), 'R303', 1, 30, USER, SYSDATE, USER, SYSDATE);

INSERT INTO student (studentid, salutation, firstname, lastname, address, phone, employer, registrationdate, created_by, created_date, modified_by, modified_date)
VALUES (101, 'Mr', 'An', 'Nguyen', 'Thu Duc', '0902000101', NULL, TO_DATE('01/03/2026', 'DD/MM/YYYY'), USER, SYSDATE, USER, SYSDATE);
INSERT INTO student VALUES (102, 'Mr', 'Binh', 'Tran', 'Binh Thanh', '0902000102', NULL, TO_DATE('01/03/2026', 'DD/MM/YYYY'), USER, SYSDATE, USER, SYSDATE);
INSERT INTO student VALUES (103, 'Ms', 'Chau', 'Le', 'Go Vap', '0902000103', NULL, TO_DATE('01/03/2026', 'DD/MM/YYYY'), USER, SYSDATE, USER, SYSDATE);
INSERT INTO student VALUES (104, 'Mr', 'Dung', 'Pham', 'Phu Nhuan', '0902000104', NULL, TO_DATE('01/03/2026', 'DD/MM/YYYY'), USER, SYSDATE, USER, SYSDATE);
INSERT INTO student VALUES (105, 'Ms', 'Giang', 'Hoang', 'District 7', '0902000105', NULL, TO_DATE('02/03/2026', 'DD/MM/YYYY'), USER, SYSDATE, USER, SYSDATE);
INSERT INTO student VALUES (106, 'Mr', 'Hieu', 'Vu', 'District 10', '0902000106', NULL, TO_DATE('02/03/2026', 'DD/MM/YYYY'), USER, SYSDATE, USER, SYSDATE);
INSERT INTO student VALUES (107, 'Mr', 'Khoa', 'Doan', 'District 5', '0902000107', NULL, TO_DATE('02/03/2026', 'DD/MM/YYYY'), USER, SYSDATE, USER, SYSDATE);
INSERT INTO student VALUES (108, 'Ms', 'Lan', 'Bui', 'District 3', '0902000108', NULL, TO_DATE('03/03/2026', 'DD/MM/YYYY'), USER, SYSDATE, USER, SYSDATE);
INSERT INTO student VALUES (109, 'Mr', 'Minh', 'Dang', 'District 1', '0902000109', NULL, TO_DATE('03/03/2026', 'DD/MM/YYYY'), USER, SYSDATE, USER, SYSDATE);
INSERT INTO student VALUES (110, 'Mr', 'Nam', 'Phan', 'District 4', '0902000110', NULL, TO_DATE('03/03/2026', 'DD/MM/YYYY'), USER, SYSDATE, USER, SYSDATE);
INSERT INTO student VALUES (111, 'Ms', 'Oanh', 'Truong', 'District 2', '0902000111', NULL, TO_DATE('04/03/2026', 'DD/MM/YYYY'), USER, SYSDATE, USER, SYSDATE);
INSERT INTO student VALUES (112, 'Mr', 'Phuc', 'Vo', 'District 12', '0902000112', NULL, TO_DATE('04/03/2026', 'DD/MM/YYYY'), USER, SYSDATE, USER, SYSDATE);
INSERT INTO student VALUES (113, 'Ms', 'Quynh', 'Duong', 'District 11', '0902000113', NULL, TO_DATE('04/03/2026', 'DD/MM/YYYY'), USER, SYSDATE, USER, SYSDATE);
INSERT INTO student VALUES (114, 'Mr', 'Son', 'Ngo', 'District 6', '0902000114', NULL, TO_DATE('05/03/2026', 'DD/MM/YYYY'), USER, SYSDATE, USER, SYSDATE);
INSERT INTO student VALUES (115, 'Mr', 'Tien', 'Huynh', 'District 8', '0902000115', NULL, TO_DATE('05/03/2026', 'DD/MM/YYYY'), USER, SYSDATE, USER, SYSDATE);
INSERT INTO student VALUES (116, 'Ms', 'Uyen', 'Cao', 'District 9', '0902000116', NULL, TO_DATE('05/03/2026', 'DD/MM/YYYY'), USER, SYSDATE, USER, SYSDATE);
INSERT INTO student VALUES (117, 'Mr', 'Van', 'Mai', 'District 7', '0902000117', NULL, TO_DATE('06/03/2026', 'DD/MM/YYYY'), USER, SYSDATE, USER, SYSDATE);
INSERT INTO student VALUES (118, 'Ms', 'Xuan', 'Dinh', 'District 3', '0902000118', NULL, TO_DATE('06/03/2026', 'DD/MM/YYYY'), USER, SYSDATE, USER, SYSDATE);
INSERT INTO student VALUES (119, 'Ms', 'Yen', 'Lam', 'District 1', '0902000119', NULL, TO_DATE('06/03/2026', 'DD/MM/YYYY'), USER, SYSDATE, USER, SYSDATE);
INSERT INTO student VALUES (120, 'Mr', 'Zed', 'Ta', 'District 4', '0902000120', NULL, TO_DATE('07/03/2026', 'DD/MM/YYYY'), USER, SYSDATE, USER, SYSDATE);
INSERT INTO student VALUES (121, 'Mr', 'Bao', 'Pham', 'Thu Duc', '0902000121', NULL, TO_DATE('07/03/2026', 'DD/MM/YYYY'), USER, SYSDATE, USER, SYSDATE);
INSERT INTO student VALUES (122, 'Mr', 'Cuong', 'Le', 'Thu Duc', '0902000122', NULL, TO_DATE('07/03/2026', 'DD/MM/YYYY'), USER, SYSDATE, USER, SYSDATE);
INSERT INTO student VALUES (123, 'Ms', 'Diep', 'Tran', 'Thu Duc', '0902000123', NULL, TO_DATE('08/03/2026', 'DD/MM/YYYY'), USER, SYSDATE, USER, SYSDATE);
INSERT INTO student VALUES (124, 'Mr', 'Em', 'Nguyen', 'Go Vap', '0902000124', NULL, TO_DATE('08/03/2026', 'DD/MM/YYYY'), USER, SYSDATE, USER, SYSDATE);
INSERT INTO student VALUES (125, 'Ms', 'Hoa', 'Do', 'Go Vap', '0902000125', NULL, TO_DATE('08/03/2026', 'DD/MM/YYYY'), USER, SYSDATE, USER, SYSDATE);
INSERT INTO student VALUES (126, 'Mr', 'Khanh', 'Bui', 'Go Vap', '0902000126', NULL, TO_DATE('09/03/2026', 'DD/MM/YYYY'), USER, SYSDATE, USER, SYSDATE);

INSERT INTO enrollment VALUES (101, 1001, SYSDATE, 85, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (102, 1001, SYSDATE, 78, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (103, 1001, SYSDATE, 92, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (104, 1001, SYSDATE, 88, USER, SYSDATE, USER, SYSDATE);

INSERT INTO enrollment VALUES (101, 1002, SYSDATE, 91, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (102, 1002, SYSDATE, 83, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (103, 1002, SYSDATE, 75, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (104, 1002, SYSDATE, 68, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (105, 1002, SYSDATE, 80, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (106, 1002, SYSDATE, 77, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (107, 1002, SYSDATE, 89, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (108, 1002, SYSDATE, 94, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (109, 1002, SYSDATE, 73, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (110, 1002, SYSDATE, 66, USER, SYSDATE, USER, SYSDATE);

INSERT INTO enrollment VALUES (111, 1003, SYSDATE, 82, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (112, 1003, SYSDATE, 79, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (113, 1003, SYSDATE, 95, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (114, 1003, SYSDATE, 87, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (115, 1003, SYSDATE, 70, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (116, 1003, SYSDATE, 65, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (117, 1003, SYSDATE, 90, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (118, 1003, SYSDATE, 76, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (119, 1003, SYSDATE, 84, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (120, 1003, SYSDATE, 88, USER, SYSDATE, USER, SYSDATE);

INSERT INTO enrollment VALUES (101, 1004, SYSDATE, 86, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (102, 1004, SYSDATE, 72, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (103, 1004, SYSDATE, 69, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (111, 1004, SYSDATE, 74, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (112, 1004, SYSDATE, 81, USER, SYSDATE, USER, SYSDATE);

INSERT INTO enrollment VALUES (121, 1005, SYSDATE, 78, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (122, 1005, SYSDATE, 91, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (123, 1005, SYSDATE, 67, USER, SYSDATE, USER, SYSDATE);

INSERT INTO enrollment VALUES (104, 1006, SYSDATE, 90, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (105, 1006, SYSDATE, 85, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (106, 1006, SYSDATE, 73, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (107, 1006, SYSDATE, 79, USER, SYSDATE, USER, SYSDATE);

INSERT INTO enrollment VALUES (108, 1007, SYSDATE, 88, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (109, 1007, SYSDATE, 92, USER, SYSDATE, USER, SYSDATE);

INSERT INTO enrollment VALUES (124, 1008, SYSDATE, 80, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (125, 1008, SYSDATE, 71, USER, SYSDATE, USER, SYSDATE);
INSERT INTO enrollment VALUES (126, 1008, SYSDATE, 83, USER, SYSDATE, USER, SYSDATE);

INSERT INTO grade VALUES (101, 1002, 91, 'Good', USER, SYSDATE, USER, SYSDATE);
INSERT INTO grade VALUES (102, 1002, 83, 'Stable', USER, SYSDATE, USER, SYSDATE);
INSERT INTO grade VALUES (103, 1002, 75, 'Need more practice', USER, SYSDATE, USER, SYSDATE);
INSERT INTO grade VALUES (104, 1002, 68, 'Improve SQL basics', USER, SYSDATE, USER, SYSDATE);
INSERT INTO grade VALUES (105, 1002, 80, 'Solid', USER, SYSDATE, USER, SYSDATE);
INSERT INTO grade VALUES (111, 1003, 82, 'Good', USER, SYSDATE, USER, SYSDATE);
INSERT INTO grade VALUES (112, 1003, 79, 'Close to B', USER, SYSDATE, USER, SYSDATE);
INSERT INTO grade VALUES (113, 1003, 95, 'Excellent', USER, SYSDATE, USER, SYSDATE);
INSERT INTO grade VALUES (114, 1003, 87, 'Very good', USER, SYSDATE, USER, SYSDATE);
INSERT INTO grade VALUES (115, 1003, 70, 'Pass', USER, SYSDATE, USER, SYSDATE);

COMMIT;

SELECT COUNT(*) AS total_course FROM course;
SELECT COUNT(*) AS total_class FROM class;
SELECT COUNT(*) AS total_student FROM student;
SELECT COUNT(*) AS total_enrollment FROM enrollment;
SELECT COUNT(*) AS total_instructor FROM instructor;
SELECT COUNT(*) AS total_grade FROM grade;
