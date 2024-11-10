CREATE TABLE fact_product_sales (
    fact_sales_id SERIAL PRIMARY KEY,
    date_id VARCHAR(50), --changed the type for compatible with dim_date table
    product_id INT,
    quantity_sold INT,
    total_sales DECIMAL(10,2),
    FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (product_id) REFERENCES dim_product(product_id)
);

INSERT INTO dim_product (product_id, product_name, supplier_id, category_id, quantity_per_unit, unit_price, units_in_stock)
SELECT product_id, product_name, supplier_id, category_id, quantity_per_unit, unit_price, units_in_stock
FROM staging.staging_products
WHERE discontinued = FALSE;

INSERT INTO fact_product_sales (date_id, product_id, quantity_sold, total_sales)
SELECT dd.date_id, p.product_id, sod.quantity, (sod.quantity * sod.unit_price) AS total_sales
FROM staging.staging_order_details sod
JOIN staging.staging_orders s ON sod.order_id = s.order_id
JOIN dim_date dd ON s.order_date = dd.date --joining dim_date cause I put the number of seconds since "January 1st, 1970" as an identifier for table dim_date
JOIN staging.staging_products p ON sod.product_id = p.product_id;

SELECT p.product_name,
    SUM(fps.quantity_sold) AS total_quantity_sold,
    SUM(fps.total_sales) AS total_revenue
FROM fact_product_sales fps
JOIN dim_product p ON fps.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_revenue DESC
LIMIT 5;

SELECT product_id, product_name, units_in_stock
FROM dim_product
WHERE units_in_stock < 10 -- Assumes a critical low stock level threshold of 10 units
ORDER BY 3; 

SELECT c.category_name, 
    EXTRACT(YEAR FROM d.date) AS year,
    EXTRACT(MONTH FROM d.date) AS month,
    SUM(fps.quantity_sold) AS total_quantity_sold,
    SUM(fps.total_sales) AS total_revenue
FROM fact_product_sales fps
JOIN dim_product p ON fps.product_id = p.product_id
JOIN dim_category c ON p.category_id = c.category_id
JOIN dim_date d ON fps.date_id = d.date_id
GROUP BY c.category_name,  year, month, d.date
ORDER BY year, month, total_revenue DESC;

SELECT p.product_name, p.units_in_stock, p.unit_price,
    (p.units_in_stock * p.unit_price) AS inventory_value
FROM dim_product p
ORDER BY inventory_value DESC;

SELECT s.company_name,
    COUNT(DISTINCT fps.fact_sales_id) AS number_of_sales_transactions,
    SUM(fps.quantity_sold) AS total_products_sold,
    SUM(fps.total_sales) AS total_revenue_generated
FROM fact_product_sales fps
JOIN dim_product p ON fps.product_id = p.product_id
JOIN dim_supplier s ON p.supplier_id = s.supplier_id
GROUP BY s.company_name
ORDER BY total_revenue_generated DESC;