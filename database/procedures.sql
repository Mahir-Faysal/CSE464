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