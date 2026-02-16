import streamlit as st
import requests
from datetime import datetime, timedelta
import base64

# Configuration
API_BASE_URL = "http://fastapi:8000"

st.set_page_config(page_title="Generate Report", page_icon="📊", layout="wide")

st.title("📊 Generate Invoice Report")
st.markdown("Create comprehensive PDF reports from your invoice data.")

# Report configuration
st.markdown("### ⚙️ Report Configuration")

col1, col2 = st.columns(2)

with col1:
    report_title = st.text_input(
        "Report Title",
        value=f"Invoice Report - {datetime.now().strftime('%B %Y')}",
        help="Enter a custom title for your report"
    )

with col2:
    report_type = st.selectbox(
        "Report Type",
        ["Summary Report", "Detailed Report", "Vendor Analysis", "Monthly Summary"],
        help="Choose the type of report to generate"
    )

# Date range selector
st.markdown("### 📅 Date Range")

date_range_type = st.radio(
    "Select Date Range",
    ["Last 30 Days", "Last 90 Days", "This Month", "Last Month", "Custom Range", "All Time"],
    horizontal=True
)

start_date = None
end_date = None

if date_range_type == "Last 30 Days":
    end_date = datetime.now()
    start_date = end_date - timedelta(days=30)
elif date_range_type == "Last 90 Days":
    end_date = datetime.now()
    start_date = end_date - timedelta(days=90)
elif date_range_type == "This Month":
    end_date = datetime.now()
    start_date = end_date.replace(day=1)
elif date_range_type == "Last Month":
    end_date = datetime.now().replace(day=1) - timedelta(days=1)
    start_date = end_date.replace(day=1)
elif date_range_type == "Custom Range":
    col1, col2 = st.columns(2)
    with col1:
        start_date = st.date_input("Start Date", value=datetime.now() - timedelta(days=30))
    with col2:
        end_date = st.date_input("End Date", value=datetime.now())
    start_date = datetime.combine(start_date, datetime.min.time())
    end_date = datetime.combine(end_date, datetime.max.time())

# Filters
st.markdown("### 🔍 Filters (Optional)")

col1, col2, col3 = st.columns(3)

with col1:
    vendor_filter = st.text_input("Filter by Vendor", placeholder="Leave empty for all vendors")

with col2:
    min_amount = st.number_input("Minimum Amount", min_value=0.0, value=0.0, step=10.0)

with col3:
    max_amount = st.number_input("Maximum Amount", min_value=0.0, value=1000000.0, step=100.0)

# Report options
st.markdown("### 📋 Report Options")

col1, col2 = st.columns(2)

with col1:
    include_charts = st.checkbox("Include Charts & Graphs", value=True)
    include_line_items = st.checkbox("Include Line Items Details", value=False)

with col2:
    include_summary = st.checkbox("Include Executive Summary", value=True)
    group_by_vendor = st.checkbox("Group by Vendor", value=True)

# Preview section
st.markdown("---")
st.markdown("### 👁️ Preview Data")

try:
    # Fetch invoices for preview
    response = requests.get(f"{API_BASE_URL}/invoices/?skip=0&limit=1000", timeout=10)
    
    if response.status_code == 200:
        all_invoices = response.json()
        
        # Apply filters
        filtered_invoices = all_invoices
        
        if start_date and end_date:
            filtered_invoices = [
                inv for inv in filtered_invoices
                if start_date.strftime('%Y-%m-%d') <= inv.get('invoice_date', '') <= end_date.strftime('%Y-%m-%d')
            ]
        
        if vendor_filter:
            filtered_invoices = [
                inv for inv in filtered_invoices
                if vendor_filter.lower() in inv.get('store_name', '').lower()
            ]
        
        filtered_invoices = [
            inv for inv in filtered_invoices
            if min_amount <= inv.get('total', 0) <= max_amount
        ]
        
        # Display preview stats
        if filtered_invoices:
            total_amount = sum(inv.get('total', 0) for inv in filtered_invoices)
            avg_amount = total_amount / len(filtered_invoices)
            
            col1, col2, col3 = st.columns(3)
            
            with col1:
                st.metric("Invoices", len(filtered_invoices))
            with col2:
                st.metric("Total Amount", f"Rp.{total_amount:,.2f}")
            with col3:
                st.metric("Average", f"Rp.{avg_amount:,.2f}")
            
            # Vendor breakdown
            if group_by_vendor:
                st.markdown("#### 🏢 Store Breakdown")
                vendor_data = {}
                for inv in filtered_invoices:
                    vendor = inv.get('store_name', 'Unknown')
                    if vendor not in vendor_data:
                        vendor_data[vendor] = {'count': 0, 'total': 0}
                    vendor_data[vendor]['count'] += 1
                    vendor_data[vendor]['total'] += inv.get('total', 0)
                
                for vendor, data in sorted(vendor_data.items(), key=lambda x: x[1]['total'], reverse=True)[:10]:
                    col1, col2, col3 = st.columns([3, 1, 2])
                    with col1:
                        st.write(f"**{vendor}**")
                    with col2:
                        st.write(f"{data['count']} invoices")
                    with col3:
                        st.write(f"Rp.{data['total']:,.2f}")
        else:
            st.warning("⚠️ No invoices match the selected criteria. Adjust your filters to include more data.")
    
    else:
        st.error("Failed to fetch invoices for preview.")

except requests.exceptions.ConnectionError:
    st.error("Cannot connect to API server.")
except Exception as e:
    st.error(f"Error loading preview: {str(e)}")

# Generate report button
st.markdown("---")

col1, col2, col3 = st.columns([1, 2, 1])

with col2:
    generate_button = st.button(
        "📄 Generate PDF Report",
        type="primary",
        use_container_width=True,
        disabled=not filtered_invoices if 'filtered_invoices' in locals() else True
    )

if generate_button:
    with st.spinner("Generating your report... This may take a moment..."):
        try:
            # Prepare request parameters
            params = {
                "title": report_title,
                "report_type": report_type.lower().replace(" ", "_"),
                "include_charts": include_charts,
                "include_summary": include_summary,
                "group_by_vendor": group_by_vendor
            }
            
            if start_date:
                params["start_date"] = start_date.strftime('%Y-%m-%d')
            if end_date:
                params["end_date"] = end_date.strftime('%Y-%m-%d')
            if vendor_filter:
                params["vendor_filter"] = vendor_filter
            if min_amount > 0:
                params["min_amount"] = min_amount
            if max_amount < 1000000:
                params["max_amount"] = max_amount
            
            # Make API request
            response = requests.post(
                f"{API_BASE_URL}/reports/generate",
                params=params,
                timeout=60
            )
            
            if response.status_code == 200:
                report_data = response.json()
                
                st.success("✅ Report generated successfully!")
                
                # Display report info
                st.markdown("#### 📄 Report Details")
                col1, col2 = st.columns(2)
                
                with col1:
                    st.info(f"""
                    **Report Information:**
                    - File: {report_data.get('filename', 'N/A')}
                    - Generated: {report_data.get('generated_at', 'N/A')}
                    - Invoices: {report_data.get('invoice_count', 0)}
                    """)
                
                with col2:
                    st.info(f"""
                    **Financial Summary:**
                    - Total Amount: Rp.{report_data.get('total_amount', 0):,.2f}
                    - File Path: {report_data.get('file_path', 'N/A')}
                    """)
                
                # Download button
                try:
                    # Fetch the PDF file
                    pdf_response = requests.get(
                        f"{API_BASE_URL}/reports/download/{report_data.get('filename')}",
                        timeout=10
                    )
                    
                    if pdf_response.status_code == 200:
                        st.download_button(
                            label="📥 Download PDF Report",
                            data=pdf_response.content,
                            file_name=report_data.get('filename', 'report.pdf'),
                            mime="application/pdf",
                            use_container_width=True,
                            type="primary"
                        )
                        
                        # Display PDF preview (if possible)
                        st.markdown("#### 👁️ Report Preview")
                        base64_pdf = base64.b64encode(pdf_response.content).decode('utf-8')
                        pdf_display = f'<iframe src="data:application/pdf;base64,{base64_pdf}" width="100%" height="800" type="application/pdf"></iframe>'
                        st.markdown(pdf_display, unsafe_allow_html=True)
                    else:
                        st.error("Could not fetch the PDF file for download.")
                
                except Exception as e:
                    st.error(f"Error downloading report: {str(e)}")
            
            elif response.status_code == 404:
                st.error("❌ No invoices found matching your criteria.")
            
            elif response.status_code == 500:
                st.error("❌ Server error while generating report.")
                with st.expander("Error Details"):
                    st.json(response.json())
            
            else:
                st.error(f"❌ Unexpected error: Status code {response.status_code}")
        
        except requests.exceptions.Timeout:
            st.error("⏱️ Request timeout. The report generation is taking longer than expected.")
        
        except requests.exceptions.ConnectionError:
            st.error("🔴 Cannot connect to the API server.")
        
        except Exception as e:
            st.error(f"❌ Error: {str(e)}")
            with st.expander("Technical Details"):
                st.exception(e)

# Tips
st.markdown("---")
st.markdown("### 💡 Report Generation Tips")

tip_col1, tip_col2 = st.columns(2)

with tip_col1:
    st.info("""
    **📊 Charts & Visualizations**
    - Enable charts for visual insights
    - Vendor breakdown shows top spenders
    - Time-series analysis available
    """)

with tip_col2:
    st.info("""
    **🎯 Best Practices**
    - Use date ranges for focused reports
    - Filter by vendor for specific analysis
    - Include executive summary for overview
    """)

# Sidebar
with st.sidebar:
    st.markdown("### 📋 Quick Reports")
    
    if st.button("📅 This Month Report", use_container_width=True):
        st.session_state.date_range = "This Month"
        st.rerun()
    
    if st.button("📆 Last Month Report", use_container_width=True):
        st.session_state.date_range = "Last Month"
        st.rerun()
    
    if st.button("📊 Year to Date", use_container_width=True):
        st.session_state.date_range = "All Time"
        st.rerun()
    
    st.markdown("---")
    st.markdown("### 🔗 Navigation")
    
    if st.button("📤 Upload Invoice", use_container_width=True):
        st.switch_page("pages/1_Upload_Invoice.py")
    
    if st.button("📋 View All Invoices", use_container_width=True):
        st.switch_page("pages/2_View_Invoices.py")