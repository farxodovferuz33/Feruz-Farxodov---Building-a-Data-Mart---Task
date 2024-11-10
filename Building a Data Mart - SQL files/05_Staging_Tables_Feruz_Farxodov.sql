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


CREATE TABLE IF NOT EXISTS northwind.FactSales (
    FactSalesID SERIAL PRIMARY KEY,
    DateID INT,
    CustomerID INT,
    ProductID INT,
    EmployeeID INT,
    CategoryID INT,
    ShipperID INT,
    SupplierID INT,
    QuantitySold INT,
    UnitPrice DECIMAL(10,2),
    Discount DECIMAL(10,2),
    TotalAmount DECIMAL(10,2) GENERATED ALWAYS AS (QuantitySold * UnitPrice - Discount) STORED,
    TaxAmount DECIMAL(10,2),
    FOREIGN KEY (DateID) REFERENCES northwind.DimDate(DateID),
    FOREIGN KEY (CustomerID) REFERENCES northwind.DimCustomer(CustomerID),
    FOREIGN KEY (ProductID) REFERENCES northwind.DimProduct(ProductID),
    FOREIGN KEY (EmployeeID) REFERENCES northwind.DimEmployee(EmployeeID),
    FOREIGN KEY (CategoryID) REFERENCES northwind.DimCategory(CategoryID),
    FOREIGN KEY (ShipperID) REFERENCES northwind.DimShipper(ShipperID),
    FOREIGN KEY (SupplierID) REFERENCES northwind.DimSupplier(SupplierID)
);

INSERT INTO northwind.FactSales (
    DateID, CustomerID, ProductID, EmployeeID, CategoryID, ShipperID, SupplierID,
    QuantitySold, UnitPrice, Discount, TotalAmount, TaxAmount
)
SELECT 
    d.DateID,
    c.CustomerID,
    p.ProductID,
    e.EmployeeID,
    cat.CategoryID,
    s.ShipperID,
    sup.SupplierID,
    od.Quantity,
    od.UnitPrice,
    od.Discount,
    (od.Quantity * od.UnitPrice - od.Discount) AS TotalAmount,
    (od.Quantity * od.UnitPrice - od.Discount) * 0.1 AS TaxAmount
FROM 
    northwind.staging_order_details AS od
JOIN 
    northwind.staging_orders AS o ON od.OrderID = o.OrderID
JOIN 
    northwind.DimCustomer AS c ON o.CustomerID = c.CustomerID
JOIN 
    northwind.DimProduct AS p ON od.ProductID = p.ProductID
LEFT JOIN 
    northwind.DimEmployee AS e ON o.EmployeeID = e.EmployeeID
LEFT JOIN 
    northwind.DimCategory AS cat ON p.CategoryID = cat.CategoryID
LEFT JOIN 
    northwind.DimShipper AS s ON o.ShipVia = s.ShipperID
LEFT JOIN 
    northwind.DimSupplier AS sup ON p.SupplierID = sup.SupplierID
LEFT JOIN 
    northwind.DimDate AS d ON o.OrderDate = d.Date;

SELECT 
    d.Month, 
    d.Year, 
    c.CategoryName, 
    SUM(fs.TotalAmount) AS TotalSales
FROM 
    northwind.FactSales fs
JOIN 
    northwind.DimDate d ON fs.DateID = d.DateID
JOIN 
    northwind.DimCategory c ON fs.CategoryID = c.CategoryID
GROUP BY 
    d.Month, d.Year, c.CategoryName
ORDER BY 
    d.Year, d.Month, TotalSales DESC;


SELECT 
    d.Quarter, 
    d.Year, 
    p.ProductName, 
    SUM(fs.QuantitySold) AS TotalQuantitySold
FROM 
    northwind.FactSales fs
JOIN 
    northwind.DimDate d ON fs.DateID = d.DateID
JOIN 
    northwind.DimProduct p ON fs.ProductID = p.ProductID
GROUP BY 
    d.Quarter, d.Year, p.ProductName
ORDER BY 
    d.Year, d.Quarter, TotalQuantitySold DESC
LIMIT 5;

SELECT 
    e.FirstName, 
    e.LastName, 
    COUNT(fs.FactSalesID) AS NumberOfSales, 
    SUM(fs.TotalAmount) AS TotalSales
FROM 
    northwind.FactSales fs
JOIN 
    northwind.DimEmployee e ON fs.EmployeeID = e.EmployeeID
GROUP BY 
    e.FirstName, e.LastName
ORDER BY 
    TotalSales DESC;


SELECT 
    cu.CompanyName, 
    SUM(fs.TotalAmount) AS TotalSpent, 
    COUNT(DISTINCT fs.FactSalesID) AS TransactionsCount
FROM 
    northwind.FactSales fs
JOIN 
    northwind.DimCustomer cu ON fs.CustomerID = cu.CustomerID
GROUP BY 
    cu.CompanyName
ORDER BY 
    TotalSpent DESC;



WITH MonthlySales AS (
    SELECT
        d.Year,
        d.Month,
        SUM(fs.TotalAmount) AS TotalSales
    FROM 
        northwind.FactSales fs
    JOIN 
        northwind.DimDate d ON fs.DateID = d.DateID
    GROUP BY 
        d.Year, d.Month
),
MonthlyGrowth AS (
    SELECT
        Year,
        Month,
        TotalSales,
        LAG(TotalSales) OVER (ORDER BY Year, Month) AS PreviousMonthSales,
        (TotalSales - LAG(TotalSales) OVER (ORDER BY Year, Month)) / LAG(TotalSales) OVER (ORDER BY Year, Month) AS GrowthRate
    FROM 
        MonthlySales
)
SELECT * FROM MonthlyGrowth;




