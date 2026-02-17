#!/bin/bash
# =====================================================
# EC2 User Data Script - Invoice AI System Setup
# This script runs when the EC2 instance first boots
# =====================================================

set -e  # Exit on error

# Logging
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "========================================="
echo "Starting Invoice AI System Setup"
echo "Time: $(date)"
echo "========================================="

# Update system
echo "[1/9] Updating system packages..."
yum update -y

# Install Docker
echo "[2/9] Installing Docker..."
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
echo "[3/9] Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Install Git
echo "[4/9] Installing Git..."
yum install -y git

# Create application directory
echo "[5/9] Setting up application directory..."
mkdir -p /home/ec2-user/invoice-ai-system
cd /home/ec2-user/invoice-ai-system

# Create directories
mkdir -p uploads reports
chown -R ec2-user:ec2-user /home/ec2-user/invoice-ai-system

# Create docker-compose.yml
echo "[6/9] Creating docker-compose.yml..."
cat > docker-compose.yml << 'DOCKERCOMPOSE'

services:
  postgres:
    image: postgres:15-alpine
    container_name: invoice-postgres
    environment:
      POSTGRES_DB: ${db_name}
      POSTGRES_USER: ${db_username}
      POSTGRES_PASSWORD: ${db_password}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    networks:
      - invoice-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${db_username}"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  fastapi:
    image: python:3.11-slim
    container_name: invoice-fastapi
    working_dir: /app
    command: >
      bash -c "
      pip install --no-cache-dir fastapi uvicorn sqlalchemy psycopg2-binary python-multipart google-generativeai pillow boto3 imagehash pydantic-settings &&
      uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
      "
    environment:
      DATABASE_URL: postgresql://${db_username}:${db_password}@postgres:5432/${db_name}
      GEMINI_API_KEY: ${gemini_api_key}
      UPLOAD_DIR: /app/uploads
      REPORT_DIR: /app/reports
      AWS_DEFAULT_REGION: ${aws_region}
      S3_BUCKET_NAME: ${s3_bucket_name}
    volumes:
      - ./app:/app/app
      - ./uploads:/app/uploads
      - ./reports:/app/reports
    ports:
      - "8000:8000"
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - invoice-network
    restart: unless-stopped

  streamlit:
    image: python:3.11-slim
    container_name: invoice-streamlit
    working_dir: /app
    command: >
      bash -c "
      pip install --no-cache-dir streamlit requests pandas pillow plotly &&
      streamlit run Home.py --server.address 0.0.0.0 --server.port 8501
      "
    environment:
      API_BASE_URL: http://fastapi:8000
    volumes:
      - ./streamlit_app:/app
    ports:
      - "8501:8501"
    depends_on:
      - fastapi
    networks:
      - invoice-network
    restart: unless-stopped

volumes:
  postgres_data:

networks:
  invoice-network:
    driver: bridge
DOCKERCOMPOSE

# Create .env file
echo "[7/9] Creating environment file..."
cat > .env << ENVFILE
db_name=${db_name}
db_username=${db_username}
db_password=${db_password}
gemini_api_key=${gemini_api_key}
aws_region=${aws_region}
s3_bucket_name=${s3_bucket_name}
ENVFILE

# Create placeholder app structure (you'll replace this with your actual app)
echo "[8/9] Creating placeholder application structure..."
mkdir -p app streamlit_app/pages

# Create minimal FastAPI app as placeholder
cat > app/__init__.py << 'EOF'
EOF

cat > app/main.py << 'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI(title="Invoice AI System")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return {"message": "Invoice AI System API", "status": "running"}

@app.get("/health")
def health():
    return {"status": "ok"}
EOF

# Create minimal Streamlit app as placeholder
cat > streamlit_app/Home.py << 'EOF'
import streamlit as st
import requests

st.set_page_config(page_title="Invoice AI System", page_icon="📄", layout="wide")

st.title("📄 Invoice AI System")
st.markdown("---")

st.info("""
### Welcome!

Your Invoice AI System is deployed successfully!

**Next Steps:**
1. SSH into this instance
2. Replace the placeholder code with your actual application
3. Restart Docker containers

**SSH Command:**
```
ssh -i your-key.pem ec2-user@<instance-ip>
```

**Your actual code should replace:**
- `/home/ec2-user/invoice-ai-system/app/` (FastAPI)
- `/home/ec2-user/invoice-ai-system/streamlit_app/` (Streamlit)

Then restart: `sudo docker-compose restart`
""")

# Try to connect to API
try:
    response = requests.get("http://fastapi:8000/health", timeout=2)
    if response.status_code == 200:
        st.success("✅ FastAPI is running!")
    else:
        st.error("❌ FastAPI returned an error")
except:
    st.warning("⚠️ Cannot connect to FastAPI yet (may still be starting)")
EOF

# Set permissions
chown -R ec2-user:ec2-user /home/ec2-user/invoice-ai-system
chmod 600 .env

# Start Docker services
echo "[9/9] Starting Docker services..."
docker-compose up -d

# Wait for services
echo "Waiting for services to start..."
sleep 30

# Check status
docker-compose ps

# Create status file
cat > /home/ec2-user/setup-status.txt << STATUS
Invoice AI System Setup Complete!
Date: $(date)

Services:
- FastAPI:   http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8000
- Streamlit: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8501

Next Steps:
1. SSH into instance: ssh -i your-key.pem ec2-user@$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
2. Check logs: cd /home/ec2-user/invoice-ai-system && sudo docker-compose logs
3. Replace placeholder code with your actual application
4. Restart: sudo docker-compose restart

Status: READY
STATUS

chown ec2-user:ec2-user /home/ec2-user/setup-status.txt

echo "========================================="
echo "Invoice AI System Setup Complete!"
echo "Time: $(date)"
echo "========================================="
echo "Check /home/ec2-user/setup-status.txt for details"