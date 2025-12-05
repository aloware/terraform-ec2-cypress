# GitHub Secrets Configuration Guide

This document provides detailed instructions for setting up GitHub Secrets for the Terraform EC2 deployment pipeline.

## Required Secrets

### 1. AWS_ACCESS_KEY_ID
**Description**: AWS IAM user access key ID for authentication

**How to get it**:
1. Log into AWS Console
2. Navigate to IAM → Users → Your User
3. Security Credentials tab
4. Create Access Key → CLI
5. Copy the Access Key ID

**Example**: `AKIAIOSFODNN7EXAMPLE`

---

### 2. AWS_SECRET_ACCESS_KEY
**Description**: Secret key paired with the access key ID

**How to get it**:
- Shown only once when creating the access key
- Download the CSV or copy immediately
- **Never commit this to git!**

**Example**: `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`

---

### 3. AWS_REGION
**Description**: Target AWS region for deployment

**Valid values**: `us-east-1`, `us-west-2`, `eu-west-1`, etc.

**Example**: `us-west-2`

**How to decide**:
- Choose region closest to your users
- Consider compliance requirements
- Check service availability

---

### 4. AWS_VPC_ID
**Description**: ID of your existing VPC (not the default VPC)

**How to get it**:
```bash
# List all VPCs in your account
aws ec2 describe-vpcs \
  --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0],IsDefault]' \
  --output table

# Or filter non-default VPCs only
aws ec2 describe-vpcs \
  --filters "Name=is-default,Values=false" \
  --query 'Vpcs[*].[VpcId,CidrBlock]' \
  --output table
```

**Example**: `vpc-0123456789abcdef0`

---

### 5. AWS_SUBNET_ID
**Description**: ID of a subnet within your VPC where the EC2 will be launched

**Requirements**:
- Must be in the same VPC as AWS_VPC_ID
- Should have internet connectivity (route to Internet Gateway)
- Should have auto-assign public IP enabled (or we need an Elastic IP)

**How to get it**:
```bash
# List subnets in your VPC
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=vpc-xxxxxxxx" \
  --query 'Subnets[*].[SubnetId,AvailabilityZone,CidrBlock,MapPublicIpOnLaunch]' \
  --output table
```

**Example**: `subnet-0123456789abcdef0`

---

### 6. AWS_KEY_NAME
**Description**: Name of an existing EC2 Key Pair for SSH access

**How to create**:
```bash
# Create new key pair
aws ec2 create-key-pair \
  --key-name MyKeyPair \
  --query 'KeyMaterial' \
  --output text > MyKeyPair.pem

# Set permissions
chmod 400 MyKeyPair.pem
```

**Or using AWS Console**:
1. EC2 → Key Pairs → Create Key Pair
2. Name: `MyKeyPair`
3. Type: RSA
4. Format: .pem
5. Download the private key file

**Example**: `MyKeyPair` (just the name, not the .pem file)

---

### 7. SSH_PRIVATE_KEY
**Description**: The complete private key file content (corresponding to AWS_KEY_NAME)

**Format**: Entire .pem file content including headers

**How to get it**:
```bash
# Display key content
cat MyKeyPair.pem

# Or copy to clipboard (macOS)
pbcopy < MyKeyPair.pem

# Or copy to clipboard (Linux with xclip)
xclip -selection clipboard < MyKeyPair.pem
```

**Example**:
```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAr4z2Y8X7JQ7ZKQvL5YqE9mH1xGv3wN9RKDjQ8F7WzP4vB5nX
[... many lines of encoded key data ...]
qX9YHZfL8vW2pB7nQ3VgJ9kL4Xm8HQaR5vT6wC8N==
-----END RSA PRIVATE KEY-----
```

**Important**:
- Include the BEGIN and END lines
- Preserve all newlines
- Do not add extra spaces
- GitHub Secret will handle the multi-line format

---

## How to Add Secrets to GitHub

### Via Web UI:
1. Go to your repository on GitHub
2. Click **Settings** tab
3. Click **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Enter **Name** and **Value**
6. Click **Add secret**

### Via GitHub CLI:
```bash
# Install GitHub CLI: https://cli.github.com/

# Authenticate
gh auth login

# Add secrets
gh secret set AWS_ACCESS_KEY_ID -b "AKIAIOSFODNN7EXAMPLE"
gh secret set AWS_SECRET_ACCESS_KEY -b "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
gh secret set AWS_REGION -b "us-west-2"
gh secret set AWS_VPC_ID -b "vpc-0123456789abcdef0"
gh secret set AWS_SUBNET_ID -b "subnet-0123456789abcdef0"
gh secret set AWS_KEY_NAME -b "MyKeyPair"

# Add multi-line SSH key from file
gh secret set SSH_PRIVATE_KEY < MyKeyPair.pem
```

---

## Verification Checklist

Before running the workflow, verify:

- [ ] All 7 secrets are added to GitHub
- [ ] AWS credentials are valid (test with `aws sts get-caller-identity`)
- [ ] VPC and Subnet IDs exist in the target region
- [ ] Subnet has internet connectivity (route to IGW)
- [ ] EC2 Key Pair exists in the target region
- [ ] SSH_PRIVATE_KEY matches the AWS_KEY_NAME
- [ ] IAM user has necessary permissions (EC2, VPC, SSM)

---

## Security Best Practices

1. **Use dedicated IAM user** for GitHub Actions (not your personal account)
2. **Apply least-privilege policy**:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "ec2:RunInstances",
           "ec2:TerminateInstances",
           "ec2:DescribeInstances",
           "ec2:CreateSecurityGroup",
           "ec2:DeleteSecurityGroup",
           "ec2:AuthorizeSecurityGroupIngress",
           "ec2:RevokeSecurityGroupIngress",
           "ec2:CreateTags",
           "ec2:DescribeSecurityGroups",
           "ec2:DescribeSubnets",
           "ec2:DescribeVpcs",
           "ssm:GetParameter"
         ],
         "Resource": "*"
       }
     ]
   }
   ```
3. **Enable MFA** on the IAM user account
4. **Rotate access keys** periodically
5. **Use AWS CloudTrail** to monitor API calls
6. **Never expose private keys** in logs or code

---

## Troubleshooting

### Issue: "Error: InvalidKeyPair.NotFound"
**Solution**: 
- Verify AWS_KEY_NAME matches an existing key in the region
- Check you're in the correct AWS region

### Issue: SSH connection fails
**Solution**:
- Verify SSH_PRIVATE_KEY matches AWS_KEY_NAME
- Check the key format (should have BEGIN/END lines)
- Ensure no extra characters or spaces

### Issue: "Error: UnauthorizedOperation"
**Solution**:
- Check IAM user permissions
- Verify AWS credentials are correct
- Ensure credentials haven't expired

### Issue: Subnet not found
**Solution**:
- Verify AWS_SUBNET_ID exists in AWS_VPC_ID
- Check you're in the correct region
- Ensure subnet ID format is correct (subnet-xxxxxxxxx)

---

## Testing Secrets Locally (Optional)

You can test the Terraform configuration locally using the same values:

```bash
export AWS_ACCESS_KEY_ID="your-access-key-id"
export AWS_SECRET_ACCESS_KEY="your-secret-access-key"
export AWS_REGION="us-west-2"
export TF_VAR_vpc_id="vpc-xxxxxxxx"
export TF_VAR_subnet_id="subnet-xxxxxxxx"
export TF_VAR_key_name="MyKeyPair"

cd terraform
terraform init
terraform plan
```

**Remember**: Never commit these values or your `terraform.tfstate` file!
