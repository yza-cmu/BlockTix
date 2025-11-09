#!/bin/bash

# BlockTix Test Runner
# Runs all unit tests with verbose output

set -e

echo "Running BlockTix test suite..."
cd contracts
forge test -vv

echo ""
echo "Test run complete!"
