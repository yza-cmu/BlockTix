# BlockTix Implementation Roadmap

## Phase 1: Environment Setup and Contract Foundation

### 1.1 Initialize Foundry Project

**Tasks:**
- Create BlockTix repository structure
- Initialize Foundry framework in contracts directory
- Install OpenZeppelin contracts library as dependency
- Set up proper gitignore for sensitive files
- Configure directory structure following Foundry conventions

**Deliverables:**
- Initialized Foundry project with lib/forge-std
- OpenZeppelin contracts installed in lib/
- Proper folder hierarchy (src/, test/, script/, lib/)
- .env.example file with required variables template

**Validation:**
- Foundry installation verified with forge --version
- OpenZeppelin imports resolve correctly
- Project compiles without errors

### 1.2 Configure Foundry Environment

**Tasks:**
- Create foundry.toml configuration file
- Set compiler version to Solidity 0.8.24
- Configure optimizer with 200 runs
- Enable gas reporting for all contracts
- Add Sepolia RPC endpoint configuration
- Configure Etherscan API for verification

**Deliverables:**
- foundry.toml with complete configuration
- Environment variables structure documented
- Remappings configured for clean imports

**Validation:**
- Configuration allows successful compilation
- Gas reports generate on test execution
- Sepolia endpoint connects successfully

### 1.3 Create Contract Structure

**Tasks:**
- Design BlockTixMain contract architecture for event and ticket management
- Design TicketNFT contract for ERC-721 token representation
- Design PriceOracle contract for pricing logic
- Define state variables and data structures
- Plan event emissions for all state changes
- Document contract interactions and dependencies

**Deliverables:**
- BlockTixMain.sol with complete implementation
- TicketNFT.sol with ERC-721 compliance
- PriceOracle.sol with pricing mechanisms
- Documented contract architecture

**Validation:**
- All contracts compile without warnings
- No high/critical issues in initial analysis
- Contracts follow Solidity best practices

### 1.4 Implement Contract Interfaces

**Tasks:**
- Extract public functions to interface definitions
- Create IBlockTix.sol interface
- Create ITicketNFT.sol interface
- Document function purposes and parameters
- Ensure interfaces match implementation signatures

**Deliverables:**
- interfaces/IBlockTix.sol
- interfaces/ITicketNFT.sol
- Complete NatSpec documentation

**Validation:**
- Interfaces compile independently
- Implementations correctly inherit interfaces
- All external functions exposed in interfaces

## Phase 2: Smart Contract Implementation

### 2.1 BlockTixMain Contract

**Tasks:**
- Implement event creation functionality with organizer verification
- Build batch ticket minting system with gas optimization
- Create primary sale mechanism with payment handling
- Develop transfer logic enforcing resale rules
- Implement configurable markup and royalty parameters
- Build withdrawal system with platform fee calculation
- Add event emission for all state changes
- Implement access control for admin functions

**Deliverables:**
- Fully functional BlockTixMain.sol
- Event struct with necessary fields
- Ticket struct with ownership and pricing data
- Mapping structures for efficient lookups
- Comprehensive event definitions

**Validation:**
- All functions execute without reverting on valid inputs
- Events emit correctly for each state change
- Access control prevents unauthorized actions
- Gas consumption within acceptable limits

### 2.2 TicketNFT Contract

**Tasks:**
- Extend OpenZeppelin ERC721URIStorage contract
- Implement safe minting with metadata URI storage
- Create burn functionality for expired tickets
- Build base URI management system
- Override transfer functions to integrate with BlockTixMain
- Implement token ID generation strategy
- Add batch operations for efficiency

**Deliverables:**
- ERC-721 compliant TicketNFT.sol
- Metadata structure definition
- Token URI management system
- Integration hooks for BlockTixMain

**Validation:**
- ERC-721 compliance test passes
- Metadata correctly associated with tokens
- Transfer restrictions properly enforced
- Burn function removes all token data

### 2.3 PriceOracle Contract

**Tasks:**
- Design dynamic pricing algorithm based on demand metrics
- Implement time-based pricing adjustments
- Create platform fee calculation logic
- Build resale price validation with markup limits
- Develop admin functions for parameter updates
- Add price history tracking mechanism
- Implement emergency pause functionality

**Deliverables:**
- Functional PriceOracle.sol
- Pricing algorithm implementation
- Fee structure configuration
- Admin control mechanisms
- Price adjustment events

**Validation:**
- Pricing calculations return expected values
- Fee calculations accurate to specification
- Markup limits properly enforced
- Admin functions restricted appropriately

## Phase 3: Comprehensive Testing Suite

### 3.1 Unit Tests Implementation

**Tasks:**
- Write unit tests for each BlockTixMain function
- Create tests for TicketNFT operations
- Develop PriceOracle calculation tests
- Test all revert conditions and error messages
- Verify event emissions with correct parameters
- Test access control on restricted functions
- Validate state transitions

**Deliverables:**
- test/unit/BlockTixMain.t.sol with 100% function coverage
- test/unit/TicketNFT.t.sol covering all NFT operations
- test/unit/PriceOracle.t.sol validating pricing logic
- Test helper contracts for common setup

**Validation:**
- All tests pass consistently
- Coverage report shows >95% line coverage
- Edge cases properly tested
- Gas usage recorded for each test

### 3.2 Generate Coverage Report

**Tasks:**
- Execute complete test suite with coverage tracking
- Generate LCOV format coverage data
- Create human-readable coverage summary
- Identify uncovered code paths
- Document any intentionally uncovered code
- Calculate coverage percentages per contract

**Deliverables:**
- metrics/coverage/coverage-summary.txt with percentages
- metrics/coverage/lcov.info with detailed line coverage
- Coverage report documentation
- Uncovered code justification

**Validation:**
- Minimum 95% line coverage achieved
- All critical paths covered
- Coverage data properly formatted
- Reports generated successfully

## Phase 4: Gas Optimization and Benchmarking

### 4.1 Initial Gas Snapshot

**Tasks:**
- Run gas snapshot for all contract functions
- Document gas costs per operation
- Identify high-cost functions
- Create baseline metrics file
- Analyze storage access patterns
- Review loop implementations

**Deliverables:**
- metrics/gas/gas-snapshot-initial.txt
- Function-by-function gas analysis
- Storage pattern documentation
- Optimization opportunities list

**Validation:**
- Snapshot captures all public functions
- Gas costs accurately measured
- Baseline established for comparison
- High-cost operations identified

### 4.2 Optimization Implementation

**Tasks:**
- Pack struct variables to minimize storage slots
- Implement unchecked arithmetic where overflow impossible
- Optimize storage layout for minimal SSTORE operations
- Convert multiple operations to batch functions
- Use events instead of storage where applicable
- Implement efficient data structures
- Cache frequently accessed storage variables

**Deliverables:**
- Optimized contract versions
- Optimization documentation per change
- Safety analysis for unchecked operations
- Storage layout diagram

**Validation:**
- All optimizations maintain correctness
- Tests still pass after changes
- No security vulnerabilities introduced
- Measurable gas reduction achieved

### 4.3 Final Gas Snapshot

**Tasks:**
- Generate new gas snapshot after optimizations
- Calculate percentage improvements per function
- Create differential analysis against baseline
- Document trade-offs made
- Verify optimization effectiveness
- Generate comparison report

**Deliverables:**
- metrics/gas/gas-snapshot.txt (final version)
- Gas differential report
- Percentage improvement calculations
- Trade-off analysis document

**Validation:**
- Minimum 20% gas reduction on key operations
- All functions still operate correctly
- Improvements documented accurately
- Snapshot format matches requirements

### 4.4 Document Optimizations

**Tasks:**
- Create detailed optimization report
- Document each optimization technique used
- Provide before/after gas comparisons
- Explain safety considerations
- Detail any functionality trade-offs
- Include recommendations for future optimizations

**Deliverables:**
- metrics/gas/gas-optimization.md
- Before/after comparison table
- Safety analysis per optimization
- Future optimization recommendations

**Validation:**
- All optimizations documented
- Comparisons accurate and complete
- Trade-offs clearly explained
- Document follows standard format

## Phase 5: Deployment Infrastructure

### 5.1 Create Deployment Script

**Tasks:**
- Write deployment script in Solidity
- Implement correct deployment order
- Configure initial contract parameters
- Set up ownership and permissions
- Add deployment verification logic
- Include deployment configuration options

**Deliverables:**
- script/Deploy.s.sol
- Deployment configuration file
- Environment setup documentation
- Deployment order specification

**Validation:**
- Script compiles without errors
- Deployment order respects dependencies
- All contracts initialized correctly
- Ownership properly transferred

### 5.2 Deploy to Local Anvil

**Tasks:**
- Start Anvil with Sepolia fork
- Execute deployment script locally
- Verify contract interactions work
- Test initial configuration
- Validate deployment addresses
- Confirm transaction success

**Deliverables:**
- Local deployment addresses
- Deployment transaction logs
- Configuration verification results
- Local testing documentation

**Validation:**
- All contracts deploy successfully
- Contracts communicate properly
- Initial state correctly set
- No deployment errors

### 5.3 Deploy to Sepolia

**Tasks:**
- Configure Sepolia RPC endpoint
- Fund deployment wallet with Sepolia ETH
- Execute deployment script on Sepolia
- Monitor deployment transactions
- Verify contracts on Etherscan
- Document deployment addresses

**Deliverables:**
- Sepolia deployment addresses
- Etherscan verification links
- Deployment transaction hashes
- Gas costs for deployment

**Validation:**
- All contracts deployed to Sepolia
- Etherscan verification successful
- Contracts accessible via Etherscan
- Source code visible and verified

### 5.4 Generate Deployment Metadata

**Tasks:**
- Collect all deployment information
- Create standardized JSON structure
- Include contract addresses and transaction hashes
- Add block numbers and timestamps
- Document compiler version and settings
- Include Etherscan verification links

**Deliverables:**
- metrics/deploy.json with complete metadata
- Deployment cost analysis
- Network configuration used
- Compiler settings documentation

**Validation:**
- JSON follows specified format exactly
- All addresses are valid Sepolia addresses
- Transaction hashes verifiable on Etherscan
- Metadata complete and accurate

## Phase 6: CLI/Etherscan Interface Runbook

**Tasks:**
- Create comprehensive documentation for interacting with contracts via Etherscan
- Write Foundry `cast` CLI commands for all key operations
- Document step-by-step process for creating events
- Document step-by-step process for purchasing tickets
- Document step-by-step process for transferring tickets
- Show how to check transaction status (pending/confirmed/failed)
- Include Etherscan transaction links for monitoring
- Add troubleshooting section for common errors
- Document empty states (no events, no tickets)

**Deliverables:**
- RUN.md or INTERFACE.md with complete interface runbook
- CLI command examples using Foundry `cast` for all operations
- Etherscan interaction guide with screenshots or detailed steps
- Transaction state checking instructions
- Error handling and troubleshooting guide

**Example CLI Commands:**
```bash
# Create Event
cast send $BLOCKTIX_ADDRESS "createEvent(string,uint256,uint256,uint256,uint256)" \
  "Concert Name" 100 1000000000000000000 1735689600 500 \
  --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY

# Purchase Ticket
cast send $BLOCKTIX_ADDRESS "purchaseTicket(uint256)" 1 \
  --value 1.05ether --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY

# Check Transaction Status
cast receipt $TX_HASH --rpc-url $SEPOLIA_RPC_URL

# View Event Details
cast call $BLOCKTIX_ADDRESS "getEvent(uint256)" 1 --rpc-url $SEPOLIA_RPC_URL
```

**Validation:**
- Someone can create event using Etherscan OR CLI
- Someone can purchase ticket using Etherscan OR CLI
- Transaction status check works
- Etherscan links provided and functional
- Clear instructions for all core operations
- Error states documented
- Empty states documented

## Phase 7: Transaction Performance Measurement

### 7.1 Execute Primary Operations

**Tasks:**
- Perform three complete event creation transactions
- Execute three ticket purchase transactions
- Complete three ticket transfer operations
- Ensure variety in transaction parameters
- Use different accounts for diversity
- Document transaction contexts

**Deliverables:**
- Nine total transactions on Sepolia
- Transaction hashes for all operations
- Screenshots of successful transactions
- Account addresses used

**Validation:**
- All transactions confirmed on Sepolia
- Variety in gas usage captured
- Different execution paths tested
- No failed transactions in dataset

### 7.2 Collect Latency Data

**Tasks:**
- Capture transaction hash for each operation
- Record block numbers for confirmations
- Measure latency from submission to confirmation
- Log gas used per transaction
- Record effective gas price
- Calculate calldata size in bytes
- Verify transaction status

**Deliverables:**
- Raw transaction data from txLogger
- Formatted measurement results
- Gas price analysis
- Network conditions documentation

**Validation:**
- All required fields captured
- Measurements in correct units
- No missing data points
- Accurate timestamp recording

### 7.3 Generate Latency Report

**Tasks:**
- Compile all nine transaction measurements
- Format data into CSV structure
- Verify all required columns present
- Calculate average metrics per operation type
- Document any anomalies
- Create performance analysis summary

**Deliverables:**
- metrics/latency/latency.csv with all data
- Performance analysis document
- Network condition notes
- Statistical summary of measurements

**Validation:**
- CSV format matches specification exactly
- All nine transactions included
- No placeholder or test data
- Headers match required format

## Phase 8: Security Analysis

### 8.1 Install Security Tools

**Tasks:**
- Install Slither static analyzer via pip
- Configure Slither for Solidity 0.8.24
- Install additional security tools if needed
- Set up analysis environment
- Configure output formats
- Prepare contracts for analysis

**Deliverables:**
- Installed Slither tool
- Configuration files
- Analysis environment ready
- Tool version documentation

**Validation:**
- Slither runs without errors
- Correct Solidity version detected
- Output formats configured
- Analysis environment functional

### 8.2 Run Security Analysis

**Tasks:**
- Execute Slither on all contracts
- Generate human-readable summary
- Create function-level analysis
- Identify all security findings
- Categorize by severity levels
- Document false positives

**Deliverables:**
- metrics/security/slither-summary.txt
- Detailed findings report
- Severity categorization
- False positive documentation

**Validation:**
- Analysis completes successfully
- All contracts analyzed
- Output properly formatted
- Findings accurately categorized

### 8.3 Address Critical Findings

**Tasks:**
- Review all high severity findings
- Implement fixes for critical issues
- Address medium severity problems
- Document mitigation strategies
- Re-run analysis after fixes
- Justify any accepted risks

**Deliverables:**
- Updated contract code with fixes
- metrics/security/audit-report.md
- Mitigation documentation
- Risk acceptance justification

**Validation:**
- High severity issues resolved
- Medium issues addressed or justified
- Re-analysis shows improvements
- No new issues introduced

### 8.4 Implement Security Patterns

**Tasks:**
- Add ReentrancyGuard to state-changing functions
- Implement Checks-Effects-Interactions pattern
- Add comprehensive access controls
- Validate all external inputs
- Implement pause mechanism
- Add rate limiting where appropriate

**Deliverables:**
- Security-enhanced contracts
- Pattern implementation documentation
- Access control matrix
- Input validation logic

**Validation:**
- All patterns correctly implemented
- No functionality broken
- Tests still pass
- Gas impact documented

## Phase 9: Usability Testing Infrastructure

### 9.1 Create Test Protocol

**Tasks:**
- Define specific user tasks to test
- Create success criteria for each task
- Design data collection methodology
- Prepare test environment setup
- Create participant instructions
- Design feedback questionnaire

**Deliverables:**
- usability/test-plans/test-protocol.md
- Task list document
- Success criteria definitions
- Data collection templates
- Participant instructions

**Validation:**
- Protocol covers all key features
- Tasks clearly defined
- Success criteria measurable
- Instructions unambiguous

### 9.2 Implement Test Scenarios

**Tasks:**
- Deploy multiple test events on Sepolia
- Configure various ticket prices
- Set different resale rules
- Create multiple ticket types
- Fund test wallets
- Prepare test data

**Deliverables:**
- Test event configurations
- Test wallet addresses
- Funded test accounts
- Scenario documentation

**Validation:**
- All test events accessible
- Various configurations tested
- Test wallets properly funded
- Scenarios cover edge cases

### 9.3 Conduct Testing Sessions

**Tasks:**
- Recruit minimum three test participants
- Conduct individual testing sessions
- Record screen during sessions
- Measure time for each task
- Document errors encountered
- Collect System Usability Scale ratings
- Gather qualitative feedback

**Deliverables:**
- Session recordings for each tester
- Time measurements per task
- Error documentation
- SEQ ratings (1-7 scale)
- Participant feedback notes

**Validation:**
- Minimum three complete sessions
- All tasks attempted by each user
- Complete data for each participant
- Recordings capture full sessions

### 9.4 Compile Results

**Tasks:**
- Aggregate all testing data
- Calculate success rates per task
- Compute average time on task
- Compile SEQ ratings
- Summarize qualitative feedback
- Format data into required CSV structure

**Deliverables:**
- usability/results/usability.csv
- Statistical analysis of results
- Qualitative feedback summary
- Recommendations for improvements

**Validation:**
- CSV format matches specification
- All participant data included
- Calculations accurate
- No missing data points

## Phase 10: Final Metrics Compilation

### 10.1 Generate Complete Metrics Pack

**Tasks:**
- Collect gas-snapshot.txt from Phase 4
- Retrieve coverage-summary.txt from Phase 3
- Compile latency.csv from Phase 7
- Include deploy.json from Phase 5
- Add slither-summary.txt from Phase 8
- Create ZIP archive with all files

**Deliverables:**
- 67404-BlockTix-metrics.zip
- All individual metric files
- Metrics validation checklist
- Archive structure documentation

**Validation:**
- All five files present in archive
- Files contain production data only
- No test or placeholder data
- Archive properly structured

### 10.2 Verify Data Completeness

**Tasks:**
- Verify all transaction hashes are real Sepolia transactions
- Confirm addresses match deployed contracts
- Validate gas measurements from actual execution
- Check CSV formats match specifications
- Ensure JSON structure correct
- Verify no sample data present

**Deliverables:**
- Data validation report
- Etherscan verification links
- Completeness checklist
- Quality assurance documentation

**Validation:**
- All data verifiable on Etherscan
- Formats match specifications exactly
- No missing required fields
- All data from production deployments

## Phase 11: Developer Documentation & Runbook

**Tasks:**
- Create comprehensive RUN.md at repository root
- Document setup instructions (clone → install → configure)
- Document how to run tests: `forge test`
- Document how to generate coverage: `forge coverage`
- Document how to deploy to Sepolia (commands + prerequisites)
- Document environment variables needed (.env setup)
- Add troubleshooting section for common issues
- Fill in shell script files:
  - scripts/deploy-sepolia.sh (deployment commands)
  - scripts/generate-metrics.sh (metrics generation)
  - scripts/test-all.sh (test execution)
  - scripts/measure-gas.sh (gas snapshot)

**Deliverables:**
- RUN.md at repository root with complete instructions
- Filled-in shell scripts (currently empty 0-byte files)
- Troubleshooting guide

**Validation:**
- Someone can clone and run from RUN.md instructions
- All commands work as documented
- Shell scripts are executable and functional
- Setup can be completed in <10 minutes

## Phase 12: Repository Finalization

### 12.1 Tag Release Versions

**Tasks:**
- Create sprint1 tag at Sprint 1 completion
- Create sprint2 tag at Sprint 2 completion
- Create sprint3 tag at Sprint 3 completion
- Create sprint4 tag at Sprint 4 completion
- Create final tag for submission
- Push all tags to remote repository

**Deliverables:**
- Git tags for all milestones
- Tagged releases on GitHub
- Release notes per tag
- Version documentation

**Validation:**
- All tags present in repository
- Tags point to correct commits
- Releases accessible on GitHub
- Chronological order maintained

### 12.2 Ensure Repository Access

**Tasks:**
- Add aazamcs as repository collaborator
- Grant read access permissions
- Verify repository visibility settings
- Test access with instructor account
- Document access configuration
- Provide repository URL

**Deliverables:**
- Collaborator invitation sent
- Access permissions configured
- Repository URL documented
- Access verification completed

**Validation:**
- Instructor account has access
- Repository publicly accessible or properly shared
- All branches visible
- History preserved

### 12.3 Create Final Submission Package

**Tasks:**
- Export complete source code
- Include all metrics files
- Package all documentation
- Include deployment scripts
- Add test suites
- Create comprehensive ZIP archive

**Deliverables:**
- 67404-FALL25-BlockTix-FINAL.zip
- Complete source tree
- All metrics and documentation
- README with setup instructions
- Submission checklist

**Validation:**
- Archive extracts correctly
- All files present
- No broken references
- Setup instructions work