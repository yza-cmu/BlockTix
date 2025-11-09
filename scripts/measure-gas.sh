#!/bin/bash

# BlockTix Gas Measurement
# Generates gas snapshot for all contract functions

set -e

echo "Generating gas snapshot..."
cd contracts
forge snapshot

# Copy to metrics directory
mkdir -p ../metrics/gas
cp .gas-snapshot ../metrics/gas/gas-snapshot.txt

echo ""
echo "Gas snapshot generated!"
echo "Results saved to:"
echo "  - contracts/.gas-snapshot"
echo "  - metrics/gas/gas-snapshot.txt"
