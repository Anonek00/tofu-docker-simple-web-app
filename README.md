# Anonek00/tofu-docker-simple-web-app

🏗️ **Infrastructure as Code** project using **OpenTofu** for AWS infrastructure provisioning and **Docker** for containerized Node.js Express application with monitoring deployment.

## 📋 Table of Contents
- [Infrastructure Modules](#-infrastructure-modules)
- [Environments](#-environments)
- [Requirements](#-requirements--prerequisites)
- [Local Development](#-how-to-run-the-project-locally)
- [Deployment](#-step-by-step-deployment)
- [Infrastructure Destruction](#-infrastructure-destruction)
- [Technical Documentation](#-technical-documentation)
- [CI/CD Pipeline](#-cicd-pipeline)

## 🏗️ Infrastructure Modules

### EC2
AWS infrastructure module for EC2 resources

### security
AWS infrastructure module for security resources

### vpc
AWS infrastructure module for vpc resources

## 🌍 Environments

| Environment | Status | Description |
|-------------|--------|-------------|
| **dev** | Not deployed - AWS not initialized | dev environment infrastructure |
| **prod** | Not deployed - AWS not initialized | prod environment infrastructure |
| **stage** | Not deployed - AWS not initialized | stage environment infrastructure |

## ⚙️ Requirements & Prerequisites

### System Requirements:
- **OpenTofu**: `>= 1.0`
- **Docker**: `>= 28.0.4`
- **Docker Compose**: `>= 2.38.2`
- **AWS CLI**: `>= 2.28.12` (for AWS authentication)
- **Python**: `>=3.12.3` (for AWS CLI)
- **Git**: Latest version

### AWS Authentication:
```bash
# Configure AWS credentials
aws configure
# OR use environment variables:
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-central-1"
```

## 🚀 How to Run the Project Locally

### 1. Clone the Repository
```bash
git clone https://github.com/Anonek00/tofu-docker-simple-web-app.git
cd tofu-docker-simple-web-app
```

### 2. Start the Application Stack
```bash
# Navigate to application directory
cd local-docker/app

# Start all services (app, database, monitoring)
docker compose up --build -d

# Check services status
docker compose ps
```

### 3. Access Services
- **Application**: http://localhost
- **Health Check**: http://localhost/health
- **Grafana**: http://localhost/grafana

### 4. Stop Services
```bash
docker compose down
# Remove volumes (optional)
docker compose down -v
```

## 📦 Step-by-Step Deployment

### Infrastructure Deployment (AWS)

!Remember to configure AWS CLI BEFORE!

#### 1. Initialize Tofu for Choosen Environment
```bash
# Choose environment (dev/stage/prod)
cd environments/dev

# Initialize Tofu
tofu init

# Review planned changes
tofu plan
```

#### 2. Deploy Infrastructure
```bash
# Apply infrastructure changes
tofu apply

# Verify deployment
tofu show
```

#### 3. Application Deployment
Attention! Due to lack of actual AWS infra, this step wasn't automized in the pipeline. For actual infra I would use Tofu provisioner to copy application & docker files to EC2 instance and there build docker image and launch docker compose.

```bash
# Copy ./local-docker content to target EC2 instance
scp -i ~/.ssh/proper_key_for_auth -v -C -r ./local-docker proper_user_name@EC2_INSTANCE_IP:/opt/node-composed

# Verify copied files
ssh -i ~/.ssh/proper_key_for_auth proper_user_name@EC2_INSTANCE_IP 'ls -la /opt/node-composed'

#Build & run application with docker compose as service user
ssh -i ~/.ssh/proper_key_for_auth proper_user_name@EC2_INSTANCE_IP 'sudo -u nodeapp bash -c "cd /opt/node-composed/local-docker/app && docker compose up --build -d"'
```

## 🔥 Infrastructure Destruction

### Complete Local Environment Cleanup

#### Quick Local Cleanup:
```bash
# Stop and remove all containers, networks, and volumes
cd local-docker/app
docker compose down -v

# Remove all unused Docker resources
docker system prune -af
docker volume prune -f
```

#### Complete Local Reset:
```bash
#!/bin/bash
# complete-local-reset.sh - Nuclear option for local cleanup

echo "🧹 Starting complete local cleanup..."

# Stop all running containers
cd local-docker/app
docker compose down -v

# Remove ALL Docker containers, images, networks, and volumes
docker container prune -f
docker image prune -af
docker network prune -f
docker volume prune -f
docker system prune -af --volumes

# Clean build cache
docker builder prune -af

echo "✅ Local environment completely cleaned!"
```

### Complete AWS Infrastructure Destruction

#### Single Environment Destruction:
```bash
# Navigate to specific environment
cd environments/dev  # or stage/prod

# Review what will be destroyed
tofu plan -destroy

# Destroy infrastructure
tofu destroy -auto-approve

# Clean local state files
rm -rf .terraform/
rm -f terraform.tfstate*
rm -f .terraform.lock.hcl
```

#### Complete Multi-Environment Destruction:
```bash
#!/bin/bash
# destroy-all-environments.sh - Destroy all AWS infrastructure

echo "💥 WARNING: This will destroy ALL AWS infrastructure!"
read -p "Type 'DESTROY' to continue: " confirm

if [ "$confirm" != "DESTROY" ]; then
  echo "❌ Destruction cancelled"
  exit 1
fi

# Destroy environments in reverse order (prod -> stage -> dev)
ENVIRONMENTS=("prod" "stage" "dev")

for env in "${ENVIRONMENTS[@]}"; do
  if [ -d "environments/$env" ]; then
    echo "💥 Destroying $env environment..."
    cd environments/$env
    
    # Force unlock if state is locked
    tofu force-unlock -force $(tofu show -json 2>/dev/null | jq -r '.values.root_module.resources[].instances[].attributes.id // empty' | head -1) 2>/dev/null || true
    
    # Destroy infrastructure
    tofu destroy -auto-approve -var-file="terraform.tfvars"
    
    # Clean state files
    rm -rf .terraform/
    rm -f terraform.tfstate*
    rm -f .terraform.lock.hcl
    
    cd ../../
    echo "✅ $env environment destroyed"
  fi
done

echo "🎉 All AWS infrastructure destroyed!"
```

#### Emergency Infrastructure Reset:
```bash
#!/bin/bash
# emergency-reset.sh - Last resort cleanup

echo "☢️ EMERGENCY RESET - This destroys EVERYTHING!"
echo "This includes:"
echo "- All AWS infrastructure across all environments"
echo "- All local Docker resources"
echo "- All Terraform state files"
echo ""
read -p "Are you absolutely sure? Type 'EMERGENCY' to continue: " confirm

if [ "$confirm" != "EMERGENCY" ]; then
  echo "❌ Emergency reset cancelled"
  exit 1
fi

# 1. Stop all local services
cd local-docker/app
docker compose down -v 2>/dev/null || true
docker system prune -af
docker volume prune -f
cd ../../

# 2. Force destroy all Tofu environments
for env in prod stage dev; do
  if [ -d "environments/$env" ]; then
    cd environments/$env
    tofu destroy -auto-approve 2>/dev/null || true
    rm -rf .terraform* terraform.tfstate*
    cd ../../
  fi
done

echo "☢️ Emergency reset complete!"
echo "Manual cleanup may be required:"
echo "1. Check AWS Console for any remaining resources"
echo "2. Clean GitHub Container Registry packages"
echo "3. Review GitHub Actions artifacts"
```

## 📖 Technical Documentation

### Architecture Overview
This project implements a **modern DevOps pipeline** with the following key components:

- **Infrastructure as Code**: OpenTofu for AWS resource management
- **Containerization**: Docker Compose for local development
- **CI/CD Automation**: GitHub Actions for testing and deployment
- **Multi-Environment Support**: Separate dev/stage/prod configurations
- **Security Integration**: Automated vulnerability scanning
- **Documentation as Code**: Auto-generated project documentation

### Key Technical Decisions

#### 🎯 **OpenTofu over Terraform**
- **Open-source** alternative with better community governance
- **No licensing concerns** for commercial use
- **Full compatibility** with existing Terraform modules

#### 🏗️ **Multi-Environment Structure**
- **Environment isolation** - separate state and configurations
- **Progressive deployment** - test in dev before production
- **Risk mitigation** - failures don't cascade between environments

#### 🐳 **Docker Compose for Development**
- **Simplicity** - easier local development than Kubernetes
- **Resource efficiency** - lower overhead for development
- **CI/CD integration** - works seamlessly with GitHub Actions

#### 🔄 **Sequential Pipeline with Strategic Parallelization**
```
validate-environments (matrix: dev,stage,prod) → docker-build-test → summary → generate-docs
```
- **Fail fast** - validate infrastructure before expensive builds
- **Resource optimization** - parallel environment validation
- **Clear dependencies** - logical job progression

#### 🧪 **Multi-Layer Testing Strategy**
- **Tofu validation** - syntax and configuration checks
- **Docker integration tests** - full application stack verification
- **Security scanning** - TfSec + Trivy for vulnerabilities

#### 📚 **Documentation as Code**
- **Always up-to-date** - generated from actual codebase
- **Zero maintenance** - no manual documentation updates
- **Consistency** - standardized structure across projects

### AWS Infra desired structure
  <img src=".github/AWS_Infra_diagram.svg" alt="AWS Diagram" style="max-width: 100%; height: auto;" />


### Docker application structure
  <img src=".github/Docker-compose_diagram.svg" alt="Docker Compose structure Diagram" style="max-width: 100%; height: auto;" />

## 🔄 CI/CD Pipeline

The project uses **GitHub Actions** for automated CI/CD:

### Pipeline Stages:
1. **🧩 Infrastructure Validation** - Validate Tofu modules and environments
2. **🐳 Docker Build & Test** - Build application, run integration tests
3. **📚 Documentation** - Auto-generate and update README.md
4. **📋 Summary** - Pipeline results and status

### Triggers:
- **Push** to `main` or `develop` branches
- **Pull Requests** to `main` branch
- **Manual trigger** via workflow dispatch

### Monitoring:
- All tests must pass before merge
- Security scans with Trivy and TfSec

---

### 📊 Project Stats
- **Modules**: 3 infrastructure modules
- **Environments**: 3 deployment environments
- **Application**: docker-express-nodejs-app

**🤖 Auto-generated on:** `Tue Aug 26 11:19:41 UTC 2025`
**📋 Last updated by:** GitHub Actions Bot
