SET PAGESIZE 100
SET LINESIZE 220
SET FEEDBACK ON
SET DEFINE OFF

ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MON-YYYY';

CONNECT XUANTINH/XUANTINH
SHOW USER

-- 1) Ma nhan vien, ten va muc luong tang them 15%
SELECT id AS emp_id,
       first_name || ' ' || last_name AS emp_name,
       salary AS current_salary,
       ROUND(salary * 1.15, 2) AS salary_plus_15pct
FROM s_emp
ORDER BY id;

-- 2) Ten, ngay tuyen dung, ngay xem xet tang luong:
-- Ngay thu hai sau 6 thang lam viec.
-- Dinh dang: "Eighth of May 1992"
SELECT first_name || ' ' || last_name AS emp_name,
       start_date AS hire_date,
       INITCAP(TO_CHAR(NEXT_DAY(ADD_MONTHS(start_date, 6), 'MONDAY'), 'fmDDSPTH')) ||
       ' of ' ||
       TO_CHAR(NEXT_DAY(ADD_MONTHS(start_date, 6), 'MONDAY'), 'fmMonth YYYY') AS review_date
FROM s_emp
ORDER BY id;

-- 3) Ten san pham co chu "ski"
SELECT id,
       name
FROM s_product
WHERE LOWER(name) LIKE '%ski%'
ORDER BY name;

-- 4) So thang tham nien (lam tron), sap xep tang dan
SELECT id AS emp_id,
       first_name || ' ' || last_name AS emp_name,
       ROUND(MONTHS_BETWEEN(SYSDATE, start_date)) AS thang_tham_nien
FROM s_emp
ORDER BY thang_tham_nien ASC, emp_id ASC;

PROMPT
PROMPT ===== BAI 3 - C5 =====
-- 5) Co bao nhieu nguoi quan ly
SELECT COUNT(DISTINCT manager_id) AS so_nguoi_quan_ly
FROM s_emp
WHERE manager_id IS NOT NULL;

PROMPT
PROMPT ===== BAI 3 - C6 =====
-- 6) Muc cao nhat va thap nhat cua don hang trong S_ORD
SELECT MAX(total) AS Hightest,
       MIN(total) AS Lowest
FROM s_ord;

EXIT
