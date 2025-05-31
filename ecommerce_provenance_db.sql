-- ===============================================
-- E-COMMERCE PROVENANCE-ENABLED DATABASE SYSTEM
-- Oracle Database 21c Express Edition
-- ===============================================

-- ===============================================
-- CLEANUP (Drop everything and restart clean)
-- ===============================================
DROP TABLE Audit_Payments CASCADE CONSTRAINTS;
DROP TABLE Audit_Customers CASCADE CONSTRAINTS;
DROP TABLE Audit_Orders CASCADE CONSTRAINTS;
DROP TABLE Audit_Products CASCADE CONSTRAINTS;
DROP TABLE Audit_Log CASCADE CONSTRAINTS;
DROP TABLE Payments CASCADE CONSTRAINTS;
DROP TABLE OrderItems CASCADE CONSTRAINTS;
DROP TABLE Orders CASCADE CONSTRAINTS;
DROP TABLE Products CASCADE CONSTRAINTS;
DROP TABLE Customers CASCADE CONSTRAINTS;
DROP TABLE Users CASCADE CONSTRAINTS;

DROP SEQUENCE seq_users;
DROP SEQUENCE seq_customers;
DROP SEQUENCE seq_products;
DROP SEQUENCE seq_orders;
DROP SEQUENCE seq_orderitems;
DROP SEQUENCE seq_payments;
DROP SEQUENCE seq_audit_log;
DROP SEQUENCE seq_audit_products;
DROP SEQUENCE seq_audit_orders;
DROP SEQUENCE seq_audit_customers;
DROP SEQUENCE seq_audit_payments;

-- ===============================================
-- CREATE SEQUENCES
-- ===============================================
CREATE SEQUENCE seq_users START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_customers START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_products START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_orders START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_orderitems START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_payments START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_audit_log START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_audit_products START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_audit_orders START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_audit_customers START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_audit_payments START WITH 1 INCREMENT BY 1;

-- ===============================================
-- CORE TABLES (WITH PROPER DEFAULTS)
-- ===============================================

-- Users table
CREATE TABLE Users (
    user_id NUMBER DEFAULT seq_users.NEXTVAL PRIMARY KEY,
    username VARCHAR2(50) UNIQUE NOT NULL,
    email VARCHAR2(100) UNIQUE NOT NULL,
    role VARCHAR2(20) CHECK (role IN ('admin', 'employee', 'customer')) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Customers table
CREATE TABLE Customers (
    customer_id NUMBER DEFAULT seq_customers.NEXTVAL PRIMARY KEY,
    name VARCHAR2(100) NOT NULL,
    email VARCHAR2(100) UNIQUE NOT NULL,
    phone VARCHAR2(20),
    address CLOB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by NUMBER,
    CONSTRAINT fk_customers_created_by FOREIGN KEY (created_by) REFERENCES Users(user_id)
);

-- Products table
CREATE TABLE Products (
    product_id NUMBER DEFAULT seq_products.NEXTVAL PRIMARY KEY,
    name VARCHAR2(100) NOT NULL,
    description CLOB,
    price NUMBER(10,2) NOT NULL,
    stock_quantity NUMBER DEFAULT 0 NOT NULL,
    category VARCHAR2(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by NUMBER,
    CONSTRAINT fk_products_created_by FOREIGN KEY (created_by) REFERENCES Users(user_id)
);

-- Orders table
CREATE TABLE Orders (
    order_id NUMBER DEFAULT seq_orders.NEXTVAL PRIMARY KEY,
    customer_id NUMBER NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR2(20) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
    total_amount NUMBER(10,2) DEFAULT 0.00 NOT NULL,
    created_by NUMBER,
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),
    CONSTRAINT fk_orders_created_by FOREIGN KEY (created_by) REFERENCES Users(user_id)
);

-- OrderItems table
CREATE TABLE OrderItems (
    order_item_id NUMBER DEFAULT seq_orderitems.NEXTVAL PRIMARY KEY,
    order_id NUMBER NOT NULL,
    product_id NUMBER NOT NULL,
    quantity NUMBER NOT NULL,
    unit_price NUMBER(10,2) NOT NULL,
    total_price NUMBER(10,2) GENERATED ALWAYS AS (quantity * unit_price),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by NUMBER,
    CONSTRAINT fk_orderitems_order FOREIGN KEY (order_id) REFERENCES Orders(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_orderitems_product FOREIGN KEY (product_id) REFERENCES Products(product_id),
    CONSTRAINT fk_orderitems_created_by FOREIGN KEY (created_by) REFERENCES Users(user_id)
);

-- Payments table
CREATE TABLE Payments (
    payment_id NUMBER DEFAULT seq_payments.NEXTVAL PRIMARY KEY,
    order_id NUMBER NOT NULL,
    amount NUMBER(10,2) NOT NULL,
    payment_method VARCHAR2(50) NOT NULL,
    payment_status VARCHAR2(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'completed', 'failed', 'refunded')),
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by NUMBER,
    CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    CONSTRAINT fk_payments_created_by FOREIGN KEY (created_by) REFERENCES Users(user_id)
);

-- ===============================================
-- AUDIT TABLES (ALL WITH PROPER DEFAULTS)
-- ===============================================

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

-- Create indexes
CREATE INDEX idx_audit_log_table_record ON Audit_Log(table_name, record_id);
CREATE INDEX idx_audit_log_changed_at ON Audit_Log(changed_at);

-- ===============================================
-- TRIGGERS (SIMPLIFIED - NO EXPLICIT SEQUENCE CALLS)
-- ===============================================

-- Products triggers
CREATE OR REPLACE TRIGGER tr_products_insert
AFTER INSERT ON Products
FOR EACH ROW
BEGIN
    INSERT INTO Audit_Products (
        product_id, new_name, new_price, new_stock_quantity, new_category,
        operation_type, changed_by, reason
    ) VALUES (
        :NEW.product_id, :NEW.name, :NEW.price, 
        :NEW.stock_quantity, :NEW.category, 'INSERT', :NEW.created_by, 'New product created'
    );
    
    INSERT INTO Audit_Log (
        table_name, record_id, operation_type, new_value, changed_by
    ) VALUES (
        'Products', :NEW.product_id, 'INSERT', 
        'Product created: ' || :NEW.name, :NEW.created_by
    );
END;
/

CREATE OR REPLACE TRIGGER tr_products_update
AFTER UPDATE ON Products
FOR EACH ROW
DECLARE
    v_user_id NUMBER;
BEGIN
    BEGIN
        SELECT user_id INTO v_user_id FROM Users WHERE username = USER;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN v_user_id := 1;
    END;
    
    INSERT INTO Audit_Products (
        product_id, old_name, new_name, old_price, new_price,
        old_stock_quantity, new_stock_quantity, old_category, new_category,
        operation_type, changed_by, reason
    ) VALUES (
        :NEW.product_id, :OLD.name, :NEW.name, :OLD.price, :NEW.price,
        :OLD.stock_quantity, :NEW.stock_quantity, :OLD.category, :NEW.category,
        'UPDATE', v_user_id, 'Product updated'
    );
END;
/

-- Products delete trigger
CREATE OR REPLACE TRIGGER tr_products_delete
AFTER DELETE ON Products
FOR EACH ROW
DECLARE
    v_user_id NUMBER := 1; -- Default to admin
BEGIN
    INSERT INTO Audit_Products (
        product_id, old_name, old_price, old_stock_quantity, old_category,
        operation_type, changed_by, reason
    ) VALUES (
        :OLD.product_id, :OLD.name, :OLD.price, 
        :OLD.stock_quantity, :OLD.category, 'DELETE', v_user_id, 'Product deleted from system'
    );
    
    INSERT INTO Audit_Log (
        table_name, record_id, operation_type, old_value, changed_by
    ) VALUES (
        'Products', :OLD.product_id, 'DELETE', 
        'Product deleted: ' || :OLD.name || ', Price: $' || :OLD.price, v_user_id
    );
END;
/

-- Orders triggers
CREATE OR REPLACE TRIGGER tr_orders_insert
AFTER INSERT ON Orders
FOR EACH ROW
BEGIN
    INSERT INTO Audit_Orders (
        order_id, new_status, new_total_amount, operation_type, changed_by, reason
    ) VALUES (
        :NEW.order_id, :NEW.status, :NEW.total_amount, 
        'INSERT', :NEW.created_by, 'New order created'
    );
END;
/

CREATE OR REPLACE TRIGGER tr_orders_update
AFTER UPDATE ON Orders
FOR EACH ROW
DECLARE
    v_user_id NUMBER;
BEGIN
    BEGIN
        SELECT user_id INTO v_user_id FROM Users WHERE username = USER;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN v_user_id := 1;
    END;
    
    INSERT INTO Audit_Orders (
        order_id, old_status, new_status, old_total_amount, new_total_amount,
        operation_type, changed_by, reason
    ) VALUES (
        :NEW.order_id, :OLD.status, :NEW.status, 
        :OLD.total_amount, :NEW.total_amount, 'UPDATE', v_user_id, 'Order updated'
    );
END;
/

-- Orders delete trigger
CREATE OR REPLACE TRIGGER tr_orders_delete
AFTER DELETE ON Orders
FOR EACH ROW
DECLARE
    v_user_id NUMBER := 1;
BEGIN
    INSERT INTO Audit_Orders (
        order_id, old_status, old_total_amount, operation_type, changed_by, reason
    ) VALUES (
        :OLD.order_id, :OLD.status, :OLD.total_amount, 
        'DELETE', v_user_id, 'Order completely removed from system'
    );
    
    INSERT INTO Audit_Log (
        table_name, record_id, operation_type, old_value, changed_by
    ) VALUES (
        'Orders', :OLD.order_id, 'DELETE', 
        'Order deleted: Status=' || :OLD.status || ', Amount=$' || :OLD.total_amount, v_user_id
    );
END;
/

-- Customers triggers
CREATE OR REPLACE TRIGGER tr_customers_insert
AFTER INSERT ON Customers
FOR EACH ROW
BEGIN
    INSERT INTO Audit_Customers (
        customer_id, new_name, new_email, new_phone, operation_type, changed_by
    ) VALUES (
        :NEW.customer_id, :NEW.name, :NEW.email, 
        :NEW.phone, 'INSERT', :NEW.created_by
    );
END;
/

CREATE OR REPLACE TRIGGER tr_customers_update
AFTER UPDATE ON Customers
FOR EACH ROW
DECLARE
    v_user_id NUMBER;
BEGIN
    BEGIN
        SELECT user_id INTO v_user_id FROM Users WHERE username = USER;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN v_user_id := 1;
    END;
    
    INSERT INTO Audit_Customers (
        customer_id, old_name, new_name, old_email, new_email, old_phone, new_phone,
        operation_type, changed_by
    ) VALUES (
        :NEW.customer_id, :OLD.name, :NEW.name, 
        :OLD.email, :NEW.email, :OLD.phone, :NEW.phone, 'UPDATE', v_user_id
    );
END;
/

-- Customers delete trigger
CREATE OR REPLACE TRIGGER tr_customers_delete
AFTER DELETE ON Customers
FOR EACH ROW
DECLARE
    v_user_id NUMBER := 1;
BEGIN
    INSERT INTO Audit_Customers (
        customer_id, old_name, old_email, old_phone, operation_type, changed_by
    ) VALUES (
        :OLD.customer_id, :OLD.name, :OLD.email, 
        :OLD.phone, 'DELETE', v_user_id
    );
    
    INSERT INTO Audit_Log (
        table_name, record_id, operation_type, old_value, changed_by
    ) VALUES (
        'Customers', :OLD.customer_id, 'DELETE', 
        'Customer deleted: ' || :OLD.name, v_user_id
    );
END;
/

-- Payments triggers
CREATE OR REPLACE TRIGGER tr_payments_insert
AFTER INSERT ON Payments
FOR EACH ROW
BEGIN
    INSERT INTO Audit_Payments (
        payment_id, new_amount, new_payment_status, operation_type, changed_by
    ) VALUES (
        :NEW.payment_id, :NEW.amount, :NEW.payment_status, 
        'INSERT', :NEW.created_by
    );
END;
/

CREATE OR REPLACE TRIGGER tr_payments_update
AFTER UPDATE ON Payments
FOR EACH ROW
DECLARE
    v_user_id NUMBER;
BEGIN
    BEGIN
        SELECT user_id INTO v_user_id FROM Users WHERE username = USER;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN v_user_id := 1;
    END;
    
    INSERT INTO Audit_Payments (
        payment_id, old_amount, new_amount, old_payment_status, new_payment_status,
        operation_type, changed_by
    ) VALUES (
        :NEW.payment_id, :OLD.amount, :NEW.amount, 
        :OLD.payment_status, :NEW.payment_status, 'UPDATE', v_user_id
    );
END;
/

-- ===============================================
-- STORED PROCEDURES (SAME AS BEFORE)
-- ===============================================

CREATE OR REPLACE PROCEDURE UpdateProductPrice(
    p_product_id IN NUMBER,
    p_new_price IN NUMBER,
    p_reason IN VARCHAR2,
    p_user_id IN NUMBER
)
IS
    v_old_price NUMBER(10,2);
BEGIN
    SELECT price INTO v_old_price FROM Products WHERE product_id = p_product_id;
    UPDATE Products SET price = p_new_price WHERE product_id = p_product_id;
    
    UPDATE Audit_Products 
    SET reason = p_reason 
    WHERE product_id = p_product_id 
    AND operation_type = 'UPDATE' 
    AND audit_id = (SELECT MAX(audit_id) FROM Audit_Products WHERE product_id = p_product_id AND operation_type = 'UPDATE');
    
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END UpdateProductPrice;
/

CREATE OR REPLACE PROCEDURE ChangeOrderStatus(
    p_order_id IN NUMBER,
    p_new_status IN VARCHAR2,
    p_reason IN VARCHAR2,
    p_user_id IN NUMBER
)
IS
    v_old_status VARCHAR2(20);
BEGIN
    SELECT status INTO v_old_status FROM Orders WHERE order_id = p_order_id;
    UPDATE Orders SET status = p_new_status WHERE order_id = p_order_id;
    
    UPDATE Audit_Orders 
    SET reason = p_reason 
    WHERE order_id = p_order_id 
    AND operation_type = 'UPDATE' 
    AND audit_id = (SELECT MAX(audit_id) FROM Audit_Orders WHERE order_id = p_order_id AND operation_type = 'UPDATE');
    
    IF p_new_status = 'cancelled' THEN
        FOR item_rec IN (SELECT product_id, quantity FROM OrderItems WHERE order_id = p_order_id) LOOP
            UPDATE Products SET stock_quantity = stock_quantity + item_rec.quantity WHERE product_id = item_rec.product_id;
        END LOOP;
    END IF;
    
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END ChangeOrderStatus;
/

-- ===============================================
-- SAMPLE DATA (NO EXPLICIT SEQUENCES)
-- ===============================================

-- Insert Users
INSERT INTO Users (username, email, role) VALUES ('admin', 'admin@ecommerce.com', 'admin');
INSERT INTO Users (username, email, role) VALUES ('employee1', '111@ecommerce.com', 'employee');
INSERT INTO Users (username, email, role) VALUES ('employee2', '222@ecommerce.com', 'employee');


-- Insert Customers
INSERT INTO Customers (name, email, phone, address, created_by) VALUES ('Mahir', 'mahir@email.com', '111-111-1111', 'narayanganj, City D', 3);
INSERT INTO Customers (name, email, phone, address, created_by) VALUES ('Tasnuva', 'tasnuva@email.com', '222-222-2222', 'Mirpur, City C', 1);
INSERT INTO Customers (name, email, phone, address, created_by) VALUES ('Alice', 'alice@email.com', '123-456-7890', '123 Main St, City A', 2);
INSERT INTO Customers (name, email, phone, address, created_by) VALUES ('Bob', 'bob@email.com', '234-567-8901', '456 Oak Ave, City B', 2);



-- Insert Products
INSERT INTO Products (name, description, price, stock_quantity, category, created_by) VALUES ('Laptop', 'High-performance laptop with 16GB RAM', 1299.99, 50, 'Electronics', 1);
INSERT INTO Products (name, description, price, stock_quantity, category, created_by) VALUES ('Wireless Mouse', 'Ergonomic wireless mouse with USB receiver', 29.99, 200, 'Electronics', 2);
INSERT INTO Products (name, description, price, stock_quantity, category, created_by) VALUES ('Office Chair', 'Comfortable ergonomic office chair', 199.99, 25, 'Furniture', 2);
INSERT INTO Products (name, description, price, stock_quantity, category, created_by) VALUES ('Coffee Maker', 'Automatic drip coffee maker - 12 cup', 89.99, 15, 'Appliances', 3);

-- Insert Orders
INSERT INTO Orders (customer_id, status, total_amount, created_by) VALUES (1, 'pending', 1329.98, 2);
INSERT INTO Orders (customer_id, status, total_amount, created_by) VALUES (2, 'processing', 199.99, 3);
INSERT INTO Orders (customer_id, status, total_amount, created_by) VALUES (3, 'shipped', 239.98, 2);

-- Insert OrderItems
INSERT INTO OrderItems (order_id, product_id, quantity, unit_price, created_by) VALUES (1, 1, 1, 1299.99, 2);
INSERT INTO OrderItems (order_id, product_id, quantity, unit_price, created_by) VALUES (1, 2, 1, 29.99, 2);
INSERT INTO OrderItems (order_id, product_id, quantity, unit_price, created_by) VALUES (2, 3, 1, 199.99, 3);

-- Insert Payments
INSERT INTO Payments (order_id, amount, payment_method, payment_status, created_by) VALUES (1, 1329.98, 'Credit Card', 'completed', 2);
INSERT INTO Payments (order_id, amount, payment_method, payment_status, created_by) VALUES (2, 199.99, 'PayPal', 'completed', 3);
select * from Payments;
COMMIT;

-- ===============================================
-- TEST THE SYSTEM
-- ===============================================

-- Test provenance tracking
BEGIN
    UpdateProductPrice(1, 1199.99, 'Black Friday Sale', 1);
    ChangeOrderStatus(1, 'processing', 'Payment confirmed, preparing for shipment', 2);
END;
/

-- Test customer update
UPDATE Customers SET phone = '123-456-7899' WHERE customer_id = 1;

-- Test payment update
UPDATE Payments SET payment_status = 'refunded' WHERE payment_id = 2;

COMMIT;

-- Show results
SELECT 'Database setup complete!' as Status FROM DUAL;

-- Test queries
SELECT * FROM Customers ORDER BY customer_id;
SELECT * FROM Audit_Customers ORDER BY audit_id;


SELECT 
    p.name AS product_name,
    ap.old_price,
    ap.new_price,
    (ap.new_price - ap.old_price) AS price_difference,
    TO_CHAR(ap.changed_at, 'YYYY-MM-DD HH24:MI:SS') AS change_timestamp,
    u.username AS changed_by_user,
    ap.reason
FROM 
    Audit_Products ap
JOIN 
    Products p ON ap.product_id = p.product_id
LEFT JOIN 
    Users u ON ap.changed_by = u.user_id
WHERE 
    ap.product_id = 1 -- Replace :ENTER_PRODUCT_ID with the actual product_id you want to trace
    AND (ap.old_price IS NOT NULL OR ap.new_price IS NOT NULL) -- Ensure there was a price to change or a new price
    AND NVL(ap.old_price, -1) != NVL(ap.new_price, -1) -- Only show actual changes in price
ORDER BY 
    ap.changed_at DESC;




    SELECT
    ao.order_id,
    ao.old_status,
    ao.new_status,
    TO_CHAR(ao.changed_at, 'YYYY-MM-DD HH24:MI:SS') AS status_change_time,
    u.username AS changed_by_user,
    ao.reason AS change_reason,
    LAG(TO_CHAR(ao.changed_at, 'YYYY-MM-DD HH24:MI:SS'), 1, TO_CHAR(o.order_date, 'YYYY-MM-DD HH24:MI:SS')) OVER (PARTITION BY ao.order_id ORDER BY ao.changed_at) AS previous_event_time,
    ROUND((CAST(ao.changed_at AS DATE) - 
           CAST(LAG(ao.changed_at, 1, o.order_date) OVER (PARTITION BY ao.order_id ORDER BY ao.changed_at) AS DATE)) * 24, 2) AS hours_in_previous_status
FROM
    Audit_Orders ao
JOIN
    Orders o ON ao.order_id = o.order_id
LEFT JOIN
    Users u ON ao.changed_by = u.user_id
WHERE
    ao.order_id = 1 -- Replace :ENTER_ORDER_ID with the actual order_id
    AND ao.operation_type IN ('INSERT', 'UPDATE') -- Consider only creation and updates for status changes
ORDER BY
    ao.order_id, ao.changed_at ASC;



SELECT
    al.audit_id,
    al.table_name,
    al.record_id AS affected_order_id,
    al.operation_type,
    al.field_name,
    SUBSTR(al.old_value, 1, 100) AS old_value_preview, -- Preview long CLOB values
    SUBSTR(al.new_value, 1, 100) AS new_value_preview, -- Preview long CLOB values
    TO_CHAR(al.changed_at, 'YYYY-MM-DD HH24:MI:SS') AS action_timestamp,
    u.username AS performed_by_user,
    u.role AS user_role
FROM
    Audit_Log al
JOIN
    Users u ON al.changed_by = u.user_id
WHERE
    u.user_id = 1 -- Replace :ENTER_USERNAME with the actual username
    AND al.table_name = 'Orders' -- Specify the table of interest
ORDER BY
    al.changed_at DESC;



SELECT
    ac.customer_id,
    ac.operation_type,
    ac.old_name,
    ac.new_name,
    ac.old_email,
    ac.new_email,
    ac.old_phone,
    ac.new_phone,
    TO_CHAR(ac.changed_at, 'YYYY-MM-DD HH24:MI:SS') AS change_timestamp,
    u.username AS changed_by_user
FROM
    Audit_Customers ac
LEFT JOIN
    Users u ON ac.changed_by = u.user_id
WHERE
    ac.customer_id = 2 -- Replace :ENTER_CUSTOMER_ID with the actual customer_id
ORDER BY
    ac.changed_at ASC;



SELECT product_id, name, price, stock_quantity FROM Products ORDER BY product_id;




SELECT customer_id, name, email, phone FROM Customers ORDER BY customer_id;
DELETE FROM Customers WHERE customer_id = 4;

ALTER TABLE Audit_Customers DROP CONSTRAINT fk_audit_customers_customer;
ALTER TABLE Audit_Products DROP CONSTRAINT fk_audit_products_product;
ALTER TABLE Audit_Orders DROP CONSTRAINT fk_audit_orders_order;
ALTER TABLE Audit_Payments DROP CONSTRAINT fk_audit_payments_payment;

SELECT
    ac.customer_id,
    ac.operation_type,
    ac.old_name as deleted_customer_name,
    ac.old_email as deleted_email,
    ac.old_phone as deleted_phone,
    TO_CHAR(ac.changed_at, 'YYYY-MM-DD HH24:MI:SS') AS deletion_timestamp,
    u.username AS deleted_by_user
FROM
    Audit_Customers ac
LEFT JOIN
    Users u ON ac.changed_by = u.user_id
WHERE
    ac.customer_id = 4
    AND ac.operation_type = 'DELETE'
ORDER BY
    ac.changed_at DESC;

    SELECT 'GENERAL AUDIT LOG:' as info FROM DUAL;
SELECT
    table_name,
    record_id,
    operation_type,
    SUBSTR(old_value, 1, 100) as what_was_deleted,
    TO_CHAR(changed_at, 'YYYY-MM-DD HH24:MI:SS') AS when_deleted
FROM
    Audit_Log
WHERE
    table_name = 'Customers'
    AND record_id = 4
    AND operation_type = 'DELETE'
ORDER BY
    changed_at DESC;

    SELECT
    ac.customer_id,
    ac.operation_type,
    ac.old_name,
    ac.new_name,
    ac.old_email,
    ac.new_email,
    ac.old_phone,
    ac.new_phone,
    TO_CHAR(ac.changed_at, 'YYYY-MM-DD HH24:MI:SS') AS change_timestamp,
    u.username AS changed_by_user
FROM
    Audit_Customers ac
LEFT JOIN
    Users u ON ac.changed_by = u.user_id
WHERE
    ac.customer_id = 1 -- Replace :ENTER_CUSTOMER_ID with the actual customer_id
ORDER BY
    ac.changed_at ASC;


    SELECT
    p.product_id,
    p.name AS product_name,
    p.category,
    p.price,
    TO_CHAR(p.created_at, 'YYYY-MM-DD HH24:MI:SS') AS creation_timestamp,
    u.username AS created_by_user,
    ap.reason AS creation_reason -- Assuming the INSERT trigger populates a reason like 'New product created'
FROM
    Products p
JOIN
    Audit_Products ap ON p.product_id = ap.product_id AND ap.operation_type = 'INSERT'
LEFT JOIN
    Users u ON p.created_by = u.user_id -- Or ap.changed_by if created_by is not directly on Products
WHERE
    p.created_at >= SYSDATE - 30 -- Example: Products created in the last 30 days
ORDER BY
    p.created_at DESC;