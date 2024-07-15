CREATE DATABASE dannys_diner;
USE dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INT
);

INSERT INTO sales (customer_id, order_date, product_id) VALUES
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
  product_id INT,
  product_name VARCHAR(5),
  price INT
);


INSERT INTO menu (product_id, product_name, price) VALUES
  (1, 'sushi', 10),
  (2, 'curry', 15),
  (3, 'ramen', 12);
  
  
  CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

-- 1. What is the total amount each customer spent at the restaurant?
select sales.customer_id,
  sum(menu.price) as Total_sum_spend
from dannys_diner.sales
join dannys_diner.menu on sales.product_id = menu.product_id
group by sales.customer_id
order by sales.customer_id;
  
-- 2. How many days has each customer visited the restaurant?
select customer_id,
  count(distinct order_date) as visit_days
from dannys_diner.sales
group by customer_id
order by customer_id;

-- 3. What was the first item from the menu purchased by each customer?

WITH cte_order AS(
SELECT 
  sales.customer_id,
  menu.product_name,
  
  ROW_NUMBER() OVER(
    PARTITION BY sales.customer_id
    ORDER BY sales.order_date,
    sales.product_id
    
    ) AS item_order 
FROM dannys_diner.sales 
  JOIN dannys_diner.menu
  
  ON sales.product_id = menu.product_id

)

SELECT * FROM cte_order
WHERE item_order=1;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
	s.product_id,
      count(m.product_id) as Purchased_item
FROM sales s
inner join	dannys_diner.menu m
ON s.product_id = m.product_id
group by 
product_id
order by count(m.product_id) desc
limit 1;

-- 5. Which item was the most popular for each customer?
WITH cte_order_count AS(
SELECT sales.customer_id,
  menu.Product_name,
  COUNT(*) AS order_count
  FROM dannys_diner.sales
  JOIN dannys_diner.menu
  
  ON sales.product_id = menu.product_id
  
  GROUP BY 
  customer_id,
  product_name

  ORDER BY 
  customer_id,
  order_count DESC
  
  ),
  cte_popular_rank AS(
SELECT *, RANK() OVER (PARTITION BY customer_id Order BY order_count DESC)
  AS ranks
  FROM cte_order_count
)

SELECT * FROM cte_popular_rank
WHERE ranks=1;



-- 6. Which item was purchased first by the customer after they became a member?
with cust_popular as (
SELECT 
	s.customer_id,
    s.product_id,
    min(s.order_date) as first_order_date
FROM sales s
inner join	dannys_diner.menu m
ON s.product_id = m.product_id
where	customer_id in ('A','B')
group by s.customer_id,    s.product_id
order by min(s.order_date) asc
)
select	customer_id, min(first_order_date)
from cust_popular
 group by customer_id;

-- -------------------------------------------6 2nd method ------------------------------------------------------
WITH FirstPurchaseAfterJoin AS (
    SELECT 
        s.customer_id,
        (SELECT m2.product_name
         FROM dannys_diner.menu m2
         WHERE m2.product_id = s.product_id
         LIMIT 1) AS first_purchase_after_join,
        MIN(s.order_date) AS first_purchase_date
    FROM 
        dannys_diner.sales s
    JOIN 
        dannys_diner.members m ON s.customer_id = m.customer_id
    WHERE 
        s.order_date > m.join_date
    GROUP BY 
        s.customer_id, s.product_id
)
SELECT 
    customer_id,
    first_purchase_after_join,
    first_purchase_date
FROM 
    FirstPurchaseAfterJoin
ORDER BY 
    customer_id;
    
    
-- 7. Which item was purchased just before the customer became a member?
SELECT 
	s.customer_id,
    m.product_name,
        min(s.order_date) as first_order_date
FROM sales s
inner join	dannys_diner.menu m
ON s.product_id = m.product_id
inner join dannys_diner.members mbr
on mbr.customer_id = s.customer_id
where	mbr.customer_id in ('A','B')
and s.order_date < mbr.join_date
group by s.customer_id,m.product_name
order by s.customer_id,min(s.order_date) asc;


-- 8. What is the total items and amount spent for each member before they became a member
SELECT 
	s.customer_id,
    count(m.product_name),
        sum(m.price) as sum_purchase
FROM sales s
inner join	dannys_diner.menu m
ON s.product_id = m.product_id
inner join dannys_diner.members mbr
on mbr.customer_id = s.customer_id
where	mbr.customer_id in ('A','B')
and s.order_date < mbr.join_date
group by s.customer_id;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select 
    s.customer_id,
    sum(
        case 
            when m.product_name = 'sushi' then m.price * 10 * 2
            else m.price * 10
        end
    ) as total_points
from 
    sales s
inner join 
    menu m on s.product_id = m.product_id
group by 
    s.customer_id;



/*
-- 10 10. In the first week after a customer joins the program (including their join date) they earn
--	2x points on all items, not just sushi — how many points do customer A and B have at the
--	end of January?
*/
with with_spend_point as (
select 
	s.customer_id,
    count(m.product_name) as Product_Count,
    sum(m.price) as ttl_spend,
    SUM(m.price) * (2 * 10) as ttl_points
FROM 
	sales s
inner join	dannys_diner.menu m
	ON s.product_id = m.product_id
inner join dannys_diner.members mbr
	on mbr.customer_id = s.customer_id
where	
s.order_date between mbr.join_date and  date(join_date + 7 )
and EXTRACT(MONTH FROM order_date) = 1
group by s.customer_id
)
select 
	customer_id,
    Product_Count,
    ttl_spend,	
    ttl_points as ttl_2x_points
from with_spend_point;


