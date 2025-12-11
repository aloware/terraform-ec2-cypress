# VS Code Remote Development via AWS Session Manager

This guide walks you through connecting VS Code to the EC2 instance using AWS Session Manager (SSM) for secure remote development without exposing SSH ports.

## Prerequisites

- AWS CLI configured with your credentials
- VS Code installed
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

## Step 2: Install VS Code Remote - SSH Extension

1. Open VS Code
2. Press `Cmd+Shift+X` (or go to Extensions)
3. Search for **"Remote - SSH"**
4. Install the extension published by **Microsoft**

## Step 3: Configure SSH for SSM Tunneling

Add the following configuration to your `~/.ssh/config` file:

```bash
# AWS SSM Session Manager - terraform-ec2-demo
Host terraform-ec2-demo
    HostName i-089ab2bb0bafcf70f
    User ubuntu
    ProxyCommand sh -c "aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p' --region us-west-2"
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

**To add this configuration:**

### Option A: Manual Edit
```bash
# Open the SSH config file in your editor
nano ~/.ssh/config

# Paste the configuration above
# Save and exit (Ctrl+O, Enter, Ctrl+X for nano)
```

### Option B: Append via Command
```bash
cat >> ~/.ssh/config << 'EOF'

# AWS SSM Session Manager - terraform-ec2-demo
Host terraform-ec2-demo
    HostName i-089ab2bb0bafcf70f
    User ubuntu
    ProxyCommand sh -c "aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p' --region us-west-2"
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF
```

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
Instance: i-089ab2bb0bafcf70f (terraform-ec2-demo)

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

## Step 8: Connect VS Code to the Instance

### Option A: Via Command Palette
1. Press `Cmd+Shift+P` (macOS) or `Ctrl+Shift+P` (Windows/Linux)
2. Type: **"Remote-SSH: Connect to Host"**
3. Select `terraform-ec2-demo` from the list
4. A new VS Code window will open connected to the instance

### Option B: Via Command Line
```bash
code --remote ssh-remote+terraform-ec2-demo /home/ubuntu
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

You now have full VS Code functionality on the remote instance!

## Features Available

- ✅ Edit files directly on the instance
- ✅ Integrated terminal (bash on the instance)
- ✅ Git integration
- ✅ Extensions run on the remote instance
- ✅ Port forwarding for web apps
- ✅ IntelliSense and debugging

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
- Verify instance ID is correct: `i-089ab2bb0bafcf70f`

### VS Code: "Could not establish connection to terraform-ec2-demo"
- Test SSH manually first: `ssh terraform-ec2-demo`
- Check SSH config syntax in `~/.ssh/config`
- Restart VS Code after modifying SSH config

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
| Instance ID | `i-089ab2bb0bafcf70f` |
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

# Open VS Code remotely
code --remote ssh-remote+terraform-ec2-demo /home/ubuntu

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

**Last Updated:** December 10, 2025
