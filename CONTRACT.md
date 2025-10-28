# BlockTix - Smart Contract API Documentation

**Version:** 1.0.0
**Solidity Version:** ^0.8.24
**License:** MIT

---

## Table of Contents

1. [Overview](#overview)
2. [Contract Architecture](#contract-architecture)
3. [BlockTixMain Contract](#blocktixmain-contract)
4. [TicketNFT Contract](#ticketnft-contract)
5. [PriceOracle Contract](#priceoracle-contract)
6. [Interfaces](#interfaces)
7. [Security Considerations](#security-considerations)
8. [Deployment Guide](#deployment-guide)

---

## Overview

BlockTix is a decentralized event ticketing platform built on Ethereum. The platform consists of three primary smart contracts that work together to provide a complete ticketing solution with dynamic pricing, NFT-based tickets, and configurable resale rules.

### Key Features

- **Event Management:** Organizers can create events with customizable parameters
- **NFT Tickets:** Each ticket is a unique ERC-721 token
- **Dynamic Pricing:** Surge pricing based on demand and time-based discounts
- **Resale Control:** Configurable markup limits on secondary sales
- **Platform Fees:** Automated fee distribution to organizers and platform
- **Access Control:** Role-based permissions for secure operations

---

## Contract Architecture

```
┌─────────────────┐
│  BlockTixMain   │ ◄──── Primary contract (Event & Ticket Management)
└────────┬────────┘
         │
         ├──────► ┌──────────────┐
         │        │  TicketNFT   │ ◄──── ERC-721 NFT for tickets
         │        └──────────────┘
         │
         └──────► ┌──────────────┐
                  │ PriceOracle  │ ◄──── Dynamic pricing engine
                  └──────────────┘
```

### Contract Dependencies

- **OpenZeppelin Contracts:** `ReentrancyGuard`, `Ownable`, `ERC721URIStorage`, `Pausable`
- **Custom Interfaces:** `ITicketNFT`, `IPriceOracle`, `IBlockTix`

---

## BlockTixMain Contract

**Address:** `contracts/src/BlockTixMain.sol`

### Description

The primary contract that manages event creation, ticket sales, transfers, and the overall ticketing ecosystem. It coordinates with TicketNFT for token management and PriceOracle for pricing calculations.

### Inheritance

```solidity
contract BlockTixMain is ReentrancyGuard, Ownable
```

- **ReentrancyGuard:** Protects against reentrancy attacks
- **Ownable:** Provides ownership and access control

---

### State Variables

#### Public State Variables

| Variable | Type | Description |
|----------|------|-------------|
| `ticketNFT` | `ITicketNFT` | Reference to the TicketNFT contract |
| `priceOracle` | `IPriceOracle` | Reference to the PriceOracle contract |
| `eventCount` | `uint256` | Total number of events created |
| `platformFeePercentage` | `uint256` | Platform fee in basis points (100 = 1%) |

#### Mappings

| Mapping | Type | Description |
|---------|------|-------------|
| `events` | `mapping(uint256 => Event)` | Event ID to Event data |
| `tickets` | `mapping(uint256 => Ticket)` | Ticket ID to Ticket data |
| `ticketToEvent` | `mapping(uint256 => uint256)` | Ticket ID to Event ID |
| `pendingWithdrawals` | `mapping(address => uint256)` | Address to pending withdrawal amount |

---

### Data Structures

#### Event Struct

```solidity
struct Event {
    uint256 eventId;           // Unique identifier for the event
    address organizer;         // Address of the event organizer
    string name;              // Name of the event
    uint256 totalTickets;     // Total tickets available
    uint256 ticketsSold;      // Number of tickets sold
    uint256 basePrice;        // Base price per ticket (wei)
    uint256 eventDate;        // Unix timestamp of event date
    bool isActive;            // Whether the event is active
    uint256 maxResaleMarkup;  // Maximum resale markup in basis points
}
```

#### Ticket Struct

```solidity
struct Ticket {
    uint256 ticketId;        // Unique identifier for the ticket
    uint256 eventId;         // Associated event ID
    address currentOwner;    // Current owner of the ticket
    uint256 purchasePrice;   // Price paid for the ticket
    bool isUsed;            // Whether the ticket has been used
}
```

---

### Events

#### EventCreated

```solidity
event EventCreated(
    uint256 indexed eventId,
    address indexed organizer,
    string name,
    uint256 totalTickets,
    uint256 basePrice,
    uint256 eventDate
)
```

**Emitted when:** A new event is created
**Parameters:**
- `eventId`: Unique identifier for the event
- `organizer`: Address of the event creator
- `name`: Event name
- `totalTickets`: Total number of available tickets
- `basePrice`: Base price per ticket in wei
- `eventDate`: Unix timestamp of event date

---

#### TicketPurchased

```solidity
event TicketPurchased(
    uint256 indexed ticketId,
    uint256 indexed eventId,
    address indexed buyer,
    uint256 price
)
```

**Emitted when:** A ticket is purchased
**Parameters:**
- `ticketId`: ID of the purchased ticket
- `eventId`: ID of the associated event
- `buyer`: Address of the purchaser
- `price`: Amount paid for the ticket

---

#### TicketTransferred

```solidity
event TicketTransferred(
    uint256 indexed ticketId,
    address indexed from,
    address indexed to,
    uint256 price
)
```

**Emitted when:** A ticket is transferred/resold
**Parameters:**
- `ticketId`: ID of the transferred ticket
- `from`: Address of the seller
- `to`: Address of the buyer
- `price`: Resale price

---

#### TicketUsed

```solidity
event TicketUsed(
    uint256 indexed ticketId,
    uint256 indexed eventId
)
```

**Emitted when:** A ticket is marked as used
**Parameters:**
- `ticketId`: ID of the used ticket
- `eventId`: Associated event ID

---

#### EventCancelled

```solidity
event EventCancelled(uint256 indexed eventId)
```

**Emitted when:** An event is cancelled
**Parameters:**
- `eventId`: ID of the cancelled event

---

#### WithdrawalProcessed

```solidity
event WithdrawalProcessed(
    address indexed recipient,
    uint256 amount
)
```

**Emitted when:** Funds are withdrawn
**Parameters:**
- `recipient`: Address receiving the funds
- `amount`: Amount withdrawn in wei

---

#### PlatformFeeUpdated

```solidity
event PlatformFeeUpdated(
    uint256 oldFee,
    uint256 newFee
)
```

**Emitted when:** Platform fee is updated
**Parameters:**
- `oldFee`: Previous fee percentage
- `newFee`: New fee percentage

---

### Custom Errors

```solidity
error InvalidEventId();          // Event ID does not exist
error InvalidTicketId();         // Ticket ID does not exist
error EventNotActive();          // Event has been cancelled
error SoldOut();                 // All tickets have been sold
error InsufficientPayment();     // Payment less than required
error NotTicketOwner();          // Caller is not the ticket owner
error TicketAlreadyUsed();       // Ticket has already been used
error ResaleMarkupExceeded();    // Resale price exceeds maximum markup
error NoWithdrawalAvailable();   // No funds available to withdraw
error WithdrawalFailed();        // Withdrawal transaction failed
error InvalidParameters();       // Invalid input parameters
```

---

### Functions

#### Constructor

```solidity
constructor(
    address _ticketNFT,
    address _priceOracle,
    uint256 _platformFee
)
```

**Description:** Initializes the contract with required dependencies
**Parameters:**
- `_ticketNFT`: Address of the TicketNFT contract
- `_priceOracle`: Address of the PriceOracle contract
- `_platformFee`: Initial platform fee in basis points

**Requirements:**
- `_ticketNFT` and `_priceOracle` must not be zero addresses

---

#### createEvent

```solidity
function createEvent(
    string calldata name,
    uint256 totalTickets,
    uint256 basePrice,
    uint256 eventDate,
    uint256 maxResaleMarkup
) external returns (uint256)
```

**Description:** Creates a new event
**Access:** Public
**Parameters:**
- `name`: Event name
- `totalTickets`: Total number of tickets available
- `basePrice`: Base price per ticket in wei
- `eventDate`: Unix timestamp of event date
- `maxResaleMarkup`: Maximum allowed resale markup in basis points

**Returns:** `uint256` - Event ID

**Requirements:**
- `totalTickets` > 0
- `basePrice` > 0
- `eventDate` > current timestamp

**Emits:** `EventCreated`

---

#### purchaseTicket

```solidity
function purchaseTicket(uint256 eventId)
    external
    payable
    nonReentrant
    returns (uint256)
```

**Description:** Purchases a ticket for an event
**Access:** Public (payable)
**State Modifying:** Yes
**Parameters:**
- `eventId`: ID of the event

**Returns:** `uint256` - Ticket ID

**Requirements:**
- Event must exist
- Event must be active
- Tickets must be available
- Payment must be sufficient (calculated via PriceOracle)

**Effects:**
- Mints NFT ticket to buyer
- Increments `ticketsSold`
- Distributes fees to organizer and platform
- Refunds excess payment

**Emits:** `TicketPurchased`

---

#### transferTicket

```solidity
function transferTicket(
    uint256 ticketId,
    address to
) external payable nonReentrant
```

**Description:** Transfers/resells a ticket to another address
**Access:** Public (payable)
**State Modifying:** Yes
**Parameters:**
- `ticketId`: ID of the ticket to transfer
- `to`: Address of the new owner

**Requirements:**
- Caller must be current ticket owner
- Ticket must not be used
- Event must be active
- Resale price must not exceed maximum markup

**Effects:**
- Updates ticket ownership
- Distributes fees to seller and platform
- Transfers NFT to new owner

**Emits:** `TicketTransferred`

---

#### useTicket

```solidity
function useTicket(uint256 ticketId) external
```

**Description:** Marks a ticket as used
**Access:** Event organizer only
**State Modifying:** Yes
**Parameters:**
- `ticketId`: ID of the ticket to mark as used

**Requirements:**
- Caller must be event organizer
- Ticket must not already be used

**Effects:**
- Sets `ticket.isUsed` to `true`

**Emits:** `TicketUsed`

---

#### cancelEvent

```solidity
function cancelEvent(uint256 eventId) external
```

**Description:** Cancels an event
**Access:** Event organizer only
**State Modifying:** Yes
**Parameters:**
- `eventId`: ID of the event to cancel

**Requirements:**
- Caller must be event organizer
- Event must exist

**Effects:**
- Sets `event.isActive` to `false`

**Emits:** `EventCancelled`

---

#### withdraw

```solidity
function withdraw() external nonReentrant
```

**Description:** Withdraws accumulated funds
**Access:** Public
**State Modifying:** Yes
**Parameters:** None

**Requirements:**
- Caller must have pending withdrawals > 0

**Effects:**
- Transfers all pending funds to caller
- Resets pending withdrawals to 0

**Emits:** `WithdrawalProcessed`

---

#### updatePlatformFee

```solidity
function updatePlatformFee(uint256 newFee) external onlyOwner
```

**Description:** Updates the platform fee percentage
**Access:** Owner only
**State Modifying:** Yes
**Parameters:**
- `newFee`: New fee in basis points

**Requirements:**
- `newFee` ≤ 1000 (max 10%)

**Emits:** `PlatformFeeUpdated`

---

#### getEvent (View)

```solidity
function getEvent(uint256 eventId)
    external
    view
    returns (Event memory)
```

**Description:** Retrieves event details
**Access:** Public (view)
**Parameters:**
- `eventId`: ID of the event

**Returns:** `Event` struct

**Requirements:**
- Event must exist

---

#### getTicket (View)

```solidity
function getTicket(uint256 ticketId)
    external
    view
    returns (Ticket memory)
```

**Description:** Retrieves ticket details
**Access:** Public (view)
**Parameters:**
- `ticketId`: ID of the ticket

**Returns:** `Ticket` struct

---

## TicketNFT Contract

**Address:** `contracts/src/TicketNFT.sol`

### Description

ERC-721 compliant NFT contract representing event tickets. Each ticket is a unique non-fungible token with associated metadata.

### Inheritance

```solidity
contract TicketNFT is ERC721URIStorage, Ownable
```

- **ERC721URIStorage:** OpenZeppelin's ERC-721 with URI storage
- **Ownable:** Provides ownership and access control

---

### State Variables

| Variable | Type | Description |
|----------|------|-------------|
| `blockTixMain` | `address` | Address of BlockTixMain contract |
| `_tokenIdCounter` | `uint256` | Counter for token IDs (private) |
| `_baseTokenURI` | `string` | Base URI for token metadata (private) |

#### Mappings

| Mapping | Type | Description |
|---------|------|-------------|
| `tokenToEvent` | `mapping(uint256 => uint256)` | Token ID to Event ID |
| `isBurned` | `mapping(uint256 => bool)` | Token ID to burned status |

---

### Events

#### TicketMinted

```solidity
event TicketMinted(
    uint256 indexed tokenId,
    address indexed to,
    uint256 indexed eventId
)
```

**Emitted when:** A new ticket NFT is minted

---

#### TicketBurned

```solidity
event TicketBurned(uint256 indexed tokenId)
```

**Emitted when:** A ticket NFT is burned

---

#### BaseURIUpdated

```solidity
event BaseURIUpdated(string newBaseURI)
```

**Emitted when:** Base URI is updated

---

#### BlockTixMainUpdated

```solidity
event BlockTixMainUpdated(
    address indexed oldAddress,
    address indexed newAddress
)
```

**Emitted when:** BlockTixMain address is updated

---

### Custom Errors

```solidity
error OnlyBlockTixMain();      // Caller is not BlockTixMain
error TokenAlreadyBurned();    // Token has been burned
error InvalidAddress();        // Invalid address provided
```

---

### Functions

#### Constructor

```solidity
constructor(
    address initialOwner,
    address _blockTixMain,
    string memory baseURI
)
```

**Description:** Initializes the NFT contract
**Parameters:**
- `initialOwner`: Address of the contract owner
- `_blockTixMain`: Address of BlockTixMain contract
- `baseURI`: Base URI for token metadata

**Requirements:**
- `_blockTixMain` must not be zero address

---

#### mint

```solidity
function mint(address to, uint256 eventId)
    external
    onlyBlockTixMain
    returns (uint256)
```

**Description:** Mints a new ticket NFT
**Access:** BlockTixMain only
**Parameters:**
- `to`: Address to mint the ticket to
- `eventId`: Associated event ID

**Returns:** `uint256` - Token ID

**Effects:**
- Increments token counter
- Mints NFT to specified address
- Records event association

**Emits:** `TicketMinted`

---

#### batchMint

```solidity
function batchMint(
    address to,
    uint256 eventId,
    uint256 amount
) external onlyBlockTixMain returns (uint256[] memory)
```

**Description:** Mints multiple tickets in batch
**Access:** BlockTixMain only
**Parameters:**
- `to`: Address to mint tickets to
- `eventId`: Associated event ID
- `amount`: Number of tickets to mint

**Returns:** `uint256[]` - Array of token IDs

**Emits:** `TicketMinted` (for each token)

---

#### burn

```solidity
function burn(uint256 tokenId) external
```

**Description:** Burns a ticket NFT
**Access:** Token owner or BlockTixMain
**Parameters:**
- `tokenId`: ID of the token to burn

**Requirements:**
- Caller must be token owner or BlockTixMain
- Token must not already be burned

**Effects:**
- Marks token as burned
- Burns the NFT

**Emits:** `TicketBurned`

---

#### setTokenURI

```solidity
function setTokenURI(uint256 tokenId, string memory uri)
    external
    onlyBlockTixMain
```

**Description:** Sets metadata URI for a token
**Access:** BlockTixMain only
**Parameters:**
- `tokenId`: Token ID
- `uri`: Metadata URI

---

#### setBaseURI

```solidity
function setBaseURI(string memory newBaseURI)
    external
    onlyOwner
```

**Description:** Updates the base URI
**Access:** Owner only
**Parameters:**
- `newBaseURI`: New base URI

**Emits:** `BaseURIUpdated`

---

#### setBlockTixMain

```solidity
function setBlockTixMain(address newBlockTixMain)
    external
    onlyOwner
```

**Description:** Updates BlockTixMain contract address
**Access:** Owner only
**Parameters:**
- `newBlockTixMain`: New BlockTixMain address

**Requirements:**
- Address must not be zero

**Emits:** `BlockTixMainUpdated`

---

#### getEventId (View)

```solidity
function getEventId(uint256 tokenId)
    external
    view
    returns (uint256)
```

**Description:** Gets the event ID for a token
**Parameters:**
- `tokenId`: Token ID

**Returns:** `uint256` - Event ID

---

#### getCurrentTokenId (View)

```solidity
function getCurrentTokenId()
    external
    view
    returns (uint256)
```

**Description:** Gets the current token ID counter
**Returns:** `uint256` - Current counter value

---

#### exists (View)

```solidity
function exists(uint256 tokenId)
    external
    view
    returns (bool)
```

**Description:** Checks if a token exists and is not burned
**Parameters:**
- `tokenId`: Token ID

**Returns:** `bool` - True if token exists and is not burned

---

## PriceOracle Contract

**Address:** `contracts/src/PriceOracle.sol`

### Description

Dynamic pricing oracle that calculates ticket prices based on demand (surge pricing) and time (early bird discounts). Also validates resale prices against markup limits.

### Inheritance

```solidity
contract PriceOracle is Ownable, Pausable
```

- **Ownable:** Provides ownership and access control
- **Pausable:** Emergency pause functionality

---

### State Variables

#### Public Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `SURGE_THRESHOLD_1` | 50 | First surge threshold (50% sold) |
| `SURGE_THRESHOLD_2` | 75 | Second surge threshold (75% sold) |
| `SURGE_THRESHOLD_3` | 90 | Third surge threshold (90% sold) |

#### Public State Variables

| Variable | Type | Description |
|----------|------|-------------|
| `blockTixMain` | `address` | Address of BlockTixMain contract |
| `demandMultiplierBasisPoints` | `uint256` | Demand multiplier in basis points |
| `timeDecayBasisPoints` | `uint256` | Time-based discount in basis points |
| `surgeMultiplier1` | `uint256` | Surge multiplier for 50% threshold (default: 500 = 5%) |
| `surgeMultiplier2` | `uint256` | Surge multiplier for 75% threshold (default: 1000 = 10%) |
| `surgeMultiplier3` | `uint256` | Surge multiplier for 90% threshold (default: 2000 = 20%) |

#### Mappings

| Mapping | Type | Description |
|---------|------|-------------|
| `eventPriceHistory` | `mapping(uint256 => PriceHistory[])` | Event ID to price history array |

---

### Data Structures

#### PriceHistory Struct

```solidity
struct PriceHistory {
    uint256 timestamp;    // Time of price calculation
    uint256 price;       // Calculated price
    uint256 ticketsSold; // Number of tickets sold
}
```

---

### Events

#### PriceCalculated

```solidity
event PriceCalculated(
    uint256 indexed eventId,
    uint256 price,
    uint256 ticketsSold
)
```

**Emitted when:** A price is calculated

---

#### DemandMultiplierUpdated

```solidity
event DemandMultiplierUpdated(
    uint256 oldMultiplier,
    uint256 newMultiplier
)
```

**Emitted when:** Demand multiplier is updated

---

#### TimeDecayUpdated

```solidity
event TimeDecayUpdated(
    uint256 oldDecay,
    uint256 newDecay
)
```

**Emitted when:** Time decay is updated

---

#### SurgeMultipliersUpdated

```solidity
event SurgeMultipliersUpdated(
    uint256 surge1,
    uint256 surge2,
    uint256 surge3
)
```

**Emitted when:** Surge multipliers are updated

---

#### BlockTixMainUpdated

```solidity
event BlockTixMainUpdated(
    address indexed oldAddress,
    address indexed newAddress
)
```

**Emitted when:** BlockTixMain address is updated

---

### Custom Errors

```solidity
error OnlyBlockTixMain();   // Caller is not BlockTixMain
error InvalidParameters();  // Invalid input parameters
error InvalidAddress();     // Invalid address provided
```

---

### Functions

#### Constructor

```solidity
constructor(
    address initialOwner,
    address _blockTixMain,
    uint256 _demandMultiplier,
    uint256 _timeDecay
)
```

**Description:** Initializes the price oracle
**Parameters:**
- `initialOwner`: Contract owner address
- `_blockTixMain`: BlockTixMain contract address
- `_demandMultiplier`: Initial demand multiplier in basis points
- `_timeDecay`: Initial time decay in basis points

**Requirements:**
- `_blockTixMain` must not be zero address

---

#### calculatePrice

```solidity
function calculatePrice(
    uint256 eventId,
    uint256 basePrice,
    uint256 ticketsSold
) external whenNotPaused onlyBlockTixMain returns (uint256)
```

**Description:** Calculates dynamic price based on demand
**Access:** BlockTixMain only
**Parameters:**
- `eventId`: Event ID
- `basePrice`: Base ticket price
- `ticketsSold`: Number of tickets sold

**Returns:** `uint256` - Calculated price in wei

**Pricing Logic:**
- No tickets sold (< 50%): Base price
- 50-74% sold: Base price + 5%
- 75-89% sold: Base price + 10%
- 90%+ sold: Base price + 20%

**Effects:**
- Records price in history

**Emits:** `PriceCalculated`

---

#### calculatePriceWithTimeDecay

```solidity
function calculatePriceWithTimeDecay(
    uint256 eventId,
    uint256 basePrice,
    uint256 ticketsSold,
    uint256 totalTickets,
    uint256 eventDate
) external whenNotPaused onlyBlockTixMain returns (uint256)
```

**Description:** Calculates price with surge pricing and time-based discounts
**Access:** BlockTixMain only
**Parameters:**
- `eventId`: Event ID
- `basePrice`: Base ticket price
- `ticketsSold`: Tickets sold
- `totalTickets`: Total tickets available
- `eventDate`: Event date timestamp

**Returns:** `uint256` - Calculated price

**Pricing Logic:**
1. Apply surge pricing based on % sold
2. If event > 1 week away, apply time decay discount

**Emits:** `PriceCalculated`

---

#### validateResalePrice

```solidity
function validateResalePrice(
    uint256 originalPrice,
    uint256 resalePrice,
    uint256 maxMarkupBasisPoints
) external pure returns (bool)
```

**Description:** Validates resale price against markup limit
**Access:** Public (pure)
**Parameters:**
- `originalPrice`: Original purchase price
- `resalePrice`: Proposed resale price
- `maxMarkupBasisPoints`: Maximum allowed markup

**Returns:** `bool` - True if valid

**Validation:**
- `resalePrice ≤ originalPrice + (originalPrice * maxMarkup / 10000)`

---

#### setDemandMultiplier

```solidity
function setDemandMultiplier(uint256 newMultiplier)
    external
    onlyOwner
```

**Description:** Updates demand multiplier
**Access:** Owner only
**Parameters:**
- `newMultiplier`: New multiplier in basis points

**Requirements:**
- `newMultiplier` ≤ 5000 (max 50%)

**Emits:** `DemandMultiplierUpdated`

---

#### setTimeDecay

```solidity
function setTimeDecay(uint256 newDecay)
    external
    onlyOwner
```

**Description:** Updates time decay percentage
**Access:** Owner only
**Parameters:**
- `newDecay`: New decay in basis points

**Requirements:**
- `newDecay` ≤ 5000 (max 50%)

**Emits:** `TimeDecayUpdated`

---

#### setSurgeMultipliers

```solidity
function setSurgeMultipliers(
    uint256 _surge1,
    uint256 _surge2,
    uint256 _surge3
) external onlyOwner
```

**Description:** Updates all surge multipliers
**Access:** Owner only
**Parameters:**
- `_surge1`: Multiplier for 50% threshold
- `_surge2`: Multiplier for 75% threshold
- `_surge3`: Multiplier for 90% threshold

**Requirements:**
- `_surge1 ≤ _surge2 ≤ _surge3` (ascending order)

**Emits:** `SurgeMultipliersUpdated`

---

#### setBlockTixMain

```solidity
function setBlockTixMain(address newBlockTixMain)
    external
    onlyOwner
```

**Description:** Updates BlockTixMain address
**Access:** Owner only
**Parameters:**
- `newBlockTixMain`: New address

**Requirements:**
- Address must not be zero

**Emits:** `BlockTixMainUpdated`

---

#### pause

```solidity
function pause() external onlyOwner
```

**Description:** Pauses the contract (emergency)
**Access:** Owner only

---

#### unpause

```solidity
function unpause() external onlyOwner
```

**Description:** Unpauses the contract
**Access:** Owner only

---

#### getPriceHistory (View)

```solidity
function getPriceHistory(uint256 eventId)
    external
    view
    returns (PriceHistory[] memory)
```

**Description:** Gets price history for an event
**Parameters:**
- `eventId`: Event ID

**Returns:** `PriceHistory[]` - Array of price records

---

#### getLatestPrice (View)

```solidity
function getLatestPrice(uint256 eventId)
    external
    view
    returns (uint256)
```

**Description:** Gets the most recent price for an event
**Parameters:**
- `eventId`: Event ID

**Returns:** `uint256` - Latest price (0 if no history)

---

## Interfaces

### IBlockTix

Defines the public interface for BlockTixMain contract.

**Location:** `contracts/src/interfaces/IBlockTix.sol`

### ITicketNFT

Defines the public interface for TicketNFT contract, extending IERC721.

**Location:** `contracts/src/interfaces/ITicketNFT.sol`

### IPriceOracle

Defines the public interface for PriceOracle contract.

**Location:** `contracts/src/interfaces/IPriceOracle.sol`

---

## Security Considerations

### Access Control

- **Owner Functions:** Only contract owner can update critical parameters
- **Organizer Functions:** Only event organizers can cancel events and use tickets
- **BlockTixMain Functions:** Only BlockTixMain can mint/burn NFTs and calculate prices

### Reentrancy Protection

- All state-changing functions with external calls use `nonReentrant` modifier
- Follows Checks-Effects-Interactions pattern

### Pull Payment Pattern

- Withdrawals use pull pattern to prevent reentrancy
- Funds held in `pendingWithdrawals` mapping

### Input Validation

- All functions validate input parameters
- Custom errors for gas-efficient reverts

### Emergency Controls

- PriceOracle has pause functionality
- Event cancellation available to organizers

### Upgrade Considerations

- Contracts can update references to each other
- Owner can reassign BlockTixMain address

---

## Deployment Guide

### Deployment Order

1. **Deploy PriceOracle**
   - Set owner, temporary BlockTixMain (address(1)), demand multiplier, time decay

2. **Deploy TicketNFT**
   - Set owner, temporary BlockTixMain (address(1)), base URI

3. **Deploy BlockTixMain**
   - Set TicketNFT address, PriceOracle address, platform fee

4. **Configure Cross-References**
   - `TicketNFT.setBlockTixMain(BlockTixMain address)`
   - `PriceOracle.setBlockTixMain(BlockTixMain address)`

### Configuration Parameters

| Parameter | Recommended Value | Description |
|-----------|------------------|-------------|
| Platform Fee | 250 bp (2.5%) | Platform commission |
| Demand Multiplier | 1000 bp (10%) | Base demand increase |
| Time Decay | 500 bp (5%) | Early bird discount |
| Surge Multiplier 1 | 500 bp (5%) | 50% sold surge |
| Surge Multiplier 2 | 1000 bp (10%) | 75% sold surge |
| Surge Multiplier 3 | 2000 bp (20%) | 90% sold surge |
| Base URI | `https://blocktix.io/metadata/` | NFT metadata base |

### Gas Estimates

| Operation | Estimated Gas |
|-----------|--------------|
| Deploy PriceOracle | ~940,000 |
| Deploy TicketNFT | ~1,614,000 |
| Deploy BlockTixMain | ~1,480,000 |
| Create Event | ~200,000 |
| Purchase Ticket | ~500,000 |
| Transfer Ticket | ~250,000 |

---

## Version History

- **v1.0.0** (2025-10-28): Initial release with core functionality

---

**Documentation Last Updated:** 2025-10-28
**Solidity Version:** ^0.8.24
**OpenZeppelin Version:** v5.x
