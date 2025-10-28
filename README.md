# BlockTix - Decentralized Event Ticketing Platform
## 67-404 Blockchain Applications - Group 4

### Repository Structure

```
BlockTix/
│
├── contracts/                      # Smart contract development (Foundry)
│   ├── src/
│   │   ├── BlockTixMain.sol       # Primary ticketing contract with event management
│   │   ├── TicketNFT.sol          # ERC-721 implementation for ticket tokens
│   │   ├── PriceOracle.sol        # Dynamic pricing and fee calculation contract
│   │   └── interfaces/
│   │       ├── IBlockTix.sol      # Main contract interface
│   │       └── ITicketNFT.sol     # NFT interface specifications
│   │
│   ├── test/
│   │   ├── unit/
│   │   │   ├── BlockTixMain.t.sol # Unit tests for main contract
│   │   │   ├── TicketNFT.t.sol    # NFT functionality tests
│   │   │   └── PriceOracle.t.sol  # Pricing mechanism tests
│   │   ├── integration/
│   │   │   └── E2E.t.sol          # End-to-end workflow tests
│   │   └── fuzz/
│   │       └── BlockTixFuzz.t.sol # Fuzz testing for edge cases
│   │
│   ├── script/
│   │   ├── Deploy.s.sol           # Deployment script for all contracts
│   │   ├── Verify.s.sol           # Etherscan verification script
│   │   └── Upgrade.s.sol          # Upgrade management script
│   │
│   ├── lib/                       # Dependencies (managed by Foundry)
│   │   └── openzeppelin-contracts/
│   │
│   ├── foundry.toml               # Foundry configuration
│   ├── .env.example               # Environment variables template
│   └── remappings.txt             # Import remappings
│
├── frontend/                       # Next.js + wagmi + viem client
│   ├── src/
│   │   ├── app/
│   │   │   ├── layout.tsx         # Root layout with providers
│   │   │   ├── page.tsx           # Landing page
│   │   │   ├── events/            # Event browsing and details
│   │   │   ├── tickets/           # Ticket management interface
│   │   │   └── profile/           # User dashboard
│   │   │
│   │   ├── components/
│   │   │   ├── wallet/            # Wallet connection components
│   │   │   ├── tickets/           # Ticket-specific UI components
│   │   │   └── common/            # Shared UI components
│   │   │
│   │   ├── hooks/
│   │   │   ├── useBlockTix.ts     # Contract interaction hooks
│   │   │   └── useTicketNFT.ts    # NFT-specific hooks
│   │   │
│   │   ├── lib/
│   │   │   ├── config.ts          # Wagmi configuration
│   │   │   ├── contracts.ts       # Contract ABIs and addresses
│   │   │   └── txLogger.ts        # Transaction measurement utility
│   │   │
│   │   └── utils/
│   │       └── constants.ts       # App constants and configurations
│   │
│   ├── public/                    # Static assets
│   ├── package.json
│   ├── tsconfig.json
│   └── next.config.js
│
├── metrics/                        # Performance and testing metrics
│   ├── gas/
│   │   ├── gas-snapshot.txt       # Foundry gas snapshots
│   │   └── gas-optimization.md    # Before/after optimization analysis
│   │
│   ├── coverage/
│   │   ├── coverage-summary.txt   # Test coverage report
│   │   └── lcov.info             # Detailed coverage data
│   │
│   ├── latency/
│   │   ├── latency.csv           # Transaction latency measurements
│   │   └── performance-report.md  # Performance analysis
│   │
│   ├── security/
│   │   ├── slither-summary.txt   # Slither static analysis output
│   │   └── audit-report.md       # Security findings and mitigations
│   │
│   └── deploy.json                # Deployment metadata
│
├── docs/                          # Project documentation
│   ├── architecture/
│   │   ├── system-design.md      # Overall system architecture
│   │   ├── smart-contracts.md    # Contract design documentation
│   │   └── data-flow.md          # Data flow and event architecture
│   │
│   ├── api/
│   │   └── contract-api.md       # Contract interface documentation
│   │
│   ├── user-guides/
│   │   ├── setup.md              # Development setup guide
│   │   ├── deployment.md         # Deployment instructions
│   │   └── testing.md            # Testing procedures
│   │
│   └── sprints/                  # Sprint deliverables
│       ├── sprint1/
│       │   ├── concept.pdf       # 1-page concept document
│       │   ├── whychain-canvas.pdf
│       │   ├── literature-scan.pdf
│       │   └── team-charter.pdf
│       ├── sprint2/
│       │   ├── architecture.pdf  # System architecture diagram
│       │   ├── threat-model.pdf
│       │   └── poc-demo.mp4
│       ├── sprint3/
│       │   ├── mvp-demo.mp4
│       │   ├── usability-test1.pdf
│       │   └── metrics-pack-v1.zip
│       └── sprint4/
│           ├── beta-demo.mp4
│           ├── security-audit.pdf
│           └── metrics-pack-final.zip
│
├── scripts/                       # Automation scripts
│   ├── test-all.sh               # Run all tests with coverage
│   ├── deploy-sepolia.sh         # Deploy to Sepolia testnet
│   ├── measure-gas.sh            # Generate gas measurements
│   └── generate-metrics.sh       # Compile all metrics
│
├── usability/                     # Usability testing materials
│   ├── test-plans/
│   │   └── test-protocol.md      # Testing methodology
│   ├── results/
│   │   └── usability.csv         # Test results data
│   └── recordings/                # Session recordings (if applicable)
│
├── .github/                       # GitHub configurations
│   └── workflows/
│       ├── test.yml              # CI testing workflow
│       └── coverage.yml          # Coverage reporting workflow
│
├── .gitignore
├── README.md                      # This file
└── LICENSE

```

---

## Build and Installation

### Prerequisites
- Node.js LTS (v18+)
- Git
- Foundry toolkit (forge, cast, anvil)
- MetaMask browser extension
- Sepolia testnet ETH

### Smart Contracts Setup

```bash
# Navigate to contracts directory
cd contracts/

# Install dependencies
forge install

# Copy environment variables
cp .env.example .env
# Edit .env with your keys (NEVER commit actual keys)

# Compile contracts
forge build

# Run tests
forge test -vv
```

### Frontend Setup

```bash
# Navigate to frontend directory
cd frontend/

# Install dependencies
npm install

# Copy environment variables
cp .env.example .env.local
# Configure with contract addresses

# Run development server
npm run dev
```

---

## Testing Infrastructure

### Contract Testing

**Location**: `contracts/test/`

**Commands**:
- `forge test`: Run all tests
- `forge test -vv`: Run with verbose logging
- `forge test --match-test testSpecificFunction`: Run specific test
- `forge coverage`: Generate coverage report

**Output Files**:
- `metrics/coverage/coverage-summary.txt`: Overall coverage percentages
- `metrics/coverage/lcov.info`: Detailed line-by-line coverage

### Gas Measurements

**Commands**:
- `forge snapshot`: Generate gas snapshot
- `forge snapshot --diff`: Compare with previous snapshot

**Output Files**:
- `metrics/gas/gas-snapshot.txt`: Gas usage per function
- `metrics/gas/gas-optimization.md`: Optimization analysis document

### Frontend Testing

**Location**: `frontend/src/__tests__/`

**Commands**:
- `npm test`: Run test suite
- `npm run test:coverage`: Generate coverage report

---

## Deployment Procedures

### Sepolia Testnet Deployment

**Script Location**: `contracts/script/Deploy.s.sol`

**Command**:
```bash
forge script script/Deploy.s.sol:Deploy --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

**Output Files**:
- `metrics/deploy.json`: Contains deployment metadata including:
  - Chain identifier
  - Contract addresses
  - Creation transaction hashes
  - Block numbers
  - Compiler version
  - Etherscan verification links

### Contract Verification

**Script Location**: `contracts/script/Verify.s.sol`

**Command**:
```bash
forge verify-contract --chain sepolia <CONTRACT_ADDRESS> src/BlockTixMain.sol:BlockTixMain --etherscan-api-key $ETHERSCAN_API_KEY
```

---

## Metrics Collection

### Transaction Latency Measurement

**Utility Location**: `frontend/src/lib/txLogger.ts`

**Process**:
1. The txLogger utility automatically measures transaction metrics
2. Execute primary write operations through the frontend
3. Data is logged to console and saved to CSV

**Output File**: `metrics/latency/latency.csv`

**CSV Format**:
```
txHash,blockNumber,latencyMs,gasUsed,effectiveGasPrice,calldataBytes,status
```

### Security Analysis

**Tool**: Slither static analyzer

**Command**:
```bash
slither contracts/src/ --print human-summary > metrics/security/slither-summary.txt
```

**Output Files**:
- `metrics/security/slither-summary.txt`: Categorized findings by severity
- `metrics/security/audit-report.md`: Detailed analysis with mitigations

### Usability Testing

**Test Protocol**: `usability/test-plans/test-protocol.md`

**Output File**: `usability/results/usability.csv`

**CSV Format**:
```
testerId,success,timeOnTaskSec,SEQ_1to7,comment
```

---

## Sprint Deliverables

### Sprint Packaging

Each sprint deliverable is packaged according to course requirements:

**Naming Convention**: `67404-FALL25-BlockTix-Sprint[N].zip`

**Contents**:
- Code snapshot (tagged in Git)
- `RUN.md` with setup instructions
- Sprint-specific deliverables (see `docs/sprints/`)
- Metrics pack (Sprint 3+)

### Metrics Micro-Pack

**Package Name**: `67404-BlockTix-metrics.zip`

**Required Files**:
1. `gas-snapshot.txt` - Foundry gas measurements
2. `coverage-summary.txt` - Test coverage summary
3. `latency.csv` - Transaction performance data
4. `deploy.json` - Deployment metadata
5. `slither-summary.txt` - Security analysis (Sprint 4 only)

---

## Development Workflow

### Branch Strategy
- `main`: Production-ready code
- `develop`: Integration branch
- `sprint-N`: Sprint-specific development
- `feature/*`: Individual features

### Commit Standards
Follow conventional commits:
- `feat:` New features
- `fix:` Bug fixes
- `test:` Test additions/modifications
- `docs:` Documentation updates
- `refactor:` Code refactoring
- `perf:` Performance improvements

### Code Review Process
1. All code requires PR review before merging
2. Tests must pass in CI
3. Coverage must meet minimum threshold (80%)
4. Security checks must pass

---

## Key Contract Functions

### BlockTixMain Contract
Primary interface for event and ticket management. Handles event creation, ticket minting, transfers, and resale rules.

### TicketNFT Contract
ERC-721 compliant NFT implementation for tickets. Manages token metadata and ownership.

### PriceOracle Contract
Handles dynamic pricing calculations and fee structures for primary and secondary sales.

---

## Environment Variables

### Contracts (.env)
```
SEPOLIA_RPC_URL=
PRIVATE_KEY=
ETHERSCAN_API_KEY=
```

### Frontend (.env.local)
```
NEXT_PUBLIC_BLOCKTIX_ADDRESS=
NEXT_PUBLIC_TICKET_NFT_ADDRESS=
NEXT_PUBLIC_PRICE_ORACLE_ADDRESS=
NEXT_PUBLIC_SEPOLIA_RPC_URL=
```

---

## Team Information

**Group 4 - BlockTix Team**

Repository maintained according to 67-404 Fall 2025 course requirements.

For detailed implementation specifics, refer to the documentation in `/docs/`.

---

## License

This project is developed for educational purposes as part of CMU 67-404.