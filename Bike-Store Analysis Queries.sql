-- 1. Customer analysis
--1.1. Customer Distribution and Total Sales by State
SELECT COUNT(distinct c.customer_id) AS Customer_count,
    s.state,
       ROUND(SUM(oi.list_price * oi.quantity * (1 - oi.discount)),2) AS total_sales
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN stores s ON o.store_id = s.store_id
GROUP BY s.state
ORDER BY total_sales DESC;

--1.2. List all customers who have placed more than 2 orders.
SELECT 
	c.first_name,
	c.last_name, 
	c.state,
	COUNT(o.order_id) as Total_Orders
FROM 
	orders o 
JOIN 
	customers c ON o.customer_id = c.customer_id 
GROUP BY 
	o.customer_id, c.first_name, c.last_name, c.state
HAVING 
	COUNT(o.order_id) > 2;


--1.3. List Top 10 customers by revenue
WITH total_spent AS (
    SELECT 
        oi.order_id,
        ot.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,  
        oi.product_id,
        oi.quantity, 
        oi.list_price, 
        oi.discount, 
        ((oi.quantity * oi.list_price) * (1 - oi.discount)) AS total_sale_product
    FROM 
        order_items AS oi
    LEFT JOIN 
        orders AS ot ON oi.order_id = ot.order_id
    LEFT JOIN 
        customers AS c ON ot.customer_id = c.customer_id
), customer_revenue AS (
    SELECT 
        customer_id, 
        customer_name, 
        ROUND(SUM(total_sale_product), 2) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY SUM(total_sale_product) DESC) AS revenue_rank
    FROM 
        total_spent
    GROUP BY 
        customer_id, customer_name
)
SELECT 
    customer_id, 
    customer_name, 
    total_spent
FROM 
    customer_revenue
WHERE 
    revenue_rank <= 10
ORDER BY 
    total_spent DESC;

--1.4. Total Revenue by Customer Segmentation
WITH customer_segments AS (
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        CASE 
            WHEN COUNT(DISTINCT o.order_id) = 1 THEN 'One-time buyer'
            ELSE 'Repeat buyer'
        END AS customer_segment,
        SUM(oi.list_price * oi.quantity * (1 - oi.discount)) AS total_revenue
    FROM 
        customers c
    JOIN 
        orders o ON c.customer_id = o.customer_id
    JOIN 
        order_items oi ON o.order_id = oi.order_id
    GROUP BY 
        c.customer_id, c.first_name, c.last_name
)
SELECT 
    customer_segment,
    ROUND(SUM(total_revenue), 2) AS total_revenue,
    ROUND(SUM(total_revenue) * 100.0 / (SELECT SUM(total_revenue) FROM customer_segments), 2) AS revenue_percentage,
    COUNT(customer_segment) AS customer_count,
    ROUND(SUM(total_revenue) / COUNT(customer_segment), 2) AS avg_spending
FROM 
    customer_segments
GROUP BY 
    customer_segment
ORDER BY 
    total_revenue DESC;


--1.5. Revenue by State and Customer Segment

	WITH customer_segments AS (
    SELECT 
        c.state,
        c.customer_id,
        CASE 
            WHEN COUNT(DISTINCT o.order_id) = 1 THEN 'One-time buyer'
            ELSE 'Repeat buyer'
        END AS customer_segment,
        SUM(oi.list_price * oi.quantity * (1 - oi.discount)) AS total_revenue
    FROM 
        customers c
    JOIN 
        orders o ON c.customer_id = o.customer_id
    JOIN 
        order_items oi ON o.order_id = oi.order_id
    GROUP BY 
        c.state, c.customer_id
)
SELECT 
    state,
    ROUND(SUM(CASE WHEN customer_segment = 'One-time buyer' THEN total_revenue ELSE 0 END), 2) AS one_time_buyer_revenue,
    ROUND(SUM(CASE WHEN customer_segment = 'Repeat buyer' THEN total_revenue ELSE 0 END), 2) AS repeat_buyer_revenue,
    ROUND(SUM(CASE WHEN customer_segment = 'One-time buyer' THEN total_revenue ELSE 0 END) * 100.0 / SUM(total_revenue), 2) AS one_time_buyer_percentage,
    ROUND(SUM(CASE WHEN customer_segment = 'Repeat buyer' THEN total_revenue ELSE 0 END) * 100.0 / SUM(total_revenue), 2) AS repeat_buyer_percentage
FROM 
    customer_segments
GROUP BY 
    state
ORDER BY 
    state;

--1.6. A stored procedure to get all orders for a given customer ID, including order details and total amount.

GO
DROP PROCEDURE IF EXISTS GetCustomerOrders;
GO
CREATE PROCEDURE GetCustomerOrders
    @p_customer_id INT
AS
BEGIN
    SELECT 
        o.order_id,
        o.order_date,
        oi.product_id,
        oi.quantity,
        ROUND(oi.list_price, 2) AS list_price, 
        ROUND(oi.discount, 2) AS discount, 
        ROUND(SUM(oi.quantity * oi.list_price * (1 - oi.discount)), 2) AS total_amount
    FROM 
        orders o
    JOIN 
        order_items oi ON o.order_id = oi.order_id
    WHERE 
        o.customer_id = @p_customer_id
    GROUP BY 
        o.order_id, o.order_date, oi.product_id, oi.quantity, oi.list_price, oi.discount
    ORDER BY 
        o.order_date DESC;
END;
GO

-- Executing the Stored Procedure
EXEC GetCustomerOrders @p_customer_id = 7


--2. Revenue analysis

--2.1. YoY Growth
SELECT 
    YEAR(o.order_date) AS year,
    SUM(oi.list_price * (1 - oi.discount) * oi.quantity) AS revenue,
    LAG(SUM(oi.list_price * (1 - oi.discount) * oi.quantity)) OVER (ORDER BY YEAR(o.order_date)) AS prev_year_revenue,
    ROUND(((SUM(oi.list_price * (1 - oi.discount) * oi.quantity) - LAG(SUM(oi.list_price * (1 - oi.discount) * oi.quantity)) OVER (ORDER BY YEAR(o.order_date))) / LAG(SUM(oi.list_price * (1 - oi.discount) * oi.quantity)) OVER (ORDER BY YEAR(o.order_date))) * 100, 2) AS yoy_growth_percent
FROM 
    orders o
JOIN 
    order_items oi ON o.order_id = oi.order_id
GROUP BY 
    YEAR(o.order_date)
ORDER BY 
    year;

--2.2. Identify Montly sales trend
SELECT 
    MONTH(o.order_date) AS month,
    Round(SUM(oi.list_price * (1 - oi.discount) * oi.quantity),2) AS revenue
FROM 
    orders o
JOIN 
    order_items oi ON o.order_id = oi.order_id
GROUP BY 
    MONTH(o.order_date)
ORDER BY 
    revenue Desc;

--2.3. List Revenue by Stores
SELECT 
    s.store_name, 
    SUM(oi.list_price * (1 - oi.discount) * oi.quantity) AS revenue,
    ROUND((SUM(oi.list_price * (1 - oi.discount) * oi.quantity) / SUM(SUM(oi.list_price * (1 - oi.discount) * oi.quantity)) OVER ()) * 100, 2) AS revenue_percentage
FROM 
    orders o
JOIN 
    order_items oi ON o.order_id = oi.order_id
JOIN 
    stores s ON o.store_id = s.store_id 
GROUP BY 
    s.store_name
ORDER BY 
    revenue DESC;


--2.4. List Revenue by States

	SELECT 
    s.state, 
    ROUND(SUM(oi.list_price * (1 - oi.discount) * oi.quantity), 2) AS total_revenue,
    ROUND(SUM(CASE 
        WHEN customer_order_count.total_orders = 1 
        THEN oi.list_price * (1 - oi.discount) * oi.quantity 
        ELSE 0 
    END), 2) AS onetime_buyer_revenue,
    ROUND(SUM(CASE 
        WHEN customer_order_count.total_orders > 1 
        THEN oi.list_price * (1 - oi.discount) * oi.quantity 
        ELSE 0 
    END), 2) AS repeat_buyer_revenue
FROM 
    orders o
JOIN 
    order_items oi ON o.order_id = oi.order_id
JOIN 
    stores s ON o.store_id = s.store_id  
JOIN 
    (
        SELECT 
            customer_id, 
            COUNT(order_id) AS total_orders
        FROM 
            orders
        GROUP BY 
            customer_id
    ) customer_order_count 
ON 
    o.customer_id = customer_order_count.customer_id
GROUP BY 
    s.state
ORDER BY 
    total_revenue DESC;


--2.5. List Revenue by Product Category
SELECT 
    c.category_name,
    Round(SUM(oi.list_price * (1 - oi.discount) * oi.quantity), 2) AS revenue
FROM 
    order_items oi
JOIN 
    products p ON oi.product_id = p.product_id
JOIN 
    categories c ON p.category_id = c.category_id
GROUP BY 
    c.category_name
ORDER BY 
    revenue DESC;  

--2.6. List Revenue by Brand name
SELECT 
    b.brand_name,
    Round(SUM(oi.list_price * (1 - oi.discount) * oi.quantity), 2) AS revenue
FROM 
    order_items oi
JOIN 
    products p ON oi.product_id = p.product_id
JOIN 
    brands b ON p.brand_id = b.brand_id
GROUP BY 
    b.brand_name
ORDER BY 
    revenue DESC;  


-- 2.7. Top 10 best selling products

SELECT top 10
    p.product_name,
    Round(SUM(oi.list_price * (1 - oi.discount) * oi.quantity),2) AS revenue
FROM 
    order_items oi
JOIN 
    products p ON oi.product_id = p.product_id
GROUP BY 
    p.product_name
ORDER BY 
    revenue DESC


--2.8. Top 10 worst selling products
SELECT TOP 10
    p.product_name,
    Round(SUM(oi.list_price * (1 - oi.discount) * oi.quantity),2) AS revenue
FROM 
    order_items oi
JOIN 
    products p ON oi.product_id = p.product_id
GROUP BY 
    p.product_name
ORDER BY 
    revenue ASC; 
	
--3.2. List the total number of products sold by each store.
SELECT 
	s.store_id, 
	s.store_name, 
	SUM(ot.quantity) AS num_products 
FROM 
	products p 
JOIN 
	order_items ot ON p.product_id = ot.product_id
JOIN 
	orders o ON o.order_id = ot.order_id
JOIN 
	stores s ON o.store_id = s.store_id
GROUP BY 
	s.store_id, s.store_name;


--3.3. Most Selling Product For Each Store
WITH RankedProducts AS (
    SELECT 
        s.store_id, 
        s.store_name, 
        p.product_name, 
        SUM(oi.quantity) AS units_sold, 
        RANK() OVER (PARTITION BY s.store_id ORDER BY SUM(oi.quantity) DESC) AS rank
    FROM 
        orders o
    JOIN 
        order_items oi ON o.order_id = oi.order_id
    JOIN 
        stores s ON o.store_id = s.store_id
    JOIN 
        products p ON oi.product_id = p.product_id 
    GROUP BY 
        s.store_id, 
        s.store_name, 
        p.product_name
)
SELECT 
    store_id,
    store_name,
    product_name,
    units_sold
FROM 
    RankedProducts
WHERE 
    rank = 1;


--2.11. Top Performing Staff Members by Total Sales and Units Sold:

 SELECT TOP 10
    CONCAT(first_name, ' ', last_name) AS staff_name,
    ROUND(SUM(oi.list_price * oi.quantity * (1 - oi.discount)),2) AS total_sales,
    SUM(quantity) AS units_sold
FROM 
    staffs s
JOIN 
    orders o ON s.staff_id = o.staff_id
JOIN 
    order_items oi ON o.order_id = oi.order_id
GROUP BY 
    s.staff_id, s.first_name, s.last_name
ORDER BY 
    total_sales DESC







