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
