# BlockTix Live Demo

This demo showcases the BlockTix decentralized ticketing platform in action on a local Anvil testnet.

## Prerequisites

1. **Start Anvil** in a separate terminal:
   ```bash
   anvil
   ```
   Keep this running throughout the demo!

2. **Navigate to contracts directory**:
   ```bash
   cd contracts
   ```

---

## Demo Setup

### Deployed Contract Addresses (from Phase 5.2)
```bash
export BLOCKTIX=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
export TICKET_NFT=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
export PRICE_ORACLE=0x5FbDB2315678afecb367f032d93F642f64180aa3
export RPC_URL=http://localhost:8545
```

### Anvil Test Accounts
```bash
# Organizer (Account 0)
export ORGANIZER=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
export ORGANIZER_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Buyer 1 (Account 1)
export BUYER1=0x70997970C51812dc3A010C7d01b50e0d17dc79C8
export BUYER1_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

# Buyer 2 (Account 2)
export BUYER2=0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
export BUYER2_KEY=0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a

# Buyer 3 (Account 3)
export BUYER3=0x90F79bf6EB2c4f870365E785982E1f101E93b906
export BUYER3_KEY=0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6
```

---

##  DEMO SCENARIO: "BlockTix Concert 2025"

### Step 1: Create an Event 

**Organizer creates a concert event with 100 tickets**

```bash
cast send $BLOCKTIX \
  "createEvent(string,uint256,uint256,uint256,uint256)" \
  "BlockTix Concert 2025" \
  100 \
  1000000000000000000 \
  $(($(date +%s) + 2592000)) \
  2000 \
  --rpc-url $RPC_URL \
  --private-key $ORGANIZER_KEY
```

**Parameters explained:**
- Event name: "BlockTix Concert 2025"
- Total tickets: 100
- Base price: 1 ETH (1000000000000000000 wei)
- Event date: 30 days from now
- Max resale markup: 2000 basis points (20%)

**Verify event creation:**
```bash
cast call $BLOCKTIX "eventCount()" --rpc-url $RPC_URL
# Should return: 1

cast call $BLOCKTIX "getEvent(uint256)" 0 --rpc-url $RPC_URL
# Returns event details
```

---

### Step 2: Initial Ticket Purchases 

#### Buyer 1 purchases first ticket (No surge pricing)

```bash
cast send $BLOCKTIX \
  "purchaseTicket(uint256)" \
  0 \
  --value 1ether \
  --rpc-url $RPC_URL \
  --private-key $BUYER1_KEY
```

**Verify purchase:**
```bash
# Check ticket ownership
cast call $TICKET_NFT "ownerOf(uint256)" 0 --rpc-url $RPC_URL
# Should return Buyer1's address

# Check event tickets sold
cast call $BLOCKTIX "getEvent(uint256)" 0 --rpc-url $RPC_URL | grep -A 10 "ticketsSold"
# Should show 1 ticket sold
```

#### Buyer 2 purchases second ticket (Still no surge)

```bash
cast send $BLOCKTIX \
  "purchaseTicket(uint256)" \
  0 \
  --value 1ether \
  --rpc-url $RPC_URL \
  --private-key $BUYER2_KEY
```

---

### Step 3: Demonstrate Dynamic Pricing 

**Let's buy enough tickets to trigger surge pricing thresholds:**

#### Purchase tickets 3-49 (approaching 50% threshold)

```bash
# Quick loop to buy 47 more tickets with Buyer 3
for i in {1..47}; do
  cast send $BLOCKTIX \
    "purchaseTicket(uint256)" \
    0 \
    --value 1.1ether \
    --rpc-url $RPC_URL \
    --private-key $BUYER3_KEY > /dev/null 2>&1
  echo "Purchased ticket #$((i+2))"
done
```

**Check tickets sold:**
```bash
cast call $BLOCKTIX "getEvent(uint256)" 0 --rpc-url $RPC_URL
# Should show 49 tickets sold
```

#### Purchase ticket #50 (Triggers 5% surge pricing!)

```bash
# Calculate expected price with 5% surge
# Base price: 1 ETH
# 50% sold = 5% surge = 1.05 ETH

cast send $BLOCKTIX \
  "purchaseTicket(uint256)" \
  0 \
  --value 1.05ether \
  --rpc-url $RPC_URL \
  --private-key $BUYER3_KEY

echo " Purchased at 50% threshold : 5% surge pricing applied!"
```

**Check price from oracle:**
```bash
cast call $PRICE_ORACLE "calculatePrice(uint256,uint256,uint256)" 0 1000000000000000000 50 \
  --rpc-url $RPC_URL
# Returns: 1050000000000000000 (1.05 ETH)
```

#### Purchase more tickets to reach 75% threshold

```bash
# Buy 25 more tickets to reach 75%
for i in {1..25}; do
  cast send $BLOCKTIX \
    "purchaseTicket(uint256)" \
    0 \
    --value 1.15ether \
    --rpc-url $RPC_URL \
    --private-key $BUYER3_KEY > /dev/null 2>&1
  echo "Purchased ticket #$((i+50))"
done

echo " Reached 75% : 10% surge pricing now active!"
```

**Verify 10% surge pricing:**
```bash
cast call $PRICE_ORACLE "calculatePrice(uint256,uint256,uint256)" 0 1000000000000000000 75 \
  --rpc-url $RPC_URL
# Returns: 1100000000000000000 (1.10 ETH)
```

#### Purchase more to reach 90% threshold

```bash
# Buy 15 more tickets to reach 90%
for i in {1..15}; do
  cast send $BLOCKTIX \
    "purchaseTicket(uint256)" \
    0 \
    --value 1.25ether \
    --rpc-url $RPC_URL \
    --private-key $BUYER3_KEY > /dev/null 2>&1
  echo "Purchased ticket #$((i+75))"
done

echo " Reached 90% : 20% surge pricing now active!"
```

**Verify 20% surge pricing:**
```bash
cast call $PRICE_ORACLE "calculatePrice(uint256,uint256,uint256)" 0 1000000000000000000 90 \
  --rpc-url $RPC_URL
# Returns: 1200000000000000000 (1.20 ETH)
```

---

### Step 4: Ticket Resale/Transfer 

**Buyer 1 resells their ticket (Ticket #0) to a new buyer within the 20% markup limit**

#### First, Buyer 1 approves BlockTix contract to transfer the NFT

```bash
cast send $TICKET_NFT \
  "approve(address,uint256)" \
  $BLOCKTIX \
  0 \
  --rpc-url $RPC_URL \
  --private-key $BUYER1_KEY

echo " Buyer1 approved BlockTix to transfer ticket #0"
```

#### Buyer 1 transfers ticket to Buyer 2 for 1.2 ETH (20% markup)

```bash
# Original price: 1 ETH
# Resale price: 1.2 ETH (20% markup : at the limit)

cast send $BLOCKTIX \
  "transferTicket(uint256,address)" \
  0 \
  $BUYER2 \
  --value 1.2ether \
  --rpc-url $RPC_URL \
  --private-key $BUYER1_KEY

echo " Ticket #0 resold from Buyer1 to Buyer2 for 1.2 ETH"
```

**Verify the transfer:**
```bash
# Check new owner
cast call $TICKET_NFT "ownerOf(uint256)" 0 --rpc-url $RPC_URL
# Should return Buyer2's address

# Check ticket details
cast call $BLOCKTIX "getTicket(uint256)" 0 --rpc-url $RPC_URL
# Shows updated owner and purchase price
```

#### Demonstrate markup limit enforcement

**Try to resell at 25% markup (should fail):**
```bash
# Buyer2 tries to resell at 1.5 ETH (50% markup from original 1 ETH : exceeds 20% limit)

cast send $TICKET_NFT \
  "approve(address,uint256)" \
  $BLOCKTIX \
  0 \
  --rpc-url $RPC_URL \
  --private-key $BUYER2_KEY

cast send $BLOCKTIX \
  "transferTicket(uint256,address)" \
  0 \
  $BUYER3 \
  --value 1.5ether \
  --rpc-url $RPC_URL \
  --private-key $BUYER2_KEY

echo "X This should fail: ResaleMarkupExceeded"
```

---

### Step 5: Fee Distribution & Withdrawals 

**Platform fees (2.5%) are distributed to organizer and platform owner**

#### Check pending withdrawals

```bash
echo "Organizer pending withdrawal:"
cast call $BLOCKTIX "pendingWithdrawals(address)" $ORGANIZER --rpc-url $RPC_URL

echo "Buyer1 pending withdrawal (from resale):"
cast call $BLOCKTIX "pendingWithdrawals(address)" $BUYER1 --rpc-url $RPC_URL
```

#### Organizer withdraws their earnings

```bash
# Check balance before
echo "Organizer balance before withdrawal:"
cast balance $ORGANIZER --rpc-url $RPC_URL

# Withdraw
cast send $BLOCKTIX \
  "withdraw()" \
  --rpc-url $RPC_URL \
  --private-key $ORGANIZER_KEY

echo " Organizer withdrew funds"

# Check balance after
echo "Organizer balance after withdrawal:"
cast balance $ORGANIZER --rpc-url $RPC_URL
```

#### Buyer1 withdraws resale earnings

```bash
# Check balance before
echo "Buyer1 balance before withdrawal:"
cast balance $BUYER1 --rpc-url $RPC_URL

# Withdraw
cast send $BLOCKTIX \
  "withdraw()" \
  --rpc-url $RPC_URL \
  --private-key $BUYER1_KEY

echo " Buyer1 withdrew resale earnings"

# Check balance after
echo "Buyer1 balance after withdrawal:"
cast balance $BUYER1 --rpc-url $RPC_URL
```

---

### Step 6: Ticket Usage (Check-in) 

**Organizer marks a ticket as used (simulating event check-in)**

```bash
cast send $BLOCKTIX \
  "useTicket(uint256)" \
  0 \
  --rpc-url $RPC_URL \
  --private-key $ORGANIZER_KEY

echo " Ticket #0 marked as used"
```

**Verify ticket is used:**
```bash
cast call $BLOCKTIX "getTicket(uint256)" 0 --rpc-url $RPC_URL
# isUsed should be true
```

**Try to use the same ticket again (should fail):**
```bash
cast send $BLOCKTIX \
  "useTicket(uint256)" \
  0 \
  --rpc-url $RPC_URL \
  --private-key $ORGANIZER_KEY

echo "X This should fail: TicketAlreadyUsed"
```

---

##  Demo Summary

**What We Demonstrated:**

1.  **Event Creation** : Organizer created concert with 100 tickets at 1 ETH base price
2.  **Ticket Purchasing** : Multiple buyers purchased tickets
3.  **Dynamic Pricing** : Demonstrated surge pricing at:
   : 50% sold  ->  5% surge (1.05 ETH)
   : 75% sold  ->  10% surge (1.10 ETH)
   : 90% sold  ->  20% surge (1.20 ETH)
4.  **Ticket Resale** : Buyer1 resold ticket to Buyer2 within 20% markup limit
5.  **Markup Enforcement** : Prevented resale above 20% markup limit
6.  **Fee Distribution** : Platform fee (2.5%) distributed correctly
7.  **Withdrawals** : Organizer and reseller withdrew earnings
8.  **Ticket Usage** : Organizer marked ticket as used (check-in)
9.  **Usage Prevention** : Prevented using already-used ticket

**Key Metrics:**
- Total Tickets Sold: 90/100
- Revenue Generated: ~100+ ETH
- Platform Fees Collected: ~2.5+ ETH
- Resales Completed: 1
- Dynamic Pricing Triggered: Yes (3 tiers)

---

##  Quick Demo Script (Copy-Paste Ready)

For a rapid demo, run this condensed version:

```bash
# Setup
export BLOCKTIX=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
export TICKET_NFT=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
export PRICE_ORACLE=0x5FbDB2315678afecb367f032d93F642f64180aa3
export RPC_URL=http://localhost:8545
export ORGANIZER_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export BUYER1_KEY=0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
export BUYER2_KEY=0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a

# 1. Create Event
cast send $BLOCKTIX "createEvent(string,uint256,uint256,uint256,uint256)" "Concert" 10 1000000000000000000 $(($(date +%s) + 2592000)) 2000 --rpc-url $RPC_URL --private-key $ORGANIZER_KEY

# 2. Buy Ticket #0 (No surge)
cast send $BLOCKTIX "purchaseTicket(uint256)" 0 --value 1ether --rpc-url $RPC_URL --private-key $BUYER1_KEY

# 3. Buy Tickets #1-4 (Still no surge)
for i in {1..4}; do cast send $BLOCKTIX "purchaseTicket(uint256)" 0 --value 1ether --rpc-url $RPC_URL --private-key $BUYER2_KEY; done

# 4. Buy Ticket #5 (50% sold : 5% surge!)
cast send $BLOCKTIX "purchaseTicket(uint256)" 0 --value 1.05ether --rpc-url $RPC_URL --private-key $BUYER2_KEY

# 5. Check surge pricing
cast call $PRICE_ORACLE "calculatePrice(uint256,uint256,uint256)" 0 1000000000000000000 5 --rpc-url $RPC_URL

# 6. Approve and resell ticket
cast send $TICKET_NFT "approve(address,uint256)" $BLOCKTIX 0 --rpc-url $RPC_URL --private-key $BUYER1_KEY
cast send $BLOCKTIX "transferTicket(uint256,address)" 0 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC --value 1.2ether --rpc-url $RPC_URL --private-key $BUYER1_KEY

# 7. Withdraw funds
cast send $BLOCKTIX "withdraw()" --rpc-url $RPC_URL --private-key $ORGANIZER_KEY

echo " Demo Complete!"
```

---

##  Troubleshooting

**If Anvil resets or you need to redeploy:**
1. Stop Anvil (Ctrl+C)
2. Restart Anvil
3. Redeploy contracts: `forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast`
4. Update contract addresses in this demo

**Common Issues:**
- **"Insufficient payment"** : Increase `--value` to match current surge price
- **"ResaleMarkupExceeded"** : Reduce resale price to within 20% of original
- **"NotTicketOwner"** : Make sure you're using the correct buyer's private key
- **"SoldOut"** : Event has sold all tickets, create a new event

---

**Enjoy the BlockTix Demo!** 
