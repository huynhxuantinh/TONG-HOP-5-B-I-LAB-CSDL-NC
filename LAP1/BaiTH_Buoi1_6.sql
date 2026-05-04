SET PAGESIZE 100
SET LINESIZE 220
SET FEEDBACK ON
SET DEFINE OFF

ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';

CONNECT XUANTINH/XUANTINH
SHOW USER

-- 1) Ho, ten, ngay tuyen dung cua nhan vien cung phong voi Lan
SELECT e.last_name,
       e.first_name,
       e.start_date
FROM s_emp e
WHERE e.dept_id = (
    SELECT dept_id
    FROM s_emp
    WHERE UPPER(first_name) = 'LAN'
      AND ROWNUM = 1
)
ORDER BY e.last_name, e.first_name;

-- 2) Ma NV, ho, ten, userid cua nhan vien co luong > luong trung binh
SELECT id,
       last_name,
       first_name,
       userid
FROM s_emp
WHERE salary > (SELECT AVG(salary) FROM s_emp)
ORDER BY id;

-- 3) Ma NV, ho, ten cua nhan vien co luong > TB va ten chua ky tu "L"
SELECT id,
       last_name,
       first_name
FROM s_emp
WHERE salary > (SELECT AVG(salary) FROM s_emp)
  AND (UPPER(first_name) LIKE '%L%' OR UPPER(last_name) LIKE '%L%')
ORDER BY id;

-- 4) Khach hang chua bao gio dat hang
SELECT c.id,
       c.name
FROM s_customer c
WHERE NOT EXISTS (
    SELECT 1
    FROM s_ord o
    WHERE o.customer_id = c.id
)
ORDER BY c.id;

EXIT
