#!/bin/bash
#
# setup-swap.sh - Create and configure a 16GB swap file on Linux
# 
# This script is idempotent and safe to re-run.
# It will skip steps if swap is already configured.
#

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration
SWAP_FILE="/swapfile"
SWAP_SIZE_GB=16
SWAP_SIZE_MB=$((SWAP_SIZE_GB * 1024))

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root (use sudo)"
   exit 1
fi

log_info "Starting swap file setup (${SWAP_SIZE_GB}GB)..."
echo

# Step 1: Check if swap file already exists
if [[ -f "$SWAP_FILE" ]]; then
    log_warn "Swap file $SWAP_FILE already exists"
    
    # Check if it's already enabled
    if swapon --show | grep -q "$SWAP_FILE"; then
        log_info "Swap file is already enabled"
        SWAP_EXISTS=true
    else
        log_warn "Swap file exists but is not enabled. Will enable it."
        SWAP_EXISTS=false
    fi
else
    SWAP_EXISTS=false
    
    # Step 2: Create swap file
    log_info "Creating ${SWAP_SIZE_GB}GB swap file at $SWAP_FILE..."
    
    # Try fallocate first (faster)
    if fallocate -l ${SWAP_SIZE_MB}M "$SWAP_FILE" 2>/dev/null; then
        log_info "Swap file created using fallocate"
    else
        log_warn "fallocate failed or not supported, falling back to dd (this may take a few minutes)..."
        if dd if=/dev/zero of="$SWAP_FILE" bs=1M count=$SWAP_SIZE_MB status=progress; then
            log_info "Swap file created using dd"
        else
            log_error "Failed to create swap file"
            exit 1
        fi
    fi
fi

# Step 3: Set correct permissions
log_info "Setting permissions to 600 on $SWAP_FILE..."
chmod 600 "$SWAP_FILE"

# Step 4: Format as swap (only if not already swap)
if ! file "$SWAP_FILE" | grep -q "swap file"; then
    log_info "Formatting $SWAP_FILE as swap space..."
    mkswap "$SWAP_FILE"
else
    log_info "Swap file is already formatted"
fi

# Step 5: Enable swap
if ! swapon --show | grep -q "$SWAP_FILE"; then
    log_info "Enabling swap file..."
    swapon "$SWAP_FILE"
else
    log_info "Swap file is already enabled"
fi

# Step 6: Add to /etc/fstab for persistence
if ! grep -q "$SWAP_FILE" /etc/fstab; then
    log_info "Adding swap entry to /etc/fstab for persistence..."
    echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
else
    log_info "Swap entry already exists in /etc/fstab"
fi

# Step 7: Configure kernel parameters
log_info "Configuring kernel swap parameters..."

# Set vm.swappiness=10 (use swap only when necessary)
if grep -q "^vm.swappiness" /etc/sysctl.conf; then
    sed -i 's/^vm.swappiness.*/vm.swappiness=10/' /etc/sysctl.conf
    log_info "Updated vm.swappiness in /etc/sysctl.conf"
else
    echo "vm.swappiness=10" >> /etc/sysctl.conf
    log_info "Added vm.swappiness=10 to /etc/sysctl.conf"
fi

# Set vm.vfs_cache_pressure=50 (reduce tendency to reclaim inode/dentry cache)
if grep -q "^vm.vfs_cache_pressure" /etc/sysctl.conf; then
    sed -i 's/^vm.vfs_cache_pressure.*/vm.vfs_cache_pressure=50/' /etc/sysctl.conf
    log_info "Updated vm.vfs_cache_pressure in /etc/sysctl.conf"
else
    echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
    log_info "Added vm.vfs_cache_pressure=50 to /etc/sysctl.conf"
fi

# Apply kernel parameters immediately
sysctl -p > /dev/null
log_info "Kernel parameters applied"

echo
log_info "=========================================="
log_info "Swap Configuration Complete"
log_info "=========================================="
echo

# Verification output
log_info "Current swap status:"
swapon --show
echo

log_info "Memory and swap usage:"
free -h
echo

log_info "Kernel swap parameters:"
echo "  vm.swappiness = $(sysctl -n vm.swappiness)"
echo "  vm.vfs_cache_pressure = $(sysctl -n vm.vfs_cache_pressure)"
echo

echo -e "${GREEN}✅ Swap file successfully created and enabled (${SWAP_SIZE_GB}GB)${NC}"
exit 0
