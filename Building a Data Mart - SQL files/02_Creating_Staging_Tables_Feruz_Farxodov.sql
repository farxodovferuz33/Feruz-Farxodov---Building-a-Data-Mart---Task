CREATE TABLE IF NOT EXISTS northwind.staging_products (
    ProductID SERIAL PRIMARY KEY,
    ProductName VARCHAR(40),
    SupplierID INT,
    CategoryID INT,
    QuantityPerUnit VARCHAR(20),
    UnitPrice NUMERIC(10, 2),
    UnitsInStock INT,
    UnitsOnOrder INT,
    ReorderLevel INT,
    Discontinued BOOL,
    LoadDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE IF NOT EXISTS northwind.staging_suppliers (
    SupplierID SERIAL PRIMARY KEY,
    CompanyName VARCHAR(40),
    ContactName VARCHAR(30),
    ContactTitle VARCHAR(30),
    Address VARCHAR(60),
    City VARCHAR(15),
    Region VARCHAR(15),
    PostalCode VARCHAR(10),
    Country VARCHAR(15),
    Phone VARCHAR(24),
    Fax VARCHAR(24),
    HomePage TEXT,
    LoadDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE IF NOT EXISTS northwind.staging_order_details (
    OrderID INT,
    ProductID INT,
    UnitPrice NUMERIC(10, 2),
    Quantity INT,
    Discount REAL,
    LoadDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE IF NOT EXISTS northwind.DimSupplier (
    SupplierID SERIAL PRIMARY KEY,
    CompanyName VARCHAR(40),
    ContactName VARCHAR(30),
    ContactTitle VARCHAR(30),
    Address VARCHAR(60),
    City VARCHAR(15),
    Region VARCHAR(15),
    PostalCode VARCHAR(10),
    Country VARCHAR(15),
    Phone VARCHAR(24),
    Fax VARCHAR(24),
    HomePage TEXT
);



INSERT INTO northwind.DimSupplier (SupplierID, CompanyName, ContactName, ContactTitle, Address, City, Region, PostalCode, Country, Phone, Fax, HomePage)
SELECT SupplierID, CompanyName, ContactName, ContactTitle, Address, City, Region, PostalCode, Country, Phone, Fax, HomePage
FROM northwind.staging_suppliers;


CREATE TABLE IF NOT EXISTS northwind.FactSupplierPurchases (
    PurchaseID SERIAL PRIMARY KEY,
    SupplierID INT,
    TotalPurchaseAmount DECIMAL,
    PurchaseDate DATE,
    NumberOfProducts INT,
    FOREIGN KEY (SupplierID) REFERENCES northwind.DimSupplier(SupplierID)
);


INSERT INTO northwind.FactSupplierPurchases (SupplierID, TotalPurchaseAmount, PurchaseDate, NumberOfProducts)
SELECT 
    p.SupplierID, 
    SUM(od.UnitPrice * od.Quantity) AS TotalPurchaseAmount, 
    CURRENT_DATE AS PurchaseDate,  -- Using the current date for simplicity
    COUNT(DISTINCT od.ProductID) AS NumberOfProducts
FROM northwind.staging_order_details od
JOIN northwind.staging_products p ON od.ProductID = p.ProductID
GROUP BY p.SupplierID;


SELECT
    s.CompanyName,
    COUNT(fsp.PurchaseID) AS TotalOrders,
    SUM(fsp.TotalPurchaseAmount) AS TotalPurchaseValue,
    AVG(fsp.NumberOfProducts) AS AverageProductsPerOrder
FROM
    northwind.FactSupplierPurchases fsp
JOIN
    northwind.DimSupplier s ON fsp.SupplierID = s.SupplierID
GROUP BY
    s.CompanyName
ORDER BY
    TotalOrders DESC, TotalPurchaseValue DESC;


SELECT
    s.CompanyName,
    SUM(fsp.TotalPurchaseAmount) AS TotalSpend,
    EXTRACT(YEAR FROM fsp.PurchaseDate) AS Year,
    EXTRACT(MONTH FROM fsp.PurchaseDate) AS Month
FROM northwind.FactSupplierPurchases fsp
JOIN northwind.DimSupplier s ON fsp.SupplierID = s.SupplierID
GROUP BY s.CompanyName, Year, Month
ORDER BY TotalSpend DESC;


SELECT
    s.CompanyName,
    p.ProductName,
    AVG(od.UnitPrice) AS AverageUnitPrice,
    SUM(od.Quantity) AS TotalQuantityPurchased,
    SUM(od.UnitPrice * od.Quantity) AS TotalSpend
FROM northwind.staging_order_details od
JOIN northwind.staging_products p ON od.ProductID = p.ProductID
JOIN northwind.DimSupplier s ON p.SupplierID = s.SupplierID
GROUP BY s.CompanyName, p.ProductName
ORDER BY s.CompanyName, TotalSpend DESC;

SELECT
    s.CompanyName,
    COUNT(fsp.PurchaseID) AS TotalTransactions,
    SUM(fsp.TotalPurchaseAmount) AS TotalSpent
FROM northwind.FactSupplierPurchases fsp
JOIN northwind.DimSupplier s ON fsp.SupplierID = s.SupplierID
GROUP BY s.CompanyName
ORDER BY TotalTransactions DESC, TotalSpent DESC;


SELECT
    s.CompanyName,
    p.ProductName,
    SUM(od.UnitPrice * od.Quantity) AS TotalSpend
FROM northwind.staging_order_details od
JOIN northwind.staging_products p ON od.ProductID = p.ProductID
JOIN northwind.DimSupplier s ON p.SupplierID = s.SupplierID
GROUP BY s.CompanyName, p.ProductName
ORDER BY s.CompanyName, TotalSpend DESC
LIMIT 5;

