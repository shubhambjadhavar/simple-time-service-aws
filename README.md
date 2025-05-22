# 🕒 Simple Time Service

A lightweight Go web service deployed on AWS using Terraform. It exposes two endpoints:

* `/` — Returns current server timestamp and client IP in JSON.
* `/health` — Basic health check endpoint returning HTTP 200.

This project includes:

* A Dockerized Go application (`app/`)
* Infrastructure as code with Terraform (`terraform/`)

---

## 📁 Project Structure

```
.
├── README.md
├── app
│   ├── Dockerfile
│   ├── go.mod / go.sum
│   ├── handler/
│   │   ├── health.go        # Health check HTTP handler
│   │   ├── root.go          # Root ("/") path HTTP handler returning JSON with timestamp and client IP
│   │   └── util.go          # Utility functions shared by handlers (e.g., JSON response writer, client IP extractor)
│   └── main.go              # Main entrypoint
└── terraform
    ├── main.tf              # Root Terraform configuration, includes module calls for VPC, ALB, ECS
    ├── providers.tf         # Terraform providers configuration (AWS)
    ├── terraform.tfvars     # Variable values for Terraform
    ├── variables.tf         # Variable declarations for Terraform modules and root
```

---

## 🚀 App Functionality

* **GET /** — Returns:

  ```json
  {
    "timestamp":  "2025-05-22T10:28:36Z",
    "ip": "104.28.37.209"
  }
  ```

* **GET /health** — Returns `200 OK` with body:
  ```json
  {
    "status": "ok"
  }
  ```

---

## 🧪 Run Locally

### 1. Build and Run with Go:

```bash
cd app
go run main.go
```

Then open `http://localhost:8080` and `http://localhost:8080/health`.

---

## 🐳 Run with Docker

### 1. Build the image:

```bash
docker build -t simple-time-service ./app
```

### 2. Run:

```bash
docker run -p 8080:8080 simple-time-service
```

---

## 🛠 Pushing Docker Image to ECR

### 1. Create ECR repository:

```bash
export AWS_DEFAULT_REGION=us-east-1
aws ecr create-repository --repository-name simple-time-service 
```

### 2. Authenticate Docker to ECR:

```bash
account_id=$(aws sts get-caller-identity --query "Account" --output text)
aws ecr get-login-password | docker login --username AWS --password-stdin ${account_id}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com
```

### 3. Tag & push image:

```bash
docker tag simple-time-service ${account_id}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/simple-time-service
docker push ${account_id}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/simple-time-service
```

---

## ☁️ Deploy with Terraform

### 📌 Prerequisites:

* AWS CLI configured
* Terraform installed

### 1. Initialize Terraform

```bash
cd terraform
terraform init
```

### 2. Preview changes

```bash
terraform plan
```

### 3. Apply infrastructure

```bash
terraform apply
```

---

## 🧪 Sample Output

```bash
http://<alb-dns>/         # JSON response with timestamp and IP
http://<alb-dns>/health   # Should return "OK"
```
---

## ✅ Terraform Remote Backend Setup with S3 & DynamoDB

---

### 🛠️ 1. **Create S3 Bucket & DynamoDB Table**

Manually create:

* An S3 bucket
* A DynamoDB table with a primary key `LockID` (String)

#### **CLI**

```bash
bucket_name="terraform-backend-$(uuidgen | tr -d '-' | tr '[:upper:]' '[:lower:]' | cut -c1-8)"
dynamodb_table_name="terraform-backend-tf-lock-table"

# Create S3 bucket
aws s3api create-bucket --bucket ${bucket_name}

# Enable versioning
aws s3api put-bucket-versioning --bucket ${bucket_name} --versioning-configuration Status=Enabled

# Create DynamoDB table
aws dynamodb create-table \
    --table-name ${dynamodb_table_name} \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST

# Wait for dynamodb table creation
```

---

### 🧱 2. **Remote Backend Block (Add to file `backend.tf`)**

```hcl
terraform {
  backend "s3" {
    bucket         = ""
    key            = "simple-time-service/terraform.tfstate"
    region         = ""
    dynamodb_table = ""
    encrypt        = true
  }
}
```
---

### 🏗️ 3. **Run Terraform Init**

```bash
terraform init -backend-config=backend.conf
```
---

📌 Note

This implementation uses the default endpoint provided by the AWS Application Load Balancer (ALB). A custom domain name (e.g., via Route 53 or another DNS provider) has not been configured as part of this setup.