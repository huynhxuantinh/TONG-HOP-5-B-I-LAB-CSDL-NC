SET ECHO ON
SET FEEDBACK ON
SET DEFINE OFF
SET SERVEROUTPUT ON
SET LINESIZE 200
SET PAGESIZE 100


CONNECT / AS SYSDBA
ALTER USER XUANTINH IDENTIFIED BY XUANTINH ACCOUNT UNLOCK;
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE, CREATE TRIGGER, UNLIMITED TABLESPACE TO XUANTINH;
CONNECT XUANTINH/XUANTINH
SHOW USER

CREATE TABLE s_region (
    id      NUMBER(7)      CONSTRAINT pk_s_region PRIMARY KEY,
    name    VARCHAR2(50)   NOT NULL
);

CREATE TABLE s_warehouse (
    id          NUMBER(7)      CONSTRAINT pk_s_warehouse PRIMARY KEY,
    region_id   NUMBER(7)      NOT NULL,
    address     VARCHAR2(120),
    city        VARCHAR2(60),
    state       VARCHAR2(60),
    country     VARCHAR2(60),
    zip_code    VARCHAR2(12),
    phone       VARCHAR2(30),
    manager_id  NUMBER(7),
    CONSTRAINT fk_s_warehouse_region FOREIGN KEY (region_id) REFERENCES s_region(id)
);

CREATE TABLE s_title (
    title   VARCHAR2(50) CONSTRAINT pk_s_title PRIMARY KEY
);

CREATE TABLE s_dept (
    id          NUMBER(7)      CONSTRAINT pk_s_dept PRIMARY KEY,
    name        VARCHAR2(60)   NOT NULL,
    region_id   NUMBER(7)      NOT NULL,
    CONSTRAINT fk_s_dept_region FOREIGN KEY (region_id) REFERENCES s_region(id)
);

CREATE TABLE s_emp (
    id              NUMBER(7)       CONSTRAINT pk_s_emp PRIMARY KEY,
    last_name       VARCHAR2(30)    NOT NULL,
    first_name      VARCHAR2(30)    NOT NULL,
    userid          VARCHAR2(20)    NOT NULL,
    start_date      DATE            NOT NULL,
    comments        VARCHAR2(200),
    manager_id      NUMBER(7),
    title           VARCHAR2(50),
    dept_id         NUMBER(7),
    salary          NUMBER(11,2),
    commission_pct  NUMBER(5,2),
    CONSTRAINT uq_s_emp_userid UNIQUE (userid),
    CONSTRAINT fk_s_emp_manager FOREIGN KEY (manager_id) REFERENCES s_emp(id),
    CONSTRAINT fk_s_emp_title FOREIGN KEY (title) REFERENCES s_title(title),
    CONSTRAINT fk_s_emp_dept FOREIGN KEY (dept_id) REFERENCES s_dept(id)
);

ALTER TABLE s_warehouse
    ADD CONSTRAINT fk_s_warehouse_manager FOREIGN KEY (manager_id) REFERENCES s_emp(id);

CREATE TABLE s_customer (
    id              NUMBER(7)      CONSTRAINT pk_s_customer PRIMARY KEY,
    name            VARCHAR2(100)  NOT NULL,
    phone           VARCHAR2(30),
    address         VARCHAR2(120),
    city            VARCHAR2(60),
    state           VARCHAR2(60),
    country         VARCHAR2(60),
    zip_code        VARCHAR2(12),
    credit_rating   VARCHAR2(20),
    sales_rep_id    NUMBER(7),
    region_id       NUMBER(7),
    comments        VARCHAR2(200),
    CONSTRAINT fk_s_customer_salesrep FOREIGN KEY (sales_rep_id) REFERENCES s_emp(id),
    CONSTRAINT fk_s_customer_region FOREIGN KEY (region_id) REFERENCES s_region(id)
);

CREATE TABLE s_image (
    id            NUMBER(7)       CONSTRAINT pk_s_image PRIMARY KEY,
    format        VARCHAR2(20),
    use_filename  CHAR(1)         CHECK (use_filename IN ('Y','N')),
    filename      VARCHAR2(255),
    image         BLOB
);

CREATE TABLE s_longtext (
    id            NUMBER(7)       CONSTRAINT pk_s_longtext PRIMARY KEY,
    use_filename  CHAR(1)         CHECK (use_filename IN ('Y','N')),
    filename      VARCHAR2(255),
    text          CLOB
);

CREATE TABLE s_product (
    id                      NUMBER(7)       CONSTRAINT pk_s_product PRIMARY KEY,
    name                    VARCHAR2(100)   NOT NULL,
    short_desc              VARCHAR2(200),
    longtext_id             NUMBER(7),
    image_id                NUMBER(7),
    suggested_whlsl_price   NUMBER(11,2),
    whlsl_units             VARCHAR2(30),
    CONSTRAINT fk_s_product_longtext FOREIGN KEY (longtext_id) REFERENCES s_longtext(id),
    CONSTRAINT fk_s_product_image FOREIGN KEY (image_id) REFERENCES s_image(id)
);

CREATE TABLE s_ord (
    id             NUMBER(10)      CONSTRAINT pk_s_ord PRIMARY KEY,
    customer_id    NUMBER(7)       NOT NULL,
    date_ordered   DATE            NOT NULL,
    date_shipped   DATE,
    sales_rep_id   NUMBER(7),
    total          NUMBER(11,2),
    payment_type   VARCHAR2(20),
    order_filled   CHAR(1)         CHECK (order_filled IN ('Y','N')),
    CONSTRAINT fk_s_ord_customer FOREIGN KEY (customer_id) REFERENCES s_customer(id),
    CONSTRAINT fk_s_ord_salesrep FOREIGN KEY (sales_rep_id) REFERENCES s_emp(id)
);

CREATE TABLE s_item (
    ord_id             NUMBER(10)   NOT NULL,
    item_id            NUMBER(5)    NOT NULL,
    product_id         NUMBER(7)    NOT NULL,
    price              NUMBER(11,2),
    quantity           NUMBER(9),
    quantity_shipped   NUMBER(9),
    CONSTRAINT pk_s_item PRIMARY KEY (ord_id, item_id),
    CONSTRAINT fk_s_item_ord FOREIGN KEY (ord_id) REFERENCES s_ord(id),
    CONSTRAINT fk_s_item_product FOREIGN KEY (product_id) REFERENCES s_product(id)
);

CREATE TABLE s_inventory (
    product_id                 NUMBER(7)   NOT NULL,
    warehouse_id               NUMBER(7)   NOT NULL,
    amount_in_stock            NUMBER(9),
    reorder_point              NUMBER(9),
    max_in_stock               NUMBER(9),
    out_of_stock_explanation   VARCHAR2(200),
    restock_date               DATE,
    CONSTRAINT pk_s_inventory PRIMARY KEY (product_id, warehouse_id),
    CONSTRAINT fk_s_inventory_product FOREIGN KEY (product_id) REFERENCES s_product(id),
    CONSTRAINT fk_s_inventory_warehouse FOREIGN KEY (warehouse_id) REFERENCES s_warehouse(id)
);

INSERT INTO s_region (id, name) VALUES (1, 'North America');
INSERT INTO s_region (id, name) VALUES (2, 'Europe');
INSERT INTO s_region (id, name) VALUES (3, 'Asia Pacific');

INSERT INTO s_title (title) VALUES ('President');
INSERT INTO s_title (title) VALUES ('VP Sales');
INSERT INTO s_title (title) VALUES ('Sales Representative');
INSERT INTO s_title (title) VALUES ('Warehouse Manager');
INSERT INTO s_title (title) VALUES ('Clerk');

INSERT INTO s_dept (id, name, region_id) VALUES (10, 'Head Office', 1);
INSERT INTO s_dept (id, name, region_id) VALUES (20, 'Sales East', 1);
INSERT INTO s_dept (id, name, region_id) VALUES (30, 'Sales Europe', 2);
INSERT INTO s_dept (id, name, region_id) VALUES (40, 'Sales APAC', 3);
INSERT INTO s_dept (id, name, region_id) VALUES (31, 'Sales Region 31', 2);
INSERT INTO s_dept (id, name, region_id) VALUES (42, 'Sales Region 42', 3);
INSERT INTO s_dept (id, name, region_id) VALUES (50, 'Sales Special', 1);

INSERT INTO s_emp (id, last_name, first_name, userid, start_date, comments, manager_id, title, dept_id, salary, commission_pct)
VALUES (1, 'Nguyen', 'An', 'NAN', DATE '2024-01-02', 'Top manager', NULL, 'President', 10, 20000, NULL);

INSERT INTO s_emp (id, last_name, first_name, userid, start_date, comments, manager_id, title, dept_id, salary, commission_pct)
VALUES (2, 'Tran', 'Binh', 'TBINH', DATE '2024-02-01', 'Manage sales team', 1, 'VP Sales', 10, 15000, NULL);

INSERT INTO s_emp (id, last_name, first_name, userid, start_date, comments, manager_id, title, dept_id, salary, commission_pct)
VALUES (3, 'Le', 'Chau', 'LCHAU', DATE '2024-03-01', 'Sales NA and APAC', 2, 'Sales Representative', 20, 8000, 0.10);

INSERT INTO s_emp (id, last_name, first_name, userid, start_date, comments, manager_id, title, dept_id, salary, commission_pct)
VALUES (4, 'Pham', 'Dung', 'PDUNG', DATE '2024-03-15', 'Sales EU market', 2, 'Sales Representative', 30, 7800, 0.12);

INSERT INTO s_emp (id, last_name, first_name, userid, start_date, comments, manager_id, title, dept_id, salary, commission_pct)
VALUES (5, 'Hoang', 'Giang', 'HGIANG', DATE '2024-04-01', 'Manage warehouse', 2, 'Warehouse Manager', 10, 7000, NULL);

INSERT INTO s_emp (id, last_name, first_name, userid, start_date, comments, manager_id, title, dept_id, salary, commission_pct)
VALUES (6, 'Santos', 'Son', 'SSON', DATE '1991-05-20', 'Data for TH2 conditions', 2, 'Sales Representative', 50, 1600, 0.05);

INSERT INTO s_emp (id, last_name, first_name, userid, start_date, comments, manager_id, title, dept_id, salary, commission_pct)
VALUES (7, 'Pham', 'Lan', 'PLAN', DATE '1991-05-14', 'Employee Lan for subquery practice', 2, 'Sales Representative', 50, 12000, 0.08);

INSERT INTO s_emp (id, last_name, first_name, userid, start_date, comments, manager_id, title, dept_id, salary, commission_pct)
VALUES (101, 'Nguyen', 'Minh', 'EMP01', DATE '2023-01-02', 'Staff data for group-function exercises', 2, 'Clerk', 20, 901, NULL);
INSERT INTO s_emp (id, last_name, first_name, userid, start_date, comments, manager_id, title, dept_id, salary, commission_pct)
VALUES (102, 'Tran', 'Hai', 'EMP02', DATE '2023-01-03', 'Staff data for group-function exercises', 2, 'Clerk', 20, 902, NULL);
INSERT INTO s_emp (id, last_name, first_name, userid, start_date, comments, manager_id, title, dept_id, salary, commission_pct)
VALUES (103, 'Le', 'Nam', 'EMP03', DATE '2023-01-04', 'Staff data for group-function exercises', 2, 'Clerk', 20, 903, NULL);
INSERT INTO s_emp (id, last_name, first_name, userid, start_date, comments, manager_id, title, dept_id, salary, commission_pct)
VALUES (104, 'Pham', 'Tuan', 'EMP04', DATE '2023-01-05', 'Staff data for group-function exercises', 2, 'Clerk', 20, 904, NULL);
INSERT INTO s_emp (id, last_name, first_name, userid, start_date, comments, manager_id, title, dept_id, salary, commission_pct)
VALUES (105, 'Hoang', 'Long', 'EMP05', DATE '2023-01-06', 'Staff data for group-function exercises', 2, 'Clerk', 20, 905, NULL);
INSERT INTO s_emp (id, last_name, first_name, userid, start_date, comments, manager_id, title, dept_id, salary, commission_pct)
VALUES (106, 'Vu', 'Hieu', 'EMP06', DATE '2023-01-07', 'Staff data for group-function exercises', 2, 'Clerk', 20, 906, NULL);
INSERT INTO s_emp (id, last_name, first_name, userid, start_date, comments, manager_id, title, dept_id, salary, commission_pct)
VALUES (107, 'Doan', 'Khoa', 'EMP07', DATE '2023-01-08', 'Staff data for group-function exercises', 2, 'Clerk', 20, 907, NULL);
INSERT INTO s_emp (id, last_name, first_name, userid, start_date, comments, manager_id, title, dept_id, salary, commission_pct)
VALUES (108, 'Bui', 'Quang', 'EMP08', DATE '2023-01-09', 'Staff data for group-function exercises', 2, 'Clerk', 20, 908, NULL);
INSERT INTO s_emp (id, last_name, first_name, userid, start_date, comments, manager_id, title, dept_id, salary, commission_pct)
VALUES (109, 'Dang', 'Duc', 'EMP09', DATE '2023-01-10', 'Staff data for group-function exercises', 2, 'Clerk', 20, 909, NULL);
INSERT INTO s_emp (id, last_name, first_name, userid, start_date, comments, manager_id, title, dept_id, salary, commission_pct)
VALUES (110, 'Phan', 'An', 'EMP10', DATE '2023-01-11', 'Staff data for group-function exercises', 2, 'Clerk', 20, 910, NULL);
INSERT INTO s_emp (id, last_name, first_name, userid, start_date, comments, manager_id, title, dept_id, salary, commission_pct)
VALUES (111, 'Truong', 'Thanh', 'EMP11', DATE '2023-01-12', 'Staff data for group-function exercises', 2, 'Clerk', 20, 911, NULL);
INSERT INTO s_emp (id, last_name, first_name, userid, start_date, comments, manager_id, title, dept_id, salary, commission_pct)
VALUES (112, 'Vo', 'Nhat', 'EMP12', DATE '2023-01-13', 'Staff data for group-function exercises', 2, 'Clerk', 20, 912, NULL);
INSERT INTO s_emp (id, last_name, first_name, userid, start_date, comments, manager_id, title, dept_id, salary, commission_pct)
VALUES (113, 'Duong', 'Viet', 'EMP13', DATE '2023-01-14', 'Staff data for group-function exercises', 2, 'Clerk', 20, 913, NULL);
INSERT INTO s_emp (id, last_name, first_name, userid, start_date, comments, manager_id, title, dept_id, salary, commission_pct)
VALUES (114, 'Ngo', 'Bao', 'EMP14', DATE '2023-01-15', 'Staff data for group-function exercises', 2, 'Clerk', 20, 914, NULL);
INSERT INTO s_emp (id, last_name, first_name, userid, start_date, comments, manager_id, title, dept_id, salary, commission_pct)
VALUES (115, 'Huynh', 'Tien', 'EMP15', DATE '2023-01-16', 'Staff data for group-function exercises', 2, 'Clerk', 20, 915, NULL);
INSERT INTO s_emp (id, last_name, first_name, userid, start_date, comments, manager_id, title, dept_id, salary, commission_pct)
VALUES (116, 'Cao', 'Quoc', 'EMP16', DATE '2023-01-17', 'Staff data for group-function exercises', 2, 'Clerk', 20, 916, NULL);
INSERT INTO s_emp (id, last_name, first_name, userid, start_date, comments, manager_id, title, dept_id, salary, commission_pct)
VALUES (117, 'Mai', 'Khai', 'EMP17', DATE '2023-01-18', 'Staff data for group-function exercises', 2, 'Clerk', 20, 917, NULL);
INSERT INTO s_emp (id, last_name, first_name, userid, start_date, comments, manager_id, title, dept_id, salary, commission_pct)
VALUES (118, 'Dinh', 'Gia', 'EMP18', DATE '2023-01-19', 'Staff data for group-function exercises', 2, 'Clerk', 20, 918, NULL);
INSERT INTO s_emp (id, last_name, first_name, userid, start_date, comments, manager_id, title, dept_id, salary, commission_pct)
VALUES (119, 'Lam', 'Van', 'EMP19', DATE '2023-01-20', 'Staff data for group-function exercises', 2, 'Clerk', 20, 919, NULL);
INSERT INTO s_emp (id, last_name, first_name, userid, start_date, comments, manager_id, title, dept_id, salary, commission_pct)
VALUES (120, 'Ta', 'Hung', 'EMP20', DATE '2023-01-21', 'Staff data for group-function exercises', 2, 'Clerk', 20, 920, NULL);

INSERT INTO s_warehouse (id, region_id, address, city, state, country, zip_code, phone, manager_id)
VALUES (101, 1, '100 Main St', 'New York', 'NY', 'USA', '10001', '+1-212-100-1000', 5);

INSERT INTO s_warehouse (id, region_id, address, city, state, country, zip_code, phone, manager_id)
VALUES (102, 2, '25 Oxford Rd', 'London', 'London', 'UK', 'SW1A', '+44-20-2000-2000', 5);

INSERT INTO s_warehouse (id, region_id, address, city, state, country, zip_code, phone, manager_id)
VALUES (103, 3, '12 Nguyen Hue', 'Ho Chi Minh City', 'HCM', 'Vietnam', '700000', '+84-28-3000-3000', 5);

INSERT INTO s_customer (id, name, phone, address, city, state, country, zip_code, credit_rating, sales_rep_id, region_id, comments)
VALUES (1001, 'ABC Retail', '+1-555-1001', '15 Market St', 'Boston', 'MA', 'USA', '02108', 'GOOD', 3, 1, 'Priority customer');

INSERT INTO s_customer (id, name, phone, address, city, state, country, zip_code, credit_rating, sales_rep_id, region_id, comments)
VALUES (1002, 'Euro Shop', '+44-555-1002', '89 King St', 'Manchester', 'Manchester', 'UK', 'M1', 'GOOD', 4, 2, 'Needs invoice by email');

INSERT INTO s_customer (id, name, phone, address, city, state, country, zip_code, credit_rating, sales_rep_id, region_id, comments)
VALUES (1003, 'Saigon Mart', '+84-28-555-1003', '1 Le Loi', 'Ho Chi Minh City', 'HCM', 'Vietnam', '700000', 'EXCELLENT', 3, 3, 'Fast delivery required');

INSERT INTO s_customer (id, name, phone, address, city, state, country, zip_code, credit_rating, sales_rep_id, region_id, comments)
VALUES (1004, 'No Order Customer', '+84-28-555-1004', '2 Tran Hung Dao', 'Da Nang', 'DN', 'Vietnam', '550000', 'AVERAGE', 7, 3, 'Customer without order for practice');

INSERT INTO s_longtext (id, use_filename, filename, text)
VALUES (201, 'Y', 'p1001.txt', 'Laptop 14 inch, 16GB RAM, 512GB SSD');

INSERT INTO s_longtext (id, use_filename, filename, text)
VALUES (202, 'N', NULL, 'Wireless mouse with rechargeable battery');

INSERT INTO s_longtext (id, use_filename, filename, text)
VALUES (203, 'N', NULL, 'Mechanical keyboard, blue switch');

INSERT INTO s_longtext (id, use_filename, filename, text)
VALUES (204, 'N', NULL, 'Pro ski bicycle combo package');

INSERT INTO s_image (id, format, use_filename, filename, image)
VALUES (301, 'JPG', 'Y', 'laptop.jpg', EMPTY_BLOB());

INSERT INTO s_image (id, format, use_filename, filename, image)
VALUES (302, 'PNG', 'Y', 'mouse.png', EMPTY_BLOB());

INSERT INTO s_image (id, format, use_filename, filename, image)
VALUES (303, 'PNG', 'Y', 'keyboard.png', EMPTY_BLOB());

INSERT INTO s_image (id, format, use_filename, filename, image)
VALUES (304, 'PNG', 'Y', 'ski_combo.png', EMPTY_BLOB());

INSERT INTO s_product (id, name, short_desc, longtext_id, image_id, suggested_whlsl_price, whlsl_units)
VALUES (10001, 'Pro Laptop 14', 'Laptop for office work', 201, 301, 950, 'Piece');

INSERT INTO s_product (id, name, short_desc, longtext_id, image_id, suggested_whlsl_price, whlsl_units)
VALUES (10002, 'Mouse Air', 'Bluetooth wireless mouse', 202, 302, 25, 'Piece');

INSERT INTO s_product (id, name, short_desc, longtext_id, image_id, suggested_whlsl_price, whlsl_units)
VALUES (10003, 'Keyboard K1', 'Bicycle accessory kit', 203, 303, 55, 'Piece');

INSERT INTO s_product (id, name, short_desc, longtext_id, image_id, suggested_whlsl_price, whlsl_units)
VALUES (10004, 'Pro Ski Combo', 'Ski bicycle combo set', 204, 304, 500, 'Set');

INSERT INTO s_ord (id, customer_id, date_ordered, date_shipped, sales_rep_id, total, payment_type, order_filled)
VALUES (5001, 1001, DATE '2026-03-25', DATE '2026-03-27', 3, 1950, 'CREDIT', 'Y');

INSERT INTO s_ord (id, customer_id, date_ordered, date_shipped, sales_rep_id, total, payment_type, order_filled)
VALUES (5002, 1002, DATE '2026-03-28', NULL, 4, 1100, 'BANK', 'N');

INSERT INTO s_ord (id, customer_id, date_ordered, date_shipped, sales_rep_id, total, payment_type, order_filled)
VALUES (5003, 1003, DATE '2026-03-29', DATE '2026-03-30', 3, 135, 'CASH', 'Y');

INSERT INTO s_ord (id, customer_id, date_ordered, date_shipped, sales_rep_id, total, payment_type, order_filled)
VALUES (101, 1002, DATE '2026-03-20', DATE '2026-03-22', 4, 150000, 'BANK', 'Y');

INSERT INTO s_item (ord_id, item_id, product_id, price, quantity, quantity_shipped)
VALUES (5001, 1, 10001, 950, 2, 2);

INSERT INTO s_item (ord_id, item_id, product_id, price, quantity, quantity_shipped)
VALUES (5001, 2, 10002, 25, 2, 2);

INSERT INTO s_item (ord_id, item_id, product_id, price, quantity, quantity_shipped)
VALUES (5002, 1, 10001, 950, 1, 0);

INSERT INTO s_item (ord_id, item_id, product_id, price, quantity, quantity_shipped)
VALUES (5002, 2, 10003, 75, 2, 0);

INSERT INTO s_item (ord_id, item_id, product_id, price, quantity, quantity_shipped)
VALUES (5003, 1, 10002, 25, 3, 3);

INSERT INTO s_item (ord_id, item_id, product_id, price, quantity, quantity_shipped)
VALUES (5003, 2, 10003, 60, 1, 1);

INSERT INTO s_item (ord_id, item_id, product_id, price, quantity, quantity_shipped)
VALUES (101, 1, 10001, 1000, 100, 100);

INSERT INTO s_item (ord_id, item_id, product_id, price, quantity, quantity_shipped)
VALUES (101, 2, 10004, 500, 100, 100);

INSERT INTO s_inventory (product_id, warehouse_id, amount_in_stock, reorder_point, max_in_stock, out_of_stock_explanation, restock_date)
VALUES (10001, 101, 40, 10, 100, NULL, DATE '2026-04-15');

INSERT INTO s_inventory (product_id, warehouse_id, amount_in_stock, reorder_point, max_in_stock, out_of_stock_explanation, restock_date)
VALUES (10002, 101, 300, 80, 500, NULL, DATE '2026-04-10');

INSERT INTO s_inventory (product_id, warehouse_id, amount_in_stock, reorder_point, max_in_stock, out_of_stock_explanation, restock_date)
VALUES (10003, 102, 120, 30, 300, NULL, DATE '2026-04-12');

INSERT INTO s_inventory (product_id, warehouse_id, amount_in_stock, reorder_point, max_in_stock, out_of_stock_explanation, restock_date)
VALUES (10003, 103, 50, 20, 200, 'Import delay', DATE '2026-04-20');

INSERT INTO s_inventory (product_id, warehouse_id, amount_in_stock, reorder_point, max_in_stock, out_of_stock_explanation, restock_date)
VALUES (10004, 101, 20, 5, 80, NULL, DATE '2026-04-25');

COMMIT;

SHOW USER
SELECT table_name FROM user_tables ORDER BY 1;

SELECT 's_region' table_name, COUNT(*) total_rows FROM s_region
UNION ALL SELECT 's_warehouse', COUNT(*) FROM s_warehouse
UNION ALL SELECT 's_title', COUNT(*) FROM s_title
UNION ALL SELECT 's_dept', COUNT(*) FROM s_dept
UNION ALL SELECT 's_emp', COUNT(*) FROM s_emp
UNION ALL SELECT 's_customer', COUNT(*) FROM s_customer
UNION ALL SELECT 's_image', COUNT(*) FROM s_image
UNION ALL SELECT 's_longtext', COUNT(*) FROM s_longtext
UNION ALL SELECT 's_product', COUNT(*) FROM s_product
UNION ALL SELECT 's_ord', COUNT(*) FROM s_ord
UNION ALL SELECT 's_item', COUNT(*) FROM s_item
UNION ALL SELECT 's_inventory', COUNT(*) FROM s_inventory
ORDER BY 1;

-- 2) HIEN THI USER HIEN HANH
SHOW USER

-- 3) HIEN THI CAC TABLE CUA MOT USER
SELECT table_name FROM all_tables WHERE owner = 'XUANTINH' ORDER BY table_name;

-- 4) HIEN THI CAU TRUC CUA MOT TABLE
DESC s_region;

-- 5) MOT SO LENH THUONG DUNG TRONG SQL*PLUS
PROMPT set pagesize 100
PROMPT set linesize 200
PROMPT spool output_th1.txt
PROMPT spool off
