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
│   │       ├── ITicketNFT.sol     # NFT interface specifications
│   │       └── IPriceOracle.sol   # Price oracle interface
│   │
│   ├── test/
│   │   └── unit/
│   │       ├── BlockTixMain.t.sol # Unit tests for main contract (31 tests)
│   │       ├── TicketNFT.t.sol    # NFT functionality tests (32 tests)
│   │       └── PriceOracle.t.sol  # Pricing mechanism tests (40 tests)
│   │
│   ├── script/
│   │   └── Deploy.s.sol           # Deployment script for all contracts
│   │
│   ├── lib/                       # Dependencies (managed by Foundry)
│   │   ├── forge-std/             # Foundry standard library
│   │   └── openzeppelin-contracts/# OpenZeppelin v5.x contracts
│   │
│   ├── foundry.toml               # Foundry configuration
│   ├── .env.example               # Environment variables template
│   └── remappings.txt             # Import remappings
│
├── COMPLETED.md                    # Phase completion tracking
├── PROGRESS.md                     # Detailed progress log
├── DIAGRAM.md                      # System architecture specifications
├── DEMO.md                         # Live demo walkthrough
├── ROADMAP.md                      # Implementation roadmap
├── .gitignore
├── README.md                       # This file
└── LICENSE

```

---

## Build and Installation

### Prerequisites
- Git
- Foundry toolkit (forge, cast, anvil)
- Sepolia testnet ETH (for testnet deployment)

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

# Run all tests (103 tests)
forge test -vv

# Run tests with gas reporting
forge test --gas-report

# Generate coverage report
forge coverage
```

---

## Testing Infrastructure

### Contract Testing

**Location**: `contracts/test/unit/`

**Test Coverage**:
- BlockTixMain.t.sol : 31 tests covering event creation, ticket purchasing, transfers, withdrawals, fee management
- TicketNFT.t.sol : 32 tests covering minting, burning, URI management, ERC-721 compliance
- PriceOracle.t.sol : 40 tests covering pricing calculations, surge pricing, time decay, access control

**Commands**:
- `forge test` : Run all tests
- `forge test -vv` : Run with verbose logging
- `forge test --match-test testSpecificFunction` : Run specific test
- `forge test --match-contract BlockTixMain` : Run tests for specific contract
- `forge coverage` : Generate coverage report

**Test Results**:
- Total Tests : 103
- Pass Rate : 100% (103/103 passing)
- Compilation : SUCCESS (0 errors, 0 warnings)

### Gas Measurements

**Commands**:
- `forge snapshot` : Generate gas snapshot
- `forge snapshot --diff` : Compare with previous snapshot
- `forge test --gas-report` : Display gas usage during tests

---

## Deployment Procedures

### Local Anvil Deployment

**Script Location**: `contracts/script/Deploy.s.sol`

**Steps**:
1. Start Anvil local testnet:
```bash
anvil
```

2. Deploy contracts (in separate terminal):
```bash
cd contracts/
forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast
```

**Deployment Configuration**:
- Platform Fee : 250 basis points (2.5%)
- Demand Multiplier : 1000 basis points (10%)
- Time Decay : 500 basis points (5%)
- Base URI : https://blocktix.io/metadata/

**Deployment Order**:
1. PriceOracle contract
2. TicketNFT contract
3. BlockTixMain contract
4. Configure cross-contract references
5. Verify deployment

**Local Deployment Addresses** (Anvil Chain ID 31337):
- BlockTixMain : 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
- TicketNFT : 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
- PriceOracle : 0x5FbDB2315678afecb367f032d93F642f64180aa3

### Sepolia Testnet Deployment

**Command**:
```bash
forge script script/Deploy.s.sol:Deploy --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

**Sepolia Deployment Addresses**(Chain ID 11155111):
- BlockTixMain: 0x4572b63734CE8395CB32E199cfb2239f9e7D7095
- TicketNFT: 0xF82bA5dac740Ab9955800ff5e807d16bC4014861
- PriceOracle: 0x3c7D84D7AF3Fb18AcFFF66d310fca456eB76245e
- Deployer Address: https://sepolia.etherscan.io/address/0x1ba94e09c8b1d8f54a43a6eb269c4da10cc111cb

**Etherscan Links**:
- [BlockTixMain](https://sepolia.etherscan.io/address/0x4572b63734ce8395cb32e199cfb2239f9e7d7095)
- [TicketNFT](https://sepolia.etherscan.io/address/0xf82ba5dac740ab9955800ff5e807d16bc4014861)
- [PriceOracle](https://sepolia.etherscan.io/address/0x3c7d84d7af3fb18acfff66d310fca456eb76245e)

### Contract Verification

**Command**:
```bash
forge verify-contract --chain sepolia <CONTRACT_ADDRESS> src/BlockTixMain.sol:BlockTixMain --etherscan-api-key $ETHERSCAN_API_KEY
```

**See Also**: `DEMO.md` for complete live demo walkthrough

---

## Smart Contract Architecture

### System Overview

BlockTix implements a modular three-contract architecture for decentralized event ticketing with the following key features:
- Event creation and management by organizers
- Dynamic pricing with surge pricing thresholds
- ERC-721 NFT tickets with resale controls
- Platform fee distribution
- Pull payment pattern for withdrawals

### Contract Descriptions

#### BlockTixMain.sol
**Purpose**: Central hub contract managing events, ticket sales, and financial flows

**Key Features**:
- Event creation with customizable parameters (total tickets, base price, event date, resale markup limits)
- Ticket purchasing with dynamic pricing via PriceOracle integration
- Ticket transfer/resale with enforced markup limits
- Ticket usage tracking (check-in functionality)
- Event cancellation by organizers
- Withdrawal system with platform fee distribution (2.5% default)
- Access control (Ownable for admin functions)
- Reentrancy protection on all payable functions

**Core Functions**:
- `createEvent()` : Create new ticketed events
- `purchaseTicket()` : Buy tickets with dynamic pricing
- `transferTicket()` : Resell tickets with price validation
- `useTicket()` : Mark tickets as used (organizer only)
- `cancelEvent()` : Cancel events (organizer only)
- `withdraw()` : Withdraw accumulated funds
- `updatePlatformFee()` : Update platform fee (owner only)

**State Management**:
- Event struct : eventId, organizer, name, totalTickets, ticketsSold, basePrice, eventDate, isActive, maxResaleMarkup
- Ticket struct : ticketId, eventId, currentOwner, purchasePrice, isUsed
- Mappings for events, tickets, pending withdrawals

#### TicketNFT.sol
**Purpose**: ERC-721 NFT contract representing event tickets

**Key Features**:
- Full ERC-721 compliance (extends OpenZeppelin ERC721URIStorage)
- Safe minting with metadata URI storage
- Batch minting capability for efficiency
- Burn functionality for expired/used tickets
- Base URI management system
- Access control (only BlockTixMain can mint)
- Token existence tracking
- Event-to-token mapping

**Core Functions**:
- `mint()` : Mint single ticket NFT
- `batchMint()` : Mint multiple tickets efficiently
- `burn()` : Burn ticket NFTs
- `setTokenURI()` : Set individual token metadata
- `setBaseURI()` : Update base URI for all tokens
- `getEventId()` : Get event ID for a ticket

#### PriceOracle.sol
**Purpose**: Dynamic pricing engine with surge pricing and time decay

**Key Features**:
- Dynamic pricing algorithm based on demand
- Surge pricing with 3 thresholds:
  - 50% sold : 5% price increase
  - 75% sold : 10% price increase
  - 90% sold : 20% price increase
- Time-based pricing adjustments (early bird discounts)
- Price validation for resales
- Platform fee calculation logic
- Price history tracking per event
- Emergency pause functionality
- Configurable surge multipliers

**Core Functions**:
- `calculatePrice()` : Calculate dynamic price based on demand
- `calculatePriceWithTimeDecay()` : Calculate price with time adjustments
- `validateResalePrice()` : Validate resale prices against markup limits
- `setDemandMultiplier()` : Update demand multiplier
- `setTimeDecay()` : Update time decay factor
- `setSurgeMultipliers()` : Configure surge pricing thresholds
- `getPriceHistory()` : Retrieve price history for events

### Contract Interactions

1. **Event Creation Flow**:
   - Organizer calls `BlockTixMain.createEvent()`
   - Event struct created and stored
   - EventCreated event emitted

2. **Ticket Purchase Flow**:
   - Buyer calls `BlockTixMain.purchaseTicket(eventId)` with ETH payment
   - BlockTixMain queries PriceOracle for current price
   - BlockTixMain calls TicketNFT.mint() to create NFT
   - Ticket struct created and ownership assigned
   - Platform fee calculated and added to pendingWithdrawals
   - Organizer share added to pendingWithdrawals
   - Excess payment refunded to buyer
   - TicketPurchased event emitted

3. **Ticket Resale Flow**:
   - Seller approves BlockTixMain to transfer NFT
   - Seller calls `BlockTixMain.transferTicket(ticketId, buyer)` with ETH payment
   - BlockTixMain validates resale price against markup limit
   - Platform fee calculated from resale price
   - Seller earnings added to pendingWithdrawals
   - NFT transferred via TicketNFT contract
   - Ticket ownership updated
   - TicketTransferred event emitted

4. **Withdrawal Flow**:
   - User calls `BlockTixMain.withdraw()`
   - Contract sends accumulated balance to user
   - WithdrawalProcessed event emitted

### Security Features

- **ReentrancyGuard**: Protects all state-changing payable functions
- **Ownable**: Restricts admin functions to contract owner
- **Pausable**: Emergency pause on PriceOracle
- **Custom Errors**: Gas-efficient error handling
- **Checks-Effects-Interactions**: External calls after state updates
- **Pull Payment Pattern**: Users withdraw rather than automatic transfers
- **Access Modifiers**: `onlyBlockTixMain` on TicketNFT and PriceOracle functions

### Dependencies

- OpenZeppelin Contracts v5.x:
  - ERC721.sol, ERC721URIStorage.sol
  - Ownable.sol
  - ReentrancyGuard.sol
  - Pausable.sol
- Foundry forge-std for testing

---

## Environment Variables

### Contracts (.env)
```bash
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY
```

**Note**: The private key above is the default Anvil test key. NEVER use this on mainnet or with real funds.

---

## Project Documentation

### Key Files
- `COMPLETED.md` : Tracks completed phases and achievements
- `PROGRESS.md` : Detailed progress log with metrics
- `DIAGRAM.md` : System architecture specifications
- `DEMO.md` : Live demo walkthrough with cast commands
- `ROADMAP.md` : Implementation roadmap

### Current Implementation Status

**Completed Phases**:
- Phase 1 : Environment Setup and Contract Foundation
- Phase 3.1 : Unit Tests Implementation (105 tests, 100% pass rate)
- Phase 3.4 : Coverage Report Generation (97%+ coverage)
- Phase 5.1 & 5.2 : Deployment Script and Local Anvil Deployment
- Phase 5.3 : Sepolia Testnet Deployment (All contracts verified)
- Phase 7 : Transaction Performance Measurement (9 transactions)

**Statistics**:
- Total Contracts : 3
- Total Interfaces : 3
- Total Test Files : 3
- Lines of Smart Contract Code : ~1,160
- Lines of Test Code : ~1,850
- Total Tests : 105
- Test Pass Rate : 100%
- Test Coverage : 97%+ (all core contracts)
- Compilation Status : SUCCESS
- Sepolia Deployment : LIVE

---

## Team Information

**Group 4 : BlockTix Team**

Repository maintained according to 67-404 Fall 2025 course requirements.

---

## License

This project is developed for educational purposes as part of CMU 67-404.