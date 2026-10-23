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
- [Portfolio 4 NoSQL use case and progress](portfolio-4-nosql/README.md)
- [Portfolio 5 distributed/cloud scope and progress](portfolio-5-distributed-cloud/README.md)
- [Assessment audit and remaining submission work](docs/assessment-audit.md)
- [Technical-verification preparation](docs/technical-verification.md)
- [Fresh reproducibility results](evidence/reproducibility-2026-10-17/README.md)
- [Assessment screenshots — nine-image gallery](evidence/screenshots/README.md)
- [Three-page LMS summary](Madueke_Emmanuel_301912318/Madueke_Emmanuel_301912318_README.md)
- [AI-use working record](docs/ai-use.md)

These documents and the conceptual ERD define the proposed initial model. The relational schema and data dictionary are specified for PostgreSQL. Normalisation is documented, including historical snapshots, aggregate redundancy, and the fixed-currency exception. The PostgreSQL 18.1 schema and controlled write routines are implemented, with 35 passing integrity/workflow checks and saved outputs. Reproducible sample data and an optional larger workload are now included. Portfolio 2 now contains 12 reports with 30 passing result checks. Five scale-dataset reports now have controlled before/after measurements for three reporting indexes and a customer-history rewrite, with unchanged results. [Optimisation findings](portfolio-2-query-optimisation/optimisation/README.md) document plan changes, costs, and limitations. Portfolio 2 is complete. Portfolio 3 now defines the checkout transaction boundary, including rollback scope, locking, and simulated-payment limitations. A COMMIT demonstration passed eight fresh-connection checks for the persisted order, payment, snapshots, and stock deductions. A ROLLBACK demonstration also passed six fresh-connection checks after an injected checkout failure. A two-session READ COMMITTED demonstration passed seven visibility checks. An isolated unsafe last-unit race reproduced overselling with eight checks. The protected checkout passed eleven concurrency checks, with confirmed lock waiting, one successful buyer, and no duplicate deduction on replay. Portfolio 3 is complete. Portfolio 4 selects MongoDB for structured product catalogue enrichment, with PostgreSQL retaining transactional data ownership. The document model, candidate validator, and three illustrative profiles are defined. MongoDB 8.0.34 now contains three source-reconciled profiles, with 22 import/validation/reconciliation checks and four fresh-connection checks passed. Five MongoDB finds, a tag aggregation, and an optional multikey index are verified with 16 checks plus hinted-result equivalence. The evidence-based SQL/NoSQL comparison is documented, including snapshot synchronisation and operational trade-offs. Portfolio 4 is complete. Portfolio 5 now selects a sourced architecture discussion covering replication, availability, consistency, and sharding. The sourced replication/availability analysis now defines proposed database roles, failover safeguards, and outage trade-offs. Consistency, replica lag, candidate shard keys, and cross-partition checkout trade-offs are now documented. A [sourced architecture diagram and eight failure scenarios](portfolio-5-distributed-cloud/architecture-scenarios.md) now connect those choices to proposed recovery and validation steps; no distributed failures have been tested. The [conclusions and evidence coverage](portfolio-5-distributed-cloud/conclusions.md) consolidate assumptions, proposed settings, trade-offs, and references. Portfolio 5 is complete for the discussion path. The [assessment audit](docs/assessment-audit.md) maps all five activities to the brief and records remaining submission work. A [fresh reproduction](evidence/reproducibility-2026-10-17/README.md) passed all 52 recorded commands across the implemented workflows, with separate raw evidence and stopped disposable runtimes. A [three-page LMS summary](Madueke_Emmanuel_301912318/Madueke_Emmanuel_301912318.pdf) now covers the technical work and evidence. The finalised summary includes a reflection grounded in Emmanuel’s recorded contributions, analysis of retained findings, and an explicit AI-use declaration. The [repository access review](Madueke_Emmanuel_301912318/Madueke_Emmanuel_301912318_access-review.md) confirms the pushed summary and progressive history; privacy and assessor access remain unverified because the CLI account cannot read repository settings. Next: resolve that access check before LMS submission.

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

The main repository directories are:

```text
advanced-database-portfolio/
├── README.md
├── docs/                             # Case study, design, setup, audit
├── diagrams/                         # Conceptual ERD image
├── portfolio-1-database-design/       # Schema, seeds, integrity checks
├── portfolio-2-query-optimisation/    # Reports, plans, comparisons
├── portfolio-3-transactions-concurrency/ # Transactions and race evidence
├── portfolio-4-nosql/                 # MongoDB model, import, queries
└── portfolio-5-distributed-cloud/     # Sourced architecture discussion
```

Each activity README links its scripts, evidence, and reproduction instructions. The named submission package is in `Madueke_Emmanuel_301912318/`; browser-captured evidence images are in `evidence/screenshots/`.

---

## Technologies

The portfolio uses the following technologies:

- **SQL** — database definition and querying
- **PostgreSQL 18.1** — verified relational database management system
- **MongoDB Community 8.0.34** — verified standalone document database
- **Python and Node.js/mongosh** — reproduction, coordination, and validation scripts
- **Git** — version control
- **GitHub** — source code and portfolio repository
- **Markdown** — documentation
- **SVG** — ERD and proposed architecture images

PostgreSQL and MongoDB runtime versions and reproduction conditions are recorded in the activity evidence. The distributed/cloud architecture remains a discussion.

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

**Status:** Five portfolio activities complete; final verification and submission documentation pending

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
- [x] Create transactional queries
- [x] Create management queries
- [x] Complete activity-specific database demonstrations and retain outputs
- [x] Audit all five activities against assessment deliverables
- [x] Complete final reproducibility review
- [ ] Complete documentation

---

## Author

**Emmanuel Madueke** — owner, author, and maintainer

Advanced Database Systems Portfolio