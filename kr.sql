-- КР2 Кушнерюк Сергей Б05-925
----------------1-----------------
SELECT p.id,
       p.name,
       COALESCE(SUM(s.quantity), 0) AS sum_quantity
FROM products p
         LEFT JOIN sales s ON p.id = s.product_id
WHERE p.type_id = 1 -- это онлайн курсы
GROUP BY p.id
ORDER BY sum_quantity DESC;	


----------------2-----------------
SELECT ospc.id,
       ospc.c_name,
       ospc.p_name,
       ospc.price
FROM (SELECT DISTINCT c.id,
                      c.name                                             AS c_name,
                      p.name                                             AS p_name,
                      COALESCE(p.price, 0)                               AS price,
                      COALESCE(max(p.price) OVER (PARTITION BY c.id), 0) AS max_c_price
      FROM orders o
               INNER JOIN sales s ON s.order_id = o.id
               INNER JOIN products p ON s.product_id = p.id
               RIGHT JOIN customers c on o.customer_id = c.id) AS ospc
WHERE ospc.price = ospc.max_c_price
ORDER BY ospc.c_name;


----------------3-----------------
SELECT d.date,
       p.name,
       COALESCE(
           sum(p.price * s.quantity * (d.date = o.order_date)::integer)
           OVER (PARTITION BY p.id
                 ORDER BY d.date), 0) AS cumsum
FROM
     products p
LEFT JOIN sales s
    ON p.id = s.product_id
LEFT JOIN orders o
    ON s.order_id = o.id
CROSS JOIN (
    SELECT date_trunc('day', d)::date date
    FROM generate_series
             ((select min(order_date) from orders),
              (select max(order_date) from orders),
              '1 day'::interval) d
) d
ORDER BY p.name, d.date;

----------------4-----------------
SELECT day_sales.date,
       day_sales.day_sum,
       day_sales.day_sum - lag(day_sum::integer, 1, 0)
       OVER (ORDER BY day_sales.date) AS difference,
       (day_sales.day_sum - lag(day_sum::integer, 1, 0)
       OVER (ORDER BY day_sales.date))::double precision / day_sales.day_sum::double precision * 100.0 AS percent_dif
FROM (
SELECT DISTINCT
    o.order_date AS date,
    sum(s.quantity * p.price)
    OVER (PARTITION BY o.order_date) AS day_sum
FROM sales s
INNER JOIN orders o
    ON o.id = s.order_id
INNER JOIN products p
    ON s.product_id = p.id
) AS day_sales
ORDER BY date;


----------------5-----------------
CREATE OR REPLACE FUNCTION demo_db.mask_text(txt text) RETURNS text
AS $$
BEGIN
    RETURN LEFT(txt, 1) || REPEAT('*', LENGTH(txt) - 1);
END;
$$ language plpgsql;

DROP VIEW IF EXISTS customers_view;
CREATE OR REPLACE VIEW customers_view AS
select c.id,
       demo_db.mask_text(split_part(c.name, ' ', 1)) || ' ' || demo_db.mask_text(split_part(c.name, ' ', 2)) AS m_name,
       demo_db.mask_text(split_part(c.email, '@', 1)) || '@' || split_part(c.email, '@', 2) AS m_email,
       p.name AS product_name
FROM customers c
INNER JOIN orders o ON c.id = o.customer_id
INNER JOIN sales s ON o.id = s.order_id
INNER JOIN products p ON s.product_id = p.id;

SELECT * FROM customers_view;

----------------6-----------------

-- Не успел ((((

----------------7-----------------
DROP TABLE IF EXISTS change_log CASCADE;
CREATE TABLE change_log
(
    table_name  VARCHAR(100),
    change_type VARCHAR(100),
    username    VARCHAR(100),
    change_dttm timestamp NOT NULL DEFAULT current_timestamp
);


CREATE OR REPLACE function change() RETURNS TRIGGER AS
$$
BEGIN
    INSERT INTO change_log
        (table_name, change_type, username)
    VALUES (TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME, TG_OP, USER);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS change ON product_types;
CREATE TRIGGER change
    AFTER INSERT OR UPDATE OR DELETE
    ON product_types
    FOR EACH ROW
EXECUTE PROCEDURE change();

DROP TRIGGER IF EXISTS change ON customers;
CREATE TRIGGER change
    AFTER INSERT OR UPDATE OR DELETE
    ON customers
    FOR EACH ROW
EXECUTE PROCEDURE change();

DROP TRIGGER IF EXISTS change ON products;
CREATE TRIGGER change
    AFTER INSERT OR UPDATE OR DELETE
    ON products
    FOR EACH ROW
EXECUTE PROCEDURE change();

DROP TRIGGER IF EXISTS change ON sales;
CREATE TRIGGER change
    AFTER INSERT OR UPDATE OR DELETE
    ON sales
    FOR EACH ROW
EXECUTE PROCEDURE change();

DROP TRIGGER IF EXISTS change ON orders;
CREATE TRIGGER change
    AFTER INSERT OR UPDATE OR DELETE
    ON orders
    FOR EACH ROW
EXECUTE PROCEDURE change();

SELECT * FROM orders;

