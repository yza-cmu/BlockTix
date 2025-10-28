# BlockTix System Architecture Diagram Specification

This document provides a detailed description of the BlockTix system architecture for designers to create visual diagrams.

---

## Overview

The BlockTix system is a decentralized event ticketing platform consisting of three main smart contracts that interact with multiple external actors. The architecture follows a modular design with clear separation of concerns.

---

## 1. HIGH-LEVEL SYSTEM ARCHITECTURE

### 1.1 Main Components (Top-Level View)

**Component Layout (Left to Right):**

1. **External Actors** (Leftmost : Outside System Boundary)
   : Event Organizers
   : Ticket Buyers (Primary Market)
   : Ticket Resellers/Buyers (Secondary Market)
   : Platform Owner/Admin

2. **Smart Contract Layer** (Center : Within System Boundary)
   : BlockTixMain (Central Hub)
   : TicketNFT (NFT Management)
   : PriceOracle (Pricing Engine)

3. **Blockchain Layer** (Rightmost : Infrastructure)
   : Ethereum/Sepolia Network
   : IPFS (Metadata Storage)

**Visual Representation:**
- Draw a large box representing the "BlockTix System Boundary"
- External actors should be represented as stick figures or user icons outside this boundary
- Smart contracts should be represented as rounded rectangles inside the boundary
- Use different colors for each contract type:
  : BlockTixMain: Blue
  : TicketNFT: Green
  : PriceOracle: Orange

---

## 2. SMART CONTRACT ARCHITECTURE

### 2.1 BlockTixMain Contract (Central Hub)

**Position:** Center of the diagram

**Visual Elements:**
- Large rounded rectangle (Blue)
- Title: "BlockTixMain"
- Subtitle: "Event & Ticket Management"

**Internal Components (subdivide the rectangle into sections):**

**Section 1: State Storage**
- Event Registry (Database icon)
  : eventId  ->  Event struct
  : Fields: organizer, name, totalTickets, ticketsSold, basePrice, eventDate, isActive, maxResaleMarkup
- Ticket Registry (Database icon)
  : ticketId  ->  Ticket struct
  : Fields: ticketId, eventId, currentOwner, purchasePrice, isUsed
- Pending Withdrawals (Wallet icon)
  : address  ->  amount mapping

**Section 2: Core Functions**
- createEvent()
- purchaseTicket()
- transferTicket()
- useTicket()
- cancelEvent()
- withdraw()
- updatePlatformFee()

**Section 3: Configuration**
- Platform Fee: 2.5%
- Owner: Platform Admin

**Connections (Arrows):**
- Bidirectional arrow to TicketNFT (labeled "mint/transfer NFTs")
- Bidirectional arrow to PriceOracle (labeled "calculate prices")
- Arrows from External Actors (labeled with function names)

---

### 2.2 TicketNFT Contract (ERC-721)

**Position:** Right side of BlockTixMain

**Visual Elements:**
- Medium rounded rectangle (Green)
- Title: "TicketNFT"
- Subtitle: "ERC-721 NFT Token"

**Internal Components:**

**Section 1: NFT Storage**
- Token Registry (NFT icon)
  : tokenId  ->  owner mapping
  : tokenId  ->  eventId mapping
  : tokenId  ->  metadata URI
- Burned Tokens Registry
  : tokenId  ->  isBurned mapping

**Section 2: Core Functions**
- mint() : only BlockTixMain
- batchMint() : only BlockTixMain
- burn()
- setTokenURI()
- transferFrom()
- approve()

**Section 3: Configuration**
- Base URI: https://blocktix.io/metadata/
- BlockTixMain Reference: address
- Owner: Platform Admin

**Connections (Arrows):**
- Incoming arrow from BlockTixMain (labeled "mint requests")
- Outgoing arrow to BlockTixMain (labeled "transfer notifications")
- Dotted line to IPFS (labeled "metadata storage")

---

### 2.3 PriceOracle Contract (Pricing Engine)

**Position:** Left side of BlockTixMain

**Visual Elements:**
- Medium rounded rectangle (Orange)
- Title: "PriceOracle"
- Subtitle: "Dynamic Pricing & Validation"

**Internal Components:**

**Section 1: Pricing Logic**
- Surge Pricing Algorithm
  : Threshold 1: 50% sold  ->  +5%
  : Threshold 2: 75% sold  ->  +10%
  : Threshold 3: 90% sold  ->  +20%
- Time Decay Algorithm
  : >7 days before event  ->  -5%
- Price History Storage
  : eventId  ->  PriceHistory[] array

**Section 2: Core Functions**
- calculatePrice()
- calculatePriceWithTimeDecay()
- validateResalePrice()
- setPricingParameters()

**Section 3: Configuration**
- Demand Multiplier: 10%
- Time Decay: 5%
- BlockTixMain Reference: address
- Owner: Platform Admin
- Pausable: Yes

**Connections (Arrows):**
- Incoming arrow from BlockTixMain (labeled "price requests")
- Outgoing arrow to BlockTixMain (labeled "calculated prices")

---

## 3. EXTERNAL ACTORS & INTERACTIONS

### 3.1 Event Organizer (User Icon with "Organizer" label)

**Position:** Top-left outside system boundary

**Interactions (Arrows pointing to BlockTixMain):**

1. **Create Event** (Solid arrow)
   : Input: Event details (name, tickets, price, date, markup limit)
   : Output: eventId
   : Flow: Organizer  ->  BlockTixMain.createEvent()

2. **Cancel Event** (Solid arrow)
   : Input: eventId
   : Output: Event marked inactive
   : Flow: Organizer  ->  BlockTixMain.cancelEvent()

3. **Use Ticket** (Solid arrow)
   : Input: ticketId
   : Output: Ticket marked as used
   : Flow: Organizer  ->  BlockTixMain.useTicket()

4. **Withdraw Funds** (Solid arrow with $ sign)
   : Input: None
   : Output: ETH transferred to organizer
   : Flow: Organizer  ->  BlockTixMain.withdraw()

---

### 3.2 Ticket Buyer (User Icon with "Buyer" label)

**Position:** Top-center outside system boundary

**Interactions (Arrows pointing to BlockTixMain):**

1. **Purchase Ticket** (Solid arrow with ETH symbol)
   : Input: eventId, payment (ETH)
   : Process Flow:
     : BlockTixMain  ->  PriceOracle (get price)
     : PriceOracle  ->  BlockTixMain (return price)
     : BlockTixMain  ->  TicketNFT (mint NFT)
     : TicketNFT  ->  Buyer (transfer NFT)
   : Output: ticketId, NFT ownership

2. **View Owned Tickets** (Dashed query arrow)
   : Input: buyer address
   : Output: List of ticket NFTs
   : Flow: Buyer  ->  TicketNFT.balanceOf() / ownerOf()

---

### 3.3 Ticket Reseller/Secondary Buyer (User Icon with "Reseller" label)

**Position:** Top-right outside system boundary

**Interactions (Arrows pointing to BlockTixMain):**

1. **Transfer/Resell Ticket** (Solid arrow with ETH symbol)
   : Input: ticketId, new owner, payment (ETH)
   : Process Flow:
     : Seller approves BlockTixMain
     : Buyer sends ETH to BlockTixMain
     : BlockTixMain validates markup limit
     : BlockTixMain  ->  TicketNFT (transfer NFT)
     : BlockTixMain distributes funds (seller + platform fee)
   : Output: Updated ownership, funds distributed

---

### 3.4 Platform Owner (Admin Icon)

**Position:** Bottom-left outside system boundary

**Interactions (Arrows pointing to all contracts):**

1. **Update Platform Fee** (Dashed admin arrow to BlockTixMain)
   : Input: New fee percentage
   : Output: Updated platform fee

2. **Update Pricing Parameters** (Dashed admin arrow to PriceOracle)
   : Input: New multipliers, thresholds
   : Output: Updated pricing logic

3. **Pause/Unpause Oracle** (Dashed admin arrow to PriceOracle)
   : Input: Pause command
   : Output: Oracle paused/unpaused

4. **Update Base URI** (Dashed admin arrow to TicketNFT)
   : Input: New base URI
   : Output: Updated metadata endpoint

5. **Withdraw Platform Fees** (Solid arrow with $ to BlockTixMain)
   : Input: None
   : Output: ETH transferred to platform owner

---

## 4. DATA FLOW DIAGRAMS

### 4.1 Event Creation Flow (Sequence Diagram)

**Participants (Left to Right):**
1. Organizer
2. BlockTixMain
3. Blockchain

**Flow (Top to Bottom with numbered arrows):**

1. **Organizer  ->  BlockTixMain:** `createEvent(name, totalTickets, basePrice, date, maxMarkup)`
2. **BlockTixMain:** Validate parameters
3. **BlockTixMain:** Store event in events mapping
4. **BlockTixMain:** Increment eventCount
5. **BlockTixMain  ->  Blockchain:** Emit EventCreated event
6. **BlockTixMain  ->  Organizer:** Return eventId

**Visual Notes:**
- Use numbered sequence arrows
- Show validation step as a decision diamond
- Show event emission as a broadcast icon

---

### 4.2 Ticket Purchase Flow (Detailed Sequence Diagram)

**Participants (Left to Right):**
1. Buyer
2. BlockTixMain
3. PriceOracle
4. TicketNFT
5. Organizer (receives funds)
6. Platform Owner (receives fees)

**Flow (Top to Bottom with numbered arrows):**

1. **Buyer  ->  BlockTixMain:** `purchaseTicket{value: payment}(eventId)`
2. **BlockTixMain:** Validate event is active
3. **BlockTixMain:** Check tickets not sold out
4. **BlockTixMain  ->  PriceOracle:** `calculatePrice(eventId, basePrice, ticketsSold)`
5. **PriceOracle:** Apply surge pricing logic
6. **PriceOracle  ->  BlockTixMain:** Return calculated price
7. **BlockTixMain:** Validate payment >= price
8. **BlockTixMain  ->  TicketNFT:** `mint(buyer, eventId)`
9. **TicketNFT:** Create new token
10. **TicketNFT  ->  Buyer:** Transfer NFT ownership
11. **TicketNFT  ->  BlockTixMain:** Return tokenId
12. **BlockTixMain:** Create ticket record
13. **BlockTixMain:** Calculate platform fee (2.5%)
14. **BlockTixMain:** Add organizer amount to pendingWithdrawals[organizer]
15. **BlockTixMain:** Add platform fee to pendingWithdrawals[owner]
16. **BlockTixMain:** Refund excess payment if any
17. **BlockTixMain  ->  Blockchain:** Emit TicketPurchased event
18. **BlockTixMain  ->  Buyer:** Return ticketId

**Visual Notes:**
- Use different colored arrows for different types of actions:
  : Blue: Data queries
  : Green: State changes
  : Red: Fund transfers
  : Orange: Event emissions
- Show decision diamonds for validations
- Show database icons for state updates

---

### 4.3 Ticket Resale Flow (Sequence Diagram)

**Participants (Left to Right):**
1. Seller (current ticket owner)
2. Buyer (new ticket owner)
3. BlockTixMain
4. TicketNFT
5. Platform Owner

**Flow (Top to Bottom with numbered arrows):**

1. **Seller  ->  TicketNFT:** `approve(BlockTixMain, ticketId)`
2. **Buyer  ->  BlockTixMain:** `transferTicket{value: resalePrice}(ticketId, buyer)`
3. **BlockTixMain:** Validate seller is current owner
4. **BlockTixMain:** Validate ticket not used
5. **BlockTixMain:** Validate event is active
6. **BlockTixMain:** Get event's maxResaleMarkup
7. **BlockTixMain:** Validate resalePrice <= originalPrice * (1 + maxMarkup)
8. **BlockTixMain:** Calculate platform fee
9. **BlockTixMain:** Add seller amount to pendingWithdrawals[seller]
10. **BlockTixMain:** Add platform fee to pendingWithdrawals[owner]
11. **BlockTixMain:** Update ticket ownership and price
12. **BlockTixMain  ->  TicketNFT:** `transferFrom(seller, buyer, ticketId)`
13. **TicketNFT:** Transfer NFT ownership
14. **BlockTixMain  ->  Blockchain:** Emit TicketTransferred event
15. **BlockTixMain  ->  Buyer:** Success

**Visual Notes:**
- Highlight the approval step (security measure)
- Show markup validation as a decision diamond with formula
- Show fund distribution with $ symbols

---

### 4.4 Withdrawal Flow (Simple Sequence Diagram)

**Participants (Left to Right):**
1. User (Organizer or Platform Owner)
2. BlockTixMain
3. User's Wallet

**Flow (Top to Bottom with numbered arrows):**

1. **User  ->  BlockTixMain:** `withdraw()`
2. **BlockTixMain:** Get pendingWithdrawals[user]
3. **BlockTixMain:** Validate amount > 0
4. **BlockTixMain:** Set pendingWithdrawals[user] = 0
5. **BlockTixMain  ->  User's Wallet:** Transfer ETH
6. **BlockTixMain:** Validate transfer success
7. **BlockTixMain  ->  Blockchain:** Emit WithdrawalProcessed event
8. **BlockTixMain  ->  User:** Success

**Visual Notes:**
- Show the "Checks-Effects-Interactions" pattern:
  : Check: Validate amount
  : Effect: Set balance to 0
  : Interaction: Transfer ETH
- Highlight reentrancy protection with a lock icon

---

## 5. STATE DIAGRAMS

### 5.1 Event Lifecycle State Diagram

**States (Circles):**

1. **[Initial]**  ->  No Event
2. **Active** (Green circle) : Event created, tickets available
3. **Sold Out** (Yellow circle) : All tickets sold
4. **Cancelled** (Red circle) : Event cancelled by organizer
5. **Completed** (Gray circle) : Event date passed

**Transitions (Arrows between states):**

- **No Event  ->  Active:** `createEvent()` called by organizer
- **Active  ->  Active:** Tickets being purchased (tickets remaining)
- **Active  ->  Sold Out:** Last ticket purchased
- **Active  ->  Cancelled:** `cancelEvent()` called by organizer
- **Sold Out  ->  Cancelled:** `cancelEvent()` called by organizer
- **Active  ->  Completed:** Event date passes
- **Sold Out  ->  Completed:** Event date passes

**Visual Notes:**
- Use different colors for each state
- Label each transition arrow with the triggering action
- Show conditions on arrows where applicable (e.g., "if ticketsSold == totalTickets")

---

### 5.2 Ticket Lifecycle State Diagram

**States (Circles):**

1. **[Initial]**  ->  Not Minted
2. **Owned** (Blue circle) : NFT owned by user, not used
3. **Listed for Resale** (Yellow circle) : Approved for transfer
4. **Used** (Green circle) : Ticket scanned/used at event
5. **Burned** (Gray circle) : NFT destroyed

**Transitions (Arrows between states):**

- **Not Minted  ->  Owned:** `purchaseTicket()` or `transferTicket()` creates NFT
- **Owned  ->  Owned:** Normal ownership (no changes)
- **Owned  ->  Listed for Resale:** Owner approves BlockTixMain
- **Listed for Resale  ->  Owned:** Approval revoked or ticket resold
- **Owned  ->  Used:** Organizer calls `useTicket()`
- **Used  ->  Used:** Permanent state (cannot revert)
- **Owned  ->  Burned:** `burn()` called
- **Used  ->  Burned:** `burn()` called after use

**Visual Notes:**
- Use icons: Ticket icon for Owned, Star for Used, Trash for Burned
- Show "Used" and "Burned" as terminal states (double circles)
- Label transitions with function names

---

## 6. PAYMENT FLOW DIAGRAM

### 6.1 Primary Sale Payment Distribution

**Visual Representation (Flow Chart):**

**Input:** Buyer pays 1 ETH for ticket

**Flow (Top to Bottom with boxes and arrows):**

1. **Payment Received** (Box: 1 ETH)
   ↓
2. **Calculate Platform Fee** (Diamond: 1 ETH × 2.5% = 0.025 ETH)
   ↓ (splits into two arrows)
3. **Split Payment:**
   : **Left Arrow:** Platform Fee  ->  0.025 ETH  ->  Platform Owner's Pending Withdrawals
   : **Right Arrow:** Organizer Amount  ->  0.975 ETH  ->  Organizer's Pending Withdrawals
   ↓
4. **Stored in Smart Contract** (Box: Pending Withdrawals Mapping)
   ↓
5. **Withdrawal Triggered** (Diamond: User calls withdraw())
   ↓
6. **ETH Transferred to User Wallet** (Box: Final destination)

**Visual Notes:**
- Use $ or ETH symbols to represent money
- Show percentages on split arrows
- Use different colors for different recipients
- Show the pending withdrawals as a temporary storage box

---

### 6.2 Secondary Sale (Resale) Payment Distribution

**Visual Representation (Flow Chart):**

**Input:** Buyer pays 1.2 ETH for resale ticket

**Flow:**

1. **Payment Received** (Box: 1.2 ETH)
   ↓
2. **Calculate Platform Fee** (Diamond: 1.2 ETH × 2.5% = 0.03 ETH)
   ↓ (splits into two arrows)
3. **Split Payment:**
   : **Left Arrow:** Platform Fee  ->  0.03 ETH  ->  Platform Owner's Pending Withdrawals
   : **Right Arrow:** Seller Amount  ->  1.17 ETH  ->  Seller's Pending Withdrawals
   ↓
4. **Note:** Original organizer gets no cut on resale
   ↓
5. **Stored in Smart Contract** (Box: Pending Withdrawals Mapping)
   ↓
6. **Withdrawal Triggered** (Diamond: User calls withdraw())
   ↓
7. **ETH Transferred to User Wallet** (Box: Final destination)

**Visual Notes:**
- Show markup validation before payment distribution
- Highlight that organizer does NOT receive funds on resale
- Use dotted line for "not included" organizer path

---

## 7. ACCESS CONTROL MATRIX

**Visual Representation (Table/Grid):**

**Columns:** Functions
**Rows:** Actor Types

| Function | Event Organizer | Ticket Buyer | Platform Owner | Anyone |
|----------|----------------|--------------|----------------|--------|
| createEvent() | | | | |
| purchaseTicket() | | | | |
| transferTicket() | (if owner) | (if owner) | (if owner) | (if owner) |
| useTicket() | (own events) | X | X | X |
| cancelEvent() | (own events) | X | X | X |
| withdraw() | (own funds) | (own funds) | (own funds) | (own funds) |
| updatePlatformFee() | X | X | | X |
| mint() | X | X | X | X (BlockTixMain only) |
| calculatePrice() | X | X | X | X (BlockTixMain only) |
| pause() | X | X | | X |

**Visual Notes:**
- Green checkmarks () for allowed
- Red X marks (X) for denied
- Add notes in parentheses for conditional access
- Highlight owner-only functions in a different color

---

## 8. EVENT EMISSION DIAGRAM

**Visual Representation (Event Tree):**

**BlockTixMain Events:**
-  EventCreated(eventId, organizer, name, totalTickets, basePrice, eventDate)
-  TicketPurchased(ticketId, eventId, buyer, price)
-  TicketTransferred(ticketId, from, to, price)
-  TicketUsed(ticketId, eventId)
-  EventCancelled(eventId)
-  WithdrawalProcessed(recipient, amount)
-  PlatformFeeUpdated(oldFee, newFee)

**TicketNFT Events:**
-  TicketMinted(tokenId, to, eventId)
-  TicketBurned(tokenId)
-  Transfer(from, to, tokenId) : ERC721 standard
-  Approval(owner, approved, tokenId) : ERC721 standard
-  BaseURIUpdated(newBaseURI)
-  BlockTixMainUpdated(oldAddress, newAddress)

**PriceOracle Events:**
-  PriceCalculated(eventId, price, ticketsSold)
-  DemandMultiplierUpdated(oldMultiplier, newMultiplier)
-  TimeDecayUpdated(oldDecay, newDecay)
-  SurgeMultipliersUpdated(surge1, surge2, surge3)
-  BlockTixMainUpdated(oldAddress, newAddress)
-  Paused(account) : Pausable standard
-  Unpaused(account) : Pausable standard

**Visual Notes:**
- Show events as broadcast icons
- Group events by contract
- Use different colors for different event types (state changes, transfers, admin actions)

---

## 9. SECURITY ARCHITECTURE

### 9.1 Security Layers Diagram

**Visual Representation (Layered Architecture):**

**Layer 1: Input Validation (Top Layer : Red)**
- Parameter validation (non-zero, non-empty)
- Address validation (not address(0))
- Date validation (future dates only)
- Amount validation (sufficient payment)

**Layer 2: Access Control (Second Layer : Orange)**
- Ownable pattern (platform admin functions)
- Function-level permissions (organizer-only, owner-only)
- Token ownership checks (NFT transfers)
- Custom modifiers (onlyBlockTixMain)

**Layer 3: Business Logic Protection (Third Layer : Yellow)**
- Event state validation (isActive)
- Ticket availability checks (not sold out)
- Markup limit enforcement (resale price validation)
- Ticket usage validation (not already used)

**Layer 4: Reentrancy Protection (Fourth Layer : Green)**
- ReentrancyGuard on state-changing functions
- Checks-Effects-Interactions pattern
- State updates before external calls

**Layer 5: Economic Security (Bottom Layer : Blue)**
- Pull payment pattern (withdraw instead of push)
- Platform fee limits (max 10%)
- Markup limits (configurable per event)
- Excess payment refunds

**Visual Notes:**
- Show as concentric circles or stacked layers
- Use different colors for each layer
- Add icons for each security measure

---

### 9.2 Attack Prevention Diagram

**Visual Representation (Threat  ->  Defense Table):**

| Threat | Defense Mechanism | Contract Location |
|--------|------------------|------------------|
| Reentrancy Attack | ReentrancyGuard | BlockTixMain |
| Integer Overflow/Underflow | Solidity 0.8.24 (built-in) | All contracts |
| Unauthorized Minting | onlyBlockTixMain modifier | TicketNFT |
| Unauthorized Price Manipulation | onlyBlockTixMain modifier | PriceOracle |
| Excessive Platform Fees | Max 10% validation | BlockTixMain |
| Price Manipulation on Resale | maxResaleMarkup validation | BlockTixMain |
| Front-running | Not fully mitigated (blockchain limitation) | N/A |
| DoS via Revert | Pull payment pattern | BlockTixMain |
| Unauthorized Admin Actions | Ownable pattern | All contracts |

**Visual Notes:**
- Use shield icons for defense mechanisms
- Use warning icons for threats
- Color-code by severity level

---

## 10. TECHNOLOGY STACK DIAGRAM

**Visual Representation (Layered Tech Stack):**

**Layer 1: Blockchain Infrastructure (Bottom)**
- Ethereum Network
- Sepolia Testnet (for testing)
- Anvil (local development)

**Layer 2: Smart Contract Layer**
- Solidity 0.8.24
- OpenZeppelin Contracts v5.x
  : ERC721
  : Ownable
  : ReentrancyGuard
  : Pausable

**Layer 3: Development Tools**
- Foundry Framework
  : forge (build, test)
  : cast (blockchain interaction)
  : anvil (local node)
- forge-std (testing library)

**Layer 4: Frontend (Future : shown as dashed)**
- Next.js
- wagmi
- viem
- TypeScript

**Layer 5: Metadata Storage**
- IPFS (decentralized storage)
- Base URI: https://blocktix.io/metadata/

**Layer 6: External Services**
- Alchemy/Infura (RPC providers)
- Etherscan (verification, block explorer)

**Visual Notes:**
- Show as a stack of boxes
- Use logos for each technology
- Show dependencies with arrows
- Use dashed lines for future/planned components

---

## 11. DEPLOYMENT ARCHITECTURE

**Visual Representation (Deployment Flow):**

**Development Environment:**
- Local Machine
  : Code Editor
  : Git Repository
  : Foundry Installation
  ↓
- Compilation (forge build)
  ↓
- Testing (forge test)
  ↓
- Local Deployment (anvil)

**Testnet Environment:**
- Sepolia Testnet
  : RPC Endpoint (Alchemy/Infura)
  : Test ETH (faucet)
  ↓
- Deploy Script Execution
  : Deploy PriceOracle
  : Deploy TicketNFT
  : Deploy BlockTixMain
  : Configure References
  ↓
- Verification
  : Etherscan API
  : Source Code Verification

**Mainnet Environment (Future):**
- Ethereum Mainnet
  : Production RPC Endpoint
  : Real ETH
  ↓
- Same deployment process
  ↓
- Production verification

**Visual Notes:**
- Use different background colors for each environment
- Show progression with large arrows
- Include icons for each service
- Add checkmarks for completed stages

---

## 12. CONTRACT DEPENDENCY GRAPH

**Visual Representation (Node Graph):**

**Nodes (Contracts/Libraries):**

1. **BlockTixMain** (Central node : Large circle)
   : Depends on: ITicketNFT, IPriceOracle, ReentrancyGuard, Ownable

2. **TicketNFT** (Right node : Medium circle)
   : Depends on: ERC721, ERC721URIStorage, Ownable

3. **PriceOracle** (Left node : Medium circle)
   : Depends on: Ownable, Pausable

4. **Interfaces** (Small circles around main nodes)
   : IBlockTix
   : ITicketNFT
   : IPriceOracle

5. **OpenZeppelin Libraries** (Bottom layer : Small circles)
   : ERC721
   : ERC721URIStorage
   : Ownable
   : ReentrancyGuard
   : Pausable

**Edges (Dependencies):**
- BlockTixMain  ->  ITicketNFT (solid arrow)
- BlockTixMain  ->  IPriceOracle (solid arrow)
- BlockTixMain  ->  ReentrancyGuard (dashed arrow : inheritance)
- BlockTixMain  ->  Ownable (dashed arrow : inheritance)
- TicketNFT  ->  ERC721URIStorage (dashed arrow : inheritance)
- TicketNFT  ->  Ownable (dashed arrow : inheritance)
- PriceOracle  ->  Ownable (dashed arrow : inheritance)
- PriceOracle  ->  Pausable (dashed arrow : inheritance)

**Visual Notes:**
- Use solid arrows for "uses/calls" relationships
- Use dashed arrows for "inherits from" relationships
- Size nodes based on complexity
- Group related nodes with colored backgrounds

---

## 13. DATA STORAGE ARCHITECTURE

**Visual Representation (Storage Layout):**

**BlockTixMain Storage:**
```
┌─────────────────────────────┐
│ State Variables              │
├─────────────────────────────┤
│ : eventCount: uint256        │
│ : platformFeePercentage      │
│ : ticketNFT: ITicketNFT     │
│ : priceOracle: IPriceOracle │
├─────────────────────────────┤
│ Mappings                    │
├─────────────────────────────┤
│ : events                    │
│   [eventId  ->  Event]         │
│ : tickets                   │
│   [ticketId  ->  Ticket]       │
│ : ticketToEvent            │
│   [ticketId  ->  eventId]     │
│ : pendingWithdrawals       │
│   [address  ->  amount]        │
└─────────────────────────────┘
```

**TicketNFT Storage:**
```
┌─────────────────────────────┐
│ ERC721 Inherited Storage    │
├─────────────────────────────┤
│ : _owners: mapping          │
│ : _balances: mapping        │
│ : _tokenApprovals: mapping  │
│ : _operatorApprovals: map   │
├─────────────────────────────┤
│ Custom Storage             │
├─────────────────────────────┤
│ : _tokenIdCounter: uint256  │
│ : blockTixMain: address     │
│ : _baseTokenURI: string     │
│ : tokenToEvent: mapping     │
│ : isBurned: mapping         │
└─────────────────────────────┘
```

**PriceOracle Storage:**
```
┌─────────────────────────────┐
│ State Variables             │
├─────────────────────────────┤
│ : demandMultiplier: uint256 │
│ : timeDecayBasisPoints      │
│ : blockTixMain: address     │
│ : surgeMultiplier1/2/3      │
├─────────────────────────────┤
│ Mappings                   │
├─────────────────────────────┤
│ : eventPriceHistory        │
│   [eventId  ->  History[]]    │
└─────────────────────────────┘
```

**Visual Notes:**
- Show storage as structured boxes
- Use tree structure for nested mappings
- Indicate inherited vs custom storage
- Show data types for clarity

---

## 14. GAS OPTIMIZATION DIAGRAM

**Visual Representation (Before/After Comparison):**

**Optimization Strategies:**

1. **Storage Packing**
   : Before: Multiple uint256 variables  ->  3 storage slots
   : After: Packed struct with uint128, uint64  ->  1 storage slot
   : Gas Saved: ~40,000 gas per deployment

2. **Batch Operations**
   : Before: mint() called 10 times  ->  10 transactions
   : After: batchMint(10) called once  ->  1 transaction
   : Gas Saved: ~30% on bulk operations

3. **Unchecked Arithmetic** (where safe)
   : Before: Checked arithmetic for loops
   : After: Unchecked counters in loops
   : Gas Saved: ~2,000 gas per loop

4. **Custom Errors**
   : Before: require() with string messages
   : After: Custom error types
   : Gas Saved: ~50 gas per revert

**Visual Notes:**
- Show side-by-side before/after code snippets
- Include gas cost numbers
- Use bar charts to show gas savings

---

## 15. FUTURE EXPANSION DIAGRAM

**Visual Representation (Roadmap Tree):**

**Current Version (v1.0 : Solid boxes):**
- BlockTixMain
- TicketNFT
- PriceOracle

**Planned Features (v2.0 : Dashed boxes):**
- **Dynamic NFT Metadata** (TicketNFT enhancement)
  : Ticket appearance changes after use
  : On-chain SVG generation

- **Multi-Token Support** (BlockTixMain enhancement)
  : Accept USDC, DAI for ticket purchases
  : Chainlink price feeds integration

- **Governance Module** (New contract)
  : DAO voting on platform parameters
  : Community-driven fee adjustments

- **Refund Mechanism** (BlockTixMain enhancement)
  : Automated refunds for cancelled events
  : Configurable refund windows

- **Royalty Distribution** (New feature)
  : Artists get % of resales
  : Programmable royalty splits

**Visual Notes:**
- Use dotted lines for "planned" features
- Show version numbers
- Connect new features to existing contracts they extend
- Use different colors for different feature types

---

## DIAGRAM COLOR SCHEME

**Recommended Colors:**
- **BlockTixMain:** Blue (#3B82F6)
- **TicketNFT:** Green (#10B981)
- **PriceOracle:** Orange (#F59E0B)
- **External Actors:** Gray (#6B7280)
- **Money/Payments:** Gold (#FCD34D)
- **Events/Logs:** Purple (#8B5CF6)
- **Admin Actions:** Red (#EF4444)
- **Success States:** Light Green (#86EFAC)
- **Error States:** Light Red (#FCA5A5)
- **Security:** Shield Blue (#1E40AF)

---

## DIAGRAM TOOLS RECOMMENDATIONS

**For Designer:**
- **Lucidchart** : Great for flowcharts and sequence diagrams
- **Draw.io (diagrams.net)** : Free, versatile
- **Miro** : Collaborative, good for complex architectures
- **Figma** : For polished, presentation-ready diagrams
- **PlantUML** : For code-based diagram generation
- **Excalidraw** : For hand-drawn style diagrams

---

## DIAGRAM DELIVERABLES

The designer should create:

1. **System Architecture Overview** : High-level view showing all components
2. **Contract Interaction Diagram** : Detailed contract relationships
3. **User Journey Flows** : One for each actor type
4. **Payment Flow Diagram** : Money movement visualization
5. **State Diagrams** : For events and tickets
6. **Security Architecture** : Layered security view
7. **Deployment Architecture** : Environment and deployment flow
8. **Technology Stack** : Tech layer visualization

Each diagram should be:
- **Clear and readable** at both high and low resolutions
- **Properly labeled** with all components named
- **Color-coded** consistently across all diagrams
- **Exportable** as PNG, SVG, and PDF formats
- **Documented** with a legend explaining symbols and colors

---

**End of Diagram Specification**
