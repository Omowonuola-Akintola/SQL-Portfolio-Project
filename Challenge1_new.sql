CREATE DATABASE IF NOT EXISTS  Danny_Diner;

USE Danny_Diner;

CREATE TABLE sales
(
customer_id VARCHAR(1),
order_date DATE,
product_id INTEGER
);

DROP TABLE sales;

#just reminding myself how to set a foreign key
ALTER TABLE sales
ADD FOREIGN KEY (product_id) REFERENCES menu(product_id) ON DELETE CASCADE;

CREATE TABLE members
(
customer_id VARCHAR (1),
join_date TIMESTAMP
); 

CREATE TABLE menu
(
product_id INTEGER,
product_name  VARCHAR(5),
price INTEGER
);

INSERT INTO sales VALUES 
("A", "2021-01-01", 1),
("A", "2021-01-01", 2),
("A", "2021-01-07", 2),
("A", "2021-01-10", 3),
("A", "2021-01-11", 3),
("A", "2021-01-11", 3),
("B", "2021-01-01", 2),
("B", "2021-01-02", 2),
("B", "2021-01-04", 1),
("B", "2021-01-11", 1),
("B", "2021-01-16",3),
("B", "2021-02-01", 3),
("C", "2021-01-01", 3),
("C", "2021-01-01", 3),
("C", "2021-01-07", 3);

INSERT INTO menu VALUES
	(1, "sushi", 10),
    (2, "curry", 15),
    (3, "ramen", 12);
    
INSERT INTO members VALUES
	("A", '2021-01-07'),
    ("B", '2021-01-09');
    

SELECT * FROM sales;
SELECT * FROM menu;
SELECT * FROM members;

#1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(m.price) AS total_price
FROM Sales s JOIN Menu m ON s.product_id = m.product_id
GROUP BY customer_id;

#2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS days FROM Sales
GROUP BY customer_id;

#3. What was the first item from each menu purchased by each customer?
WITH first_item AS
(
	SELECT s.customer_id, s.product_id, m.product_name, s.order_date,
    DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY order_date ASC) AS ranking
    FROM sales s JOIN menu m on s.product_id = m.product_id
)

SELECT customer_id, product_id, product_name, order_date FROM first_item 
WHERE ranking = 1;

#4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT s.product_id, m.product_name, COUNT(s.product_id) AS COUNT FROM sales s JOIN menu m ON s.product_id = m.product_id
GROUP BY product_id
ORDER BY COUNT DESC;

#5. Which item was the most popular for each customer? #Attempt 1
WITH pop_item AS
(
	SELECT COUNT(s.product_id) AS occurences, s.customer_id, m.product_name
    FROM sales s JOIN menu m on s.product_id = m.product_id
    GROUP BY s.customer_id, s.product_id
)

SELECT MAX(occurences), customer_id, product_name FROM pop_item
GROUP BY customer_id;

#Attempt 2
WITH pop_item AS
(
	SELECT COUNT(s.product_id) AS occurences, s.customer_id, m.product_name,
    DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.product_id)) AS ranking
    FROM sales s JOIN menu m on s.product_id = m.product_id
    GROUP BY s.customer_id, s.product_id
)

SELECT occurences, customer_id,product_name FROM pop_item WHERE ranking = 1;

#6. Which item was purchased first by the customer after they became a member?
WITH purchase AS
(
	SELECT s.customer_id, s.product_id, s.order_date, m.product_name, 
	DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS ranking
	FROM sales s JOIN menu m on s.product_id = m.product_id
	JOIN members me on s.customer_id = me.customer_id
	WHERE s.order_date > me.join_date
)

SELECT customer_id, product_id, product_name FROM purchase
WHERE ranking = 1;

#7. Which item was purchased just before the customer became a member?
WITH mem_before AS
(
	SELECT s.customer_id, s.product_id, s.order_date, m.product_name, 
	DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS ranking
	FROM sales s JOIN menu m on s.product_id = m.product_id
	JOIN members me on s.customer_id = me.customer_id
	WHERE s.order_date < me.join_date
)

SELECT customer_id, product_id, product_name, order_date FROM mem_before
WHERE ranking = 1;

#8. What is the total items and amount spent for each member before they became a member?
	SELECT s.customer_id, COUNT(s.product_id), SUM(m.price)
	FROM sales s JOIN menu m on s.product_id = m.product_id
	JOIN members me on s.customer_id = me.customer_id
	WHERE s.order_date < me.join_date
    GROUP BY customer_id
    ORDER BY customer_id;
    
#9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT s.product_id, s.customer_id, m.price,
SUM(CASE 
WHEN m.product_id = 1 THEN price*20 
ELSE price*10
END ) AS points
FROM sales s JOIN menu m on s.product_id = m.product_id
GROUP BY customer_id;

#10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH dates AS 
(
	SELECT *, 
     DATE_ADD(join_date, INTERVAL 6 DAY) AS valid_date,
	 LAST_DAY('2021-01-31') AS last_date
	FROM members AS m
)

SELECT d.customer_id, d.join_date, d.valid_date, d.last_date, s.order_date, m.product_name, m.price,
SUM(CASE 
WHEN m.product_name = 'sushi' THEN price*20 
WHEN s.order_date BETWEEN d.join_date AND d.valid_date THEN price*20
ELSE price*10
END ) AS points
FROM dates AS d JOIN sales As s on d.customer_id = s.customer_id
JOIN menu  AS m
ON s.product_id = m.product_id
WHERE S.order_date < d.last_date
GROUP BY customer_id;
