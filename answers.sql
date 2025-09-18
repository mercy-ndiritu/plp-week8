
-- E-COMMERCE DATABASE FULL SETUP


-- Create and select database
CREATE DATABASE ecommerce_db
  DEFAULT CHARACTER SET = utf8mb4
  DEFAULT COLLATE = utf8mb4_unicode_ci;
USE ecommerce_db;


-- TABLES


CREATE TABLE Customers (
    CustomerID       INT AUTO_INCREMENT PRIMARY KEY,
    Email            VARCHAR(255) NOT NULL UNIQUE,
    PasswordHash     VARBINARY(255) NOT NULL,
    FirstName        VARCHAR(100) NOT NULL,
    LastName         VARCHAR(100) NOT NULL,
    Phone            VARCHAR(30),
    CreatedAt        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE Addresses (
    AddressID        INT AUTO_INCREMENT PRIMARY KEY,
    CustomerID       INT NOT NULL,
    Label            VARCHAR(50) NOT NULL,
    Line1            VARCHAR(255) NOT NULL,
    Line2            VARCHAR(255),
    City             VARCHAR(100) NOT NULL,
    State            VARCHAR(100),
    PostalCode       VARCHAR(30),
    Country          VARCHAR(100) NOT NULL,
    IsDefault        BOOLEAN NOT NULL DEFAULT FALSE,
    CreatedAt        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Suppliers (
    SupplierID       INT AUTO_INCREMENT PRIMARY KEY,
    Name             VARCHAR(255) NOT NULL UNIQUE,
    ContactName      VARCHAR(150),
    ContactEmail     VARCHAR(255),
    Phone            VARCHAR(30),
    CreatedAt        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Categories (
    CategoryID       INT AUTO_INCREMENT PRIMARY KEY,
    Name             VARCHAR(150) NOT NULL,
    Slug             VARCHAR(150) NOT NULL UNIQUE,
    Description      TEXT,
    CreatedAt        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Products (
    ProductID        INT AUTO_INCREMENT PRIMARY KEY,
    SKU              VARCHAR(100) NOT NULL UNIQUE,
    Name             VARCHAR(255) NOT NULL,
    Description      TEXT,
    Price            DECIMAL(10,2) NOT NULL CHECK (Price >= 0),
    WeightKg         DECIMAL(8,3),
    IsActive         BOOLEAN NOT NULL DEFAULT TRUE,
    CreatedAt        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE ProductCategories (
    ProductID INT NOT NULL,
    CategoryID INT NOT NULL,
    PRIMARY KEY (ProductID, CategoryID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE ProductSuppliers (
    ProductID    INT NOT NULL,
    SupplierID   INT NOT NULL,
    SupplierSKU  VARCHAR(150),
    LeadTimeDays INT,
    PRIMARY KEY (ProductID, SupplierID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE ProductImages (
    ImageID   INT AUTO_INCREMENT PRIMARY KEY,
    ProductID INT NOT NULL,
    Url       VARCHAR(500) NOT NULL,
    AltText   VARCHAR(255),
    IsPrimary BOOLEAN NOT NULL DEFAULT FALSE,
    SortOrder INT NOT NULL DEFAULT 0,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Inventory (
    ProductID      INT PRIMARY KEY,
    QuantityOnHand INT NOT NULL DEFAULT 0 CHECK (QuantityOnHand >= 0),
    ReorderLevel   INT NOT NULL DEFAULT 0 CHECK (ReorderLevel >= 0),
    LastUpdated    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE StockMovements (
    MovementID     BIGINT AUTO_INCREMENT PRIMARY KEY,
    ProductID      INT NOT NULL,
    ChangeQuantity INT NOT NULL,
    Reason         VARCHAR(255) NOT NULL,
    ReferenceType  VARCHAR(50),
    ReferenceID    BIGINT,
    CreatedAt      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Orders (
    OrderID          BIGINT AUTO_INCREMENT PRIMARY KEY,
    CustomerID       INT NOT NULL,
    BillingAddressID INT NOT NULL,
    ShippingAddressID INT NOT NULL,
    OrderStatus      ENUM('PENDING','PROCESSING','SHIPPED','DELIVERED','CANCELLED','REFUNDED') NOT NULL DEFAULT 'PENDING',
    OrderTotal       DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    PlacedAt         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (BillingAddressID) REFERENCES Addresses(AddressID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (ShippingAddressID) REFERENCES Addresses(AddressID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE OrderItems (
    OrderID    BIGINT NOT NULL,
    ProductID  INT NOT NULL,
    Quantity   INT NOT NULL CHECK (Quantity > 0),
    UnitPrice  DECIMAL(10,2) NOT NULL CHECK (UnitPrice >= 0),
    DiscountAmount DECIMAL(10,2) DEFAULT 0.00 CHECK (DiscountAmount >= 0),
    PRIMARY KEY (OrderID, ProductID),
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE Payments (
    PaymentID     BIGINT AUTO_INCREMENT PRIMARY KEY,
    OrderID       BIGINT NOT NULL,
    Amount        DECIMAL(12,2) NOT NULL CHECK (Amount >= 0),
    Currency      CHAR(3) NOT NULL DEFAULT 'USD',
    PaymentMethod ENUM('CARD','PAYPAL','BANK_TRANSFER','CASH') NOT NULL,
    PaymentStatus ENUM('INITIATED','SUCCEEDED','FAILED','REFUNDED') NOT NULL DEFAULT 'INITIATED',
    ProcessedAt   DATETIME,
    ProviderRef   VARCHAR(255),
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE ProductReviews (
    ReviewID   BIGINT AUTO_INCREMENT PRIMARY KEY,
    ProductID  INT NOT NULL,
    CustomerID INT NOT NULL,
    Rating     TINYINT NOT NULL CHECK (Rating >= 1 AND Rating <= 5),
    Title      VARCHAR(255),
    Body       TEXT,
    CreatedAt  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
        ON DELETE CASCADE ON UPDATE CASCADE
);


-- VIEW + TRIGGER


CREATE OR REPLACE VIEW vw_ProductStock AS
SELECT p.ProductID, p.SKU, p.Name,
       COALESCE(i.QuantityOnHand,0) AS QuantityOnHand,
       COALESCE(i.ReorderLevel,0) AS ReorderLevel
FROM Products p
LEFT JOIN Inventory i ON p.ProductID = i.ProductID;

DELIMITER $$
CREATE TRIGGER trg_decrement_inventory_after_orderitem_insert
AFTER INSERT ON OrderItems
FOR EACH ROW
BEGIN
    UPDATE Inventory
    SET QuantityOnHand = GREATEST(0, QuantityOnHand - NEW.Quantity),
        LastUpdated = NOW()
    WHERE ProductID = NEW.ProductID;

    INSERT INTO StockMovements (ProductID, ChangeQuantity, Reason, ReferenceType, ReferenceID)
    VALUES (NEW.ProductID, -NEW.Quantity, 'Sale', 'ORDER', NEW.OrderID);
END$$
DELIMITER ;


-- SAMPLE DATA


-- Customers
INSERT INTO Customers (Email, PasswordHash, FirstName, LastName, Phone)
VALUES
('alice@example.com', UNHEX(SHA2('alice123',256)), 'Alice', 'Johnson', '555-1234'),
('bob@example.com',   UNHEX(SHA2('bob123',256)),   'Bob',   'Smith',   '555-5678');

-- Addresses
INSERT INTO Addresses (CustomerID, Label, Line1, City, Country, IsDefault)
VALUES
(1, 'Home', '123 Main St', 'New York', 'USA', TRUE),
(2, 'Home', '456 Oak Ave', 'Los Angeles', 'USA', TRUE);

-- Categories
INSERT INTO Categories (Name, Slug, Description)
VALUES
('Electronics', 'electronics', 'Electronic devices and accessories'),
('Computers', 'computers', 'Computers and peripherals');

-- Suppliers
INSERT INTO Suppliers (Name, ContactName, ContactEmail, Phone)
VALUES
('TechSupply Inc.', 'Jane Supplier', 'jane@techsupply.com', '555-2222');

-- Products
INSERT INTO Products (SKU, Name, Description, Price, WeightKg)
VALUES
('LAP123', 'Laptop', 'High performance laptop', 1200.00, 2.5),
('MOU456', 'Wireless Mouse', 'Ergonomic wireless mouse', 25.00, 0.1);

-- Product Categories
INSERT INTO ProductCategories (ProductID, CategoryID)
VALUES
(1, 1), (1, 2), (2, 1);

-- Product Suppliers
INSERT INTO ProductSuppliers (ProductID, SupplierID, SupplierSKU, LeadTimeDays)
VALUES
(1, 1, 'SUP-LAPTOP', 7),
(2, 1, 'SUP-MOUSE', 3);

-- Inventory
INSERT INTO Inventory (ProductID, QuantityOnHand, ReorderLevel)
VALUES
(1, 10, 2),
(2, 50, 10);

-- Orders
INSERT INTO Orders (CustomerID, BillingAddressID, ShippingAddressID, OrderStatus, OrderTotal)
VALUES
(1, 1, 1, 'PENDING', 1225.00);

-- OrderItems (trigger will decrement inventory + add stock movements)
INSERT INTO OrderItems (OrderID, ProductID, Quantity, UnitPrice)
VALUES
(1, 1, 1, 1200.00),
(1, 2, 1, 25.00);

-- Payments
INSERT INTO Payments (OrderID, Amount, Currency, PaymentMethod, PaymentStatus, ProcessedAt, ProviderRef)
VALUES
(1, 1225.00, 'USD', 'CARD', 'SUCCEEDED', NOW(), 'TXN123ABC');

-- Product Reviews
INSERT INTO ProductReviews (ProductID, CustomerID, Rating, Title, Body)
VALUES
(1, 1, 5, 'Excellent Laptop', 'Super fast and reliable. Highly recommended!'),
(2, 2, 4, 'Good Mouse', 'Works well, but a little small for my hands.');


-- VERIFICATION QUERIES


-- View product stock (should show decremented quantities)
SELECT * FROM vw_ProductStock;

-- Stock movements (should show 2 rows from trigger)
SELECT * FROM StockMovements;

-- Orders and items
SELECT * FROM Orders;
SELECT * FROM OrderItems;

-- Payments
SELECT * FROM Payments;

-- Reviews
SELECT * FROM ProductReviews;
