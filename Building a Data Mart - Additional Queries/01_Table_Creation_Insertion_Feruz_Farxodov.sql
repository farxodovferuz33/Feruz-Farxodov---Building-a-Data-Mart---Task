CREATE TABLE fact_supplier_purchases (
    purchase_id SERIAL PRIMARY KEY,
    supplier_id INT,
    total_purchase_amount DECIMAL,
    purchase_date DATE,
    number_of_products INT,
    FOREIGN KEY (supplier_id) REFERENCES dim_supplier(supplier_id)
);

INSERT INTO fact_supplier_purchases (supplier_id, total_purchase_amount, purchase_date, number_of_products)
SELECT p.supplier_id, 
    SUM(od.unit_price * od.quantity) AS total_purchase_amount, 
    o.order_date AS purchase_date,
    COUNT(DISTINCT od.product_id) AS number_of_products
FROM staging.staging_order_details od
JOIN staging.staging_orders o ON od.order_id = o.order_id
JOIN staging.staging_products p ON od.product_id = p.product_id
GROUP BY p.supplier_id, o.order_date;

SELECT s.company_name,
    COUNT(fsp.purchase_id) AS total_orders,
    SUM(fsp.total_purchase_amount) AS total_purchase_value,
    ROUND(AVG(fsp.number_of_products), 2) AS average_products_per_order
FROM fact_supplier_purchases fsp
JOIN dim_supplier s ON fsp.supplier_id = s.supplier_id
GROUP BY s.company_name
ORDER BY total_orders DESC, total_purchase_value DESC;

SELECT s.company_name,
    SUM(fsp.total_purchase_amount) AS total_spend,
    EXTRACT(YEAR FROM fsp.purchase_date) AS Year,
    EXTRACT(MONTH FROM fsp.purchase_date) AS Month
FROM fact_supplier_purchases fsp
JOIN dim_supplier s ON fsp.supplier_id = s.supplier_id
GROUP BY s.company_name, Year, Month
ORDER BY total_spend DESC;

SELECT s.company_name,
    p.product_name,
    ROUND(AVG(od.unit_price), 2) AS average_unit_price,
    SUM(od.quantity) AS total_quantity_purchased,
    SUM(od.unit_price * od.quantity) AS total_spend
FROM staging.staging_order_details od
JOIN staging.staging_products p ON od.product_id = p.product_id
JOIN dim_supplier s ON p.supplier_id = s.supplier_id
GROUP BY s.company_name, p.product_name
ORDER BY s.company_name, total_spend DESC;

SELECT s.company_name,
    COUNT(fsp.purchase_id) AS total_transactions,
    SUM(fsp.total_purchase_amount) AS total_spent
FROM fact_supplier_purchases fsp
JOIN dim_supplier s ON fsp.supplier_id = s.supplier_id
GROUP BY s.company_name
ORDER BY total_transactions DESC, total_spent DESC;

SELECT s.company_name,
    p.product_name,
    SUM(od.unit_price * od.quantity) AS total_spend
FROM staging.staging_order_details od
JOIN staging.staging_products p ON od.product_id = p.product_id
JOIN dim_supplier s ON p.supplier_id = s.supplier_id
GROUP BY s.company_name, p.product_name
ORDER BY s.company_name, total_spend DESC
LIMIT 5;
