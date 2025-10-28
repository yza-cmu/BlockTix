# BlockTix : Sprint Progress & Backlog

**Project:** BlockTix : Decentralized Event Ticketing Platform
**Course:** 67-404 Blockchain Applications : Group 4
**Last Updated:** 2025-10-28

---

## Sprint Overview

| Sprint | Status | Timeline | Deliverables |
|--------|--------|----------|--------------|
| Sprint 1 |  Completed | Week 1-2 | Concept, WhyChain Canvas, Literature Scan, Team Charter |
| **Sprint 2** |  **COMPLETED** | Week 3-6 | Architecture, Smart Contracts, Tests, Local Deployment |
| **Sprint 3** | 🔄 **IN PROGRESS** | Week 7-10 | Sepolia Deployment, Frontend, Metrics, Gas Optimization |
| **Sprint 4** | 📋 **PLANNED** | Week 11-14 | Security Audit, Usability Testing, CI/CD, Final Metrics |

---

##  Sprint 2: Core Development (COMPLETED)

**Objective:** Build production-ready smart contracts with comprehensive testing and local deployment infrastructure.

### Completed Features

#### 1. Environment Setup & Contract Foundation (Phase 1)
-  **1.1** Foundry project initialized with OpenZeppelin contracts
-  **1.2** Foundry configuration (Solidity 0.8.24, optimizer, gas reporting)
-  **1.3** Smart contract architecture designed and implemented
-  **1.4** Contract interfaces with complete NatSpec documentation

**Deliverables:**
- `BlockTixMain.sol` : Event & ticket management (330 lines)
- `TicketNFT.sol` : ERC-721 NFT implementation (180 lines)
- `PriceOracle.sol` : Dynamic pricing system (280 lines)
- `IBlockTix.sol`, `ITicketNFT.sol`, `IPriceOracle.sol` interfaces

#### 2. Comprehensive Testing Suite (Phase 3.1)
-  **3.1** Unit tests for all three contracts
  : BlockTixMain: 31 tests covering all functions
  : TicketNFT: 32 tests with ERC-721 compliance
  : PriceOracle: 40 tests with pricing algorithms
  : **Total: 105/105 tests passing (100% success rate)**

**Deliverables:**
- `test/unit/BlockTixMain.t.sol` (650 lines)
- `test/unit/TicketNFT.t.sol` (550 lines)
- `test/unit/PriceOracle.t.sol` (650 lines)
- Full error condition coverage
- Complete event emission verification
- Access control testing

#### 3. Deployment Infrastructure (Phase 5.1 & 5.2)
-  **5.1** Deployment script with automated configuration
-  **5.2** Successful local Anvil deployment

**Deliverables:**
- `script/Deploy.s.sol` (150 lines)
- Local deployment to Anvil (Chain ID 31337)
- 3 contracts deployed and configured
- Gas metrics: ~4.1M gas, ~0.0037 ETH cost

### Sprint 2 Metrics

| Metric | Value |
|--------|-------|
| Smart Contracts | 3 |
| Interfaces | 3 |
| Test Files | 3 |
| Deployment Scripts | 1 |
| Total Tests | 105 |
| Test Pass Rate | 100% |
| Lines of Contract Code | ~1,160 |
| Lines of Test Code | ~1,850 |
| Test Coverage | Ready for measurement |
| Compilation Status |  SUCCESS |
| Deployment Status |  SUCCESS (Local) |

### Sprint 2 Achievements

**Smart Contract Features:**
-  Event creation with organizer verification
-  Ticket purchasing with dynamic pricing
-  Ticket resale with markup limits
-  Platform fee distribution system
-  Withdrawal mechanism (pull payment pattern)
-  ERC-721 compliant NFT tickets
-  Batch minting for efficiency
-  Surge pricing (50%, 75%, 90% thresholds)
-  Time-based price decay
-  Resale price validation
-  Reentrancy protection
-  Access control (Ownable)
-  Pause functionality (PriceOracle)

**Development Infrastructure:**
-  Foundry build system configured
-  OpenZeppelin contracts integrated
-  Gas reporting enabled
-  Automated deployment script
-  Environment variable management
-  Local testing environment (Anvil)

---

## 🔄 Sprint 3: Production Deployment & Frontend (IN PROGRESS)

**Objective:** Deploy to Sepolia testnet, build frontend interface, implement performance metrics, and optimize gas usage.

### Phase 5.3: Deploy to Sepolia Testnet

**Status:** 📋 Pending
**Priority:** HIGH
**Estimated Effort:** 2-3 hours

**Tasks:**
- [ ] Configure Sepolia RPC endpoint in environment
- [ ] Obtain Sepolia testnet ETH from faucet
- [ ] Execute deployment script on Sepolia
- [ ] Monitor and verify deployment transactions
- [ ] Verify contracts on Etherscan
- [ ] Document deployed contract addresses
- [ ] Test contract interactions on Sepolia

**Deliverables:**
- Sepolia deployment addresses (3 contracts)
- Etherscan verification links
- Deployment transaction hashes
- Gas cost analysis for production deployment
- Updated `.env.example` with Sepolia configuration

**Acceptance Criteria:**
- All 3 contracts deployed to Sepolia successfully
- Etherscan verification shows verified source code
- Contracts are accessible and functional via Etherscan
- Cross-contract references properly configured
- Deployment metadata documented

---

### Phase 6: Frontend Implementation

**Status:** 📋 Pending
**Priority:** HIGH
**Estimated Effort:** 15-20 hours

#### 6.1 Initialize Next.js Project
**Tasks:**
- [ ] Create Next.js 14 application with TypeScript
- [ ] Configure Tailwind CSS for styling
- [ ] Set up App Router structure
- [ ] Configure environment variables
- [ ] Install required dependencies (wagmi, viem, ethers)

**Deliverables:**
- `frontend/package.json` with all dependencies
- `frontend/tsconfig.json` configuration
- `frontend/tailwind.config.js`
- `frontend/.env.example`

#### 6.2 Configure Wagmi & Web3 Integration
**Tasks:**
- [ ] Install and configure wagmi + viem
- [ ] Set up Sepolia chain configuration
- [ ] Configure MetaMask connector
- [ ] Create wagmi client configuration
- [ ] Set up Web3 provider wrapper

**Deliverables:**
- `src/lib/config.ts` : Wagmi configuration
- Provider setup for Sepolia
- Wallet connection hooks

#### 6.3 Contract Integration
**Tasks:**
- [ ] Export contract ABIs from Foundry
- [ ] Create contract address constants
- [ ] Set up typed contract hooks
- [ ] Implement read function wrappers
- [ ] Create write function wrappers
- [ ] Handle transaction states

**Deliverables:**
- `src/lib/contracts.ts` : Contract ABIs and addresses
- Typed contract interfaces
- Custom hooks for contract interactions
- Transaction state management

#### 6.4 Transaction Logger Implementation
**Tasks:**
- [ ] Create txLogger utility as per course requirements
- [ ] Implement transaction timing measurement
- [ ] Capture gas usage and costs
- [ ] Log calldata size
- [ ] Format output as CSV
- [ ] Handle transaction failures

**Deliverables:**
- `src/lib/txLogger.ts` implementation
- CSV output formatting (txHash, blockNumber, latencyMs, gasUsed, etc.)
- Console logging for debugging

#### 6.5 Core Pages Development
**Tasks:**
- [ ] Create landing page with event listings
- [ ] Build event detail page with ticket purchase
- [ ] Implement user ticket management page
- [ ] Create user profile dashboard
- [ ] Add navigation between pages
- [ ] Implement responsive design

**Deliverables:**
- `app/page.tsx` : Event listing page
- `app/events/[id]/page.tsx` : Event details
- `app/tickets/page.tsx` : User tickets
- `app/profile/page.tsx` : User dashboard
- Navigation components
- Responsive layouts

#### 6.6 UI Components
**Tasks:**
- [ ] Build wallet connection component
- [ ] Create ticket purchase form
- [ ] Implement ticket transfer modal
- [ ] Design event card component
- [ ] Add loading states
- [ ] Implement error boundaries
- [ ] Create success notifications

**Deliverables:**
- `components/wallet/ConnectButton.tsx`
- `components/tickets/PurchaseForm.tsx`
- `components/tickets/TransferModal.tsx`
- `components/events/EventCard.tsx`
- Common UI components
- Error handling components

**Acceptance Criteria:**
- Frontend connects to Sepolia testnet
- Users can connect MetaMask wallet
- Event creation functionality works
- Ticket purchasing works with payment
- Ticket transfers work with resale validation
- All transactions logged with metrics
- Responsive design on mobile/desktop

---

### Phase 3.4: Coverage Report Generation

**Status:** 📋 Pending
**Priority:** MEDIUM
**Estimated Effort:** 1-2 hours

**Tasks:**
- [ ] Execute test suite with coverage tracking
- [ ] Generate LCOV format coverage data
- [ ] Create human-readable coverage summary
- [ ] Identify uncovered code paths
- [ ] Document intentionally uncovered code
- [ ] Calculate coverage percentages per contract

**Deliverables:**
- `metrics/coverage/coverage-summary.txt`
- `metrics/coverage/lcov.info`
- Coverage report documentation
- Coverage badge for README

**Acceptance Criteria:**
- Minimum 95% line coverage achieved
- All critical paths covered
- Coverage data properly formatted
- Reports generated successfully

---

### Phase 4.3: Final Gas Snapshot

**Status:** 📋 Pending
**Priority:** MEDIUM
**Estimated Effort:** 2-3 hours

#### 4.1 Initial Gas Snapshot
**Tasks:**
- [ ] Run gas snapshot for all contract functions
- [ ] Document gas costs per operation
- [ ] Identify high-cost functions
- [ ] Create baseline metrics file

**Deliverables:**
- `metrics/gas/gas-snapshot-initial.txt`
- Function-by-function gas analysis

#### 4.2 Gas Optimization (if needed)
**Tasks:**
- [ ] Analyze storage access patterns
- [ ] Optimize struct packing
- [ ] Implement unchecked arithmetic where safe
- [ ] Review loop implementations
- [ ] Optimize storage layout

**Deliverables:**
- Optimized contract versions (if needed)
- Optimization documentation

#### 4.3 Final Gas Snapshot
**Tasks:**
- [ ] Generate final gas snapshot
- [ ] Calculate percentage improvements
- [ ] Create differential analysis
- [ ] Document trade-offs made

**Deliverables:**
- `metrics/gas/gas-snapshot.txt` (final)
- Gas differential report
- Percentage improvement calculations

**Acceptance Criteria:**
- Gas snapshot captures all public functions
- Baseline established for comparison
- Optimizations documented (if implemented)
- Final metrics meet acceptable limits

---

### Phase 7: Transaction Performance Measurement

**Status:** 📋 Pending
**Priority:** HIGH
**Estimated Effort:** 3-4 hours

#### 7.1 Execute Primary Operations
**Tasks:**
- [ ] Perform 3 event creation transactions on Sepolia
- [ ] Execute 3 ticket purchase transactions
- [ ] Complete 3 ticket transfer operations
- [ ] Use different accounts for diversity
- [ ] Document transaction contexts

**Deliverables:**
- 9 total transactions on Sepolia
- Transaction hashes for all operations
- Screenshots of successful transactions

#### 7.2 Collect Latency Data
**Tasks:**
- [ ] Capture transaction hash for each operation
- [ ] Record block numbers
- [ ] Measure latency from submission to confirmation
- [ ] Log gas used per transaction
- [ ] Record effective gas price
- [ ] Calculate calldata size in bytes

**Deliverables:**
- Raw transaction data from txLogger
- Gas price analysis
- Network conditions documentation

#### 7.3 Generate Latency Report
**Tasks:**
- [ ] Compile all 9 transaction measurements
- [ ] Format data into CSV structure
- [ ] Calculate average metrics per operation type
- [ ] Document any anomalies
- [ ] Create performance analysis summary

**Deliverables:**
- `metrics/latency/latency.csv` with all data
- Performance analysis document
- Statistical summary

**CSV Format:**
```
txHash,blockNumber,latencyMs,gasUsed,effectiveGasPrice,calldataBytes,status
```

**Acceptance Criteria:**
- All 9 transactions included
- CSV format matches specification
- No placeholder or test data
- Performance patterns documented

---

### Sprint 3 Success Metrics

| Metric | Target |
|--------|--------|
| Sepolia Deployment |  Complete |
| Frontend Pages | 4 core pages |
| UI Components | 6+ components |
| Transaction Types Tested | 3 (create, purchase, transfer) |
| Transaction Samples | 9 total (3 per type) |
| Test Coverage | ≥95% |
| Gas Optimization | Documented baseline |

---

## 📋 Sprint 4: Security, Testing & Final Delivery (PLANNED)

**Objective:** Complete security audit, usability testing, CI/CD setup, and final metrics compilation.

### Phase 8: Security Analysis

**Status:** 📋 Planned
**Priority:** HIGH
**Estimated Effort:** 4-6 hours

#### 8.1 Install Security Tools
**Tasks:**
- [ ] Install Slither static analyzer
- [ ] Configure Slither for Solidity 0.8.24
- [ ] Set up analysis environment

#### 8.2 Run Security Analysis
**Tasks:**
- [ ] Execute Slither on all contracts
- [ ] Generate human-readable summary
- [ ] Identify all security findings
- [ ] Categorize by severity levels

**Deliverables:**
- `metrics/security/slither-summary.txt`
- Detailed findings report

#### 8.3 Address Critical Findings
**Tasks:**
- [ ] Review all high severity findings
- [ ] Implement fixes for critical issues
- [ ] Document mitigation strategies
- [ ] Re-run analysis after fixes

**Deliverables:**
- `metrics/security/audit-report.md`
- Updated contracts with security fixes

#### 8.4 Security Patterns Implementation
**Tasks:**
- [ ] Verify ReentrancyGuard implementation
- [ ] Confirm Checks-Effects-Interactions pattern
- [ ] Validate access controls
- [ ] Review input validation
- [ ] Document security measures

**Acceptance Criteria:**
- No high severity issues remaining
- Medium issues addressed or justified
- Security patterns properly implemented
- Audit report comprehensive

---

### Phase 9: Usability Testing Infrastructure

**Status:** 📋 Planned
**Priority:** MEDIUM
**Estimated Effort:** 6-8 hours

#### 9.1 Create Test Protocol
**Tasks:**
- [ ] Define specific user tasks to test
- [ ] Create success criteria for each task
- [ ] Design data collection methodology
- [ ] Prepare test environment
- [ ] Create participant instructions
- [ ] Design feedback questionnaire

**Deliverables:**
- `usability/test-plans/test-protocol.md`
- Task list document
- Success criteria definitions

#### 9.2 Implement Test Scenarios
**Tasks:**
- [ ] Deploy multiple test events on Sepolia
- [ ] Configure various ticket prices
- [ ] Set different resale rules
- [ ] Fund test wallets
- [ ] Prepare test data

**Deliverables:**
- Test event configurations
- Test wallet addresses
- Scenario documentation

#### 9.3 Conduct Testing Sessions
**Tasks:**
- [ ] Recruit minimum 3 test participants
- [ ] Conduct individual testing sessions
- [ ] Record screen during sessions
- [ ] Measure time for each task
- [ ] Document errors encountered
- [ ] Collect System Usability Scale (SEQ) ratings
- [ ] Gather qualitative feedback

**Deliverables:**
- Session recordings
- Time measurements per task
- Error documentation
- SEQ ratings (1-7 scale)

#### 9.4 Compile Results
**Tasks:**
- [ ] Aggregate all testing data
- [ ] Calculate success rates per task
- [ ] Compute average time on task
- [ ] Compile SEQ ratings
- [ ] Format data into CSV

**Deliverables:**
- `usability/results/usability.csv`
- Statistical analysis
- Recommendations document

**CSV Format:**
```
testerId,success,timeOnTaskSec,SEQ_1to7,comment
```

**Acceptance Criteria:**
- Minimum 3 complete test sessions
- All tasks attempted by each user
- Complete data for each participant
- Actionable recommendations identified

---

### Phase 10: Continuous Integration

**Status:** 📋 Planned
**Priority:** MEDIUM
**Estimated Effort:** 2-3 hours

#### 10.1 GitHub Actions Workflow
**Tasks:**
- [ ] Create test workflow configuration
- [ ] Configure Foundry toolchain action
- [ ] Set up test execution steps
- [ ] Add branch protection rules

**Deliverables:**
- `.github/workflows/test.yml`
- CI pipeline configuration
- Build status badges

#### 10.2 Coverage Reporting
**Tasks:**
- [ ] Create coverage workflow
- [ ] Configure coverage tool
- [ ] Set up artifact storage
- [ ] Configure coverage thresholds

**Deliverables:**
- `.github/workflows/coverage.yml`
- Coverage badges
- Automated reports

**Acceptance Criteria:**
- Workflow triggers on push/PR
- Tests execute successfully in CI
- Coverage reports generated
- Failures properly reported

---

### Phase 11: Final Metrics Compilation

**Status:** 📋 Planned
**Priority:** HIGH
**Estimated Effort:** 2-3 hours

#### 11.1 Generate Complete Metrics Pack
**Tasks:**
- [ ] Collect gas-snapshot.txt
- [ ] Retrieve coverage-summary.txt
- [ ] Compile latency.csv
- [ ] Include deploy.json
- [ ] Add slither-summary.txt
- [ ] Create ZIP archive

**Deliverables:**
- `67404-BlockTix-metrics.zip`

**Required Files:**
1. `gas-snapshot.txt` : Foundry gas measurements
2. `coverage-summary.txt` : Test coverage summary
3. `latency.csv` : Transaction performance data
4. `deploy.json` : Deployment metadata
5. `slither-summary.txt` : Security analysis

#### 11.2 Verify Data Completeness
**Tasks:**
- [ ] Verify all transaction hashes are real Sepolia transactions
- [ ] Confirm addresses match deployed contracts
- [ ] Validate gas measurements from actual execution
- [ ] Check CSV formats match specifications
- [ ] Ensure no sample data present

**Deliverables:**
- Data validation report
- Etherscan verification links
- Quality assurance checklist

**Acceptance Criteria:**
- All 5 files present in metrics pack
- All data verifiable on Etherscan
- Formats match specifications exactly
- No test or placeholder data

---

### Sprint 4 Success Metrics

| Metric | Target |
|--------|--------|
| Security Issues (High) | 0 |
| Security Issues (Medium) | Documented & Addressed |
| Usability Test Participants | ≥3 |
| CI/CD Pipelines | 2 (test + coverage) |
| Metrics Files | 5 complete |
| Etherscan Verification |  All contracts |
| Final Documentation | Complete |

---

## Sprint Deliverables Summary

### Sprint 2 (Completed)
-  3 Smart Contracts
-  3 Interfaces
-  3 Test Suites (105 tests)
-  1 Deployment Script
-  Local Deployment

### Sprint 3 (In Progress)
- [ ] Sepolia Deployment
- [ ] Frontend Application (6 components, 4 pages)
- [ ] Transaction Logger
- [ ] Coverage Report
- [ ] Gas Snapshot
- [ ] Performance Metrics (9 transactions)

### Sprint 4 (Planned)
- [ ] Security Audit Report
- [ ] Usability Test Results (3+ participants)
- [ ] CI/CD Pipelines (2)
- [ ] Complete Metrics Pack (5 files)
- [ ] Final Documentation

---

## Risk Assessment

### Sprint 3 Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Sepolia faucet delays | Medium | Low | Use multiple faucet sources |
| Frontend complexity | High | Medium | Start early, modular development |
| Transaction latency variability | Medium | High | Multiple measurements, document conditions |
| Gas price fluctuations | Low | High | Document gas prices used |

### Sprint 4 Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Security findings require major changes | High | Low | Thorough testing in Sprint 2/3 |
| Usability participant recruitment | Medium | Medium | Recruit early, incentivize participation |
| CI/CD configuration issues | Low | Low | Use standard templates |

---

## Dependencies & Blockers

### Current Blockers
- None

### Dependencies for Sprint 3
- Sepolia testnet ETH (from faucet)
- Etherscan API key (for verification)
- Frontend hosting (optional for demo)

### Dependencies for Sprint 4
- Usability test participants (3+ people)
- GitHub Actions credits (free tier sufficient)

---

## Timeline

| Phase | Sprint | Target Completion |
|-------|--------|-------------------|
| 1.1 : 1.4 | Sprint 2 |  Complete |
| 3.1 | Sprint 2 |  Complete |
| 5.1 : 5.2 | Sprint 2 |  Complete |
| 5.3 | Sprint 3 | Week 7 |
| 6.1 : 6.6 | Sprint 3 | Week 8-9 |
| 3.4, 4.3, 7 | Sprint 3 | Week 10 |
| 8 | Sprint 4 | Week 11 |
| 9 | Sprint 4 | Week 12 |
| 10, 11 | Sprint 4 | Week 13 |
| Final Submission | Sprint 4 | Week 14 |

---

**Project Status:** 🟢 ON TRACK

**Next Action Items:**
1. Deploy to Sepolia testnet (Phase 5.3)
2. Initialize frontend project (Phase 6.1)
3. Set up wagmi configuration (Phase 6.2)

**Last Updated:** 2025-10-28
**Updated By:** Claude Code Assistant
