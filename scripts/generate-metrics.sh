#!/bin/bash

# BlockTix Metrics Generator
# Generates all metrics files for Sprint 3 submission

set -e

echo "=== BlockTix Metrics Generation ==="
echo ""

# Navigate to contracts directory
cd contracts

# 1. Generate gas snapshot
echo "[1/3] Generating gas snapshot..."
forge snapshot
mkdir -p ../metrics/gas
cp .gas-snapshot ../metrics/gas/gas-snapshot.txt
echo " Gas snapshot saved to metrics/gas/gas-snapshot.txt"
echo ""

# 2. Generate coverage report
echo "[2/3] Generating coverage report..."
forge coverage --report summary > ../metrics/coverage/coverage-summary.txt
forge coverage --report lcov
lcov_file=$(find . -name "lcov.info" 2>/dev/null | head -1)
if [ -n "$lcov_file" ]; then
    cp "$lcov_file" ../metrics/coverage/lcov.info
fi
echo " Coverage reports saved to metrics/coverage/"
echo ""

# 3. Verify all metrics exist
echo "[3/3] Verifying metrics files..."
cd ..
required_files=(
    "metrics/gas/gas-snapshot.txt"
    "metrics/coverage/coverage-summary.txt"
    "metrics/coverage/lcov.info"
    "metrics/latency/latency.csv"
    "metrics/deploy.json"
)

all_exist=true
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo " $file"
    else
        echo " $file (missing)"
        all_exist=false
    fi
done

echo ""
if [ "$all_exist" = true ]; then
    echo "=== All metrics generated successfully! ==="
else
    echo "=== Warning: Some metrics files are missing ==="
    echo "Run the following to generate missing files:"
    echo "  - latency.csv: Execute transactions on Sepolia (see RUN.md)"
    echo "  - deploy.json: Deploy contracts (see scripts/deploy-sepolia.sh)"
fi
