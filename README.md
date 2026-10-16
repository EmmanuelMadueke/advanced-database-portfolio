# Advanced Database Systems Portfolio

## Project Title

**Online Fashion Retail Store Database System**

## Overview

This project is an academic database design and implementation portfolio based on an **online fashion retail store**.

The system is designed to support the operations of a web-based fashion store that sells clothing, footwear, and fashion accessories.

The database handles core business activities such as:

- Customer registration
- Product management
- Product categorisation
- Product variants
- Inventory management
- Shopping carts
- Order processing
- Payments
- Delivery information
- Sales reporting

The project focuses on designing a database that is accurate, scalable, consistent, and suitable for both transactional processing and management reporting.

---

## Case Study

The case study is based on an online fashion retail store that sells clothing, footwear, and fashion accessories to customers through a web-based platform.

Customers can create accounts, browse available products, search and filter products, add items to their shopping carts, place orders, make payments, and monitor their order and delivery status.

Fashion products can exist in different combinations of size and colour. For this reason, the database manages individual **product variants** separately.

For example, a shirt may have the following variants:

- Black / Small
- Black / Medium
- Black / Large
- White / Small
- White / Medium
- White / Large

Each variant can have its own inventory quantity.

The database must also maintain accurate records of customer transactions, stock levels, payments, orders, and deliveries.

---

## Project Objectives

The main objectives of this project are to:

1. Analyse the data requirements of an online fashion retail business.
2. Identify the main entities and relationships within the system.
3. Design an Entity Relationship Diagram (ERD).
4. Transform the conceptual design into a relational database schema.
5. Apply database normalisation principles.
6. Define appropriate primary and foreign keys.
7. Implement integrity constraints.
8. Create the database using SQL.
9. Insert realistic sample data.
10. Develop SQL queries for transactional and management requirements.
11. Demonstrate how the database supports inventory and order management.
12. Retrieve useful business information from the database.

---

## Requirements and Modelling Documents

- [Requirements analysis](docs/requirements.md)
- [Business rules and relationship decisions](docs/business-rules.md)
- [Proposed entities and attributes](docs/entities-and-attributes.md)
- [Conceptual ERD](docs/conceptual-erd.md)
- [Relational schema specification](docs/relational-schema.md)
- [Data dictionary](docs/data-dictionary.md)
- [Normalisation analysis](docs/normalization.md)
- [Database setup and verification](docs/setup.md)
- [Sample data and expected results](docs/sample-data.md)
- [Portfolio 1 evidence and reproduction instructions](portfolio-1-database-design/README.md)
- [Portfolio 2 queries, verification, and evidence](portfolio-2-query-optimisation/README.md)
- [Portfolio 3 transaction boundary and progress](portfolio-3-transactions-concurrency/README.md)
- [AI-use working record](docs/ai-use.md)

These documents and the conceptual ERD define the proposed initial model. The relational schema and data dictionary are specified for PostgreSQL. Normalisation is documented, including historical snapshots, aggregate redundancy, and the fixed-currency exception. The PostgreSQL 18.1 schema and controlled write routines are implemented, with 35 passing integrity/workflow checks and saved outputs. Reproducible sample data and an optional larger workload are now included. Portfolio 2 now contains 12 reports with 30 passing result checks. Five scale-dataset reports now have controlled before/after measurements for three reporting indexes and a customer-history rewrite, with unchanged results. [Optimisation findings](portfolio-2-query-optimisation/optimisation/README.md) document plan changes, costs, and limitations. Portfolio 2 is complete. Portfolio 3 now defines the checkout transaction boundary, including rollback scope, locking, and simulated-payment limitations. A COMMIT demonstration passed eight fresh-connection checks for the persisted order, payment, snapshots, and stock deductions. A ROLLBACK demonstration also passed six fresh-connection checks after an injected checkout failure. Next: demonstrate isolation with two database sessions.

## Main Entities

The database is expected to contain entities such as:

- Customer
- Customer Address
- Product
- Category
- Brand
- Size
- Colour
- Product Variant
- Inventory
- Shopping Cart
- Cart Item
- Order
- Order Item
- Payment
- Delivery
- Administrator

The final entity structure may change during the database design and normalisation process.

---

## Core Database Requirements

The database must support the following operations.

### Customer Management

The system should allow customer information to be stored and managed.

This includes:

- Customer account details
- Contact information
- Delivery information
- Customer order history

### Product Management

The system should store information about fashion products including:

- Product name
- Description
- Category
- Brand
- Price
- Available variants

### Product Variants

Products can have multiple combinations of attributes such as size and colour.

Each product variant should be represented separately so that inventory can be managed accurately.

### Inventory Management

The system should:

- Track the quantity available for each product variant.
- Update stock after successful purchases.
- Prevent unavailable products from being sold.
- Identify low-stock products.
- Identify out-of-stock products.

### Shopping Cart

Customers should be able to:

- Add products to their cart.
- Change product quantities.
- Remove products.
- Review their cart before checkout.

### Order Management

The system should support:

- Order creation
- Order items
- Order totals
- Order status
- Customer order history
- Order processing

### Payment Management

The database should maintain records of payments associated with orders.

This may include:

- Payment amount
- Payment method
- Payment status
- Payment date
- Transaction reference

Sensitive payment credentials such as full card details should not be stored directly in the database.

### Delivery Management

The database should store information required for delivering customer orders.

This may include:

- Delivery address
- Delivery status
- Dispatch date
- Delivery date
- Tracking information

---

## Business Rules

Some of the main business rules for the system include:

1. A customer can place many orders.
2. Each order belongs to one customer.
3. An order can contain multiple order items.
4. Each order item references a specific product variant.
5. A product can belong to a category.
6. A product can have multiple variants.
7. Each product variant represents a specific combination of product attributes such as size and colour.
8. Each product variant has an associated inventory quantity.
9. A product variant cannot be purchased when its available inventory is insufficient.
10. Inventory should be reduced after a successful purchase.
11. A customer can maintain a shopping cart containing multiple products.
12. A payment must be associated with an order.
13. Delivery information must be associated with the relevant order.
14. Product and transaction records should maintain referential integrity.

---

## Management Information Requirements

The database should support queries that provide useful business information such as:

- Current stock levels
- Low-stock products
- Out-of-stock products
- Customer purchase history
- Pending orders
- Completed orders
- Delivery status
- Popular products
- Best-selling products
- Sales by category
- Sales by product
- Sales over a selected period
- Total revenue
- Customer purchasing activity

---

## Database Design Process

The project will follow a structured database development process.

### 1. Requirements Analysis

Analyse the case study and identify:

- Data requirements
- Business processes
- Business rules
- Required reports

### 2. Entity Identification

Identify the major entities required by the system.

### 3. Attribute Identification

Define the attributes associated with each entity.

### 4. Relationship Identification

Determine relationships between entities and their cardinalities.

### 5. Conceptual Database Design

Create an Entity Relationship Diagram representing the database structure.

### 6. Logical Database Design

Convert the conceptual model into relational tables.

### 7. Normalisation

Normalise the relational schema to reduce redundancy and prevent data anomalies.

The database will be evaluated against:

- First Normal Form (1NF)
- Second Normal Form (2NF)
- Third Normal Form (3NF)

Higher normal forms may be considered where appropriate.

### 8. Physical Database Design

Define:

- Data types
- Primary keys
- Foreign keys
- Constraints
- Indexes

### 9. Database Implementation

Create the database using SQL.

### 10. Data Population

Insert realistic sample data for testing.

### 11. Query Development

Develop SQL queries for transactional operations and management reporting.

---

## Repository Structure

A possible project structure is:

```text
advanced-database-portfolio/
│
├── README.md
│
├── docs/
│   ├── case-study.md
│   ├── requirements.md
│   ├── business-rules.md
│   ├── entities-and-attributes.md
│   ├── normalization.md
│   └── database-design.md
│
├── diagrams/
│   ├── conceptual-erd.png
│   └── logical-erd.png
│
├── sql/
│   ├── schema.sql
│   ├── constraints.sql
│   ├── sample-data.sql
│   └── queries.sql
│
└── reports/
    └── query-results.md
```

The structure may be expanded as the project progresses.

---

## Technologies

The project may use the following technologies:

- **SQL** — database definition and querying
- **PostgreSQL 18.1** — verified relational database management system
- **Git** — version control
- **GitHub** — source code and portfolio repository
- **Markdown** — documentation
- **ERD Tool** — database modelling and visualisation

PostgreSQL is the relational design target. The remaining tools and NoSQL database will be confirmed during setup and their respective activities.

---

## Expected Deliverables

The completed project is expected to contain:

- Case study
- Requirements analysis
- Entity and attribute identification
- Business rules
- Entity Relationship Diagram
- Relational schema
- Normalisation analysis
- SQL database creation scripts
- Constraints
- Sample data
- SQL queries
- Query results
- Management reports
- Project documentation

---

## Project Status

**Status:** In Development

Current stage:

- [x] Select case study
- [x] Define case study description
- [x] Identify entities
- [x] Identify entity attributes
- [x] Define business rules
- [x] Define relationships and cardinalities
- [x] Create conceptual ERD
- [x] Convert ERD to relational schema
- [x] Perform normalisation
- [x] Create SQL schema
- [x] Add database constraints
- [x] Insert sample data
- [ ] Create transactional queries
- [x] Create management queries
- [ ] Complete database testing (35 schema/integrity checks passed; remaining activities pending)
- [ ] Complete documentation

---

## Author

**Emmanuel Madueke** — owner, author, and maintainer

Advanced Database Systems Portfolio