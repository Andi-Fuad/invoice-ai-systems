import streamlit as st
import requests
from PIL import Image
import io

# Configuration
API_BASE_URL = "http://fastapi:8000"

st.set_page_config(page_title="Upload Invoice", page_icon="📤", layout="wide")

st.title("📤 Upload Invoice")
st.markdown("Upload an invoice image to extract data automatically using AI.")

# Upload section
st.markdown("### Upload Invoice Image")
uploaded_file = st.file_uploader(
    "Choose an invoice image (JPG, JPEG, PNG)",
    type=["jpg", "jpeg", "png"],
    help="Upload a clear image of your invoice for best results"
)

if uploaded_file is not None:
    # Display the uploaded image
    col1, col2 = st.columns([1, 1])
    
    with col1:
        st.markdown("#### 📷 Uploaded Image")
        image = Image.open(uploaded_file)
        st.image(image)
        
        # Image info
        st.info(f"""
        **File Details:**
        - Name: {uploaded_file.name}
        - Size: {uploaded_file.size / 1024:.2f} KB
        - Format: {image.format}
        - Dimensions: {image.size[0]} x {image.size[1]}
        """)
    
    with col2:
        st.markdown("#### 🤖 AI Processing")
        
        # Process button
        if st.button("🚀 Process Invoice with AI", type="primary", use_container_width=True):
            with st.spinner("Processing invoice... This may take a few seconds..."):
                try:
                    # Reset file pointer
                    uploaded_file.seek(0)
                    
                    # Prepare the file for upload
                    files = {
                        "file": (uploaded_file.name, uploaded_file, uploaded_file.type)
                    }
                    
                    # Send POST request to FastAPI
                    response = requests.post(
                        f"{API_BASE_URL}/invoices/upload",
                        files=files,
                    )
                    
                    if response.status_code == 200:
                        invoice_data = response.json()
                        
                        st.success("✅ Invoice processed successfully!")
                        
                        # Check if cached
                        if invoice_data.get('is_cached'):
                            st.info("ℹ️ This invoice was already processed. Returning cached data (saved API costs!).")
                        
                        # Display extracted data
                        st.markdown("#### 📊 Extracted Data")
                        
                        # Create a nice display of the data
                        data_col1, data_col2 = st.columns(2)
                        
                        with data_col1:
                            st.metric("Store Name", invoice_data.get("store_name", "N/A"))
                            st.metric("Invoice Date", invoice_data.get("invoice_date", "N/A"))
                        
                        with data_col2:
                            st.metric("Total Amount", f"Rp.{invoice_data.get('total', 0):.2f}")
                            st.metric("Invoice ID", invoice_data.get("id", "N/A"))
                        
                        # Details
                        if invoice_data.get("details"):
                            st.markdown("#### 📝 Details")
                            st.text_area("Invoice Details", invoice_data["details"], height=150, disabled=True)
                        
                        # Additional info
                        with st.expander("🔍 Additional Information"):
                            st.write(f"**File Hash:** {invoice_data.get('file_hash', 'N/A')}")
                            st.write(f"**File Path:** {invoice_data.get('file_path', 'N/A')}")
                            st.write(f"**Created At:** {invoice_data.get('created_at', 'N/A')}")
                            st.write(f"**Cached:** {'Yes' if invoice_data.get('is_cached') else 'No'}")
                        
                        # Action buttons
                        st.markdown("---")
                        col_a, col_b, col_c = st.columns(3)
                        
                        with col_a:
                            if st.button("📋 View All Invoices", use_container_width=True):
                                st.switch_page("pages/2_View_Invoices.py")
                        
                        with col_b:
                            if st.button("📤 Upload Another", use_container_width=True):
                                st.rerun()
                        
                        with col_c:
                            if st.button("📊 Generate Report", use_container_width=True):
                                st.switch_page("pages/3_Generate_Report.py")
                    
                    elif response.status_code == 400:
                        st.error(f"❌ Bad Request: {response.json().get('detail', 'Unknown error')}")
                    
                    elif response.status_code == 500:
                        st.error("❌ Server Error: The API encountered an error while processing your invoice.")
                        with st.expander("Error Details"):
                            st.json(response.json())
                    
                    else:
                        st.error(f"❌ Unexpected error: Status code {response.status_code}")
                
                except requests.exceptions.Timeout:
                    st.error("""
                        ⏱️ **Request Timeout**
                        
                        The request took too long to process. This might happen with:
                        - Very large images
                        - Slow network connection
                        - API overload
                        
                        Please try again with a smaller image or check your connection.
                    """)
                
                except requests.exceptions.ConnectionError:
                    st.error("""
                        🔴 **Connection Error**
                        
                        Cannot connect to the API server. Please ensure:
                        1. The FastAPI server is running (check terminal)
                        2. The server is accessible at: `{API_BASE_URL}`
                        3. No firewall is blocking the connection
                    """)
                
                except Exception as e:
                    st.error(f"❌ Unexpected error: {str(e)}")
                    with st.expander("Technical Details"):
                        st.exception(e)

# Tips section
st.markdown("---")
st.markdown("### 💡 Tips for Best Results")

tip_col1, tip_col2, tip_col3 = st.columns(3)

with tip_col1:
    st.info("""
    **📸 Image Quality**
    - Use high-resolution images
    - Ensure good lighting
    - Avoid blurry photos
    """)

with tip_col2:
    st.info("""
    **📄 Document Format**
    - Keep the entire invoice visible
    - Avoid cutting off edges
    - Straighten skewed images
    """)

with tip_col3:
    st.info("""
    **✅ Supported Formats**
    - JPG / JPEG
    - PNG
    - Max size: 10MB
    """)

# API Status Check
with st.sidebar:
    st.markdown("### 🔧 System Status")
    
    try:
        health_response = requests.get(f"{API_BASE_URL}/health", timeout=3)
        if health_response.status_code == 200:
            st.success("✅ API Connected")
        else:
            st.error("❌ API Error")
    except:
        st.error("🔴 API Offline")
    
    st.markdown("---")
    st.markdown(f"**API Endpoint:** `{API_BASE_URL}`")