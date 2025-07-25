import streamlit as st
import pandas as pd
import oracledb
from datetime import datetime, date
import plotly.express as px
import plotly.graph_objects as go

# --- Streamlit App UI ---
st.set_page_config(layout="wide", page_title="E-Commerce Provenance Viewer")
st.title("🛒 E-Commerce Provenance Tracking System")

# --- Oracle Database Connection ---
DB_USER = ""  # Replace with your Oracle DB username
DB_PASSWORD = ""  # Replace with your Oracle DB password
DB_DSN = ""  # Replace with your Oracle DSN

@st.cache_resource
def init_connection():
    """Initializes and returns a connection to the Oracle database."""
    try:
        connection = oracledb.connect(user=DB_USER, password=DB_PASSWORD, dsn=DB_DSN)
        return connection
    except oracledb.Error as e:
        st.error(f"Error connecting to Oracle Database: {e}")
        st.error("Please check your DB_USER, DB_PASSWORD, and DB_DSN in the script.")
        return None

conn = init_connection()

# --- Data Fetching Functions ---
def run_query(query, params=None):
    """Runs a SQL query and returns the result as a Pandas DataFrame."""
    if conn is None:
        return pd.DataFrame()
    try:
        with conn.cursor() as cursor:
            if params:
                cursor.execute(query, params)
            else:
                cursor.execute(query)
            
            columns = [col[0] for col in cursor.description]
            rows = cursor.fetchall()
            df = pd.DataFrame(rows, columns=columns)
            return df
    except oracledb.Error as e:
        st.error(f"Database query error: {e}")
        return pd.DataFrame()
    except Exception as e:
        st.error(f"An unexpected error occurred: {e}")
        return pd.DataFrame()

# === CURRENT DATA FUNCTIONS ===
def get_current_users():
    """Fetches all current users."""
    query = """SELECT user_id, username, email, role, 
                      TO_CHAR(created_at, 'YYYY-MM-DD HH24:MI:SS') as created_at 
               FROM Users ORDER BY user_id"""
    return run_query(query)

def get_current_customers():
    """Fetches all current customers."""
    query = """SELECT c.customer_id, c.name, c.email, c.phone, 
                      SUBSTR(c.address, 1, 50) as address_preview,
                      u.username as created_by,
                      TO_CHAR(c.created_at, 'YYYY-MM-DD HH24:MI:SS') as created_at
               FROM Customers c
               LEFT JOIN Users u ON c.created_by = u.user_id
               ORDER BY c.customer_id"""
    return run_query(query)

def get_current_products():
    """Fetches all current products."""
    query = """SELECT p.product_id, p.name, 
                      SUBSTR(p.description, 1, 50) as description_preview,
                      p.price, p.stock_quantity, p.category,
                      u.username as created_by,
                      TO_CHAR(p.created_at, 'YYYY-MM-DD HH24:MI:SS') as created_at
               FROM Products p
               LEFT JOIN Users u ON p.created_by = u.user_id
               ORDER BY p.product_id"""
    return run_query(query)

def get_current_orders():
    """Fetches all current orders."""
    query = """SELECT o.order_id, c.name as customer_name, o.status, 
                      o.total_amount, u.username as created_by,
                      TO_CHAR(o.order_date, 'YYYY-MM-DD HH24:MI:SS') as order_date
               FROM Orders o
               LEFT JOIN Customers c ON o.customer_id = c.customer_id
               LEFT JOIN Users u ON o.created_by = u.user_id
               ORDER BY o.order_id"""
    return run_query(query)

def get_current_payments():
    """Fetches all current payments."""
    query = """SELECT p.payment_id, p.order_id, p.amount, p.payment_method, 
                      p.payment_status, u.username as created_by,
                      TO_CHAR(p.payment_date, 'YYYY-MM-DD HH24:MI:SS') as payment_date
               FROM Payments p
               LEFT JOIN Users u ON p.created_by = u.user_id
               ORDER BY p.payment_id"""
    return run_query(query)

# === AUDIT LOG FUNCTIONS ===
def get_audit_products(start_date=None, end_date=None):
    """Fetches product audit logs."""
    query = """SELECT ap.audit_id, p.name as product_name, ap.operation_type,
                      ap.old_price, ap.new_price, ap.old_stock_quantity, ap.new_stock_quantity,
                      u.username as changed_by, ap.reason,
                      TO_CHAR(ap.changed_at, 'YYYY-MM-DD HH24:MI:SS') as changed_at
               FROM Audit_Products ap
               LEFT JOIN Products p ON ap.product_id = p.product_id
               LEFT JOIN Users u ON ap.changed_by = u.user_id
               WHERE 1=1"""
    
    params = {}
    if start_date:
        query += " AND ap.changed_at >= TO_TIMESTAMP(:start_date, 'YYYY-MM-DD HH24:MI:SS')"
        params['start_date'] = datetime.combine(start_date, datetime.min.time()).strftime('%Y-%m-%d %H:%M:%S')
    if end_date:
        query += " AND ap.changed_at <= TO_TIMESTAMP(:end_date, 'YYYY-MM-DD HH24:MI:SS')"
        params['end_date'] = datetime.combine(end_date, datetime.max.time()).strftime('%Y-%m-%d %H:%M:%S')
    
    query += " ORDER BY ap.changed_at DESC"
    return run_query(query, params if params else None)

def get_audit_orders(start_date=None, end_date=None):
    """Fetches order audit logs."""
    query = """SELECT ao.audit_id, ao.order_id, ao.operation_type,
                      ao.old_status, ao.new_status, ao.old_total_amount, ao.new_total_amount,
                      u.username as changed_by, ao.reason,
                      TO_CHAR(ao.changed_at, 'YYYY-MM-DD HH24:MI:SS') as changed_at
               FROM Audit_Orders ao
               LEFT JOIN Users u ON ao.changed_by = u.user_id
               WHERE 1=1"""
    
    params = {}
    if start_date:
        query += " AND ao.changed_at >= TO_TIMESTAMP(:start_date, 'YYYY-MM-DD HH24:MI:SS')"
        params['start_date'] = datetime.combine(start_date, datetime.min.time()).strftime('%Y-%m-%d %H:%M:%S')
    if end_date:
        query += " AND ao.changed_at <= TO_TIMESTAMP(:end_date, 'YYYY-MM-DD HH24:MI:SS')"
        params['end_date'] = datetime.combine(end_date, datetime.max.time()).strftime('%Y-%m-%d %H:%M:%S')
    
    query += " ORDER BY ao.changed_at DESC"
    return run_query(query, params if params else None)

def get_audit_customers(start_date=None, end_date=None):
    """Fetches customer audit logs."""
    query = """SELECT ac.audit_id, ac.customer_id, ac.operation_type,
                      ac.old_name, ac.new_name, ac.old_email, ac.new_email,
                      u.username as changed_by,
                      TO_CHAR(ac.changed_at, 'YYYY-MM-DD HH24:MI:SS') as changed_at
               FROM Audit_Customers ac
               LEFT JOIN Users u ON ac.changed_by = u.user_id
               WHERE 1=1"""
    
    params = {}
    if start_date:
        query += " AND ac.changed_at >= TO_TIMESTAMP(:start_date, 'YYYY-MM-DD HH24:MI:SS')"
        params['start_date'] = datetime.combine(start_date, datetime.min.time()).strftime('%Y-%m-%d %H:%M:%S')
    if end_date:
        query += " AND ac.changed_at <= TO_TIMESTAMP(:end_date, 'YYYY-MM-DD HH24:MI:SS')"
        params['end_date'] = datetime.combine(end_date, datetime.max.time()).strftime('%Y-%m-%d %H:%M:%S')
    
    query += " ORDER BY ac.changed_at DESC"
    return run_query(query, params if params else None)

def get_audit_payments(start_date=None, end_date=None):
    """Fetches payment audit logs."""
    query = """SELECT ap.audit_id, ap.payment_id, ap.operation_type,
                      ap.old_amount, ap.new_amount, ap.old_payment_status, ap.new_payment_status,
                      u.username as changed_by,
                      TO_CHAR(ap.changed_at, 'YYYY-MM-DD HH24:MI:SS') as changed_at
               FROM Audit_Payments ap
               LEFT JOIN Users u ON ap.changed_by = u.user_id
               WHERE 1=1"""
    
    params = {}
    if start_date:
        query += " AND ap.changed_at >= TO_TIMESTAMP(:start_date, 'YYYY-MM-DD HH24:MI:SS')"
        params['start_date'] = datetime.combine(start_date, datetime.min.time()).strftime('%Y-%m-%d %H:%M:%S')
    if end_date:
        query += " AND ap.changed_at <= TO_TIMESTAMP(:end_date, 'YYYY-MM-DD HH24:MI:SS')"
        params['end_date'] = datetime.combine(end_date, datetime.max.time()).strftime('%Y-%m-%d %H:%M:%S')
    
    query += " ORDER BY ap.changed_at DESC"
    return run_query(query, params if params else None)

# === PROVENANCE QUERY FUNCTIONS ===
def get_why_provenance():
    """WHY-PROVENANCE: Product price changes with reasons."""
    query = """SELECT ap.audit_id, p.name as product_name, ap.old_price, ap.new_price,
                      (ap.new_price - ap.old_price) as price_change,
                      TO_CHAR(ap.changed_at, 'YYYY-MM-DD HH24:MI:SS') as changed_at,
                      u.username as changed_by, ap.reason
               FROM Audit_Products ap
               JOIN Products p ON ap.product_id = p.product_id
               LEFT JOIN Users u ON ap.changed_by = u.user_id
               WHERE ap.operation_type = 'UPDATE'
                 AND (ap.old_price != ap.new_price OR ap.old_price IS NULL)
               ORDER BY ap.changed_at DESC"""
    return run_query(query)

def get_how_provenance():
    """HOW-PROVENANCE: Order status transitions."""
    query = """SELECT ao.audit_id, o.order_id, ao.old_status, ao.new_status,
                      TO_CHAR(ao.changed_at, 'YYYY-MM-DD HH24:MI:SS') as changed_at,
                      u.username as changed_by, ao.reason,
                      CASE 
                          WHEN LAG(ao.changed_at) OVER (PARTITION BY ao.order_id ORDER BY ao.changed_at) IS NOT NULL THEN
                              ROUND((CAST(ao.changed_at AS DATE) - 
                                   CAST(LAG(ao.changed_at) OVER (PARTITION BY ao.order_id ORDER BY ao.changed_at) AS DATE)) * 24, 2)
                          ELSE NULL 
                      END as hours_in_previous_status
               FROM Audit_Orders ao
               JOIN Orders o ON ao.order_id = o.order_id
               LEFT JOIN Users u ON ao.changed_by = u.user_id
               ORDER BY ao.order_id, ao.changed_at ASC"""
    return run_query(query)

def get_where_provenance():
    """WHERE-PROVENANCE: User actions on specific tables."""
    query = """SELECT al.audit_id, al.table_name, al.record_id, al.operation_type,
                      al.field_name, al.old_value, al.new_value,
                      TO_CHAR(al.changed_at, 'YYYY-MM-DD HH24:MI:SS') as changed_at,
                      u.username, u.role
               FROM Audit_Log al
               LEFT JOIN Users u ON al.changed_by = u.user_id
               WHERE al.table_name IN ('Products', 'Orders', 'Customers', 'Payments')
               ORDER BY al.changed_at DESC"""
    return run_query(query)

def get_lineage_tracking(customer_id):
    """LINEAGE TRACKING: Complete customer journey."""
    if not customer_id:
        return pd.DataFrame()
    
    query = """SELECT * FROM (
                   SELECT 'Customer' as entity_type,
                          c.name as entity_name,
                          ac.operation_type,
                          TO_CHAR(ac.changed_at, 'YYYY-MM-DD HH24:MI:SS') as changed_at,
                          'Name: ' || NVL(ac.old_name, 'N/A') || ' → ' || NVL(ac.new_name, 'N/A') as change_details,
                          1 as sort_order
                   FROM Customers c
                   JOIN Audit_Customers ac ON c.customer_id = ac.customer_id
                   WHERE c.customer_id = :customer_id
                   
                   UNION ALL
                   
                   SELECT 'Order' as entity_type,
                          'Order #' || o.order_id as entity_name,
                          ao.operation_type,
                          TO_CHAR(ao.changed_at, 'YYYY-MM-DD HH24:MI:SS') as changed_at,
                          'Status: ' || NVL(ao.old_status, 'N/A') || ' → ' || NVL(ao.new_status, 'N/A') as change_details,
                          2 as sort_order
                   FROM Orders o
                   JOIN Audit_Orders ao ON o.order_id = ao.order_id
                   WHERE o.customer_id = :customer_id
                   
                   UNION ALL
                   
                   SELECT 'Payment' as entity_type,
                          'Payment #' || py.payment_id as entity_name,
                          ap.operation_type,
                          TO_CHAR(ap.changed_at, 'YYYY-MM-DD HH24:MI:SS') as changed_at,
                          'Status: ' || NVL(ap.old_payment_status, 'N/A') || ' → ' || NVL(ap.new_payment_status, 'N/A') as change_details,
                          3 as sort_order
                   FROM Orders o
                   JOIN Payments py ON o.order_id = py.order_id
                   JOIN Audit_Payments ap ON py.payment_id = ap.payment_id
                   WHERE o.customer_id = :customer_id
               )
               ORDER BY TO_TIMESTAMP(changed_at, 'YYYY-MM-DD HH24:MI:SS') ASC, sort_order"""
    
    return run_query(query, {'customer_id': customer_id})

# === ANALYTICS FUNCTIONS ===
def get_provenance_summary():
    """Gets summary statistics for provenance data."""
    query = """SELECT table_name, operation_type, COUNT(*) as change_count
               FROM Audit_Log
               GROUP BY table_name, operation_type
               ORDER BY table_name, operation_type"""
    return run_query(query)

def get_user_activity_summary():
    """Gets user activity summary."""
    query = """SELECT u.username, u.role, COUNT(al.audit_id) as total_changes
               FROM Users u
               LEFT JOIN Audit_Log al ON u.user_id = al.changed_by
               GROUP BY u.username, u.role
               ORDER BY total_changes DESC"""
    return run_query(query)

# === SELECTION HELPER FUNCTIONS ===
def get_customers_for_selection():
    """Gets customers for selection dropdown."""
    query = "SELECT customer_id, name FROM Customers ORDER BY name"
    return run_query(query)

def get_products_for_selection():
    """Gets products for selection dropdown."""
    query = "SELECT product_id, name FROM Products ORDER BY name"
    return run_query(query)

def get_orders_for_selection():
    """Gets orders for selection dropdown."""
    query = """SELECT o.order_id, 'Order #' || o.order_id || ' - ' || c.name as display_name
               FROM Orders o
               LEFT JOIN Customers c ON o.customer_id = c.customer_id
               ORDER BY o.order_id"""
    return run_query(query)

# === INDIVIDUAL TRACE FUNCTIONS ===
def get_product_trace(product_id):
    """Gets complete trace for a specific product."""
    if not product_id:
        return pd.DataFrame()
    
    query = """SELECT audit_id, operation_type, old_name, new_name, old_price, new_price,
                      old_stock_quantity, new_stock_quantity, old_category, new_category,
                      reason, TO_CHAR(changed_at, 'YYYY-MM-DD HH24:MI:SS') as changed_at,
                      (SELECT username FROM Users WHERE user_id = changed_by) as changed_by
               FROM Audit_Products
               WHERE product_id = :product_id
               ORDER BY changed_at ASC"""
    return run_query(query, {'product_id': product_id})

def get_order_trace(order_id):
    """Gets complete trace for a specific order."""
    if not order_id:
        return pd.DataFrame()
    
    query = """SELECT audit_id, operation_type, old_status, new_status, 
                      old_total_amount, new_total_amount, reason,
                      TO_CHAR(changed_at, 'YYYY-MM-DD HH24:MI:SS') as changed_at,
                      (SELECT username FROM Users WHERE user_id = changed_by) as changed_by
               FROM Audit_Orders
               WHERE order_id = :order_id
               ORDER BY changed_at ASC"""
    return run_query(query, {'order_id': order_id})

def get_customer_trace(customer_id):
    """Gets complete trace for a specific customer."""
    if not customer_id:
        return pd.DataFrame()
    
    query = """SELECT audit_id, operation_type, old_name, new_name, old_email, new_email,
                      old_phone, new_phone, TO_CHAR(changed_at, 'YYYY-MM-DD HH24:MI:SS') as changed_at,
                      (SELECT username FROM Users WHERE user_id = changed_by) as changed_by
               FROM Audit_Customers
               WHERE customer_id = :customer_id
               ORDER BY changed_at ASC"""
    return run_query(query, {'customer_id': customer_id})

# === MAIN APP UI ===
if conn is None:
    st.warning("Could not connect to the database. Please check your connection details.")
    st.stop()

# Create main tabs
tab1, tab2, tab3, tab4, tab5, tab6 = st.tabs([
    "📊 Current Data", 
    "📜 Audit Logs", 
    "🔍 Provenance Queries", 
    "📈 Analytics",
    "🔎 Individual Traces",
    "🛤️ Customer Journey"
])

# === TAB 1: CURRENT DATA ===
with tab1:
    st.header("Current System Data")
    
    data_tab1, data_tab2, data_tab3, data_tab4, data_tab5 = st.tabs([
        "👥 Users", "🏪 Customers", "📦 Products", "📋 Orders", "💳 Payments"
    ])
    
    with data_tab1:
        st.subheader("Current Users")
        users_df = get_current_users()
        if not users_df.empty:
            st.dataframe(users_df, use_container_width=True)
        else:
            st.info("No users found or unable to fetch data.")
    
    with data_tab2:
        st.subheader("Current Customers")
        customers_df = get_current_customers()
        if not customers_df.empty:
            st.dataframe(customers_df, use_container_width=True)
        else:
            st.info("No customers found or unable to fetch data.")
    
    with data_tab3:
        st.subheader("Current Products")
        products_df = get_current_products()
        if not products_df.empty:
            st.dataframe(products_df, use_container_width=True)
        else:
            st.info("No products found or unable to fetch data.")
    
    with data_tab4:
        st.subheader("Current Orders")
        orders_df = get_current_orders()
        if not orders_df.empty:
            st.dataframe(orders_df, use_container_width=True)
        else:
            st.info("No orders found or unable to fetch data.")
    
    with data_tab5:
        st.subheader("Current Payments")
        payments_df = get_current_payments()
        if not payments_df.empty:
            st.dataframe(payments_df, use_container_width=True)
        else:
            st.info("No payments found or unable to fetch data.")

# === TAB 2: AUDIT LOGS ===
with tab2:
    st.header("Audit Logs (Change History)")
    
    # Date filters
    col1, col2 = st.columns(2)
    with col1:
        start_date = st.date_input("Start Date:", value=None, key="audit_start")
    with col2:
        end_date = st.date_input("End Date:", value=date.today(), key="audit_end")
    
    audit_tab1, audit_tab2, audit_tab3, audit_tab4 = st.tabs([
        "📦 Product Changes", "📋 Order Changes", "🏪 Customer Changes", "💳 Payment Changes"
    ])
    
    with audit_tab1:
        st.subheader("Product Audit Trail")
        products_audit_df = get_audit_products(start_date, end_date)
        if not products_audit_df.empty:
            st.dataframe(products_audit_df, use_container_width=True)
        else:
            st.info("No product audit logs found for the selected date range.")
    
    with audit_tab2:
        st.subheader("Order Audit Trail")
        orders_audit_df = get_audit_orders(start_date, end_date)
        if not orders_audit_df.empty:
            st.dataframe(orders_audit_df, use_container_width=True)
        else:
            st.info("No order audit logs found for the selected date range.")
    
    with audit_tab3:
        st.subheader("Customer Audit Trail")
        customers_audit_df = get_audit_customers(start_date, end_date)
        if not customers_audit_df.empty:
            st.dataframe(customers_audit_df, use_container_width=True)
        else:
            st.info("No customer audit logs found for the selected date range.")
    
    with audit_tab4:
        st.subheader("Payment Audit Trail")
        payments_audit_df = get_audit_payments(start_date, end_date)
        if not payments_audit_df.empty:
            st.dataframe(payments_audit_df, use_container_width=True)
        else:
            st.info("No payment audit logs found for the selected date range.")

# === TAB 3: PROVENANCE QUERIES ===
with tab3:
    st.header("Provenance Analysis Queries")
    
    prov_tab1, prov_tab2, prov_tab3 = st.tabs([
        "❓ WHY-Provenance", "⚙️ HOW-Provenance", "📍 WHERE-Provenance"
    ])
    
    with prov_tab1:
        st.subheader("WHY-Provenance: Product Price Changes with Reasons")
        st.markdown("This shows **why** product prices were changed, including the business justification.")
        
        why_df = get_why_provenance()
        if not why_df.empty:
            st.dataframe(why_df, use_container_width=True)
            
            # Visualization
            if len(why_df) > 0:
                fig = px.bar(why_df.head(10), x='PRODUCT_NAME', y='PRICE_CHANGE', 
                           color='PRICE_CHANGE', title="Top 10 Product Price Changes",
                           hover_data=['REASON'])
                st.plotly_chart(fig, use_container_width=True)
        else:
            st.info("No price change data found.")
    
    with prov_tab2:
        st.subheader("HOW-Provenance: Order Status Transitions")
        st.markdown("This shows **how** orders progressed through different statuses over time.")
        
        how_df = get_how_provenance()
        if not how_df.empty:
            st.dataframe(how_df, use_container_width=True)
            
            # Show status transition flow
            status_flow = how_df.groupby(['OLD_STATUS', 'NEW_STATUS']).size().reset_index(name='count')
            if not status_flow.empty:
                fig = px.bar(status_flow, x='OLD_STATUS', y='count', color='NEW_STATUS',
                           title="Order Status Transition Flow")
                st.plotly_chart(fig, use_container_width=True)
        else:
            st.info("No order status transition data found.")
    
    with prov_tab3:
        st.subheader("WHERE-Provenance: User Actions Across Tables")
        st.markdown("This shows **where** changes originated from (which users made what changes).")
        
        where_df = get_where_provenance()
        if not where_df.empty:
            st.dataframe(where_df, use_container_width=True)
            
            # User activity chart
            user_activity = where_df.groupby(['USERNAME', 'TABLE_NAME']).size().reset_index(name='changes')
            if not user_activity.empty:
                fig = px.bar(user_activity, x='USERNAME', y='changes', color='TABLE_NAME',
                           title="User Activity by Table")
                st.plotly_chart(fig, use_container_width=True)
        else:
            st.info("No user activity data found.")

# === TAB 4: ANALYTICS ===
with tab4:
    st.header("Provenance Analytics Dashboard")
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("Change Summary by Table")
        summary_df = get_provenance_summary()
        if not summary_df.empty:
            fig = px.bar(summary_df, x='TABLE_NAME', y='CHANGE_COUNT', color='OPERATION_TYPE',
                        title="Changes by Table and Operation Type")
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.info("No summary data available.")
    
    with col2:
        st.subheader("User Activity Summary")
        user_activity_df = get_user_activity_summary()
        if not user_activity_df.empty:
            fig = px.pie(user_activity_df, values='TOTAL_CHANGES', names='USERNAME',
                        title="Changes by User")
            st.plotly_chart(fig, use_container_width=True)
        else:
            st.info("No user activity data available.")

# === TAB 5: INDIVIDUAL TRACES ===
with tab5:
    st.header("Individual Record Traces")
    
    trace_tab1, trace_tab2, trace_tab3 = st.tabs([
        "📦 Product Trace", "📋 Order Trace", "🏪 Customer Trace"
    ])
    
    with trace_tab1:
        st.subheader("Product History Trace")
        products_for_selection = get_products_for_selection()
        if not products_for_selection.empty:
            product_options = {f"{row['PRODUCT_ID']} - {row['NAME']}": row['PRODUCT_ID'] 
                             for _, row in products_for_selection.iterrows()}
            
            selected_product = st.selectbox("Select a Product:", 
                                          options=list(product_options.keys()),
                                          key="product_trace")
            
            if selected_product:
                product_id = product_options[selected_product]
                product_trace_df = get_product_trace(product_id)
                if not product_trace_df.empty:
                    st.dataframe(product_trace_df, use_container_width=True)
                    
                    # Narrative trace
                    st.markdown("### Change Narrative:")
                    for _, row in product_trace_df.iterrows():
                        if row['OPERATION_TYPE'] == 'INSERT':
                            st.markdown(f"- **{row['CHANGED_AT']}**: Product created by `{row['CHANGED_BY']}`")
                        elif row['OPERATION_TYPE'] == 'UPDATE':
                            changes = []
                            if row['OLD_PRICE'] != row['NEW_PRICE']:
                                changes.append(f"Price: ${row['OLD_PRICE']} → ${row['NEW_PRICE']}")
                            if row['OLD_STOCK_QUANTITY'] != row['NEW_STOCK_QUANTITY']:
                                changes.append(f"Stock: {row['OLD_STOCK_QUANTITY']} → {row['NEW_STOCK_QUANTITY']}")
                            st.markdown(f"- **{row['CHANGED_AT']}**: Updated by `{row['CHANGED_BY']}` - {', '.join(changes)}")
                            if row['REASON']:
                                st.markdown(f"  - Reason: {row['REASON']}")
                else:
                    st.info("No history found for this product.")
    
    with trace_tab2:
        st.subheader("Order History Trace")
        orders_for_selection = get_orders_for_selection()
        if not orders_for_selection.empty:
            order_options = {row['DISPLAY_NAME']: row['ORDER_ID'] 
                           for _, row in orders_for_selection.iterrows()}
            
            selected_order = st.selectbox("Select an Order:", 
                                        options=list(order_options.keys()),
                                        key="order_trace")
            
            if selected_order:
                order_id = order_options[selected_order]
                order_trace_df = get_order_trace(order_id)
                if not order_trace_df.empty:
                    st.dataframe(order_trace_df, use_container_width=True)
                    
                    # Status progression visualization
                    if len(order_trace_df) > 1:
                        fig = go.Figure()
                        fig.add_trace(go.Scatter(
                            x=list(range(len(order_trace_df))),
                            y=order_trace_df['NEW_STATUS'],
                            mode='lines+markers',
                            name='Status Progression',
                            text=order_trace_df['CHANGED_AT'],
                            hovertemplate='%{y}<br>%{text}<extra></extra>'
                        ))
                        fig.update_layout(title="Order Status Progression", 
                                        xaxis_title="Step", yaxis_title="Status")
                        st.plotly_chart(fig, use_container_width=True)
                else:
                    st.info("No history found for this order.")
    
    with trace_tab3:
        st.subheader("Customer History Trace")
        customers_for_selection = get_customers_for_selection()
        if not customers_for_selection.empty:
            customer_options = {f"{row['CUSTOMER_ID']} - {row['NAME']}": row['CUSTOMER_ID'] 
                              for _, row in customers_for_selection.iterrows()}
            
            selected_customer = st.selectbox("Select a Customer:", 
                                           options=list(customer_options.keys()),
                                           key="customer_trace")
            
            if selected_customer:
                customer_id = customer_options[selected_customer]
                customer_trace_df = get_customer_trace(customer_id)
                if not customer_trace_df.empty:
                    st.dataframe(customer_trace_df, use_container_width=True)
                else:
                    st.info("No history found for this customer.")

# === TAB 6: CUSTOMER JOURNEY ===
with tab6:
    st.header("Complete Customer Journey Lineage")
    st.markdown("Trace the complete journey of a customer through the system - from account creation to orders and payments.")
    
    customers_for_journey = get_customers_for_selection()
    if not customers_for_journey.empty:
        customer_journey_options = {f"{row['CUSTOMER_ID']} - {row['NAME']}": row['CUSTOMER_ID'] 
                                  for _, row in customers_for_journey.iterrows()}
        
        selected_journey_customer = st.selectbox("Select Customer for Journey Analysis:", 
                                                options=list(customer_journey_options.keys()),
                                                key="journey_customer")
        
        if selected_journey_customer:
            customer_id = customer_journey_options[selected_journey_customer]
            lineage_df = get_lineage_tracking(customer_id)
            
            if not lineage_df.empty:
                st.subheader(f"Journey for: {selected_journey_customer}")
                st.dataframe(lineage_df, use_container_width=True)
                
                # Timeline visualization
                fig = px.timeline(lineage_df, 
                                x_start='CHANGED_AT', x_end='CHANGED_AT',
                                y='ENTITY_TYPE', color='OPERATION_TYPE',
                                title="Customer Journey Timeline",
                                hover_data=['CHANGE_DETAILS'])
                st.plotly_chart(fig, use_container_width=True)
                
                # Narrative journey
                st.markdown("### Journey Narrative:")
                for _, row in lineage_df.iterrows():
                    st.markdown(f"- **{row['CHANGED_AT']}** ({row['ENTITY_TYPE']}): {row['OPERATION_TYPE']} - {row['CHANGE_DETAILS']}")
            else:
                st.info("No journey data found for this customer.")

# === SIDEBAR ===
st.sidebar.header("About E-Commerce Provenance System")
st.sidebar.info(
    "This application demonstrates comprehensive provenance tracking for an e-commerce system using Oracle 21g XE database.\n\n"
    "**Features:**\n"
    "- Current data visualization\n"
    "- Complete audit trail tracking\n"
    "- WHY/HOW/WHERE provenance analysis\n"
    "- Individual record tracing\n"
    "- Customer journey lineage\n"
    "- Analytics dashboard"
)

if conn:
    st.sidebar.success("✅ Connected to Oracle DB")
    # Show some quick stats
    try:
        total_products = run_query("SELECT COUNT(*) as count FROM Products")
        total_orders = run_query("SELECT COUNT(*) as count FROM Orders")
        total_customers = run_query("SELECT COUNT(*) as count FROM Customers")
        total_audit_logs = run_query("SELECT COUNT(*) as count FROM Audit_Log")
        
        st.sidebar.markdown("### Quick Stats")
        if not total_products.empty:
            st.sidebar.metric("Total Products", total_products.iloc[0]['COUNT'])
        if not total_orders.empty:
            st.sidebar.metric("Total Orders", total_orders.iloc[0]['COUNT'])
        if not total_customers.empty:
            st.sidebar.metric("Total Customers", total_customers.iloc[0]['COUNT'])
        if not total_audit_logs.empty:
            st.sidebar.metric("Total Audit Logs", total_audit_logs.iloc[0]['COUNT'])
    except:
        pass
else:
    st.sidebar.error("❌ Failed to connect to Oracle DB")

st.sidebar.markdown("---")
st.sidebar.markdown("**To run this app:**\n1. Save as `ecommerce_app.py`\n2. Run: ` streamlit run ecommerce_app.py`")
