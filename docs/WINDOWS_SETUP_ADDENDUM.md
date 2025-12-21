# Windows Users - Additional Setup Steps

> **Append this section to the main Confluence guide after the macOS/Linux SSH configuration section**

---

## Windows-Specific Configuration

### SSH Config File Location
- **Path:** `C:\Users\YourUsername\.ssh\config`
- If the `.ssh` folder doesn't exist, create it first

### Step 3 (Windows): Configure SSH for SSM Tunneling

Replace the macOS/Linux SSH config with this **Windows-specific version**:

```bash
# AWS SSM Session Manager - terraform-ec2-demo
Host terraform-ec2-demo
    HostName i-089ab2bb0bafcf70f
    User ubuntu
    ProxyCommand C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe "aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters portNumber=%p --region us-west-2"
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

**Key Differences from macOS/Linux:**
- Uses PowerShell instead of `sh -c`
- No quotes around `portNumber=%p` parameter
- Different syntax for command execution

### Prerequisites for Windows

Before connecting, ensure AWS CLI is properly installed:

#### 1. Install AWS CLI v2
- Download from: https://awscli.amazonaws.com/AWSCLIV2.msi
- Run the installer with default options
- Default installation path: `C:\Program Files\Amazon\AWSCLIV2\`

#### 2. Verify AWS CLI Installation
Open **PowerShell** (not Command Prompt) and run:
```powershell
aws --version
```

**Expected output:**
```
aws-cli/2.x.x Python/3.x.x Windows/10 exe/AMD64
```

If you see "aws: command not found", the installation didn't complete properly.

#### 3. Configure AWS Credentials
If not already configured, run:
```powershell
aws configure
```

Enter your:
- AWS Access Key ID
- AWS Secret Access Key
- Default region: `us-west-2`
- Default output format: `json`

#### 4. Restart Your IDE Completely
After installing AWS CLI, **close all Cursor/VS Code windows** and restart the application.

### Common Windows Issues & Solutions

#### Issue: "aws: command not found" in connection logs

**Cause:** SSH ProxyCommand can't find AWS CLI in PATH

**Solutions (try in order):**

**Option 1: Restart IDE**
- Close **all** Cursor/VS Code windows completely
- Reopen and try connecting again

**Option 2: Use Full AWS CLI Path**
Edit your SSH config to use the absolute path:
```bash
Host terraform-ec2-demo
    HostName i-089ab2bb0bafcf70f
    User ubuntu
    ProxyCommand C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe "C:\Program Files\Amazon\AWSCLIV2\aws.exe ssm start-session --target %h --document-name AWS-StartSSHSession --parameters portNumber=%p --region us-west-2"
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

**Option 3: Verify AWS CLI in PATH**
Open a new PowerShell window and run:
```powershell
$env:PATH -split ';' | Select-String -Pattern 'AWS'
```

If no results, AWS CLI is not in your PATH. Reinstall AWS CLI.

#### Issue: "The process tried to write to a nonexistent pipe"

**Cause:** SSH connection failed before establishing tunnel

**Solution:**
1. Test AWS CLI directly in PowerShell:
   ```powershell
   aws ssm start-session --target i-089ab2bb0bafcf70f --region us-west-2
   ```
2. If this works, the issue is with your SSH config syntax
3. Double-check the ProxyCommand line (no line breaks, correct quotes)

#### Issue: Session Manager Plugin Not Found

**Installation:**
Download from: https://s3.amazonaws.com/session-manager-downloads/plugin/latest/windows/SessionManagerPluginSetup.exe

**Verify installation:**
```powershell
session-manager-plugin
```

### Testing Your Windows Setup

**Step 1: Test AWS CLI**
```powershell
aws sts get-caller-identity
```
Should return your AWS account information.

**Step 2: Test Session Manager**
```powershell
aws ssm start-session --target i-089ab2bb0bafcf70f --region us-west-2
```
Should connect you to the instance. Type `exit` to disconnect.

**Step 3: Test SSH Connection**
```powershell
ssh terraform-ec2-demo
```
Should connect via SSH over SSM tunnel.

**Step 4: Connect Cursor/VS Code**
- Press `Ctrl+Shift+P`
- Type "Remote-SSH: Connect to Host"
- Select `terraform-ec2-demo`

---

## Quick Reference - Windows Commands

```powershell
# Verify AWS CLI installation
aws --version

# Test AWS credentials
aws sts get-caller-identity

# Test Session Manager connection
aws ssm start-session --target i-089ab2bb0bafcf70f --region us-west-2

# Test SSH connection
ssh terraform-ec2-demo

# Open Cursor remotely
cursor --remote ssh-remote+terraform-ec2-demo /home/ubuntu

# Check SSH config location
echo $env:USERPROFILE\.ssh\config
```

---

## Windows-Specific File Paths Reference

| Description | Windows Path | macOS/Linux Equivalent |
|-------------|--------------|------------------------|
| SSH Config | `C:\Users\YourName\.ssh\config` | `~/.ssh/config` |
| SSH Keys | `C:\Users\YourName\.ssh\` | `~/.ssh/` |
| AWS Config | `C:\Users\YourName\.aws\config` | `~/.aws/config` |
| AWS Credentials | `C:\Users\YourName\.aws\credentials` | `~/.aws/credentials` |
| PowerShell | `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe` | `/bin/bash` or `/bin/zsh` |
| AWS CLI | `C:\Program Files\Amazon\AWSCLIV2\aws.exe` | `/usr/local/bin/aws` |

---

**Need Help?**
Contact Orlando (orlando@aloware.com) if you encounter issues after following these steps.
