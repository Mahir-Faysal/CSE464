--quer 1 : why was the price changed?
SELECT 
    p.name AS product_name,
    ap.old_price,
    ap.new_price,
    (ap.new_price - ap.old_price) AS price_difference,
    ap.changed_at,
    u.username AS changed_by_user,
    ap.reason
FROM 
    Audit_Products ap
JOIN 
    Products p ON ap.product_id = p.product_id
LEFT JOIN 
    Users u ON ap.changed_by = u.user_id
WHERE 
    ap.product_id = 1 
    AND (ap.old_price IS NOT NULL OR ap.new_price IS NOT NULL) 
    AND NVL(ap.old_price, -1) != NVL(ap.new_price, -1) 
ORDER BY 
    ap.changed_at ASC;


-- Query 2: Order Status Transition and Time in Each Status

SELECT
    ao.order_id,
    ao.old_status,
    ao.new_status,
    u.username AS changed_by_user,
    ao.reason AS change_reason,
    ao.changed_at
FROM
    Audit_Orders ao
JOIN
    Orders o ON ao.order_id = o.order_id
LEFT JOIN
    Users u ON ao.changed_by = u.user_id
WHERE
    ao.order_id = 5 
    AND ao.operation_type IN ('INSERT', 'UPDATE') 
ORDER BY
    ao.order_id, ao.changed_at ASC;


-- Query 3: User Activity on a Specific Table

SELECT 
*
  --  u.username AS performing_user,
    --u.role AS user_role,
   -- ap.operation_type,
   -- p.product_id
   -- p.name AS product_name
    
FROM
    Audit_Orders ap
JOIN
    Users u ON ap.changed_by = u.user_id
JOIN
    Orders p ON ap.order_id = p.order_id 
WHERE
    ap.changed_at >= SYSDATE - 7 ;



-- Query 4: Customer Changes Summary
SELECT
    ac.customer_id,
    ac.operation_type,
    ac.old_name,
    ac.new_name,
    ac.old_email,
    ac.new_email,
    ac.old_phone,
    ac.new_phone,
u.username AS changed_by_user
FROM
    Audit_Customers ac
LEFT JOIN
    Users u ON ac.changed_by = u.user_id
WHERE
    ac.customer_id = 1 
ORDER BY
    ac.changed_at ASC;

-- Query 5: last 7 days of user activity on Products
SELECT
    u.username AS performing_user,
    u.role AS user_role,
    ap.operation_type,
    p.product_id,
    p.name AS product_name,
    ap.changed_at
FROM
    Audit_Products ap
JOIN
    Users u ON ap.changed_by = u.user_id
JOIN
    Products p ON ap.product_id = p.product_id -- Join with Products to get current name if needed, or for context
WHERE
    ap.changed_at >= SYSDATE - 7 -- Replace :NUMBER_OF_DAYS with a value, e.g., 7 for the last week
ORDER BY
    ap.changed_at ASC, u.username;

-- total sum of a customer's orders
SELECT
    c.customer_id,
    c.name AS customer_name,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS sum_of_total_amounts
FROM
    Customers c
JOIN
    Orders o ON c.customer_id = o.customer_id
WHERE
    c.customer_id = 2 
GROUP BY
    c.customer_id,
    c.name
ORDER BY
    customer_name;


-- query 4
SELECT
    al.audit_id,
    al.table_name,
    al.record_id AS affected_order_id,
    al.operation_type,
    al.field_name,
    al.changed_at,
    u.username AS performed_by_user,
    u.role AS user_role
FROM
    Audit_Log al
JOIN
    Users u ON al.changed_by = u.user_id
WHERE
    u.username = 'admin' 
    AND al.table_name = 'Orders' 
ORDER BY
    al.changed_at DESC;