#!/bin/bash
#
# Quick Cypress Test Runner - Clone and Execute
# This script clones the repo and runs the test automatically
#
# Usage: 
#   export GH_TOKEN="your-token-here"
#   bash quick-test.sh
# Or:
#   GH_TOKEN="your-token" bash quick-test.sh
#

set -e

echo "================================================"
echo "  🚀 Quick Cypress Test from GitHub"
echo "================================================"
echo ""

# Clone the repository
echo "Step 1: Cloning repository..."
cd /tmp
rm -rf terraform-ec2-cypress

# Clone using token if provided, otherwise try public clone
if [ -n "$GH_TOKEN" ]; then
    git clone https://aloware:$\{GH_TOKEN\}@github.com/aloware/terraform-ec2-cypress.git
elif [ -n "$GITHUB_TOKEN" ]; then
    git clone https://aloware:$\{GITHUB_TOKEN\}@github.com/aloware/terraform-ec2-cypress.git
else
    git clone https://github.com/aloware/terraform-ec2-cypress.git
fi

echo "✓ Repository cloned"
echo ""

# Run the installation script
echo "Step 2: Running Cypress installation and test..."
cd terraform-ec2-cypress
bash install-and-test.sh

echo ""
echo "================================================"
echo "  ✅ COMPLETE! Test executed successfully"
echo "================================================"
