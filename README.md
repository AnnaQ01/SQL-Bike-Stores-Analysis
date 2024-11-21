# SQL-Bike-Stores-Analysis

The SQL Bike Store Analysis project provides comprehensive insights into the sales, customer behavior, and product performance of bike stores from 2016 to 2018. By leveraging advanced SQL techniques, the analysis delves into  customer distribution and segmentation, state-wise and store-wise revenue trends, top-performing staff, and product performance. It includes detailed queries to identify customer buying patterns, such as one-time and repeat buyers, and measures year-over-year (YoY) and monthly sales growth. Additionally, the project explores revenue contributions from brands, product categories, and top-selling products while ranking the most successful staff and stores.

# 1. Customer analysis
**1.1. Customer Distribution and Total Sales by State**
```
SELECT COUNT(distinct c.customer_id) AS Customer_count,
    s.state,
       ROUND(SUM(oi.list_price * oi.quantity * (1 - oi.discount)),2) AS total_sales
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN stores s ON o.store_id = s.store_id
GROUP BY s.state
ORDER BY total_sales DESC;
```

<img width="400" alt="image" src="https://github.com/user-attachments/assets/8a1f2470-29c0-491e-bf0b-1920a6a56613">

**Analysis:**
- New York leads with the highest customer count (10,119) and total sales ($5.2M) but has lower average revenue per customer.
- California generates significant revenue ($1.6M) from fewer customers (284), indicating high-value purchases.
- Texas shows potential for growth with lower sales ($867K) and customer count (142).

**Recommendations:**
- Focus on upselling and cross-selling in New York to boost average customer spending.
- Retain high-value customers in California through exclusive offers and premium product lines.
- Implement marketing campaign to attract new customers.

**1.2. List all customers who have placed more than 2 orders.**
```
SELECT 
	c.first_name,
	c.last_name, 
	COUNT(o.order_id) as Total_Orders
FROM 
	orders o 
JOIN 
	customers c ON o.customer_id = c.customer_id 
GROUP BY 
	o.customer_id, c.first_name, c.last_name
HAVING 
	COUNT(order_id) > 2;
```
<img width="400" alt="image" src="https://github.com/user-attachments/assets/ab2107eb-7cce-4ac4-b5fe-4d1b2aa1fdc6">


**Analysis:**
- This query identifies customers and their locations with more than two orders, highlighting a segment of loyal, repeat buyers for the customer loyalty program. Only 39 out of 1,445 customers meet this criterion. 

**Recommendations:**
- Implement customer loyalty programs such as discounts, special offers, or early access to new products to encourage continued purchases.

**1.3. List Top 10 customers by revenue**
```
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
```

<img width="300" alt="image" src="https://github.com/user-attachments/assets/df909c67-f124-4e28-93b0-7a4664c46d2b">

**Analysis:**

- The top 10 customers contribute significantly to the total revenue, with the highest spender, Sharyn Hopkins, generating $34,807.94. 

**Recommendations:**

- Develop personalized loyalty programs or VIP memberships for these customers to encourage repeat purchases and enhance retention.

**1.4. Total Revenue by Customer Segmentation**
```
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
```
<img width="500" alt="image" src="https://github.com/user-attachments/assets/83118efa-c8db-4ae2-81cc-64ccdceffeb8">

**Analysis:**

- One-time buyers contribute the majority of the revenue (77.99%, or $5,996,361.95), but their average spending per customer is relatively low ($4,563.44).
- Repeat buyers, despite being a much smaller group (131 customers), contribute a significant 22.01% of the revenue ($1,692,754.62) and have a much higher average spending ($12,921.79)

**Recommendations:**

- Focus on converting one-time buyers into repeat buyers through personalized follow-up campaigns, loyalty rewards, and incentives for second purchases.
- Strengthen relationships with repeat buyers by offering exclusive benefits.

**1.5. Revenue by State and Customer Segment.**
```
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
```
<img width="551" alt="image" src="https://github.com/user-attachments/assets/73c95755-8364-49a5-8991-7375e18166f9">

**Analysis:**

- California (CA): 63.4% of revenue comes from one-time buyers, while repeat buyers contribute 36.6%.
- New York (NY): An overwhelming 84.02% of revenue is from one-time buyers, indicating low repeat buyer engagement in this state.
- Texas (TX): 68.7% of revenue is from one-time buyers, with repeat buyers accounting for 31.3%.

**Recommendations:**

- Boost Repeat Buyers: Focus retention efforts in New York and Texas through loyalty programs and personalized offers.
- Leverage California's Potential: Strengthen repeat buyer incentives in California to maximize high-value customer contributions
