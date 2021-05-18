CREATE SCHEMA demo_db;

SET SEARCH_PATH = demo_db;

-- Создание таблиц

-- Создаем таблицы для продуктов онлайн школы
DROP TABLE IF EXISTS product_types CASCADE;
CREATE TABLE product_types(
    id serial PRIMARY KEY,
	type_name VARCHAR(100)
);

DROP TABLE IF EXISTS customers CASCADE;
CREATE TABLE customers(
    id serial PRIMARY KEY,
	name VARCHAR(100),
	email VARCHAR(30)
);

DROP TABLE IF EXISTS products CASCADE;
CREATE TABLE products(
    id serial PRIMARY KEY,
	name VARCHAR(100),
	type_id INT REFERENCES product_types(id),
	price INT
);

DROP TABLE IF EXISTS orders CASCADE;
CREATE TABLE orders(
    id serial PRIMARY KEY,
	order_date DATE,
	customer_id INT REFERENCES customers(id)
);

DROP TABLE IF EXISTS sales;
CREATE TABLE sales(
    product_id INT REFERENCES products(id),
	order_id INT REFERENCES orders(id),
	quantity INT,
	PRIMARY KEY(product_id, order_id)
);


-- Заполняем таблицу product_types
INSERT INTO product_types(id, type_name) VALUES(1, 'Онлайн-курс');
INSERT INTO product_types(id, type_name) VALUES(2, 'Вебинар');
INSERT INTO product_types(id, type_name) VALUES(3, 'Книга');
INSERT INTO product_types(id, type_name) VALUES(4, 'Консультация');


-- Заполняем таблицу products
INSERT INTO products(id, name, type_id, price) VALUES(1, 'Основы искусственного интеллекта', 1, 15000);
INSERT INTO products(id, name, type_id, price) VALUES(2, 'Технологии обработки больших данных', 1, 50000);
INSERT INTO products(id, name, type_id, price) VALUES(3, 'Программирование глубоких нейронных сетей', 1, 30000);
INSERT INTO products(id, name, type_id, price) VALUES(4, 'Нейронные сети для анализа текстов', 1, 50000);
INSERT INTO products(id, name, type_id, price) VALUES(5, 'Нейронные сети для анализа изображений', 1, 50000);
INSERT INTO products(id, name, type_id, price) VALUES(6, 'Инженерия искусственного интеллекта', 1, 60000);
INSERT INTO products(id, name, type_id, price) VALUES(7, 'Как стать DataScientist''ом', 2, 0);
INSERT INTO products(id, name, type_id, price) VALUES(8, 'Планирование карьеры в DataScience', 2, 2000);
INSERT INTO products(id, name, type_id, price) VALUES(9, 'Области применения нейросетей: в какой развивать экспертность', 2, 4000);
INSERT INTO products(id, name, type_id, price) VALUES(10, 'Программирование глубоких нейронных сетей на Python', 3, 1000);
INSERT INTO products(id, name, type_id, price) VALUES(11, 'Математика для DataScience', 3, 2000);
INSERT INTO products(id, name, type_id, price) VALUES(12, 'Основы визуализации данных', 3, 500);

-- Заполняем таблицу customers
INSERT INTO customers(id, name, email) VALUES(1, 'Иван Петров', 'petrov@mail.ru');
INSERT INTO customers(id, name, email) VALUES(2, 'Петр Иванов', 'ivanov@gmail.com');
INSERT INTO customers(id, name, email) VALUES(3, 'Тимофей Сергеев', 'ts@gmail.com');
INSERT INTO customers(id, name, email) VALUES(4, 'Даша Корнеева', 'dasha.korneeva@mail.ru');
INSERT INTO customers(id, name, email) VALUES(5, 'Иван Иван', 'petrov@mail.ru');
INSERT INTO customers(id, name, email) VALUES(6, 'Сергей Щербаков', 'user156@yandex.ru');
INSERT INTO customers(id, name, email) VALUES(7, 'Катя Самарина', 'kate@mail.ru');
INSERT INTO customers(id, name, email) VALUES(8, 'Андрей Котов', 'a.kotoff@yandex.ru');

-- Заполняем таблицу orders
INSERT INTO orders(id, order_date, customer_id) VALUES(1, '2021-01-11', 1);
INSERT INTO orders(id, order_date, customer_id) VALUES(2, '2021-01-15', 3);
INSERT INTO orders(id, order_date, customer_id) VALUES(3, '2021-01-20', 4);
INSERT INTO orders(id, order_date, customer_id) VALUES(4, '2021-01-12', 2);
INSERT INTO orders(id, order_date, customer_id) VALUES(5, '2021-01-25', 8);
INSERT INTO orders(id, order_date, customer_id) VALUES(6, '2021-01-30', 1);


-- Заполняем таблицу sales
INSERT INTO sales(product_id, order_id, quantity) VALUES(3, 1, 1);
INSERT INTO sales(product_id, order_id, quantity) VALUES(4, 6, 1);
INSERT INTO sales(product_id, order_id, quantity) VALUES(10, 2, 3);
INSERT INTO sales(product_id, order_id, quantity) VALUES(11, 2, 3);
INSERT INTO sales(product_id, order_id, quantity) VALUES(3, 3, 1);
INSERT INTO sales(product_id, order_id, quantity) VALUES(4, 3, 1);
INSERT INTO sales(product_id, order_id, quantity) VALUES(5, 3, 1);
INSERT INTO sales(product_id, order_id, quantity) VALUES(1, 4, 1);
INSERT INTO sales(product_id, order_id, quantity) VALUES(6, 5, 1);
INSERT INTO sales(product_id, order_id, quantity) VALUES(7, 5, 1);

--------------------1-----------------
SELECT prod.id,
       prod.name,
       COALESCE(sum(s.quantity), 0) as purchase_frequency
FROM products as prod
        left join sales s on prod.id = s.product_id
-- Онлайн курсы = 1 --
WHERE prod.type_id = 1
GROUP BY prod.id
ORDER BY  purchase_frequency;

-------------------2-----------------------

DROP VIEW IF EXISTS customer_to_product;
create or replace view customer_to_product as (
    select c.id as customer_id, c.name as name ,p.name as product_name, p.price
    FROM sales s
             left join products p on s.product_id = p.id
             inner join orders o on s.order_id = o.id
             left join customers c on o.customer_id = c.id
    ---курсы--
    where p.type_id = 1
    order by c.id, p.price DESC
);

DROP VIEW IF EXISTS most_chip;
create or replace view most_chip as (
    select c.id as customer_id, min(p.price) as min_price
    FROM sales s
             left join products p on s.product_id = p.id
             inner join orders o on s.order_id = o.id
             left join customers c on o.customer_id = c.id
    ---курсы--
    where p.type_id = 1
    group by c.id
);

select ctp.*
from customer_to_product as ctp, most_chip
where ctp.price = most_chip.min_price;

-----------------------4----------------------

create or replace view sayels_for_day  as (
    select distinct o.order_date as date,
                    sum(s.quantity * p.price) over (partition by o.order_date) as day_sum
    from sales s
    inner join products p on s.product_id = p.id
    inner join orders o on s.order_id = o.id
);

select sfd.date,
       sfd.day_sum,
       sfd.day_sum - lag(day_sum, 1, 0)
       OVER (ORDER BY sfd.date) AS difference,
       (sfd.day_sum - lag(day_sum, 1, 0)
       OVER (ORDER BY sfd.date)) / sfd.day_sum::double precision * 100.0 AS percent_dif
from sayels_for_day as sfd
order by sfd.date;


----------------------5-----------------------







