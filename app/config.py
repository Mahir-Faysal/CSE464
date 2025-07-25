"""
Configuration file for E-Commerce Provenance System
"""

# Database Configuration
DB_USER = " "
DB_PASSWORD = " "  # Change this to your password
DB_DSN = " "

# Application Configuration
APP_TITLE = "E-Commerce Provenance Tracking System"
APP_ICON = "🛒"
PAGE_LAYOUT = "wide"

# UI Configuration
SIDEBAR_INFO = """
This application demonstrates comprehensive provenance tracking 
for an e-commerce system using Oracle 21g XE database.

**Features:**
- Current data visualization
- Complete audit trail tracking
- WHY/HOW/WHERE provenance analysis
- Individual record tracing
- Customer journey lineage
- Analytics dashboard
"""

# Query Limits
MAX_RECORDS_DISPLAY = 1000
DEFAULT_DATE_RANGE_DAYS = 30

# Security
ENABLE_DEBUG = False
LOG_QUERIES = False
