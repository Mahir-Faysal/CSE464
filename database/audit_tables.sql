-- Generic audit log
CREATE TABLE Audit_Log (
    audit_id NUMBER DEFAULT seq_audit_log.NEXTVAL PRIMARY KEY,
    table_name VARCHAR2(50) NOT NULL,
    record_id NUMBER NOT NULL,
    operation_type VARCHAR2(10) CHECK (operation_type IN ('INSERT', 'UPDATE', 'DELETE')) NOT NULL,
    field_name VARCHAR2(50),
    old_value CLOB,
    new_value CLOB,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by NUMBER,
    session_id VARCHAR2(100),
    ip_address VARCHAR2(45),
    user_agent CLOB,
    CONSTRAINT fk_audit_log_user FOREIGN KEY (changed_by) REFERENCES Users(user_id)
);

-- Products audit table
CREATE TABLE Audit_Products (
    audit_id NUMBER DEFAULT seq_audit_products.NEXTVAL PRIMARY KEY,
    product_id NUMBER NOT NULL,
    old_name VARCHAR2(100),
    new_name VARCHAR2(100),
    old_price NUMBER(10,2),
    new_price NUMBER(10,2),
    old_stock_quantity NUMBER,
    new_stock_quantity NUMBER,
    old_category VARCHAR2(50),
    new_category VARCHAR2(50),
    operation_type VARCHAR2(10) CHECK (operation_type IN ('INSERT', 'UPDATE', 'DELETE')) NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by NUMBER,
    reason VARCHAR2(255),
    CONSTRAINT fk_audit_products_product FOREIGN KEY (product_id) REFERENCES Products(product_id),
    CONSTRAINT fk_audit_products_user FOREIGN KEY (changed_by) REFERENCES Users(user_id)
);

-- Orders audit table
CREATE TABLE Audit_Orders (
    audit_id NUMBER DEFAULT seq_audit_orders.NEXTVAL PRIMARY KEY,
    order_id NUMBER NOT NULL,
    old_status VARCHAR2(20),
    new_status VARCHAR2(20),
    old_total_amount NUMBER(10,2),
    new_total_amount NUMBER(10,2),
    operation_type VARCHAR2(10) CHECK (operation_type IN ('INSERT', 'UPDATE', 'DELETE')) NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by NUMBER,
    reason VARCHAR2(255),
    CONSTRAINT fk_audit_orders_order FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    CONSTRAINT fk_audit_orders_user FOREIGN KEY (changed_by) REFERENCES Users(user_id)
);

-- Customers audit table
CREATE TABLE Audit_Customers (
    audit_id NUMBER DEFAULT seq_audit_customers.NEXTVAL PRIMARY KEY,
    customer_id NUMBER NOT NULL,
    old_name VARCHAR2(100),
    new_name VARCHAR2(100),
    old_email VARCHAR2(100),
    new_email VARCHAR2(100),
    old_phone VARCHAR2(20),
    new_phone VARCHAR2(20),
    operation_type VARCHAR2(10) CHECK (operation_type IN ('INSERT', 'UPDATE', 'DELETE')) NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by NUMBER,
    CONSTRAINT fk_audit_customers_customer FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),
    CONSTRAINT fk_audit_customers_user FOREIGN KEY (changed_by) REFERENCES Users(user_id)
);

-- Payments audit table
CREATE TABLE Audit_Payments (
    audit_id NUMBER DEFAULT seq_audit_payments.NEXTVAL PRIMARY KEY,
    payment_id NUMBER NOT NULL,
    old_amount NUMBER(10,2),
    new_amount NUMBER(10,2),
    old_payment_status VARCHAR2(20),
    new_payment_status VARCHAR2(20),
    operation_type VARCHAR2(10) CHECK (operation_type IN ('INSERT', 'UPDATE', 'DELETE')) NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by NUMBER,
    CONSTRAINT fk_audit_payments_payment FOREIGN KEY (payment_id) REFERENCES Payments(payment_id),
    CONSTRAINT fk_audit_payments_user FOREIGN KEY (changed_by) REFERENCES Users(user_id)
);