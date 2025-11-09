# BlockTix Operations Runbook

Complete guide for setting up, deploying, and interacting with the BlockTix decentralized event ticketing platform.

---

## Table of Contents
1. [Setup & Reproducibility](#part-1-setup--reproducibility)
2. [CLI Interface Operations](#part-2-cli-interface-operations)
3. [Etherscan Interface Guide](#part-3-etherscan-interface-guide)
4. [Troubleshooting](#part-4-troubleshooting)

---

## Part 1: Setup & Reproducibility

### Prerequisites
- **Foundry**: Install from [getfoundry.sh](https://getfoundry.sh)
- **Git**: For cloning the repository
- **Sepolia ETH**: Get testnet ETH from [Sepolia Faucet](https://sepoliafaucet.com)

### 1.1 Clone & Install

```bash
# Clone repository
git clone <REPOSITORY_URL>
cd BlockTix

# Navigate to contracts directory
cd contracts

# Install dependencies
forge install
```

**Expected Output:**
```
Installing forge-std...
Installing openzeppelin-contracts...
Installed 2 dependencies
```

### 1.2 Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit .env file with your values
nano .env
```

**Required Variables:**
```bash
PRIVATE_KEY=0xYOUR_PRIVATE_KEY_HERE
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY
```

**Security Notes:**
- NEVER commit your actual `.env` file
- The example private key is Anvil's default (TESTNET ONLY)
- Get Infura key from [infura.io](https://infura.io)
- Get Etherscan API key from [etherscan.io](https://etherscan.io/myapikey)

### 1.3 Run Tests

```bash
# Run all tests with verbose output
forge test -vv
```

**Expected Output:**
```
Ran 105 tests for test/unit/...
Suite result: ok. 105 passed; 0 failed; 0 skipped
```

**Alternative Scripts:**
```bash
# From repository root
./scripts/test-all.sh
```

### 1.4 Generate Coverage

```bash
# Generate coverage report
forge coverage

# View coverage summary
cat ../metrics/coverage/coverage-summary.txt
```

**Expected Coverage:**
- BlockTixMain.sol: 97.53% lines
- TicketNFT.sol: 97.83% lines
- PriceOracle.sol: 97.37% lines

### 1.5 Deploy Contracts

**Option A: Use Deployment Script (Recomended)**
```bash
# From contracts directory
forge script script/Deploy.s.sol:Deploy \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

**Option B: Use Shell Script**
```bash
# From repository root
./scripts/deploy-sepolia.sh
```

**Deployment Output:**
```
PriceOracle deployed to: 0x3c7D84D7AF3Fb18AcFFF66d310fca456eB76245e
TicketNFT deployed to: 0xF82bA5dac740Ab9955800ff5e807d16bC4014861
BlockTixMain deployed to: 0x4572b63734CE8395CB32E199cfb2239f9e7D7095
```

**Contract Verification:** Contracts are automatically verified on Etherscan.

---

## Part 2: CLI Interface Operations

### 2.1 Environment Setup

Export environment variables for easy command execution:

```bash
# Load environment
source contracts/.env

# Export contract addresses (current Sepolia deployment)
export BLOCKTIX_ADDRESS="0x4572b63734CE8395CB32E199cfb2239f9e7D7095"
export TICKETNFT_ADDRESS="0xF82bA5dac740Ab9955800ff5e807d16bC4014861"
export PRICEORACLE_ADDRESS="0x3c7D84D7AF3Fb18AcFFF66d310fca456eB76245e"

# Verify RPC connection
cast chain-id --rpc-url $SEPOLIA_RPC_URL
```

**Expected Output:** `11155111` (Sepolia chain ID)

### 2.2 Core Operations

#### Operation 1: Create Event

```bash
cast send $BLOCKTIX_ADDRESS \
  "createEvent(string,uint256,uint256,uint256,uint256)" \
  "Tech Conference 2025" \
  100 \
  10000000000000000 \
  1735689600 \
  500 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

**Parameters Explained:**
- `"Tech Conference 2025"`: Event name
- `100`: Total tickets
- `10000000000000000`: Base price (0.01 ETH in wei)
- `1735689600`: Event date (Unix timestamp)
- `500`: Max resale markup (500 = 50%)

**Transaction States:**
1. **Pending**: Transaction submitted, waiting for confirmation
   ```
   blockHash               null
   status                  pending
   ```

2. **Confirmed**: Transaction mined succesfully
   ```
   blockHash               0x1234...
   blockNumber             9594575
   status                  1 (success)
   gasUsed                 208743
   ```

3. **Failed**: Transaction reverted
   ```
   status                  0 (failure)
   ```

**Check Status:**
```bash
# Get transaction receipt (replace with actual TX hash)
cast receipt 0xTRANSACTION_HASH --rpc-url $SEPOLIA_RPC_URL
```

**View on Etherscan:**
```
https://sepolia.etherscan.io/tx/0xTRANSACTION_HASH
```

#### Operation 2: Purchase Ticket

```bash
cast send $BLOCKTIX_ADDRESS \
  "purchaseTicket(uint256)" \
  0 \
  --value 0.015ether \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

**Parameters:**
- `0`: Event ID
- `--value 0.015ether`: Payment (include extra for dynamic pricing + fees)

**What Happens:**
1. Dynamic price calculated based on demand
2. NFT ticket minted to buyer
3. Platform fee deducted (2.5%)
4. Organizer receives payment
5. Excess ETH refunded automatically

**Verify Purchase:**
```bash
# Check ticket ownership
cast call $TICKETNFT_ADDRESS \
  "ownerOf(uint256)(address)" 0 \
  --rpc-url $SEPOLIA_RPC_URL
```

#### Operation 3: Check Event Details

```bash
cast call $BLOCKTIX_ADDRESS \
  "getEvent(uint256)" 0 \
  --rpc-url $SEPOLIA_RPC_URL
```

**Output Format:**
```
eventId           0
organizer         0x1234...
name              Tech Conference 2025
totalTickets      100
ticketsSold       1
basePrice         10000000000000000
eventDate         1735689600
isActive          true
maxResaleMarkup   500
```

#### Operation 4: Transfer Ticket (Resale)

```bash
# First, approve BlockTixMain to transfer your NFT
cast send $TICKETNFT_ADDRESS \
  "approve(address,uint256)" \
  $BLOCKTIX_ADDRESS \
  0 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY

# Then transfer ticket with payment
cast send $BLOCKTIX_ADDRESS \
  "transferTicket(uint256,address)" \
  0 \
  0xBUYER_ADDRESS \
  --value 0.012ether \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

**Resale Rules:**
- Price must not exceed `basePrice * (1 + maxResaleMarkup/10000)`
- Platform fee applies to resale
- Original buyer can withdraw earnings

**Alternative: Direct NFT Transfer**
```bash
cast send $TICKETNFT_ADDRESS \
  "transferFrom(address,address,uint256)" \
  YOUR_ADDRESS \
  RECIPIENT_ADDRESS \
  0 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

#### Operation 5: Check Ticket Details

```bash
cast call $BLOCKTIX_ADDRESS \
  "getTicket(uint256)" 0 \
  --rpc-url $SEPOLIA_RPC_URL
```

**Returns:**
```
ticketId          0
eventId           0
currentOwner      0x1234...
purchasePrice     10500000000000000
isUsed            false
```

#### Operation 6: Withdraw Funds

```bash
# Check pending withdrawals
cast call $BLOCKTIX_ADDRESS \
  "pendingWithdrawals(address)(uint256)" \
  YOUR_ADDRESS \
  --rpc-url $SEPOLIA_RPC_URL

# Withdraw available funds
cast send $BLOCKTIX_ADDRESS \
  "withdraw()" \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

#### Operation 7: Use Ticket (Organizer Only)

```bash
cast send $BLOCKTIX_ADDRESS \
  "useTicket(uint256)" 0 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY
```

**Access Control:** Only event organizer can mark tickets as used.

### 2.3 Transaction Monitoring

#### Check Transaction Status

```bash
# Get full transaction receipt
cast receipt TX_HASH --rpc-url $SEPOLIA_RPC_URL

# Check if transaction succeeded
cast receipt TX_HASH --rpc-url $SEPOLIA_RPC_URL | grep status

# Get gas used
cast tx TX_HASH --rpc-url $SEPOLIA_RPC_URL gasUsed
```

#### Read Transaction Logs

```bash
# View all logs from transaction
cast receipt TX_HASH --rpc-url $SEPOLIA_RPC_URL -j | jq '.logs'
```

**Common Events:**
- `EventCreated`: New event created
- `TicketPurchased`: Ticket sold
- `TicketTransferred`: Ticket resold
- `TicketUsed`: Ticket checked in
- `WithdrawalProcessed`: Funds withdrawn

#### Check Account Balance

```bash
# Check ETH balance
cast balance YOUR_ADDRESS --rpc-url $SEPOLIA_RPC_URL

# Check ticket (NFT) balance
cast call $TICKETNFT_ADDRESS \
  "balanceOf(address)(uint256)" \
  YOUR_ADDRESS \
  --rpc-url $SEPOLIA_RPC_URL
```

---

## Part 3: Etherscan Interface Guide

### 3.1 Navigate to Contracts

**BlockTixMain (Main Contract):**
```
https://sepolia.etherscan.io/address/0x4572b63734ce8395cb32e199cfb2239f9e7d7095
```

**TicketNFT (ERC-721 Contract):**
```
https://sepolia.etherscan.io/address/0xf82ba5dac740ab9955800ff5e807d16bc4014861
```

**PriceOracle (Pricing Contract):**
```
https://sepolia.etherscan.io/address/0x3c7d84d7af3fb18acfff66d310fca456eb76245e
```

### 3.2 Using "Write Contract" Tab

**Step 1:** Navigate to contract on Etherscan
**Step 2:** Click "Contract" tab
**Step 3:** Click "Write Contract" sub-tab
**Step 4:** Click "Connect to Web3" button
**Step 5:** Connect your MetaMask wallet
**Step 6:** Ensure you're on Sepolia network

**Example: Create Event**
1. Find `createEvent` function (#2)
2. Fill in parameters:
   - `_name`: "My Event"
   - `_totalTickets`: 50
   - `_basePrice`: 10000000000000000 (0.01 ETH)
   - `_eventDate`: 1735689600
   - `_maxResaleMarkup`: 500
3. Click "Write"
4. Confirm transaction in MetaMask
5. Wait for confirmation

**Example: Purchase Ticket**
1. Find `purchaseTicket` function (#3)
2. Enter `payableAmount`: 0.015 (in ETH)
3. Enter `_eventId`: 0
4. Click "Write"
5. Confirm in MetaMask

### 3.3 Using "Read Contract" Tab

**No wallet connection needed for reading.**

**Step 1:** Click "Read Contract" sub-tab
**Step 2:** Enter parameters for view functions
**Step 3:** Click "Query"

**Example: View Event**
1. Find `getEvent` function
2. Enter `eventId`: 0
3. Click "Query"
4. See event details displayed

**Example: Check Ticket Owner**
1. Navigate to TicketNFT contract
2. Find `ownerOf` function
3. Enter `tokenId`: 0
4. See owner address

### 3.4 Transaction Verification

**View Transaction Status:**
1. Go to transaction URL: `https://sepolia.etherscan.io/tx/TX_HASH`
2. Check "Status" field:
   - Success (green checkmark)
   - Fail (red X)
   - Pending (yellow clock)

**Read Event Logs:**
1. Scroll to "Logs" section on transaction page
2. Click "Decode" to see event details
3. View emitted events (EventCreated, TicketPurchased, etc.)

**Check Gas Usage:**
1. View "Gas Used" field
2. See "Transaction Fee" in ETH

---

## Part 4: Troubleshooting

### Common Errors

#### Error: "insufficient funds for gas * price + value"
**Cause:** Not enough Sepolia ETH in wallet
**Solution:**
```bash
# Check balance
cast balance YOUR_ADDRESS --rpc-url $SEPOLIA_RPC_URL

# Get testnet ETH from faucet
# https://sepoliafaucet.com
```

#### Error: "execution reverted: InvalidEventId"
**Cause:** Event ID doesn't exist
**Solution:** Check latest event ID:
```bash
cast call $BLOCKTIX_ADDRESS \
  "nextEventId()(uint256)" \
  --rpc-url $SEPOLIA_RPC_URL
```

#### Error: "execution reverted: InsufficientPayment"
**Cause:** Sent ETH is less than ticket price
**Solution:** Check current price and add buffer for fees:
```bash
# Get event base price
cast call $BLOCKTIX_ADDRESS "getEvent(uint256)" EVENT_ID \
  --rpc-url $SEPOLIA_RPC_URL

# Add ~50% buffer for dynamic pricing + platform fee
```

#### Error: "execution reverted: NotTicketOwner"
**Cause:** Trying to transfer/use ticket you don't own
**Solution:** Verify ownership:
```bash
cast call $TICKETNFT_ADDRESS \
  "ownerOf(uint256)(address)" TICKET_ID \
  --rpc-url $SEPOLIA_RPC_URL
```

#### Error: "nonce too low"
**Cause:** Transaction nonce out of sync
**Solution:** Wait for pending transactions or reset MetaMask account

#### Error: "wrong network"
**Cause:** Connected to mainnet instead of Sepolia
**Solution:**
- In MetaMask: Switch to Sepolia test network
- In CLI: Verify `$SEPOLIA_RPC_URL` is set correctly

### Empty States

#### No Events Created
**Check:**
```bash
cast call $BLOCKTIX_ADDRESS \
  "nextEventId()(uint256)" \
  --rpc-url $SEPOLIA_RPC_URL
```
If returns `0`, no events exist. Create one using Operation 1.

#### No Tickets Available
**Check:**
```bash
cast call $BLOCKTIX_ADDRESS "getEvent(uint256)" EVENT_ID \
  --rpc-url $SEPOLIA_RPC_URL
```
Look at `ticketsSold` vs `totalTickets`. If equal, event is sold out.

#### Zero Balance
**Check pending withdrawals:**
```bash
cast call $BLOCKTIX_ADDRESS \
  "pendingWithdrawals(address)(uint256)" \
  YOUR_ADDRESS \
  --rpc-url $SEPOLIA_RPC_URL
```
If returns `0`,  no funds available to withdraw.

### Contract Addresses & Links

**Sepolia Testnet (Chain ID: 11155111)**

| Contract | Address | Etherscan Link |
|----------|---------|----------------|
| BlockTixMain | `0x4572b63734CE8395CB32E199cfb2239f9e7D7095` | [View](https://sepolia.etherscan.io/address/0x4572b63734ce8395cb32e199cfb2239f9e7d7095) |
| TicketNFT | `0xF82bA5dac740Ab9955800ff5e807d16bC4014861` | [View](https://sepolia.etherscan.io/address/0xf82ba5dac740ab9955800ff5e807d16bc4014861) |
| PriceOracle | `0x3c7D84D7AF3Fb18AcFFF66d310fca456eB76245e` | [View](https://sepolia.etherscan.io/address/0x3c7d84d7af3fb18acfff66d310fca456eb76245e) |
| Deployer | `0x1bA94e09c8B1d8f54A43A6Eb269C4DA10Cc111Cb` | [View](https://sepolia.etherscan.io/address/0x1ba94e09c8b1d8f54a43a6eb269c4da10cc111cb) |

### Getting Help

- **Documentation:** See README.md for architecture details
- **Contract Code:** All contracts verified on Etherscan
- **Test Examples:** See `test/unit/` for usage examples

---

**Last Updated:** November 9, 2025
**Network:** Sepolia Testnet
**Block:** 9594488
