USE master;
--Si la base de datos existe la elimina
IF DB_ID('TK463DW') IS NOT NULL
DROP DATABASE TK463DW;
GO
--Crea una base de datos , crea archivos de datos y se configura el modo de recuperacion.
CREATE DATABASE TK463DW
ON PRIMARY
(NAME = N'TK463DW', FILENAME = N'C:\TK463\TK463DW.mdf',
SIZE = 307200KB , FILEGROWTH = 10240KB )
LOG ON
(NAME = N'TK463DW_log', FILENAME = N'C:\TK463\TK463DW_log.ldf',
SIZE = 51200KB , FILEGROWTH = 10%);
GO
ALTER DATABASE TK463DW SET RECOVERY SIMPLE WITH NO_WAIT;
GO

--Creacion de un objeto de secuencia--
USE TK463DW;
GO
IF OBJECT_ID('dbo.SeqCustomerDwKey','SO') IS NOT NULL
DROP SEQUENCE dbo.SeqCustomerDwKey;
GO
CREATE SEQUENCE dbo.SeqCustomerDwKey AS INT
START WITH 1
INCREMENT BY 1;
GO

-- Dimension Clientes --
CREATE TABLE dbo.Customers
(
CustomerDwKey INT NOT NULL,
CustomerKey INT NOT NULL,
FullName NVARCHAR(150) NULL,
EmailAddress NVARCHAR(50) NULL,
BirthDate DATE NULL,
MaritalStatus NCHAR(1) NULL,
Gender NCHAR(1) NULL,
Education NVARCHAR(40) NULL,
Occupation NVARCHAR(100) NULL,
City NVARCHAR(30) NULL,
StateProvince NVARCHAR(50) NULL,
CountryRegion NVARCHAR(50) NULL,
Age AS
CASE
WHEN DATEDIFF(yy, BirthDate, CURRENT_TIMESTAMP) <= 40
THEN 'Younger'
WHEN DATEDIFF(yy, BirthDate, CURRENT_TIMESTAMP) > 50
THEN 'Older'
ELSE 'Middle Age'
END,

CurrentFlag BIT NOT NULL DEFAULT 1,
CONSTRAINT PK_Customers PRIMARY KEY (CustomerDwKey)
);
GO

--Dimension productos--
CREATE TABLE dbo.Products (
    ProductKey INT NOT NULL,
    ProductName NVARCHAR(50) NULL,
    Color NVARCHAR(15) NULL,
    Size NVARCHAR(50) NULL,
    SubcategoryName NVARCHAR(50) NULL,
    CategoryName NVARCHAR(50) NULL,
    CONSTRAINT PK_Products PRIMARY KEY (ProductKey)
);

--seleccion de datos de DimProducts de AdventureWorksDW2012--
INSERT INTO dbo.Products (ProductKey, ProductName, Color, Size, SubcategoryName, CategoryName)
SELECT
    p.ProductKey,
    p.EnglishProductName AS ProductName,
    p.Color,
    p.Size,
    subcat.EnglishProductSubcategoryName AS SubcategoryName,
    cat.EnglishProductCategoryName AS CategoryName
FROM 
    AdventureWorksDW2016.dbo.DimProduct AS p
LEFT JOIN 
    AdventureWorksDW2016.dbo.DimProductSubcategory AS subcat ON p.ProductSubcategoryKey = subcat.ProductSubcategoryKey
LEFT JOIN 
    AdventureWorksDW2016.dbo.DimProductCategory AS cat ON subcat.ProductCategoryKey = cat.ProductCategoryKey;

-- Dimension Fechas --
CREATE TABLE dbo.Dates
(
DateKey INT NOT NULL,
FullDate DATE NOT NULL,
MonthNumberName NVARCHAR(15) NULL,
CalendarQuarter TINYINT NULL,
CalendarYear SMALLINT NULL,
CONSTRAINT PK_Dates PRIMARY KEY (DateKey)
);

--tabla InternetSales--
CREATE TABLE dbo.InternetSales
(
InternetSalesKey INT NOT NULL IDENTITY(1,1),
CustomerDwKey INT NOT NULL,
ProductKey INT NOT NULL,
DateKey INT NOT NULL,
OrderQuantity SMALLINT NOT NULL DEFAULT 0,
SalesAmount MONEY NOT NULL DEFAULT 0,
UnitPrice MONEY NOT NULL DEFAULT 0,
DiscountAmount FLOAT NOT NULL DEFAULT 0,

CONSTRAINT PK_InternetSales
PRIMARY KEY (InternetSalesKey)
);
GO

--agregar restricciones de clave externa para las relaciones con las tres dimensiones--
ALTER TABLE dbo.InternetSales ADD CONSTRAINT
FK_InternetSales_Customers FOREIGN KEY(CustomerDwKey)
REFERENCES dbo.Customers (CustomerDwKey);
ALTER TABLE dbo.InternetSales ADD CONSTRAINT
FK_InternetSales_Products FOREIGN KEY(ProductKey)
REFERENCES dbo.Products (ProductKey);

ALTER TABLE dbo.InternetSales ADD CONSTRAINT
FK_InternetSales_Dates FOREIGN KEY(DateKey)
REFERENCES dbo.Dates (DateKey);
GO