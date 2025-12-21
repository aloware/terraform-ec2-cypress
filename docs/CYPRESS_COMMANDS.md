# Minimal Cypress Commands for Ubuntu

## 🚀 Most Basic Commands (No Dependencies)

### 1. Super Minimal Test (Just curl - NO packages needed)
```bash
curl -s http://localhost | grep -q "nginx" && echo "✅ Test Passed" || echo "❌ Test Failed"
```

**What it does**: Tests if nginx is running without any installation  
**Requirements**: None (curl is pre-installed on Ubuntu)

---

## 📦 Cypress Commands

### 2. Global Cypress Installation
```bash
# Install globally (NOT recommended by Cypress)
npm install -g cypress

# Run tests
cypress run
```

### 3. Using npx (Recommended - No Global Install)
```bash
# Run Cypress without installing globally
npx cypress run --spec "cypress/e2e/*.cy.js"
```

### 4. Local Project Installation (Best Practice)
```bash
# Initialize project
npm init -y

# Install Cypress locally
npm install --save-dev cypress

# Run tests
npx cypress run
```

---

## 🎯 Complete Installation Script

### Download and Run the Script

**Option 1: Direct from GitHub**
```bash
curl -fsSL https://raw.githubusercontent.com/aloware/terraform-ec2-cypress/main/install-and-test.sh | bash
```

**Option 2: Download first, then run**
```bash
wget https://raw.githubusercontent.com/aloware/terraform-ec2-cypress/main/install-and-test.sh
chmod +x install-and-test.sh
./install-and-test.sh
```

**Option 3: Copy/Paste Script**
The script is located at: `/Users/orlando/_tmp/alwr/terraform-ec2-cypress/install-and-test.sh`

### What the Script Does:
1. ✅ Checks/installs Node.js 18.x
2. ✅ Installs Cypress system dependencies
3. ✅ Creates test project directory
4. ✅ Installs Cypress locally
5. ✅ Creates basic test files
6. ✅ Runs tests automatically

---

## 🔗 GitHub Repository Links

**Script URL**: https://github.com/aloware/terraform-ec2-cypress/blob/main/install-and-test.sh

**Raw Script URL**: https://raw.githubusercontent.com/aloware/terraform-ec2-cypress/main/install-and-test.sh

**Repository**: https://github.com/aloware/terraform-ec2-cypress

---

## 📋 Quick Reference

| Method | Pros | Cons | Command |
|--------|------|------|---------|
| curl only | No install needed | Limited testing | `curl -s http://localhost \| grep nginx` |
| npx | No global install | Requires npm | `npx cypress run` |
| Global | Available everywhere | Not recommended | `npm i -g cypress && cypress run` |
| Local | Best practice | Need setup | `npm i -D cypress && npx cypress run` |
| Script | Fully automated | Takes 2-3 min | `curl -fsSL <url> \| bash` |

---

## 🧪 Test Execution on EC2

**Script uploaded to**: `/tmp/install-and-test.sh` on EC2 instance

**Test Results**: ✅ All methods validated and working

**Instance**: terraform-ec2-demo (34.208.187.138)
