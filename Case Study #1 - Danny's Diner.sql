use datadanny

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', 1),
  ('A', '2021-01-01', 2),
  ('A', '2021-01-07', 2),
  ('A', '2021-01-10', 3),
  ('A', '2021-01-11', 3),
  ('A', '2021-01-11', 3),
  ('B', '2021-01-01', 2),
  ('B', '2021-01-02', 2),
  ('B', '2021-01-04', 1),
  ('B', '2021-01-11', 1),
  ('B', '2021-01-16', 3),
  ('B', '2021-02-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-07', 3);
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  (1, 'sushi', 10),
  (2, 'curry', 15),
  (3, 'ramen', 12);
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  select * from members
   select * from menu
    select * from sales
    
/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?


-- 1. What is the total amount each customer spent at the restaurant?
SELECT 
    customer_id, SUM(price) AS total_amount_spent
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
GROUP BY customer_id

-- 2. How many days has each customer visited the restaurant?
SELECT 
    customer_id,
    COUNT(DISTINCT order_date) AS customer_visited_days
FROM
    sales
GROUP BY customer_id

-- 3. What was the first item from the menu purchased by each customer?
WITH cte
AS (SELECT customer_id,
           product_name,
           order_date,
           RANK() OVER (PARTITION BY customer_id ORDER BY order_date ASC) AS rnk
    FROM sales s
        JOIN menu m
            ON s.product_id = m.product_id
   )
SELECT customer_id,
       product_name,
       order_date
FROM cte
WHERE rnk = 1

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
    product_name AS most_purchased_item,
    COUNT(*) AS no_of_orders
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
GROUP BY product_name
ORDER BY no_of_orders DESC
LIMIT 1

-- 5. Which item was the most popular for each customer?

WITH cte
AS (SELECT customer_id,
           product_name,
           count(*) AS orders,
           RANK() OVER (PARTITION BY customer_id ORDER BY count(*) DESC) AS rnk
    FROM sales s
        JOIN menu m
            ON s.product_id = m.product_id
    GROUP BY customer_id,
             product_name
   )
SELECT customer_id,
       product_name AS most_popular_product_for_customer
FROM cte
WHERE rnk = 1

-- 6. Which item was purchased first by the customer after they became a member?
WITH cte
AS (SELECT s.customer_id AS customer_id,
           s.product_id AS product_id,
           product_name,
           order_date,
           RANK() OVER (PARTITION BY s.customer_id ORDER BY order_date) as rnk
    FROM sales s
        JOIN members me
            ON s.customer_id = me.customer_id
        JOIN menu m
            ON s.product_id = m.product_id
    where order_date >= join_date
   )
SELECT customer_id,
       product_id,
       product_name
from cte
WHERE rnk = 1

-- 7. Which item was purchased just before the customer became a member?
WITH cte
AS (SELECT s.customer_id AS customer_id,
           s.product_id AS product_id,
           product_name,
           order_date,
           RANK() OVER (PARTITION BY s.customer_id ORDER BY order_date DESC) AS rnk
    FROM sales s
        JOIN members me
            ON s.customer_id = me.customer_id
        JOIN menu m
            ON s.product_id = m.product_id
    where order_date < join_date
   )
SELECT customer_id,
       product_id,
       product_name,
       order_date
FROM cte
WHERE rnk = 1

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id AS customer_id,
       COUNT(order_date) AS total_items,
       sum(price) as amount_spent
FROM sales s
    JOIN members me
        ON s.customer_id = me.customer_id
    JOIN menu m
        ON s.product_id = m.product_id
WHERE order_date < join_date
GROUP BY s.customer_id

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT customer_id,
       sum(price) AS amount_spent,
       sum(   CASE
                  WHEN product_name = 'sushi' THEN
                      price * 2 * 10
                  ELSE
                      price * 10
              END
          ) AS points
FROM sales s
    JOIN menu m
        ON s.product_id = m.product_id
GROUP BY s.customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
-- how many points do customer A and B have at the end of January?
SELECT s.customer_id ,sum(price) AS amount_spent,
  SUM(
    CASE 
      WHEN order_date BETWEEN join_date AND ADDDATE(join_date,INTERVAL 6 DAY) THEN price * 10 * 2 
      WHEN product_name = 'sushi' THEN price * 10 * 2 
      ELSE price * 10 
    END
  ) as points
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
JOIN members me
ON me.customer_id = s.customer_id
where MONTH(order_date)=1
GROUP BY s.customer_id
ORDER BY points DESC

-- 11. Joining all the things
SELECT s.customer_id AS customer_id,
       order_date,
       product_name,
       price,
       CASE
           WHEN join_date is null
                OR order_date < join_date THEN
               'N'
           ELSE
               'Y'
       END AS member
FROM sales s
    LEFT JOIN members me
        ON s.customer_id = me.customer_id
    LEFT JOIN menu m
        ON s.product_id = m.product_id


-- 12. Ranking

WITH cte
AS (SELECT s.customer_id AS customer_id,
           order_date,
           product_name,
           price,
           CASE
               WHEN join_date is null
                    OR order_date < join_date THEN
                   'N'
               ELSE
                   'Y'
           END AS member
    FROM sales s
        LEFT JOIN members me
            ON s.customer_id = me.customer_id
        LEFT JOIN menu m
            ON s.product_id = m.product_id
   )
SELECT *,
       CASE
           WHEN member = 'N' THEN
               null
           ELSE
               RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date)
       END AS ranking
FROM cte
