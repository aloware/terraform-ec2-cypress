# Terraform EC2 Deployment with GitHub Actions & Cypress Testing

This repository provides a complete CI/CD pipeline for deploying an Ubuntu EC2 instance on AWS using Terraform and running Cypress end-to-end tests via GitHub Actions.

## 🚀 Features

- **Infrastructure as Code**: Terraform configuration for EC2 provisioning
- **Dynamic AMI Selection**: Automatically uses the latest Ubuntu 22.04 LTS AMI for any AWS region
- **Existing VPC Integration**: Deploys into your specified VPC and subnet
- **Automated Testing**: Cypress E2E tests run on the deployed instance ✅ **Verified Working**
- **Secure Secrets Management**: All sensitive data stored in GitHub Secrets
- **Web Server Ready**: Nginx installed and configured automatically
- **Optimized Instance Size**: Configured for t3.xlarge (4 vCPUs, 16GB RAM) - meets IDE requirements (min 4 cores, 4GB RAM)

## 📋 Prerequisites

Before you begin, ensure you have:

1. **AWS Account** with appropriate permissions to create:
   - EC2 instances
   - Security groups
   - Network interfaces

2. **AWS EC2 Key Pair** created in your target region:
   ```bash
   aws ec2 create-key-pair --key-name MyKeyPair --query 'KeyMaterial' --output text > MyKeyPair.pem
   chmod 400 MyKeyPair.pem
   ```

3. **Existing VPC and Subnet** IDs (not using default VPC):
   ```bash
   # List your VPCs
   aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' --output table
   
   # List subnets in a VPC
   aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-xxxxxxxx" \
     --query 'Subnets[*].[SubnetId,AvailabilityZone,CidrBlock]' --output table
   ```

4. **AWS IAM Credentials** with permissions for EC2, VPC, and SSM Parameter Store

## 🔧 Setup Instructions

### Step 1: Fork or Clone This Repository

```bash
git clone https://github.com/yourusername/terraform-ec2-cypress.git
cd terraform-ec2-cypress
```

### Step 2: Configure GitHub Secrets

Navigate to your GitHub repository: **Settings → Secrets and variables → Actions → New repository secret**

Add the following secrets:

| Secret Name | Description | Example Value |
|------------|-------------|---------------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key ID | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `AWS_REGION` | Target AWS region | `us-west-2` |
| `AWS_VPC_ID` | Existing VPC ID | `vpc-0123456789abcdef0` |
| `AWS_SUBNET_ID` | Subnet ID in the VPC | `subnet-0123456789abcdef0` |
| `AWS_KEY_NAME` | EC2 Key Pair name | `MyKeyPair` |
| `SSH_PRIVATE_KEY` | Private key content (entire .pem file) | `-----BEGIN RSA PRIVATE KEY-----`<br>`MIIEpAIBAAKCAQEA...`<br>`-----END RSA PRIVATE KEY-----` |

**Important**: For `SSH_PRIVATE_KEY`, paste the entire content of your `.pem` file including the header and footer lines.

### Step 3: Push to GitHub

```bash
git add .
git commit -m "Initial Terraform EC2 setup with Cypress"
git push origin main
```

The GitHub Actions workflow will trigger automatically on push to `main`.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Actions Workflow                  │
│                                                               │
│  1. Checkout Code                                            │
│  2. Configure AWS Credentials                                │
│  3. Setup Terraform                                          │
│  4. Terraform Init & Apply                                   │
│  5. Extract EC2 Public IP                                    │
│  6. Wait for SSH Availability                                │
│  7. SSH into EC2 & Run Tests                                 │
│     ├─ Install Node.js                                       │
│     ├─ Install Cypress                                       │
│     ├─ Create Test Specs                                     │
│     └─ Execute Cypress Tests                                 │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                         AWS Cloud                            │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                  Your Existing VPC                    │  │
│  │                                                        │  │
│  │  ┌──────────────────────────────────────────────┐   │  │
│  │  │         Subnet (specified)                    │   │  │
│  │  │                                                │   │  │
│  │  │  ┌─────────────────────────────────────┐     │   │  │
│  │  │  │   EC2 Instance (Ubuntu 22.04 LTS)   │     │   │  │
│  │  │  │   - Nginx Web Server (Port 80)      │     │   │  │
│  │  │  │   - SSH Access (Port 22)            │     │   │  │
│  │  │  │   - Node.js + Cypress               │     │   │  │
│  │  │  └─────────────────────────────────────┘     │   │  │
│  │  │                                                │   │  │
│  │  └──────────────────────────────────────────────┘   │  │
│  │                                                        │  │
│  │  Security Group:                                      │  │
│  │    - Ingress: 22 (SSH), 80 (HTTP)                    │  │
│  │    - Egress: All                                      │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Repository Structure

```
terraform-ec2-cypress/
├── .github/
│   └── workflows/
│       ├── deploy_and_test.yml    # Main CI/CD pipeline
│       └── destroy.yml             # Infrastructure teardown
├── terraform/
│   ├── main.tf                     # Main Terraform config
│   ├── variables.tf                # Input variables
│   └── versions.tf                 # Provider versions
├── .gitignore                      # Ignore Terraform state & keys
└── README.md                       # This file
```

## 🔄 Workflows

### Deploy and Test Workflow

**Trigger**: Automatic on push to `main` branch, or manual via workflow_dispatch

**Steps**:
1. Provisions EC2 instance with Terraform
2. Waits for instance to be SSH-ready
3. Installs Node.js and Cypress on the instance
4. Runs Cypress tests against the local Nginx server
5. Validates with curl fallback

**View workflow runs**: Go to **Actions** tab in your GitHub repository

### Destroy Workflow

**Trigger**: Manual only (workflow_dispatch)

**Purpose**: Tears down all AWS resources created by Terraform to avoid ongoing costs

**Usage**:
1. Go to **Actions** tab
2. Select "Terraform Destroy" workflow
3. Click "Run workflow"
4. Confirm destruction

## 🧪 Testing

### Verified Test Results ✅

Successfully tested on **t3.xlarge** EC2 instance (4 vCPUs, 16GB RAM, Ubuntu 22.04 LTS):

```
Cypress:        13.6.0
Browser:        Electron 114 (headless)
Node Version:   v18.20.8
Specs:          1 found (basic-test.cy.js)

Basic Web Test
  ✓ should load the local web page (101ms)
  ✓ should find expected content (72ms)

2 passing (232ms)
```

The Cypress test performs the following checks:

1. **HTTP Connectivity**: Visits `http://localhost` on the EC2 instance
2. **Content Verification**: Checks for "nginx" text in the page
3. **Installation**: Fully automated via `install-and-test.sh` script

### Test File Location (on EC2)

```javascript
// ~/cypress-test/cypress/e2e/basic-test.cy.js
describe('Basic Web Test', () => {
  it('should load the local web page', () => {
    cy.visit('http://localhost');
  });
  
  it('should find expected content', () => {
    cy.visit('http://localhost');
    cy.contains('nginx').should('exist');
  });
});
```

### Running Tests Manually

After SSH into the instance:

```bash
# First time setup (installs everything)
bash install-and-test.sh

# Run tests again without reinstalling
cd ~/cypress-test
npx cypress run
```

## 🛠️ Local Testing (Optional)

To test Terraform locally before pushing:

```bash
cd terraform

# Initialize Terraform
terraform init

# Create terraform.tfvars with your configuration
cat > terraform.tfvars << EOF
aws_region = "us-west-2"
vpc_id = "vpc-xxxxxxxx"
subnet_id = "subnet-xxxxxxxx"
key_name = "MyKeyPair"
instance_name = "terraform-ec2-demo"
instance_type = "t3.xlarge"
EOF

# Plan (preview changes)
terraform plan

# Apply (create resources)
terraform apply

# Get the public IP
terraform output public_ip

# SSH into the instance and run tests
ssh -i /path/to/MyKeyPair.pem ubuntu@<public-ip>

# On the instance, run the test script
bash install-and-test.sh

# Destroy (cleanup)
terraform destroy
```

**Note**: The `terraform.tfvars` file is automatically ignored by git for security.

## � Cost Breakdown and Optimization

### Current Instance Configuration
- **Instance Type**: m7g.xlarge (ARM64 Graviton3 - 4 vCPUs, 16 GB RAM)
- **Storage**: 100 GB gp3 SSD (3000 IOPS, 125 MB/s throughput)
- **Region**: us-west-2 (Oregon)

### Monthly Cost Estimates

| Component | Running 24/7 | Stopped | Notes |
|-----------|--------------|---------|-------|
| **m7g.xlarge compute** | ~$119/mo | $0/mo | $0.1632/hour × 730 hours |
| **EBS gp3 100 GB** | ~$8/mo | ~$8/mo | Storage always charges |
| **Elastic IP (if attached)** | $0/mo | $3.60/mo | Only charges when stopped |
| **Data Transfer OUT** | ~$0-10/mo | $0/mo | First 100 GB/mo free |
| **TOTAL** | **~$127/mo** | **~$8/mo** | **94% savings when stopped** |

### Cost Optimization Strategies

#### 1. Stop When Not in Use (Recommended)
Stop the instance during non-working hours to save compute costs while keeping data intact:

| Usage Pattern | Hours/Month | Monthly Cost | Annual Cost | Savings vs 24/7 |
|---------------|-------------|--------------|-------------|-----------------|
| **24/7 running** | 730 hrs | ~$127/mo | ~$1,524/year | - |
| **Business hours (12h/day, M-F)** | 260 hrs | ~$50/mo | ~$600/year | ~$924/year (61%) |
| **Single shift (8h/day, M-F)** | 173 hrs | ~$36/mo | ~$432/year | ~$1,092/year (72%) |
| **Dev hours (6h/day, M-F)** | 130 hrs | ~$29/mo | ~$348/year | ~$1,176/year (77%) |
| **Only storage (stopped)** | 0 hrs | ~$8/mo | ~$96/year | ~$1,428/year (94%) |

**Stop/Start Commands** (Admin only - see [VSCODE_SSM_SETUP.md](docs/VSCODE_SSM_SETUP.md)):
```bash
# Stop instance
aws ec2 stop-instances --instance-ids i-0bb73c9206a8dbf62 --region us-west-2

# Start instance
aws ec2 start-instances --instance-ids i-0bb73c9206a8dbf62 --region us-west-2
```

#### 2. Schedule Instance with Lambda/EventBridge
Automate start/stop with AWS Lambda for predictable work schedules:
- **Example**: Auto-start at 9 AM PST, auto-stop at 6 PM PST (weekdays only)
- **Additional Cost**: ~$0-1/month for Lambda executions
- **Savings**: ~$75/month compared to 24/7

#### 3. Downsize Instance Type
Consider smaller instance types if workload permits:

| Instance Type | vCPU | RAM | Cost/Hour | Monthly (730h) | Savings vs m7g.xlarge |
|---------------|------|-----|-----------|----------------|-----------------------|
| m7g.xlarge | 4 | 16 GB | $0.1632 | ~$119/mo | - |
| m7g.large | 2 | 8 GB | $0.0816 | ~$60/mo | ~$59/mo (50%) |
| m7g.medium | 1 | 4 GB | $0.0408 | ~$30/mo | ~$89/mo (75%) |
| t4g.xlarge | 4 | 16 GB | $0.1344 | ~$98/mo | ~$21/mo (18%) |

⚠️ **Minimum Requirements for Remote Development**: 4 vCPUs, 4 GB RAM (current: m7g.xlarge exceeds requirements)

#### 4. What Still Charges When Stopped?
- ✅ **EBS Storage**: ~$8/month (cannot be avoided without data loss)
- ✅ **Elastic IP** (if attached): $3.60/month when instance is stopped
- ✅ **Snapshots**: $0.05/GB-month (if you create backups)
- ❌ **Compute**: $0 when stopped
- ❌ **Data Transfer**: $0 when stopped

### Best Practices for Cost Management
1. **Stop instances during nights/weekends**: Save ~$80-100/month
2. **Set up AWS Budget Alerts**: Get notified at $100, $150 thresholds
3. **Use AWS Cost Explorer**: Track daily spending patterns
4. **Tag resources**: `Project=terraform-ec2-cypress`, `Environment=dev`
5. **Regular audits**: Review resource usage monthly
6. **Delete unused snapshots**: $0.05/GB-month adds up

### Quick Cost Commands
```bash
# Check current month's estimated costs
aws ce get-cost-and-usage --time-period Start=2025-12-01,End=2025-12-31 \
  --granularity MONTHLY --metrics "UnblendedCost" --region us-east-1

# List running instances with costs
aws ec2 describe-instances --region us-west-2 \
  --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name]' --output table
```

For detailed stop/start procedures and permissions, see [Instance Management Documentation](docs/VSCODE_SSM_SETUP.md#stopping-the-instance-to-save-costs-admin-only).

---

## �🔒 Security Considerations

1. **SSH Access**: The security group opens SSH to `0.0.0.0/0` for demonstration. In production:
   - Restrict to specific IP ranges: `cidr_blocks = ["YOUR_IP/32"]`
   - Use AWS Systems Manager Session Manager instead
   - Implement bastion hosts for VPC access

2. **Secrets Management**: Never commit:
   - AWS credentials
   - Private keys
   - `terraform.tfstate` files
   - `.tfvars` files with sensitive data

3. **IAM Permissions**: Use least-privilege IAM policies:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "ec2:*",
           "ssm:GetParameter"
         ],
         "Resource": "*"
       }
     ]
   }
   ```

4. **Cost Management**: Always destroy resources when not in use:
   - Use the destroy workflow
   - Set up AWS Budget alerts
   - Tag resources for cost tracking

## 🐛 Troubleshooting

### Issue: SSH Connection Timeout

**Symptoms**: Workflow hangs at "Wait for EC2 SSH to become available"

**Solutions**:
- Verify the subnet has a route to an Internet Gateway (for public IP)
- Check security group rules allow inbound on port 22
- Ensure the subnet is configured to auto-assign public IPs

### Issue: Terraform Apply Fails

**Symptoms**: `Error: InvalidKeyPair.NotFound`

**Solutions**:
- Verify the key pair name matches in AWS and GitHub Secrets
- Ensure the key pair exists in the target region
- Check IAM permissions for EC2 key pair operations

### Issue: Cypress Tests Fail

**Symptoms**: `CypressError: cy.visit() failed trying to load`

**Solutions**:
- Verify Nginx is running: `sudo systemctl status nginx`
- Check Node.js version: `node --version` (should be 18.x)
- Review Cypress dependencies are installed correctly
- Check system resources (Cypress needs sufficient memory)

### Issue: Private Key Format Error

**Symptoms**: `Load key "ec2_key.pem": invalid format`

**Solutions**:
- Ensure the entire key content is copied (including headers/footers)
- Check for extra spaces or newlines in GitHub Secret
- Verify key format is RSA or ED25519 (not encrypted)

## 📚 Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Cypress Documentation](https://docs.cypress.io/)
- [Ubuntu on AWS](https://ubuntu.com/aws)
- [AWS SSM Parameter Store for AMIs](https://discourse.ubuntu.com/t/finding-ubuntu-images-with-the-aws-ssm-parameter-store/15507)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- HashiCorp for Terraform
- GitHub for Actions
- Cypress.io for testing framework
- Ubuntu/Canonical for AMI images

---

**Happy Deploying! 🚀**

For questions or issues, please open a GitHub issue in this repository.
