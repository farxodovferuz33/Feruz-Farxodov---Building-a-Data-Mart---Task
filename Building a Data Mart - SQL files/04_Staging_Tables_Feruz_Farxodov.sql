CREATE TABLE IF NOT EXISTS northwind.staging_customers (
    CustomerID INT PRIMARY KEY,
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


CREATE TABLE IF NOT EXISTS northwind.staging_order_details (
    OrderID INT,
    ProductID INT,
    UnitPrice DECIMAL(10,2),
    Quantity INT,
    Discount REAL,
    LoadDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE IF NOT EXISTS northwind.DimCustomer (
    CustomerID INT PRIMARY KEY,
    CompanyName VARCHAR(40),
    ContactName VARCHAR(30),
    ContactTitle VARCHAR(30),
    Address VARCHAR(60),
    City VARCHAR(15),
    Region VARCHAR(15),
    PostalCode VARCHAR(10),
    Country VARCHAR(15),
    Phone VARCHAR(24),
    Fax VARCHAR(24)
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



CREATE TABLE IF NOT EXISTS northwind.FactCustomerSales (
    FactCustomerSalesID SERIAL PRIMARY KEY,
    DateID INT,
    CustomerID INT,
    TotalAmount DECIMAL(10,2),
    TotalQuantity INT,
    NumberOfTransactions INT,
    FOREIGN KEY (DateID) REFERENCES northwind.DimDate(DateID),
    FOREIGN KEY (CustomerID) REFERENCES northwind.DimCustomer(CustomerID)
);


INSERT INTO northwind.DimCustomer (CustomerID, CompanyName, ContactName, ContactTitle, Address, City, Region, PostalCode, Country, Phone, Fax)
SELECT CustomerID, CompanyName, ContactName, ContactTitle, Address, City, Region, PostalCode, Country, Phone, Fax
FROM northwind.staging_customers;


INSERT INTO northwind.FactCustomerSales (DateID, CustomerID, TotalAmount, TotalQuantity, NumberOfTransactions)
SELECT
    d.DateID,
    c.CustomerID,
    SUM((od.UnitPrice * od.Quantity) - (od.UnitPrice * od.Quantity * od.Discount)) AS TotalAmount,
    SUM(od.Quantity) AS TotalQuantity,
    COUNT(DISTINCT o.OrderID) AS NumberOfTransactions
FROM
    northwind.staging_orders AS o
JOIN
    northwind.staging_order_details AS od ON o.OrderID = od.OrderID
JOIN
    northwind.DimDate AS d ON d.Date = o.OrderDate
JOIN
    northwind.DimCustomer AS c ON c.CustomerID = CAST(o.CustomerID AS INTEGER)
GROUP BY
    d.DateID,
    c.CustomerID;



SELECT 
    c.CustomerID, 
    c.CompanyName, 
    SUM(fcs.TotalAmount) AS TotalSpent,
    SUM(fcs.TotalQuantity) AS TotalItemsPurchased,
    SUM(fcs.NumberOfTransactions) AS TransactionCount
FROM 
    northwind.FactCustomerSales fcs
JOIN 
    northwind.DimCustomer c ON fcs.CustomerID = c.CustomerID
GROUP BY 
    c.CustomerID, c.CompanyName
ORDER BY 
    TotalSpent DESC;


SELECT 
    c.CompanyName,
    SUM(fcs.TotalAmount) AS TotalSpent
FROM 
    northwind.FactCustomerSales fcs
JOIN 
    northwind.DimCustomer c ON fcs.CustomerID = c.CustomerID
GROUP BY 
    c.CompanyName
ORDER BY 
    TotalSpent DESC
LIMIT 5;


SELECT 
    c.Region,
    COUNT(*) AS NumberOfCustomers,
    SUM(fcs.TotalAmount) AS TotalSpentInRegion
FROM 
    northwind.FactCustomerSales fcs
JOIN 
    northwind.DimCustomer c ON fcs.CustomerID = c.CustomerID
GROUP BY 
    c.Region
ORDER BY 
    NumberOfCustomers DESC;


SELECT 
    c.CustomerID, 
    c.CompanyName,
    CASE
        WHEN SUM(fcs.TotalAmount) > 10000 THEN 'VIP'
        WHEN SUM(fcs.TotalAmount) BETWEEN 5000 AND 10000 THEN 'Premium'
        ELSE 'Standard'
    END AS CustomerSegment
FROM 
    northwind.FactCustomerSales fcs
JOIN 
    northwind.DimCustomer c ON fcs.CustomerID = c.CustomerID
GROUP BY 
    c.CustomerID, c.CompanyName
ORDER BY 
    SUM(fcs.TotalAmount) DESC;


