# Bike-Stores-Analysis

The SQL Bike Store Analysis project provides in-depth insights into sales performance, customer behavior, and product trends across bike stores from 2016 to 2018. Utilizing advanced SQL techniques and Power BI, the analysis examines customer segmentation, state-wise and store-wise revenue trends, top-performing staff, and product performance. Power BI is used to create interactive dashboards and visualizations, allowing for a deeper understanding of customer buying patterns, such as one-time and repeat buyers, while also tracking year-over-year (YoY) and monthly sales growth. Additionally, the project evaluates revenue contributions by brands, product categories, and top-selling products, along with identifying the most successful staff and stores based on sales performance. 

<img width="985" alt="image" src="https://github.com/user-attachments/assets/d2997f4b-c5ac-4bce-b584-aa25a5aeda51" />

<img width="982" alt="image" src="https://github.com/user-attachments/assets/0eb6c864-0467-4e82-89c4-e5a308ca0f00" />



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

------
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


------
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

-----

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

--------

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

------

- California (CA): 63.4% of revenue comes from one-time buyers, while repeat buyers contribute 36.6%.
- New York (NY): An overwhelming 84.02% of revenue is from one-time buyers, indicating low repeat buyer engagement in this state.
- Texas (TX): 68.7% of revenue is from one-time buyers, with repeat buyers accounting for 31.3%.

**Recommendations:**

- Boost Repeat Buyers: Focus retention efforts in New York and Texas through loyalty programs and personalized offers.
- Leverage California's Potential: Strengthen repeat buyer incentives in California to maximize high-value customer contributions.

# 2. Revenue analysis

**2.1. YoY Growth**
```
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
```
<img width="486" alt="image" src="https://github.com/user-attachments/assets/cfd844c9-b54f-4d54-b288-fc46d0b2344a">
---------
- Revenue grew by 42.01% in 2017 compared to 2016, indicating strong business performance and possibly successful marketing or product strategies.
- Revenue dropped significantly by -47.36% in 2018, suggesting potential challenges such as reduced customer retention, market saturation...

**Recommendations:**
- Identify the drivers behind the 2017 growth and replicate these strategies.
- Conduct root cause analysis for the 2018 revenue drop and address the underlying issues.

**2.2. Identify Montly sales trend**
```
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
  ```
<img width="146" alt="image" src="https://github.com/user-attachments/assets/7feb89e0-bf85-47ae-89a8-6875d023ac6e">
  
-------
- The first quarter (January to March) shows moderate sales, with January contributing $882,193.01. April has the highest revenue ($1,212,356.83), indicating a strong sales period.
- November ($465,852.93) and December ($440,890.11) have the lowest revenues.

**Recommendations:**

- Introduce special offers, holiday promotions, or marketing campaigns to improve performance in November and December.
- Allocate resources and marketing efforts strategically, focusing on high-performing months like April while addressing gaps in weaker months. 

**2.3. List Revenue by Store**
```
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
```
<img width="260" alt="image" src="https://github.com/user-attachments/assets/5ac3bd14-22e3-4387-a6b1-8588ba6a4b34">

---------

- Baldwin Bikes leads, contributing 67.83% of revenue ($5.2M), far outperforming the other stores.
- Santa Cruz Bikes (20.88%) and Rowlett Bikes (11.28%) lag behind, indicating growth opportunities.

**Recommendations:**
- Increase marketing efforts and promotional campaigns for Santa Cruz and Rowlett to attract more customers and boost revenue.

**2.4. List Revenue by State**
```
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
```
<img width="293" alt="image" src="https://github.com/user-attachments/assets/5c465f02-c602-4392-9f38-92c2ca4eed7a" />

--------
- New York generates the highest total revenue ($5.2M), with most of it coming from one-time buyers ($4.38M, 84%).
- California has a higher repeat buyer contribution ($587K) compared to Texas, but one-time buyers still dominate ($1.01M, 63%).
- Texas has the lowest total revenue ($867K) and repeat buyer revenue ($271K), showing room for growth.

**Recommendations:**
 - Focus on converting New York and Calefornia's one-time buyers into repeat buyers through loyalty programs and targeted marketing.

**2.5. List Revenue by Product Category**
```
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
```
<img width="500" alt="image" src="https://github.com/user-attachments/assets/91a03e7d-8250-4f92-8cf5-c00ff54ec10c" />

---------
- Mountain Bikes Dominate: Highest revenue at $2.72M, nearly 1.6x Road Bikes.
- Road & Cruisers in Demand: Road Bikes ($1.67M) and Cruisers ($995K) are strong performers.
- Lower Revenue Categories: Children’s ($292K) and Comfort Bicycles ($394K) have the lowest sales.
**Recommendations:**
- Expand Mountain Bike Sales: Focus on promotions, new models, and upselling accessories.
- Boost Low-Selling Categories: Offer discounts or bundled deals to drive demand for Children’s and Comfort Bicycles.

**2.6. List Revenue by Brand name**
```
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
```
<img width="515" alt="image" src="https://github.com/user-attachments/assets/a74a0c79-c2c7-41a8-95e3-d43f2a34f1f1" />

--------
- Trek Leads dominating sales with $4.6M.
- Electra & Surly: Strong performers at $1.2M and $949K.
- Low Performers: Strider ($4.3K) and Ritchey ($78.9K) have minimal sales.
**Recommendations:**
- Expand Trek Sales: Leverage its dominance with premium offerings.
- Improve Low-Performing Brands: Consider discontinuation or aggressive marketing.

**2.7. Top 10 best selling products**
```
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
```
<img width="552" alt="image" src="https://github.com/user-attachments/assets/0ffa9382-b59c-46b7-b88d-0c2f86a52319" />

-------
- Trek dominates with 7 out of 10 top-selling models.
- 2016 models perform better overall than 2017 models.
- Surly Straggler is the only non-Trek bike in the top 5.
**Recommendations:** 
- Expand Trek Slash 8 Sales: High demand justifies continued production.
- Leverage 2016 Models' Popularity: Offer discounts or re-release successful ones.

**2.8. Top 10 worst selling products**
```
SELECT TOP 10
    p.product_name,
    SUM(oi.list_price * (1 - oi.discount) * oi.quantity) AS revenue
FROM 
    order_items oi
JOIN 
    products p ON oi.product_id = p.product_id
GROUP BY 
    p.product_name
ORDER BY 
    revenue ASC;
```
<img width="545" alt="image" src="https://github.com/user-attachments/assets/a3254013-3d38-43f3-bcdc-eb69ffb71f94" />

------

- There is low demand on children's bikes with Electra and Trek dominate the worst-sellers.
**Recommendations:**
- Bundle children’s bikes with accessories (helmets, pads) to boost sales.
- Offer discounts or promotions to clear inventory.

**2.9. List the total number of products sold by each store.**
```
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
```

<img width="507" alt="image" src="https://github.com/user-attachments/assets/743d76d0-e927-46de-9cce-f246a26116ae" />
**Recommendations:**
- Baldwin Bikes is the top performer with 4,779 products sold, significantly ahead of the others. Santa Cruz Bikes follows with 1,516 products sold. Rowlett Bikes has the lowest sales.
- Rowlett Bikes should analyze customer demand and implement marketing strategies to boost sales.
- Santa Cruz Bikes can improve through promotions or better product assortment to compete with Baldwin Bikes.

**2.10. Most Selling Product For Each Store**
```
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
```
<img width="541" alt="image" src="https://github.com/user-attachments/assets/dde8a9fe-14aa-483e-b947-82ad520ab960" />

**2.11. Top Performing Staff Members by Total Sales and Units Sold**
```
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
```

<img width="472" alt="image" src="https://github.com/user-attachments/assets/26b44050-755e-4688-9dc1-7a727aba7232" />
