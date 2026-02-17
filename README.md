# Serverless Monorepo AWS

A production-ready serverless architecture using a monorepo structure with Infrastructure as Code (Terraform), Lambda functions, DynamoDB, and GitHub Actions CI/CD automation.

## 🎯 Overview

This project demonstrates best practices for building scalable serverless applications on AWS with:

- **Infrastructure as Code** - All AWS resources defined in Terraform
- **Monorepo Structure** - Organized separation of infrastructure, applications, and data layers
- **Security First** - GitHub OIDC authentication, least-privilege IAM roles, encrypted state
- **Automated CI/CD** - GitHub Actions workflows with OIDC-based authentication
- **Cost Optimization** - Scripts to detect orphaned resources and analyze costs
- **Comprehensive Testing** - Unit, integration, smoke, and property-based tests

## 📁 Project Structure

```
serverless-monorepo-aws/
├── infrastructure/              # Terraform IaC
│   ├── modules/                # Reusable Terraform modules
│   │   ├── api_gateway/
│   │   ├── lambda/
│   │   ├── dynamodb/
│   │   ├── iam/
│   │   └── s3/
│   ├── environments/            # Environment-specific configs
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   ├── global/                 # Global resources (OIDC, state backend)
│   ├── scripts/                # Infrastructure validation scripts
│   └── tests/                  # Terraform tests
│
├── apps/                        # Lambda applications
│   ├── api-handler/            # CRUD operations Lambda
│   │   ├── src/
│   │   │   ├── handlers/
│   │   │   ├── utils/
│   │   │   └── index.js
│   │   └── tests/
│   │       ├── unit/
│   │       ├── integration/
│   │       └── smoke/
│   └── authorizer/             # Optional JWT authorizer
│
├── data/                        # Data layer
│   ├── schemas/                # DynamoDB table schemas
│   ├── migrations/             # Database migrations
│   └── seeds/                  # Seed data
│
├── .github/
│   └── workflows/              # GitHub Actions workflows
│       ├── infrastructure-provisioning.yml
│       └── lambda-deployment.yml
│
├── package.json                # Root monorepo config
├── .gitignore
└── README.md
```

## 🚀 Quick Start

### Prerequisites

- Node.js 18+
- Terraform 1.6+
- AWS CLI configured
- GitHub repository with OIDC provider configured

### Local Development Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd serverless-monorepo-aws
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Initialize Terraform**
   ```bash
   cd infrastructure/environments/dev
   terraform init
   ```

4. **Validate infrastructure**
   ```bash
   npm run validate:terraform
   npm run validate:infrastructure
   ```

## 🏗️ Architecture

### High-Level Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     GitHub Repository                           │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  .github/workflows/                                      │   │
│  │  ├── infrastructure-provisioning.yml                     │   │
│  │  └── lambda-deployment.yml                              │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ GitHub OIDC Token
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AWS Account                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  API Gateway                                             │   │
│  │  ├── POST /items                                         │   │
│  │  ├── GET /items                                          │   │
│  │  ├── GET /items/{id}                                     │   │
│  │  ├── PUT /items/{id}                                     │   │
│  │  └── DELETE /items/{id}                                  │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Lambda Functions                                        │   │
│  │  ├── api-handler (CRUD operations)                       │   │
│  │  └── authorizer (Optional JWT validation)                │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  DynamoDB                                                │   │
│  │  ├── items table                                         │   │
│  │  └── status-index (GSI)                                  │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  S3 (Terraform State)                                    │   │
│  │  ├── Encryption: KMS                                     │   │
│  │  ├── Versioning: Enabled                                 │   │
│  │  └── Public Access: Blocked                              │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  DynamoDB (State Locking)                                │   │
│  │  └── LockID (Primary Key)                                │   │
│  └──────────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  CloudWatch                                              │   │
│  │  ├── Lambda Logs                                         │   │
│  │  ├── API Gateway Logs                                    │   │
│  │  └── Terraform Logs                                      │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## 🔐 Security Features

- ✅ **GitHub OIDC Authentication** - No hardcoded AWS credentials
- ✅ **Least-Privilege IAM Roles** - Separate roles for infrastructure and Lambda deployments
- ✅ **Encrypted Terraform State** - S3 with KMS encryption and DynamoDB locking
- ✅ **Environment-Specific Configurations** - Isolated settings per environment
- ✅ **Input Validation** - All Lambda inputs validated before processing
- ✅ **HTTPS Enforcement** - All API communications use HTTPS
- ✅ **CloudWatch Logging** - Comprehensive audit trails and monitoring

## 📊 API Endpoints

### Base URL
```
https://{api-id}.execute-api.{region}.amazonaws.com/{stage}
```

### Endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | /items | Create a new item |
| GET | /items | List all items (with pagination) |
| GET | /items/{id} | Get item by ID |
| PUT | /items/{id} | Update item |
| DELETE | /items/{id} | Delete item |

### Example Requests

**Create Item**
```bash
curl -X POST https://api.example.com/items \
  -H "Content-Type: application/json" \
  -d '{"name": "My Item", "description": "Item description"}'
```

**Get Item**
```bash
curl https://api.example.com/items/item-id
```

**List Items**
```bash
curl "https://api.example.com/items?limit=10&offset=0"
```

**Update Item**
```bash
curl -X PUT https://api.example.com/items/item-id \
  -H "Content-Type: application/json" \
  -d '{"name": "Updated Name"}'
```

**Delete Item**
```bash
curl -X DELETE https://api.example.com/items/item-id
```

## 🧪 Testing

### Run All Tests
```bash
npm test
```

### Run Tests with Coverage
```bash
npm run test:coverage
```

### Run Tests in Watch Mode
```bash
npm run test:watch
```

### Test Types

- **Unit Tests** - Individual function testing
- **Integration Tests** - API Gateway + Lambda integration
- **Smoke Tests** - Post-deployment validation
- **Property-Based Tests** - Universal correctness properties

## 🛠️ Infrastructure Management

### Validate Infrastructure
```bash
npm run validate:infrastructure
```

### Detect Orphaned Resources
```bash
npm run detect:orphans
```

### Analyze Costs
```bash
npm run analyze:costs
```

### Validate Before Destruction
```bash
npm run validate:destroy
```

## 📋 Deployment

### Development Environment
```bash
cd infrastructure/environments/dev
terraform init
terraform plan
terraform apply
```

### Staging Environment
```bash
cd infrastructure/environments/staging
terraform init
terraform plan
terraform apply
```

### Production Environment
```bash
cd infrastructure/environments/prod
terraform init
terraform plan
terraform apply  # Requires manual approval
```

## 📚 Documentation

- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Detailed architecture documentation
- **[CONFIGURATION.md](./CONFIGURATION.md)** - Environment variables and configuration
- **[OIDC_SETUP.md](./OIDC_SETUP.md)** - GitHub OIDC configuration guide
- **[DEPLOYMENT.md](./DEPLOYMENT.md)** - Production deployment guide

## 🔍 Troubleshooting

### Terraform State Lock Issues
```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

### Lambda Function Not Updating
```bash
# Check Lambda logs
aws logs tail /aws/lambda/api-handler-dev --follow
```

### API Gateway Errors
```bash
# Check API Gateway logs
aws logs tail /aws/apigateway/api-id --follow
```

## 💰 Cost Optimization

Use the included scripts to:
- Detect orphaned resources
- Analyze pricing models
- Identify unused resources
- Generate optimization recommendations

```bash
npm run analyze:costs
```

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Run tests and validation
4. Submit a pull request

## 📝 License

MIT

## 📞 Support

For issues or questions:
1. Check the documentation files
2. Review the spec documents in `.kiro/specs/serverless-monorepo-aws/`
3. Check AWS CloudTrail for API errors

---

**Ready to deploy? Start with the [Quick Start](#quick-start) section above.**
