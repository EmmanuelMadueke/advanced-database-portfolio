# Case Study: Online Fashion Retail Store

The case study is based on an **online fashion retail store** that sells clothing, footwear, and fashion accessories to customers through a web-based platform.

The system allows customers to create accounts, browse available fashion products, search and filter products by categories such as:

- Gender
- Size
- Colour
- Brand
- Price

Customers can also view detailed product information before making a purchase.

## Shopping and Checkout

Customers can add products to a shopping cart, update quantities, remove items, and proceed to checkout.

During checkout, the system must:

- Record customer delivery information.
- Calculate the total cost of the order.
- Process payment information.
- Create an order for the customer.
- Store the purchased items associated with the order.

Customers should also be able to view their previous orders and monitor the status of their current orders.

## Database Requirements

The database must support the storage and management of:

- Customer information
- Products
- Product categories
- Brands
- Sizes
- Colours
- Product variants
- Inventory levels
- Shopping carts
- Shopping cart items
- Orders
- Order items
- Payments
- Delivery information

Since fashion products may exist in different combinations of size and colour, the database must keep track of individual **product variants**.

For example, a particular shirt may be available as:

- Black / Small
- Black / Medium
- Black / Large
- White / Small
- White / Medium
- White / Large

Each product variant must have its own inventory quantity so that stock can be managed accurately.

## Inventory Management

The system must ensure that product stock is updated whenever purchases are successfully completed.

The database should prevent unavailable or out-of-stock product variants from being sold and maintain accurate inventory records.

Inventory information should allow administrators to determine:

- Current stock quantities.
- Products that are out of stock.
- Products with low stock levels.
- Available sizes and colours for each product.

## Order and Transaction Management

The database must maintain accurate records of all customer transactions.

Each order should contain information such as:

- The customer who placed the order.
- The products purchased.
- The quantity of each product.
- The price of each product at the time of purchase.
- The total order amount.
- Payment information.
- Delivery information.
- Order status.
- Delivery status.
- Date and time of the transaction.

Customers should be able to access their purchase history and check the status of active orders.

## Administrative Functions

Administrators should be able to:

- Add new products.
- Update existing products.
- Create and manage product categories.
- Manage brands.
- Create and update product variants.
- Manage product sizes and colours.
- Update inventory quantities.
- View and process customer orders.
- Update order statuses.
- Update delivery statuses.
- View customer information where necessary.
- Access sales and inventory information.

## Management and Reporting Requirements

The database should support both the daily transactional activities of the fashion store and the retrieval of information required for management and decision-making.

The system should be capable of retrieving information such as:

- Available stock.
- Low-stock products.
- Out-of-stock products.
- Customer purchase history.
- Current order statuses.
- Delivery statuses.
- Popular products.
- Best-selling product variants.
- Sales by product.
- Sales by category.
- Sales over a given period.
- Overall sales performance.

The database must therefore provide a reliable structure for managing customers, products, inventory, orders, payments, deliveries, and sales while maintaining data accuracy and consistency throughout the online fashion retail system.
