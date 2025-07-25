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
    ap.changed_at DESC;



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
    ao.order_id = 1 
    AND ao.operation_type IN ('INSERT', 'UPDATE') 
ORDER BY
    ao.order_id, ao.changed_at ASC;


-- Query 3: User Activity Log
SELECT
    u.username AS performing_user,
    u.role AS user_role,
    ap.operation_type,
    p.product_id,
    p.name AS product_name,
    TO_CHAR(ap.changed_at, 'YYYY-MM-DD HH24:MI:SS') AS action_timestamp
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