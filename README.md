# Terraform EC2 Deployment with GitHub Actions & Cypress Testing

This repository provides a complete CI/CD pipeline for deploying an Ubuntu EC2 instance on AWS using Terraform and running Cypress end-to-end tests via GitHub Actions.

## 🚀 Features

- **Infrastructure as Code**: Terraform configuration for EC2 provisioning
- **Dynamic AMI Selection**: Automatically uses the latest Ubuntu 22.04 LTS ARM64 AMI for any AWS region
- **Existing VPC Integration**: Deploys into your specified VPC and subnet
- **Automated Testing**: Cypress E2E tests run on the deployed instance ✅ **Verified Working**
- **Secure Secrets Management**: All sensitive data stored in GitHub Secrets
- **Web Server Ready**: Nginx installed and configured automatically
- **Optimized Instance Size**: Configured for m7g.xlarge ARM64 Graviton3 (4 vCPUs, 16GB RAM) - ~$119/month
- **Secure Access**: AWS Systems Manager Session Manager - SSH disabled for enhanced security ($0 additional cost)

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
│  │  │  │  EC2 m7g.xlarge (ARM64 Graviton3)   │     │   │  │
│  │  │  │   - Nginx Web Server (Port 80)      │     │   │  │
│  │  │  │   - Session Manager Access         │     │   │  │
│  │  │  │   - Docker + Node.js + Cypress      │     │   │  │
│  │  │  └─────────────────────────────────────┘     │   │  │
│  │  │                                                │   │  │
│  │  └──────────────────────────────────────────────┘   │  │
│  │                                                        │  │
│  │  Security Group:                                      │  │
│  │    - Ingress: 80 (HTTP) only - SSH disabled         │  │
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

After connecting via Session Manager:

```bash
# First time setup (installs everything)
bash install-and-test.sh

# Run tests again without reinstalling
cd ~/cypress-test
npx cypress run
```

## 🔐 Secure Access with AWS Systems Manager

SSH is **disabled** for enhanced security. Access the instance using AWS Systems Manager Session Manager:

### Method 1: AWS Console (Easiest)
1. Navigate to [EC2 Instances](https://us-west-2.console.aws.amazon.com/ec2/home?region=us-west-2#Instances:)
2. Select your instance (`i-089ab2bb0bafcf70f`)
3. Click **Connect** → **Session Manager** tab → **Connect** button

### Method 2: AWS CLI
```bash
# Install Session Manager plugin (one-time setup)
brew install session-manager-plugin  # macOS
# For other OS: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

# Connect to the instance
aws ssm start-session --target i-089ab2bb0bafcf70f --region us-west-2

# Verify connection
whoami  # should show: ssm-user
```

### Security Benefits
- ✅ No exposed SSH port (port 22 blocked)
- ✅ No SSH keys to manage or lose
- ✅ Audit trail via CloudTrail
- ✅ IAM-based access control
- ✅ $0 additional cost

### Required IAM Permissions
Your IAM user/group needs the `AmazonSSMFullAccess` policy (already attached to `Developers` group).

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
instance_type = "m7g.xlarge"  # ARM64 Graviton3
EOF

# Plan (preview changes)
terraform plan

# Apply (create resources)
terraform apply

# Get the public IP
terraform output public_ip

# Connect via Session Manager (SSH disabled)
aws ssm start-session --target $(terraform output -raw instance_id) --region us-west-2

# On the instance, run the test script
bash install-and-test.sh

# Destroy (cleanup)
terraform destroy
```

**Note**: The `terraform.tfvars` file is automatically ignored by git for security.

## 🔒 Security Features

1. **SSH Disabled**: Port 22 is blocked at the security group level
   - Uses AWS Systems Manager Session Manager for secure access
   - No SSH keys to manage or rotate
   - All access logged via CloudTrail
   
2. **IAM-Based Access Control**: Access managed through IAM policies
   - `Developers` group has `AmazonSSMFullAccess` policy
   - No need for SSH key distribution

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
