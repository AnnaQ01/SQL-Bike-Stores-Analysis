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

<img width="500" alt="image" src="https://github.com/user-attachments/assets/8a1f2470-29c0-491e-bf0b-1920a6a56613">

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
<img width="500" alt="image" src="https://github.com/user-attachments/assets/ab2107eb-7cce-4ac4-b5fe-4d1b2aa1fdc6">


**Analysis:**
- This query identifies customers and their locations with more than two orders, highlighting a segment of loyal, repeat buyers for the customer loyalty program. Only 39 out of 1,445 customers meet this criterion. 

**Recommendations:**
- Implement customer loyalty programs such as discounts, special offers, or early access to new products to encourage continued purchases.


