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


CREATE TABLE IF NOT EXISTS northwind.staging_orders (
    OrderID SERIAL PRIMARY KEY,
    CustomerID INT,
    EmployeeID INT,
    OrderDate DATE,
    RequiredDate DATE,
    ShippedDate DATE,
    ShipVia INT,
    Freight DECIMAL(10,2),
    ShipName VARCHAR(40),
    ShipAddress VARCHAR(60),
    ShipCity VARCHAR(15),
    ShipRegion VARCHAR(15),
    ShipPostalCode VARCHAR(10),
    ShipCountry VARCHAR(15),
    LoadDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE IF NOT EXISTS northwind.staging_categories (
    CategoryID SERIAL PRIMARY KEY,
    CategoryName VARCHAR(15),
    Description TEXT,
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



CREATE TABLE IF NOT EXISTS northwind.DimProduct (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(40),
    SupplierID INT,
    CategoryID INT,
    QuantityPerUnit VARCHAR(20),
    UnitPrice DECIMAL(10,2),
    UnitsInStock SMALLINT
);


CREATE TABLE IF NOT EXISTS northwind.DimCategory (
    CategoryID INT PRIMARY KEY,
    CategoryName VARCHAR(15),
    Description TEXT
);


CREATE TABLE IF NOT EXISTS northwind.DimDate (
    DateID SERIAL PRIMARY KEY,
    Date DATE NOT NULL,
    Day INT NOT NULL,
    Month INT NOT NULL,
    Year INT NOT NULL,
    Quarter INT NOT NULL,
    WeekOfYear INT NOT NULL
);



CREATE TABLE IF NOT EXISTS northwind.FactProductSales (
    FactSalesID SERIAL PRIMARY KEY,
    DateID INT,
    ProductID INT,
    QuantitySold INT,
    TotalSales DECIMAL(10,2),
    FOREIGN KEY (DateID) REFERENCES northwind.DimDate(DateID),
    FOREIGN KEY (ProductID) REFERENCES northwind.DimProduct(ProductID)
);


INSERT INTO northwind.DimProduct (ProductID, ProductName, SupplierID, CategoryID, QuantityPerUnit, UnitPrice, UnitsInStock)
SELECT ProductID, ProductName, SupplierID, CategoryID, QuantityPerUnit, UnitPrice, UnitsInStock
FROM northwind.staging_products
WHERE Discontinued = FALSE;

INSERT INTO northwind.DimCategory (CategoryID, CategoryName, Description)
SELECT CategoryID, CategoryName, Description
FROM northwind.staging_categories;


INSERT INTO northwind.FactProductSales (DateID, ProductID, QuantitySold, TotalSales)
SELECT 
    d.DateID,
    p.ProductID,
    od.Quantity,
    (od.Quantity * od.UnitPrice) AS TotalSales
FROM 
    northwind.staging_order_details od
JOIN 
    northwind.staging_orders o ON od.OrderID = o.OrderID
JOIN 
    northwind.DimProduct p ON od.ProductID = p.ProductID
JOIN 
    northwind.DimDate d ON o.OrderDate = d.Date;


SELECT 
    p.ProductName,
    SUM(fps.QuantitySold) AS TotalQuantitySold,
    SUM(fps.TotalSales) AS TotalRevenue
FROM 
    northwind.FactProductSales fps
JOIN 
    northwind.DimProduct p ON fps.ProductID = p.ProductID
GROUP BY 
    p.ProductName
ORDER BY 
    TotalRevenue DESC
LIMIT 5;


SELECT 
    ProductID,
    ProductName,
    UnitsInStock
FROM 
    northwind.DimProduct
WHERE 
    UnitsInStock < 10;


SELECT 
    c.CategoryName, 
    EXTRACT(YEAR FROM d.Date) AS Year,
    EXTRACT(MONTH FROM d.Date) AS Month,
    SUM(fps.QuantitySold) AS TotalQuantitySold,
    SUM(fps.TotalSales) AS TotalRevenue
FROM 
    northwind.FactProductSales fps
JOIN 
    northwind.DimProduct p ON fps.ProductID = p.ProductID
JOIN 
    northwind.DimCategory c ON p.CategoryID = c.CategoryID
JOIN 
    northwind.DimDate d ON fps.DateID = d.DateID
GROUP BY 
    c.CategoryName, Year, Month
ORDER BY 
    Year, Month, TotalRevenue DESC;



SELECT 
    p.ProductName,
    p.UnitsInStock,
    p.UnitPrice,
    (p.UnitsInStock * p.UnitPrice) AS InventoryValue
FROM 
    northwind.DimProduct p
ORDER BY 
    InventoryValue DESC;



SELECT 
    s.CompanyName,
    COUNT(DISTINCT fps.FactSalesID) AS NumberOfSalesTransactions,
    SUM(fps.QuantitySold) AS TotalProductsSold,
    SUM(fps.TotalSales) AS TotalRevenueGenerated
FROM 
    northwind.FactProductSales fps
JOIN 
    northwind.DimProduct p ON fps.ProductID = p.ProductID
JOIN 
    northwind.DimSupplier s ON p.SupplierID = s.SupplierID
GROUP BY 
    s.CompanyName
ORDER BY 
    TotalRevenueGenerated DESC;




