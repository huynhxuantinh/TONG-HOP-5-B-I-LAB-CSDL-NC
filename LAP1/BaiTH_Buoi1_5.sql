SET PAGESIZE 100
SET LINESIZE 220
SET FEEDBACK ON
SET DEFINE OFF

CONNECT XUANTINH/XUANTINH
SHOW USER

-- 1) Ma nguoi quan ly va so nhan vien duoc quan ly
SELECT manager_id,
       COUNT(*) AS so_nhan_vien
FROM s_emp
WHERE manager_id IS NOT NULL
GROUP BY manager_id
ORDER BY manager_id;

-- 2) Nguoi quan ly tu 20 nhan vien tro len
SELECT manager_id,
       COUNT(*) AS so_nhan_vien
FROM s_emp
WHERE manager_id IS NOT NULL
GROUP BY manager_id
HAVING COUNT(*) >= 20
ORDER BY manager_id;

-- 3) Ma vung, ten vung, so phong ban truc thuoc moi vung
SELECT r.id AS region_id,
       r.name AS region_name,
       COUNT(d.id) AS so_phong_ban
FROM s_region r
LEFT JOIN s_dept d ON d.region_id = r.id
GROUP BY r.id, r.name
ORDER BY r.id;

-- 4) Ten khach hang va so luong don dat hang cua moi khach hang
SELECT c.name AS customer_name,
       COUNT(o.id) AS so_don_dat_hang
FROM s_customer c
LEFT JOIN s_ord o ON o.customer_id = c.id
GROUP BY c.id, c.name
ORDER BY c.id;

-- 5) Khach hang co so don dat hang nhieu nhat
WITH t AS (
    SELECT c.id,
           c.name,
           COUNT(o.id) AS so_don_dat_hang
    FROM s_customer c
    LEFT JOIN s_ord o ON o.customer_id = c.id
    GROUP BY c.id, c.name
)
SELECT id AS customer_id,
       name AS customer_name,
       so_don_dat_hang
FROM t
WHERE so_don_dat_hang = (SELECT MAX(so_don_dat_hang) FROM t)
ORDER BY id;

-- 6) Khach hang co tong tien mua hang lon nhat
WITH t AS (
    SELECT c.id,
           c.name,
           NVL(SUM(o.total), 0) AS tong_tien_mua_hang
    FROM s_customer c
    LEFT JOIN s_ord o ON o.customer_id = c.id
    GROUP BY c.id, c.name
)
SELECT id AS customer_id,
       name AS customer_name,
       tong_tien_mua_hang
FROM t
WHERE tong_tien_mua_hang = (SELECT MAX(tong_tien_mua_hang) FROM t)
ORDER BY id;

EXIT
