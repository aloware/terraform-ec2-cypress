#!/bin/bash
#
# Minimal Cypress Installation and Test Script for Ubuntu
# No dependencies required - this script installs everything
#
# Usage: curl -fsSL <script-url> | bash
# Or: wget -O - <script-url> | bash
# Or: bash install-and-test.sh
#

set -e

echo "================================================"
echo "  Cypress E2E Test Installation & Execution"
echo "================================================"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
   echo "⚠️  Please don't run as root/sudo"
   exit 1
fi

# Install Node.js if not present
echo "Step 1: Checking Node.js..."
if ! command -v node &> /dev/null; then
    echo "Installing Node.js 18.x..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    echo "✓ Node.js installed: $(node --version)"
else
    echo "✓ Node.js already installed: $(node --version)"
fi

# Install system dependencies for Cypress
echo ""
echo "Step 2: Installing Cypress dependencies..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev \
    libnss3 libxss1 libasound2 libxtst6 xauth xvfb \
    > /dev/null 2>&1
echo "✓ System dependencies installed"

# Create test directory
echo ""
echo "Step 3: Setting up test project..."
TEST_DIR="$HOME/cypress-test"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Initialize npm project
npm init -y > /dev/null 2>&1

# Install Cypress locally (fastest method)
echo ""
echo "Step 4: Installing Cypress (this may take 1-2 minutes)..."
npm install --save-dev cypress@13.6.0 > /dev/null 2>&1
echo "✓ Cypress installed"

# Create test file
echo ""
echo "Step 5: Creating test spec..."
mkdir -p cypress/e2e
cat > cypress/e2e/basic-test.cy.js << 'EOF'
describe('Basic Web Test', () => {
  it('should load the local web page', () => {
    cy.visit('http://localhost');
  });
  
  it('should find expected content', () => {
    cy.visit('http://localhost');
    cy.contains('nginx').should('exist');
  });
});
EOF

# Create Cypress config
cat > cypress.config.js << 'EOF'
const { defineConfig } = require('cypress');

module.exports = defineConfig({
  e2e: {
    baseUrl: 'http://localhost',
    video: false,
    screenshotOnRunFailure: false,
    supportFile: false,
  },
});
EOF

echo "✓ Test files created"

# Run Cypress tests
echo ""
echo "Step 6: Running Cypress tests..."
echo "================================================"
npx cypress run --headless --spec "cypress/e2e/basic-test.cy.js" 2>&1 | \
  grep -v "DevTools\|ERROR:object_proxy\|freedesktop\|tput"

echo "================================================"
echo ""
echo "✅ Installation and test execution complete!"
echo ""
echo "Test directory: $TEST_DIR"
echo "To run tests again: cd $TEST_DIR && npx cypress run"
