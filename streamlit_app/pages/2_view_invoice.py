import streamlit as st
import requests
import pandas as pd
from datetime import datetime

# Configuration
API_BASE_URL = "http://fastapi:8000"

st.set_page_config(page_title="View Invoices", page_icon="📋", layout="wide")

st.title("📋 View Invoices")
st.markdown("Browse, search, and manage all your invoices.")

# Initialize session state for refresh
if 'refresh' not in st.session_state:
    st.session_state.refresh = 0

# Filters and Search
with st.expander("🔍 Filter & Search", expanded=True):
    col1, col2, col3 = st.columns(3)
    
    with col1:
        search_vendor = st.text_input("🏢 Store Name", placeholder="Search by store...")
    
    with col2:
        search_invoice_number = st.text_input("📄 Invoice Number", placeholder="Search by invoice number...")
    
    with col3:
        date_filter = st.date_input("📅 Filter by Date", value=None)
    
    col4, col5 = st.columns(2)

# Fetch invoices
try:
    with st.spinner("Loading invoices..."):
        response = requests.get(f"{API_BASE_URL}/invoices/?skip=0&limit=1000", timeout=10)
        
        if response.status_code == 200:
            invoices = response.json()
            
            if not invoices:
                st.info("📭 No invoices found. Upload your first invoice to get started!")
            else:
                # Apply filters
                filtered_invoices = invoices
                
                if search_vendor:
                    filtered_invoices = [
                        inv for inv in filtered_invoices 
                        if search_vendor.lower() in inv.get('store_name', '').lower()
                    ]
                
                if search_invoice_number:
                    filtered_invoices = [
                        inv for inv in filtered_invoices 
                        if search_invoice_number.lower() in str(inv.get('id', '')).lower()
                    ]
                
                if date_filter:
                    date_str = date_filter.strftime('%Y-%m-%d')
                    filtered_invoices = [
                        inv for inv in filtered_invoices 
                        if inv.get('invoice_date', '').startswith(date_str)
                    ]
                
                # Display results count
                st.markdown(f"### Found {len(filtered_invoices)} invoice(s)")
                
                if filtered_invoices:
                    # Summary statistics
                    total_amount = sum(inv.get('total', 0) for inv in filtered_invoices)
                    
                    col1, col2 = st.columns(2)
                    col1.metric("Total Invoices", len(filtered_invoices))
                    col2.metric("Total Amount", f"Rp.{total_amount:,.2f}")
                    
                    st.markdown("---")
                    
                    # Display options
                    view_mode = st.radio(
                        "View Mode",
                        ["Card View", "Table View"],
                        horizontal=True
                    )
                    
                    if view_mode == "Card View":
                        # Card view
                        for invoice in filtered_invoices:
                            with st.container():
                                col1, col2, col3, col4 = st.columns([3, 2, 2, 2])
                                
                                with col1:
                                    st.markdown(f"### {invoice.get('store_name', 'N/A')}")
                                    st.caption(f"Invoice ID: {invoice.get('id', 'N/A')}")
                                
                                with col2:
                                    st.metric("Amount", f"Rp.{invoice.get('total', 0):,.2f}")
                                
                                with col3:
                                    st.write("**Date:**")
                                    st.write(invoice.get('invoice_date', 'N/A'))
                                
                                with col4:
                                    st.write("**File Hash:**")
                                    st.write(invoice.get('file_hash', 'N/A')[:8] + "...")
                                
                                # Expandable details
                                with st.expander("View Details"):
                                    detail_col1, detail_col2 = st.columns(2)
                                    
                                    with detail_col1:
                                        st.write("**Invoice Information:**")
                                        st.write(f"- Invoice ID: {invoice.get('id', 'N/A')}")
                                        st.write(f"- Total: Rp.{invoice.get('total', 0):.2f}")
                                        st.write(f"- File Hash: {invoice.get('file_hash', 'N/A')[:16]}...")
                                    
                                    with detail_col2:
                                        st.write("**Details:**")
                                        details = invoice.get('details', 'No details')
                                        st.text_area("Invoice Details", details, height=100, key=f"details_{invoice['id']}", disabled=True)
                                    
                                    # Action buttons
                                    st.markdown("---")
                                    btn_col1, btn_col2, btn_col3 = st.columns(3)
                                    
                                    with btn_col1:
                                        if invoice.get('file_path'):
                                            # View image button
                                            if st.button(f"🖼️ View Image", key=f"view_{invoice['id']}"):
                                                try:
                                                    img_response = requests.get(
                                                        f"{API_BASE_URL}/invoices/{invoice['id']}/image",
                                                        timeout=5
                                                    )
                                                    if img_response.status_code == 200:
                                                        st.image(img_response.content, caption=invoice.get('vendor_name'))
                                                    else:
                                                        st.error("Could not load image")
                                                except Exception as e:
                                                    st.error(f"Error: {str(e)}")
                                    
                                    with btn_col2:
                                        # Download data button
                                        if st.button(f"⬇️ Download", key=f"download_{invoice['id']}"):
                                            st.download_button(
                                                label="Download JSON",
                                                data=str(invoice),
                                                file_name=f"invoice_{invoice['id']}.json",
                                                mime="application/json",
                                                key=f"dl_btn_{invoice['id']}"
                                            )
                                    
                                    with btn_col3:
                                        # Delete button
                                        if st.button(f"🗑️ Delete", key=f"delete_{invoice['id']}", type="secondary"):
                                            if st.button(f"⚠️ Confirm Delete?", key=f"confirm_{invoice['id']}", type="primary"):
                                                try:
                                                    del_response = requests.delete(
                                                        f"{API_BASE_URL}/invoices/{invoice['id']}",
                                                        timeout=5
                                                    )
                                                    if del_response.status_code == 200:
                                                        st.success("✅ Invoice deleted successfully!")
                                                        st.session_state.refresh += 1
                                                        st.rerun()
                                                    else:
                                                        st.error(f"Failed to delete: {del_response.status_code}")
                                                except Exception as e:
                                                    st.error(f"Error deleting invoice: {str(e)}")
                                
                                st.markdown("---")
                    
                    else:  # Table View
                        # Create DataFrame
                        df_data = []
                        for inv in filtered_invoices:
                            df_data.append({
                                "ID": inv.get('id'),
                                "Store": inv.get('store_name', 'N/A'),
                                "Date": inv.get('invoice_date', 'N/A'),
                                "Amount": inv.get('total', 0),
                                "File Hash": inv.get('file_hash', 'N/A')[:16] + "...",
                                "Created": inv.get('created_at', 'N/A')[:10]
                            })
                        
                        df = pd.DataFrame(df_data)
                        
                        # Display dataframe
                        st.dataframe(
                            df,
                            use_container_width=True,
                            hide_index=True,
                            column_config={
                                "Amount": st.column_config.NumberColumn(
                                    "Amount",
                                    format="Rp.%.2f"
                                )
                            }
                        )
                        
                        # Download CSV
                        csv = df.to_csv(index=False)
                        st.download_button(
                            label="📥 Download as CSV",
                            data=csv,
                            file_name=f"invoices_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv",
                            mime="text/csv"
                        )
                
                else:
                    st.warning("No invoices match your filters. Try adjusting your search criteria.")
        
        else:
            st.error(f"Failed to fetch invoices. Status code: {response.status_code}")

except requests.exceptions.ConnectionError:
    st.error("""
        🔴 **Connection Error**
        
        Cannot connect to the API server. Please ensure:
        1. The FastAPI server is running
        2. The server is accessible at: `{API_BASE_URL}`
    """)

except Exception as e:
    st.error(f"An error occurred: {str(e)}")
    with st.expander("Error Details"):
        st.exception(e)

# Sidebar actions
with st.sidebar:
    st.markdown("### ⚡ Quick Actions")
    
    if st.button("🔄 Refresh", use_container_width=True):
        st.session_state.refresh += 1
        st.rerun()
    
    if st.button("📤 Upload New", use_container_width=True):
        st.switch_page("pages/1_Upload_Invoice.py")
    
    if st.button("📊 Generate Report", use_container_width=True):
        st.switch_page("pages/3_Generate_Report.py")
    
    st.markdown("---")
    st.markdown("### 📊 Statistics")
    
    try:
        stats_response = requests.get(f"{API_BASE_URL}/invoices/stats/cache", timeout=3)
        if stats_response.status_code == 200:
            stats = stats_response.json()
            st.metric("Total Invoices", stats.get('total_invoices', 0))
            st.metric("Unique Invoices", stats.get('unique_invoices', 0))
            st.metric("Cache Hit Rate", stats.get('cache_hit_rate', '0%'))
    except:
        st.info("Stats unavailable")