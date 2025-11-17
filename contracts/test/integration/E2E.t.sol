// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/BlockTixMain.sol";
import "../src/TicketNFT.sol";
import "../src/PriceOracle.sol";

contract BlockTixE2ETest is Test {
    BlockTixMain public main;
    TicketNFT public ticketNFT;
    PriceOracle public priceOracle;

    address owner      = address(0xA1);
    address organizer  = address(0xB1);
    address buyer1     = address(0xC1);
    address buyer2     = address(0xD1);

    function setUp() public {
        vm.startPrank(owner);

        // Use non-zero dummy addresses for ctor, then wire correctly
        ticketNFT = new TicketNFT(
            owner,
            address(0xDEAD),
            "https://base/"
        );

        priceOracle = new PriceOracle(
            owner,
            address(0xBEEF),
            0,      // demand multiplier
            0       // time decay
        );

        main = new BlockTixMain(
            address(ticketNFT),
            address(priceOracle),
            500 // 5% platform fee in basis points
        );

        // Wire BlockTixMain as the real main contract
        ticketNFT.setBlockTixMain(address(main));
        priceOracle.setBlockTixMain(address(main));

        vm.stopPrank();

        // Give ETH to actors
        vm.deal(organizer, 10 ether);
        vm.deal(buyer1, 20 ether);
        vm.deal(buyer2, 20 ether);
    }

    function test_EndToEnd_FullFlow() public {
        // -----------------------------
        // 1) Organizer creates event
        // -----------------------------
        vm.prank(organizer);
        uint256 eventId = main.createEvent(
            "Champions League Final",
            3,                      // totalTickets
            1 ether,                // basePrice
            block.timestamp + 7 days,
            2000                    // 20% max resale markup
        );

        BlockTixMain.Event memory e = main.getEvent(eventId);
        assertEq(e.organizer, organizer);
        assertEq(e.totalTickets, 3);
        assertTrue(e.isActive);

        // -----------------------------
        // 2) Buyers purchase tickets
        // -----------------------------
        vm.prank(buyer1);
        uint256 t1 = main.purchaseTicket{value: 1 ether}(eventId);

        vm.prank(buyer2);
        uint256 t2 = main.purchaseTicket{value: 1 ether}(eventId);

        // Check ownership + event link
        BlockTixMain.Ticket memory ticket1 = main.getTicket(t1);
        BlockTixMain.Ticket memory ticket2 = main.getTicket(t2);

        assertEq(ticket1.currentOwner, buyer1);
        assertEq(ticket1.eventId, eventId);
        assertEq(ticket2.currentOwner, buyer2);
        assertEq(ticket2.eventId, eventId);

        // Event should now have 2 tickets sold
        e = main.getEvent(eventId);
        assertEq(e.ticketsSold, 2);

        // -----------------------------
        // 3) Resale: buyer1 -> buyer2
        // -----------------------------
        // buyer1 resells their ticket to buyer2 within allowed markup
        uint256 resalePrice = 11 ether / 10; // 1.1 ETH (10% markup, under 20%)

        vm.prank(buyer1);
        main.transferTicket{value: resalePrice}(t1, buyer2);

        ticket1 = main.getTicket(t1);
        assertEq(ticket1.currentOwner, buyer2);
        assertEq(ticket1.purchasePrice, resalePrice);

        // -----------------------------
        // 4) Ticket usage at event gate
        // -----------------------------
        // Organizer checks/uses ticket2 (held by buyer2)
        vm.prank(organizer);
        main.useTicket(t2);

        ticket2 = main.getTicket(t2);
        assertTrue(ticket2.isUsed);

        // Using again should revert
        vm.prank(organizer);
        vm.expectRevert(BlockTixMain.TicketAlreadyUsed.selector);
        main.useTicket(t2);

        // -----------------------------
        // 5) Organizer + Platform withdraw funds
        // -----------------------------
        uint256 organizerBefore = organizer.balance;
        uint256 ownerBefore = owner.balance;

        // Organizer withdraws their share from primary + resale
        vm.prank(organizer);
        main.withdraw();

        uint256 organizerAfter = organizer.balance;
        assertGt(organizerAfter, organizerBefore);

        // Platform owner withdraws fees
        vm.prank(owner);
        main.withdraw();

        uint256 ownerAfter = owner.balance;
        assertGt(ownerAfter, ownerBefore);

        // -----------------------------
        // 6) Basic sanity checks
        // -----------------------------
        // Event is still active (not canceled)
        e = main.getEvent(eventId);
        assertTrue(e.isActive);

        // Tickets remain linked to the same event
        ticket1 = main.getTicket(t1);
        ticket2 = main.getTicket(t2);
        assertEq(ticket1.eventId, eventId);
        assertEq(ticket2.eventId, eventId);
    }
}
