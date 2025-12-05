# Terraform EC2 Deployment with GitHub Actions & Cypress Testing

This repository provides a complete CI/CD pipeline for deploying an Ubuntu EC2 instance on AWS using Terraform and running Cypress end-to-end tests via GitHub Actions.

## 🚀 Features

- **Infrastructure as Code**: Terraform configuration for EC2 provisioning
- **Dynamic AMI Selection**: Automatically uses the latest Ubuntu 22.04 LTS AMI for any AWS region
- **Existing VPC Integration**: Deploys into your specified VPC and subnet
- **Automated Testing**: Cypress E2E tests run on the deployed instance
- **Secure Secrets Management**: All sensitive data stored in GitHub Secrets
- **Web Server Ready**: Nginx installed and configured automatically

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

The Cypress test performs the following checks:

1. **HTTP Connectivity**: Visits `http://localhost` on the EC2 instance
2. **Content Verification**: Checks for "Welcome to nginx!" text
3. **Fallback Validation**: Uses curl to verify HTTP 200 response

### Test File Location (on EC2)

```javascript
// ~/e2e-tests/cypress/e2e/welcome.cy.js
describe('Nginx Welcome Page', () => {
  it('should display the default welcome message', () => {
    cy.visit('http://localhost');
    cy.contains('Welcome to nginx!');
  });
});
```

## 🛠️ Local Testing (Optional)

To test Terraform locally before pushing:

```bash
cd terraform

# Initialize Terraform
terraform init

# Set required variables
export TF_VAR_vpc_id="vpc-xxxxxxxx"
export TF_VAR_subnet_id="subnet-xxxxxxxx"
export TF_VAR_key_name="MyKeyPair"
export TF_VAR_aws_region="us-west-2"

# Plan (preview changes)
terraform plan

# Apply (create resources)
terraform apply

# Get the public IP
terraform output public_ip

# SSH into the instance
ssh -i /path/to/MyKeyPair.pem ubuntu@<public-ip>

# Destroy (cleanup)
terraform destroy
```

## 🔒 Security Considerations

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
