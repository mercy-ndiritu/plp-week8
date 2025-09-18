🛒 E-Commerce Database Management System
📌 Project Overview

This project implements a full-featured relational database for an e-commerce platform using MySQL.

It demonstrates:
Good database design practices
Normalization up to 3NF
Entity relationships (1-to-1, 1-to-many, many-to-many)
Constraints (PK, FK, NOT NULL, UNIQUE, CHECK)
Triggers for automatic inventory updates
Views for simplified reporting

⚙️ Features

✔️ Customers & Addresses
✔️ Products, Categories, Suppliers
✔️ Orders & Order Items
✔️ Payments & Reviews
✔️ Inventory Management with automatic stock decrements via triggers
✔️ View for quick product stock lookup

📂 Project Structure
📦 ecommerce-db
 ┣ 📜 ecommerce_full.sql   # Full schema + inserts + triggers + test queries
 ┣ 📜 README.md            # Project documentation

🛠️ How to Run
1️⃣ Import Database

Run the script in MySQL Workbench or CLI:

mysql -u root -p < ecommerce_full.sql

2️⃣ Verify Setup

After running, you can verify relationships and trigger execution with:

SELECT * FROM vw_ProductStock;   -- Check updated product stock
SELECT * FROM StockMovements;    -- Trigger logs stock decrements
SELECT * FROM Orders;            -- Orders data
SELECT * FROM OrderItems;        -- Ordered items
SELECT * FROM Payments;          -- Payment records
SELECT * FROM ProductReviews;    -- Customer reviews

📊 Sample Data Included

2 Customers (Alice, Bob)
Addresses for each customer

2 Products (Laptop, Wireless Mouse)
Categories & Suppliers
1 Order with items (Laptop + Mouse)
Payment record for the order
Reviews for both products

🚀 Key Learning Objectives
Apply normalization (1NF → 3NF)
Define primary/foreign keys and enforce constraints
Build relationships across tables
Use triggers to maintain data integrity automatically
Create views for simplified reporting

📌 Future Enhancements

Add support for discount codes & promotions
Implement shipping tracking
Introduce user roles & authentication
Create stored procedures for common workflows