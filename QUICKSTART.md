# Quick Setup Guide

## AWS Prerequisites Checklist

- [ ] AWS account with EC2 permissions
- [ ] Existing VPC ID noted
- [ ] Subnet ID (in the VPC) noted
- [ ] EC2 Key Pair created and private key saved
- [ ] IAM user credentials (Access Key ID and Secret)

## GitHub Setup Steps

1. **Fork/Clone this repository**
   ```bash
   git clone https://github.com/yourusername/terraform-ec2-cypress.git
   ```

2. **Add GitHub Secrets** (Settings → Secrets → Actions → New):
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_REGION` (e.g., us-west-2)
   - `AWS_VPC_ID` (e.g., vpc-xxxxx)
   - `AWS_SUBNET_ID` (e.g., subnet-xxxxx)
   - `AWS_KEY_NAME` (e.g., MyKeyPair)
   - `SSH_PRIVATE_KEY` (entire .pem file content)

3. **Push to main branch**
   ```bash
   git add .
   git commit -m "Configure for my AWS account"
   git push origin main
   ```

4. **Monitor workflow** in Actions tab

5. **Destroy resources** when done (Actions → Terraform Destroy → Run workflow)

## AWS CLI Commands for Prerequisites

### Create Key Pair
```bash
aws ec2 create-key-pair --key-name MyKeyPair \
  --query 'KeyMaterial' --output text > MyKeyPair.pem
chmod 400 MyKeyPair.pem
```

### Find VPC ID
```bash
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' --output table
```

### Find Subnet ID
```bash
aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-xxxxxxxx" \
  --query 'Subnets[*].[SubnetId,AvailabilityZone,CidrBlock]' --output table
```

### Verify Region
```bash
aws configure get region
```

## Testing Locally (Before GitHub Actions)

```bash
cd terraform

export TF_VAR_vpc_id="vpc-xxxxxxxx"
export TF_VAR_subnet_id="subnet-xxxxxxxx"
export TF_VAR_key_name="MyKeyPair"
export TF_VAR_aws_region="us-west-2"

terraform init
terraform plan
terraform apply
terraform output public_ip

# SSH to test
ssh -i ../MyKeyPair.pem ubuntu@$(terraform output -raw public_ip)

# Cleanup
terraform destroy
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| SSH timeout | Check subnet has internet gateway route |
| Invalid key pair | Ensure key exists in target region |
| Cypress fails | Verify Nginx running: `sudo systemctl status nginx` |
| Apply fails | Check IAM permissions for EC2/VPC/SSM |

## Cost Estimate

- **t3.micro instance**: ~$0.0104/hour (~$7.50/month if left running)
- **EBS volume**: ~$0.10/GB/month (8GB = $0.80/month)
- **Data transfer**: First 100GB/month free

**Always destroy resources when not in use!**
