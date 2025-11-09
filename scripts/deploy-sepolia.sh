#!/bin/bash

# BlockTix Sepolia Deployment Script
# This script deploys all BlockTix contracts to Sepolia testnet with Etherscan verification

set -e  # Exit on error

echo "=========================================="
echo "BlockTix Sepolia Deployment"
echo "=========================================="
echo ""

# Navigate to contracts directory
cd "$(dirname "$0")/../contracts" || exit 1

# Load environment variables
if [ ! -f .env ]; then
    echo "Error: .env file not found!"
    echo "Please create .env file with:"
    echo "  SEPOLIA_RPC_URL=<your_rpc_url>"
    echo "  PRIVATE_KEY=<your_private_key>"
    echo "  ETHERSCAN_API_KEY=<your_etherscan_api_key>"
    exit 1
fi

source .env

# Check required environment variables
if [ -z "$SEPOLIA_RPC_URL" ]; then
    echo "Error: SEPOLIA_RPC_URL not set in .env"
    exit 1
fi

if [ -z "$PRIVATE_KEY" ]; then
    echo "Error: PRIVATE_KEY not set in .env"
    exit 1
fi

if [ -z "$ETHERSCAN_API_KEY" ]; then
    echo "Error: ETHERSCAN_API_KEY not set in .env"
    exit 1
fi

# Get deployer address
DEPLOYER=$(cast wallet address --private-key $PRIVATE_KEY)
echo "Deployer Address: $DEPLOYER"

# Check balance
BALANCE=$(cast balance $DEPLOYER --rpc-url $SEPOLIA_RPC_URL --ether)
echo "Sepolia ETH Balance: $BALANCE ETH"
echo ""

# Check if balance is sufficient (need at least 0.005 ETH)
if (( $(echo "$BALANCE < 0.005" | bc -l) )); then
    echo "Warning: Balance may be insufficient for deployment"
    echo "Recommended minimum: 0.005 ETH"
    read -p "Continue anyway? (y/N): " confirm
    if [[ $confirm != [yY] ]]; then
        echo "Deployment cancelled"
        exit 0
    fi
fi

echo "Starting deployment..."
echo ""

# Run deployment script with verification
forge script script/Deploy.s.sol:Deploy \
    --rpc-url $SEPOLIA_RPC_URL \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    -vvvv

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Deployment details saved to:"
echo "  broadcast/Deploy.s.sol/11155111/run-latest.json"
echo ""
echo "View contracts on Sepolia Etherscan"
