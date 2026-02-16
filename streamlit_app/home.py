import streamlit as st
import requests
from datetime import datetime

# Configuration
API_BASE_URL = "http://fastapi:8000"

st.set_page_config(
    page_title="Invoice AI System",
    page_icon="📄",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS
st.markdown("""
    <style>
    .main-header {
        font-size: 3rem;
        font-weight: bold;
        color: #1f77b4;
        text-align: center;
        margin-bottom: 2rem;
    }
    .stat-card {
        background-color: #f0f2f6;
        padding: 1.5rem;
        border-radius: 0.5rem;
        text-align: center;
    }
    .stat-number {
        font-size: 2.5rem;
        font-weight: bold;
        color: #1f77b4;
    }
    .stat-label {
        font-size: 1rem;
        color: #666;
        margin-top: 0.5rem;
    }
    </style>
""", unsafe_allow_html=True)

# Header
st.markdown('<div class="main-header">📄 Invoice AI System</div>', unsafe_allow_html=True)
st.markdown("---")

# Introduction
col1, col2 = st.columns([2, 1])

with col1:
    st.markdown("""
    ### Welcome to Invoice AI System
    
    This intelligent system helps you manage and process invoices efficiently using AI-powered data extraction.
    
    **Features:**
    - 🤖 **AI-Powered Extraction**: Automatically extract data from invoice images using Gemini Vision API
    - 📊 **Smart Organization**: Store and manage all your invoices in one place
    - 📈 **Report Generation**: Create comprehensive PDF reports for analysis
    - 🔍 **Easy Search**: Quickly find invoices by vendor, date, or amount
    - 🗑️ **Secure Deletion**: Safely remove invoices when no longer needed
    
    **How to Use:**
    1. Navigate to **Upload Invoice** to process a new invoice
    2. View all invoices in **View Invoices** page
    3. Generate reports in **Generate Report** page
    """)

with col2:
    st.info("""
    **Quick Stats**
    
    View your invoice statistics and system health below.
    """)

# System Status
st.markdown("### 📊 System Overview")

try:
    # Try to fetch statistics from API
    response = requests.get(f"{API_BASE_URL}/invoices/stats/cache", timeout=5)
    
    if response.status_code == 200:
        stats = response.json()
        
        col1, col2, col3 = st.columns(3)
        
        with col1:
            st.markdown(f"""
                <div class="stat-card">
                    <div class="stat-number">{stats.get('total_invoices', 0)}</div>
                    <div class="stat-label">Total Invoices</div>
                </div>
            """, unsafe_allow_html=True)
        
        with col2:
            st.markdown(f"""
                <div class="stat-card">
                    <div class="stat-number">{stats.get('unique_invoices', 0)}</div>
                    <div class="stat-label">Unique Invoices</div>
                </div>
            """, unsafe_allow_html=True)
        
        with col3:
            st.markdown(f"""
                <div class="stat-card">
                    <div class="stat-number">{stats.get('cache_hit_rate', '0%')}</div>
                    <div class="stat-label">Cache Hit Rate</div>
                </div>
            """, unsafe_allow_html=True)
    else:
        st.warning("⚠️ Could not fetch statistics. API might be unavailable.")
        
except requests.exceptions.RequestException:
    st.error("""
        🔴 **API Connection Error**
        
        Cannot connect to the FastAPI backend. Please ensure:
        1. The FastAPI server is running
        2. The API_BASE_URL is correctly configured
        3. Check the terminal for any error messages
    """)

# Recent Activity (if API is available)
st.markdown("### 📋 Recent Activity")

try:
    response = requests.get(f"{API_BASE_URL}/invoices/?skip=0&limit=5", timeout=5)
    
    if response.status_code == 200:
        invoices = response.json()
        
        if invoices:
            for invoice in invoices:
                with st.container():
                    col1, col2, col3, col4 = st.columns([3, 2, 2, 2])
                    
                    with col1:
                        st.write(f"**{invoice.get('store_name', 'N/A')}**")
                    with col2:
                        st.write(f"Rp.{invoice.get('total', 0):.2f}")
                    with col3:
                        st.write(invoice.get('invoice_date', 'N/A'))
                    with col4:
                        st.write(f"📅 {invoice.get('created_at', 'N/A')[:10]}")
                    
                    st.markdown("---")
        else:
            st.info("No invoices yet. Upload your first invoice to get started!")
    
except requests.exceptions.RequestException:
    st.info("📭 Recent activity will appear here once the API is connected.")

# Footer
st.markdown("---")
st.markdown("""
    <div style="text-align: center; color: #666; padding: 2rem;">
        <p>Built with FastAPI, Streamlit, and Gemini Vision API</p>
        <p>💡 Tip: Use the sidebar to navigate between different pages</p>
    </div>
""", unsafe_allow_html=True)