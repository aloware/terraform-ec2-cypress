# Remote Development via AWS Session Manager

This guide walks you through connecting Cursor IDE to the EC2 instance using AWS Session Manager (SSM) for secure remote development without exposing SSH ports.

## Prerequisites

- AWS CLI configured with your credentials
- Cursor IDE installed
- Access to AWS account (Developers IAM group)

## Step 1: Install Session Manager Plugin

### macOS (via Homebrew)
```bash
brew install --cask session-manager-plugin
```

### macOS (Manual Installation)
```bash
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/sessionmanager-bundle.zip" -o "sessionmanager-bundle.zip"
unzip sessionmanager-bundle.zip
sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin
```

### Verify Installation
```bash
session-manager-plugin
```

You should see the Session Manager plugin version information.

## Step 2: Install Remote SSH Extension in Cursor

1. Open Cursor
2. Press `Cmd+Shift+X` (or go to Extensions)
3. Search for **"Remote - SSH"**
4. Install the extension published by **Microsoft**

> **Note:** Cursor is built on VS Code and uses the same Remote-SSH extension.

## Step 3: Configure SSH for SSM Tunneling

### macOS/Linux Users

Add the following configuration to your `~/.ssh/config` file:

```bash
# AWS SSM Session Manager - terraform-ec2-demo
Host terraform-ec2-demo
    HostName i-0bb73c9206a8dbf62
    User ubuntu
    ProxyCommand sh -c "aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p' --region us-west-2"
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

**To add this configuration:**

#### Option A: Manual Edit
```bash
# Open the SSH config file in your editor
nano ~/.ssh/config

# Paste the configuration above
# Save and exit (Ctrl+O, Enter, Ctrl+X for nano)
```

#### Option B: Append via Command
```bash
cat >> ~/.ssh/config << 'EOF'

# AWS SSM Session Manager - terraform-ec2-demo
Host terraform-ec2-demo
    HostName i-0bb73c9206a8dbf62
    User ubuntu
    ProxyCommand sh -c "aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p' --region us-west-2"
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF
```

### Windows Users

Add the following configuration to `C:\Users\YourUsername\.ssh\config`:

```bash
# AWS SSM Session Manager - terraform-ec2-demo
Host terraform-ec2-demo
    HostName i-0bb73c9206a8dbf62
    User ubuntu
    ProxyCommand C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe "aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters portNumber=%p --region us-west-2"
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

> **Critical for Windows:**
> 1. AWS CLI must be installed and accessible in PowerShell
> 2. Test first: Open PowerShell and run `aws --version`
> 3. If "aws: command not found", install AWS CLI v2 from: https://aws.amazon.com/cli/
> 4. After installing, restart Cursor/VS Code completely

## Step 4: Generate SSH Key (If You Don't Have One)

Check if you already have an SSH key:
```bash
ls -la ~/.ssh/id_*.pub
```

If you don't have one, generate it:
```bash
ssh-keygen -t ed25519 -C "your-email@aloware.com"
# Press Enter to accept default location
# Optionally set a passphrase or press Enter for no passphrase
```

## Step 5: Get Your SSH Public Key

```bash
cat ~/.ssh/id_ed25519.pub
```

Copy the entire output (it looks like: `ssh-ed25519 AAAA...xyz your-email@aloware.com`)

## Step 6: Request SSH Key Access

**Send the following information to Orlando:**

```
Subject: SSH Key for terraform-ec2-demo Instance Access

Hi Orlando,

Please add my SSH public key to the terraform-ec2-demo instance.

SSH Public Key:
[PASTE YOUR PUBLIC KEY FROM STEP 5 HERE]

Email: your-email@aloware.com
Instance: i-0bb73c9206a8dbf62 (terraform-ec2-demo)

Thanks!
```

**Wait for confirmation** that your key has been added to the instance.

## Step 7: Test SSH Connection

Once Orlando confirms your key is added, test the connection:

```bash
ssh terraform-ec2-demo "echo 'Connection successful!' && pwd && whoami"
```

**Expected output:**
```
Connection successful!
/home/ubuntu
ubuntu
```

If you see "Permission denied (publickey)", your key hasn't been added yet or there's a configuration issue.

## Step 8: Connect Cursor to the Instance

### Option A: Via Command Palette
1. Press `Cmd+Shift+P` (macOS) or `Ctrl+Shift+P` (Windows/Linux)
2. Type: **"Remote-SSH: Connect to Host"**
3. Select `terraform-ec2-demo` from the list
4. A new Cursor window will open connected to the instance

### Option B: Via Command Line
```bash
cursor --remote ssh-remote+terraform-ec2-demo /home/ubuntu
```

### Option C: Via SSH Targets Icon
1. Click the Remote Explorer icon in the left sidebar (looks like a monitor)
2. Find `terraform-ec2-demo` under "SSH Targets"
3. Click the connect icon (→) next to it

## Step 9: Open Your Project Folder

Once connected:
1. Press `Cmd+O` or File → Open Folder
2. Navigate to your project directory (e.g., `/home/ubuntu/my-project`)
3. Click "OK"

You now have full Cursor functionality on the remote instance, including AI features!

## Features Available

- ✅ Edit files directly on the instance
- ✅ Integrated terminal (bash on the instance)
- ✅ Git integration
- ✅ Extensions/plugins run on the remote instance
- ✅ Port forwarding for web apps
- ✅ IntelliSense and debugging
- ✅ File synchronization

## Troubleshooting

### Error: "session-manager-plugin not found"
- Verify installation: `which session-manager-plugin`
- Reinstall using Step 1

### Error: "Permission denied (publickey)"
- Your SSH key hasn't been added to the instance
- Contact Orlando to add your key (Step 6)
- Verify your key: `cat ~/.ssh/id_ed25519.pub`

### Error: "Connection timeout" or "TargetNotConnected"
- Verify SSM agent is running: Contact Orlando
- Check your AWS credentials: `aws sts get-caller-identity`
- Verify you're in the Developers IAM group

### Error: "Unable to start session"
- Check AWS credentials are configured: `aws configure list`
- Ensure you have SSM permissions (should be in Developers group)
- Verify instance ID is correct: `i-0bb73c9206a8dbf62`

### IDE: "Could not establish connection to terraform-ec2-demo"
- Test SSH manually first: `ssh terraform-ec2-demo`
- Check SSH config syntax in `~/.ssh/config` (or `C:\Users\YourName\.ssh\config` on Windows)
- Restart Cursor after modifying SSH config
- Try reloading the window: `Cmd+Shift+P` → "Reload Window"

### Windows: "aws: command not found" in ProxyCommand
**This is the most common Windows issue**
- AWS CLI is not in your PATH when SSH runs
- **Solution 1:** Install AWS CLI v2 from https://aws.amazon.com/cli/
- **Solution 2:** After installing, completely restart Cursor (close all windows)
- **Solution 3:** Use full path in ProxyCommand:
  ```
  ProxyCommand C:\Program Files\Amazon\AWSCLIV2\aws.exe ssm start-session...
  ```
- **Verify:** Open PowerShell and run `aws --version` - should show version number

## Security Notes

- ✅ No SSH port (22) exposed to the internet
- ✅ All traffic goes through AWS Session Manager (encrypted)
- ✅ IAM-based authentication + SSH key authentication
- ✅ All connections logged in CloudTrail
- ⚠️ Do NOT share your private SSH key (`~/.ssh/id_ed25519`)
- ⚠️ Only share the public key (`~/.ssh/id_ed25519.pub`)

## Instance Information

| Property | Value |
|----------|-------|
| Instance ID | `i-0bb73c9206a8dbf62` |
| Instance Type | m7g.xlarge (ARM64 Graviton3) |
| vCPUs | 4 |
| RAM | 16 GB |
| Storage | 100 GB gp3 |
| Region | us-west-2 |
| OS | Ubuntu 22.04 LTS (ARM64) |
| Access Method | AWS Session Manager only |

## Quick Reference Commands

```bash
# Test connection
ssh terraform-ec2-demo "whoami"

# Open in Cursor
cursor --remote ssh-remote+terraform-ec2-demo /home/ubuntu

# Start interactive SSH session
ssh terraform-ec2-demo

# Copy file to instance
scp myfile.txt terraform-ec2-demo:/home/ubuntu/

# Copy file from instance
scp terraform-ec2-demo:/home/ubuntu/remotefile.txt ./
```

## Need Help?

Contact Orlando (orlando@aloware.com) for:
- Adding your SSH public key
- Instance access issues
- AWS credentials/permissions
- Session Manager troubleshooting

---

## Managing Your SSM Sessions

You can manage your own SSM sessions without admin help:

### List Your Active Sessions
```bash
aws ssm describe-sessions --state Active --region us-west-2 --filters "key=Owner,value=$(aws sts get-caller-identity --query Arn --output text)"
```

### Terminate a Specific Session
```bash
# Replace SESSION_ID with the actual session ID
aws ssm terminate-session --session-id SESSION_ID --region us-west-2
```

### Terminate ALL Your Sessions
```bash
for session_id in $(aws ssm describe-sessions --state Active --region us-west-2 --filters "key=Owner,value=$(aws sts get-caller-identity --query Arn --output text)" --query 'Sessions[].SessionId' --output text); do
  aws ssm terminate-session --session-id "$session_id" --region us-west-2
done
```

**Note:** You can only terminate your own sessions. These commands are useful if Cursor/VS Code loses connection and you need to clean up stale sessions.

---

## Instance Hard Reset (Admin Only)

If the instance becomes unresponsive and SSM shows "TargetNotConnected", admins can perform a hard stop/start:

### Check Instance Status
```bash
# Check if instance is impaired
aws ec2 describe-instance-status --instance-ids i-0bb73c9206a8dbf62 --region us-west-2 \
  --query 'InstanceStatuses[0].[InstanceStatus.Status,SystemStatus.Status]' --output table

# Check SSM connectivity
aws ssm describe-instance-information --filters "Key=InstanceIds,Values=i-0bb73c9206a8dbf62" \
  --region us-west-2 --query 'InstanceInformationList[0].[InstanceId,PingStatus,LastPingDateTime]' --output table
```

### Hard Stop and Start (Fixes Frozen Instances)
```bash
# Stop the instance (wait for full stop)
aws ec2 stop-instances --instance-ids i-0bb73c9206a8dbf62 --region us-west-2
aws ec2 wait instance-stopped --instance-ids i-0bb73c9206a8dbf62 --region us-west-2

# Start the instance
aws ec2 start-instances --instance-ids i-0bb73c9206a8dbf62 --region us-west-2
aws ec2 wait instance-running --instance-ids i-0bb73c9206a8dbf62 --region us-west-2

# Wait for SSM agent (30 seconds)
sleep 30
aws ssm describe-instance-information --filters "Key=InstanceIds,Values=i-0bb73c9206a8dbf62" \
  --region us-west-2 --query 'InstanceInformationList[0].PingStatus' --output text
```

### Quick Reboot (Softer Reset)
```bash
# Reboot without full stop/start cycle
aws ec2 reboot-instances --instance-ids i-0bb73c9206a8dbf62 --region us-west-2
```

**⚠️ Permissions Required:**
- Developers group: **Read-only access** (cannot stop/start/reboot)
- Contact Orlando for instance resets or to request elevated permissions

**When to Use:**
- SSM shows "TargetNotConnected" error
- Instance status shows "impaired" 
- Cursor/VS Code connection fails with "i-0bb73c9206a8dbf62 is not connected"
- Instance unresponsive for >5 minutes

**Downtime:** ~2-3 minutes for full stop/start cycle, ~1 minute for reboot.

---

**Last Updated:** December 12, 2025
