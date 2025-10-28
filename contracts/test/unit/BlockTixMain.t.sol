// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {BlockTixMain} from "../../src/BlockTixMain.sol";
import {TicketNFT} from "../../src/TicketNFT.sol";
import {PriceOracle} from "../../src/PriceOracle.sol";

/**
 * @title BlockTixMainTest
 * @notice Comprehensive unit tests for BlockTixMain contract
 */
contract BlockTixMainTest is Test {
    BlockTixMain public blockTix;
    TicketNFT public ticketNFT;
    PriceOracle public priceOracle;

    address public owner;
    address public organizer;
    address public buyer1;
    address public buyer2;

    uint256 public constant PLATFORM_FEE = 250; // 2.5%
    uint256 public constant INITIAL_BALANCE = 100 ether;

    event EventCreated(
        uint256 indexed eventId,
        address indexed organizer,
        string name,
        uint256 totalTickets,
        uint256 basePrice,
        uint256 eventDate
    );

    event TicketPurchased(uint256 indexed ticketId, uint256 indexed eventId, address indexed buyer, uint256 price);

    event TicketTransferred(uint256 indexed ticketId, address indexed from, address indexed to, uint256 price);

    event TicketUsed(uint256 indexed ticketId, uint256 indexed eventId);

    event EventCancelled(uint256 indexed eventId);

    event WithdrawalProcessed(address indexed recipient, uint256 amount);

    event PlatformFeeUpdated(uint256 oldFee, uint256 newFee);

    function setUp() public {
        owner = address(this);
        organizer = makeAddr("organizer");
        buyer1 = makeAddr("buyer1");
        buyer2 = makeAddr("buyer2");

        // Fund test accounts
        vm.deal(buyer1, INITIAL_BALANCE);
        vm.deal(buyer2, INITIAL_BALANCE);
        vm.deal(organizer, INITIAL_BALANCE);

        // Deploy contracts
        ticketNFT = new TicketNFT(owner, address(1), "https://blocktix.io/metadata/");
        priceOracle = new PriceOracle(owner, address(1), 1000, 500);
        blockTix = new BlockTixMain(address(ticketNFT), address(priceOracle), PLATFORM_FEE);

        // Set BlockTixMain address in dependent contracts
        ticketNFT.setBlockTixMain(address(blockTix));
        priceOracle.setBlockTixMain(address(blockTix));
    }

    // ============ Event Creation Tests ============

    function test_CreateEvent_Success() public {
        vm.startPrank(organizer);

        uint256 eventDate = block.timestamp + 30 days;
        string memory eventName = "Test Concert";
        uint256 totalTickets = 100;
        uint256 basePrice = 1 ether;
        uint256 maxMarkup = 2000; // 20%

        vm.expectEmit(true, true, false, true);
        emit EventCreated(0, organizer, eventName, totalTickets, basePrice, eventDate);

        uint256 eventId = blockTix.createEvent(eventName, totalTickets, basePrice, eventDate, maxMarkup);

        assertEq(eventId, 0);
        assertEq(blockTix.eventCount(), 1);

        BlockTixMain.Event memory eventData = blockTix.getEvent(eventId);
        assertEq(eventData.eventId, 0);
        assertEq(eventData.organizer, organizer);
        assertEq(eventData.name, eventName);
        assertEq(eventData.totalTickets, totalTickets);
        assertEq(eventData.ticketsSold, 0);
        assertEq(eventData.basePrice, basePrice);
        assertEq(eventData.eventDate, eventDate);
        assertTrue(eventData.isActive);
        assertEq(eventData.maxResaleMarkup, maxMarkup);

        vm.stopPrank();
    }

    function test_CreateEvent_RevertInvalidTotalTickets() public {
        vm.startPrank(organizer);

        vm.expectRevert(BlockTixMain.InvalidParameters.selector);
        blockTix.createEvent("Event", 0, 1 ether, block.timestamp + 30 days, 2000);

        vm.stopPrank();
    }

    function test_CreateEvent_RevertInvalidBasePrice() public {
        vm.startPrank(organizer);

        vm.expectRevert(BlockTixMain.InvalidParameters.selector);
        blockTix.createEvent("Event", 100, 0, block.timestamp + 30 days, 2000);

        vm.stopPrank();
    }

    function test_CreateEvent_RevertPastEventDate() public {
        vm.startPrank(organizer);

        vm.expectRevert(BlockTixMain.InvalidParameters.selector);
        blockTix.createEvent("Event", 100, 1 ether, block.timestamp - 1, 2000);

        vm.stopPrank();
    }

    function test_CreateEvent_MultipleEvents() public {
        vm.startPrank(organizer);

        uint256 eventId1 = blockTix.createEvent("Event1", 100, 1 ether, block.timestamp + 30 days, 2000);
        uint256 eventId2 = blockTix.createEvent("Event2", 200, 2 ether, block.timestamp + 60 days, 3000);

        assertEq(eventId1, 0);
        assertEq(eventId2, 1);
        assertEq(blockTix.eventCount(), 2);

        vm.stopPrank();
    }

    // ============ Ticket Purchase Tests ============

    function test_PurchaseTicket_Success() public {
        // Create event
        vm.prank(organizer);
        uint256 eventId = blockTix.createEvent("Concert", 100, 1 ether, block.timestamp + 30 days, 2000);

        // Purchase ticket
        vm.startPrank(buyer1);
        uint256 price = 1 ether;

        vm.expectEmit(true, true, true, true);
        emit TicketPurchased(0, eventId, buyer1, price);

        uint256 ticketId = blockTix.purchaseTicket{value: price}(eventId);

        assertEq(ticketId, 0);
        assertEq(ticketNFT.ownerOf(ticketId), buyer1);

        BlockTixMain.Ticket memory ticket = blockTix.getTicket(ticketId);
        assertEq(ticket.ticketId, ticketId);
        assertEq(ticket.eventId, eventId);
        assertEq(ticket.currentOwner, buyer1);
        assertEq(ticket.purchasePrice, price);
        assertFalse(ticket.isUsed);

        BlockTixMain.Event memory eventData = blockTix.getEvent(eventId);
        assertEq(eventData.ticketsSold, 1);

        vm.stopPrank();
    }

    function test_PurchaseTicket_WithRefund() public {
        vm.prank(organizer);
        uint256 eventId = blockTix.createEvent("Concert", 100, 1 ether, block.timestamp + 30 days, 2000);

        vm.startPrank(buyer1);
        uint256 price = 1 ether;
        uint256 overpayment = 0.5 ether;

        uint256 balanceBefore = buyer1.balance;
        blockTix.purchaseTicket{value: price + overpayment}(eventId);
        uint256 balanceAfter = buyer1.balance;

        assertEq(balanceBefore - balanceAfter, price);

        vm.stopPrank();
    }

    function test_PurchaseTicket_RevertInvalidEventId() public {
        vm.startPrank(buyer1);

        vm.expectRevert(BlockTixMain.InvalidEventId.selector);
        blockTix.purchaseTicket{value: 1 ether}(999);

        vm.stopPrank();
    }

    function test_PurchaseTicket_RevertEventNotActive() public {
        vm.prank(organizer);
        uint256 eventId = blockTix.createEvent("Concert", 100, 1 ether, block.timestamp + 30 days, 2000);

        vm.prank(organizer);
        blockTix.cancelEvent(eventId);

        vm.startPrank(buyer1);

        vm.expectRevert(BlockTixMain.EventNotActive.selector);
        blockTix.purchaseTicket{value: 1 ether}(eventId);

        vm.stopPrank();
    }

    function test_PurchaseTicket_RevertSoldOut() public {
        vm.prank(organizer);
        uint256 eventId = blockTix.createEvent("Concert", 2, 1 ether, block.timestamp + 30 days, 2000);

        vm.prank(buyer1);
        blockTix.purchaseTicket{value: 1 ether}(eventId);

        vm.prank(buyer2);
        blockTix.purchaseTicket{value: 1 ether}(eventId);

        vm.startPrank(buyer1);

        vm.expectRevert(BlockTixMain.SoldOut.selector);
        blockTix.purchaseTicket{value: 1 ether}(eventId);

        vm.stopPrank();
    }

    function test_PurchaseTicket_RevertInsufficientPayment() public {
        vm.prank(organizer);
        uint256 eventId = blockTix.createEvent("Concert", 100, 1 ether, block.timestamp + 30 days, 2000);

        vm.startPrank(buyer1);

        vm.expectRevert(BlockTixMain.InsufficientPayment.selector);
        blockTix.purchaseTicket{value: 0.5 ether}(eventId);

        vm.stopPrank();
    }

    function test_PurchaseTicket_FeeDistribution() public {
        vm.prank(organizer);
        uint256 eventId = blockTix.createEvent("Concert", 100, 1 ether, block.timestamp + 30 days, 2000);

        vm.prank(buyer1);
        blockTix.purchaseTicket{value: 1 ether}(eventId);

        uint256 platformFee = (1 ether * PLATFORM_FEE) / 10000;
        uint256 organizerAmount = 1 ether - platformFee;

        assertEq(blockTix.pendingWithdrawals(organizer), organizerAmount);
        assertEq(blockTix.pendingWithdrawals(owner), platformFee);
    }

    // ============ Ticket Transfer Tests ============

    function test_TransferTicket_Success() public {
        vm.prank(organizer);
        uint256 eventId = blockTix.createEvent("Concert", 100, 1 ether, block.timestamp + 30 days, 2000);

        vm.prank(buyer1);
        uint256 ticketId = blockTix.purchaseTicket{value: 1 ether}(eventId);

        vm.startPrank(buyer1);
        ticketNFT.approve(address(blockTix), ticketId);

        uint256 resalePrice = 1.1 ether;

        vm.expectEmit(true, true, true, true);
        emit TicketTransferred(ticketId, buyer1, buyer2, resalePrice);

        vm.deal(buyer1, resalePrice); // Ensure buyer1 has funds
        blockTix.transferTicket{value: resalePrice}(ticketId, buyer2);

        vm.stopPrank();

        assertEq(ticketNFT.ownerOf(ticketId), buyer2);

        BlockTixMain.Ticket memory ticket = blockTix.getTicket(ticketId);
        assertEq(ticket.currentOwner, buyer2);
        assertEq(ticket.purchasePrice, resalePrice);
    }

    function test_TransferTicket_RevertNotOwner() public {
        vm.prank(organizer);
        uint256 eventId = blockTix.createEvent("Concert", 100, 1 ether, block.timestamp + 30 days, 2000);

        vm.prank(buyer1);
        uint256 ticketId = blockTix.purchaseTicket{value: 1 ether}(eventId);

        vm.startPrank(buyer2);

        vm.expectRevert(BlockTixMain.NotTicketOwner.selector);
        blockTix.transferTicket{value: 1.1 ether}(ticketId, buyer2);

        vm.stopPrank();
    }

    function test_TransferTicket_RevertTicketUsed() public {
        vm.prank(organizer);
        uint256 eventId = blockTix.createEvent("Concert", 100, 1 ether, block.timestamp + 30 days, 2000);

        vm.prank(buyer1);
        uint256 ticketId = blockTix.purchaseTicket{value: 1 ether}(eventId);

        vm.prank(organizer);
        blockTix.useTicket(ticketId);

        vm.startPrank(buyer1);
        ticketNFT.approve(address(blockTix), ticketId);

        vm.expectRevert(BlockTixMain.TicketAlreadyUsed.selector);
        blockTix.transferTicket{value: 1.1 ether}(ticketId, buyer2);

        vm.stopPrank();
    }

    function test_TransferTicket_RevertMarkupExceeded() public {
        vm.prank(organizer);
        uint256 eventId = blockTix.createEvent("Concert", 100, 1 ether, block.timestamp + 30 days, 2000);

        vm.prank(buyer1);
        uint256 ticketId = blockTix.purchaseTicket{value: 1 ether}(eventId);

        vm.startPrank(buyer1);
        ticketNFT.approve(address(blockTix), ticketId);

        uint256 excessivePrice = 1.3 ether; // Over 20% markup

        vm.expectRevert(BlockTixMain.ResaleMarkupExceeded.selector);
        blockTix.transferTicket{value: excessivePrice}(ticketId, buyer2);

        vm.stopPrank();
    }

    // ============ Ticket Usage Tests ============

    function test_UseTicket_Success() public {
        vm.prank(organizer);
        uint256 eventId = blockTix.createEvent("Concert", 100, 1 ether, block.timestamp + 30 days, 2000);

        vm.prank(buyer1);
        uint256 ticketId = blockTix.purchaseTicket{value: 1 ether}(eventId);

        vm.startPrank(organizer);

        vm.expectEmit(true, true, false, false);
        emit TicketUsed(ticketId, eventId);

        blockTix.useTicket(ticketId);

        BlockTixMain.Ticket memory ticket = blockTix.getTicket(ticketId);
        assertTrue(ticket.isUsed);

        vm.stopPrank();
    }

    function test_UseTicket_RevertNotOrganizer() public {
        vm.prank(organizer);
        uint256 eventId = blockTix.createEvent("Concert", 100, 1 ether, block.timestamp + 30 days, 2000);

        vm.prank(buyer1);
        uint256 ticketId = blockTix.purchaseTicket{value: 1 ether}(eventId);

        vm.startPrank(buyer1);

        vm.expectRevert(BlockTixMain.NotTicketOwner.selector);
        blockTix.useTicket(ticketId);

        vm.stopPrank();
    }

    function test_UseTicket_RevertAlreadyUsed() public {
        vm.prank(organizer);
        uint256 eventId = blockTix.createEvent("Concert", 100, 1 ether, block.timestamp + 30 days, 2000);

        vm.prank(buyer1);
        uint256 ticketId = blockTix.purchaseTicket{value: 1 ether}(eventId);

        vm.startPrank(organizer);
        blockTix.useTicket(ticketId);

        vm.expectRevert(BlockTixMain.TicketAlreadyUsed.selector);
        blockTix.useTicket(ticketId);

        vm.stopPrank();
    }

    // ============ Event Cancellation Tests ============

    function test_CancelEvent_Success() public {
        vm.startPrank(organizer);

        uint256 eventId = blockTix.createEvent("Concert", 100, 1 ether, block.timestamp + 30 days, 2000);

        vm.expectEmit(true, false, false, false);
        emit EventCancelled(eventId);

        blockTix.cancelEvent(eventId);

        BlockTixMain.Event memory eventData = blockTix.getEvent(eventId);
        assertFalse(eventData.isActive);

        vm.stopPrank();
    }

    function test_CancelEvent_RevertNotOrganizer() public {
        vm.prank(organizer);
        uint256 eventId = blockTix.createEvent("Concert", 100, 1 ether, block.timestamp + 30 days, 2000);

        vm.startPrank(buyer1);

        vm.expectRevert(BlockTixMain.NotTicketOwner.selector);
        blockTix.cancelEvent(eventId);

        vm.stopPrank();
    }

    function test_CancelEvent_RevertInvalidEventId() public {
        vm.startPrank(organizer);

        vm.expectRevert(BlockTixMain.InvalidEventId.selector);
        blockTix.cancelEvent(999);

        vm.stopPrank();
    }

    // ============ Withdrawal Tests ============

    function test_Withdraw_Success() public {
        vm.prank(organizer);
        uint256 eventId = blockTix.createEvent("Concert", 100, 1 ether, block.timestamp + 30 days, 2000);

        vm.prank(buyer1);
        blockTix.purchaseTicket{value: 1 ether}(eventId);

        uint256 platformFee = (1 ether * PLATFORM_FEE) / 10000;
        uint256 organizerAmount = 1 ether - platformFee;

        vm.startPrank(organizer);

        uint256 balanceBefore = organizer.balance;

        vm.expectEmit(true, false, false, true);
        emit WithdrawalProcessed(organizer, organizerAmount);

        blockTix.withdraw();

        uint256 balanceAfter = organizer.balance;
        assertEq(balanceAfter - balanceBefore, organizerAmount);
        assertEq(blockTix.pendingWithdrawals(organizer), 0);

        vm.stopPrank();
    }

    function test_Withdraw_RevertNoFunds() public {
        vm.startPrank(buyer1);

        vm.expectRevert(BlockTixMain.NoWithdrawalAvailable.selector);
        blockTix.withdraw();

        vm.stopPrank();
    }

    function test_Withdraw_MultipleTickets() public {
        vm.prank(organizer);
        uint256 eventId = blockTix.createEvent("Concert", 100, 1 ether, block.timestamp + 30 days, 2000);

        vm.prank(buyer1);
        blockTix.purchaseTicket{value: 1 ether}(eventId);

        vm.prank(buyer2);
        blockTix.purchaseTicket{value: 1 ether}(eventId);

        uint256 platformFee = (1 ether * PLATFORM_FEE) / 10000;
        uint256 organizerAmount = 1 ether - platformFee;

        // After 2 purchases, organizer should have 2x organizerAmount
        assertEq(blockTix.pendingWithdrawals(organizer), organizerAmount * 2);

        vm.prank(organizer);
        blockTix.withdraw();

        // After withdrawal, pending should be 0
        assertEq(blockTix.pendingWithdrawals(organizer), 0);
    }

    // ============ Platform Fee Tests ============

    function test_UpdatePlatformFee_Success() public {
        uint256 newFee = 500; // 5%

        vm.expectEmit(false, false, false, true);
        emit PlatformFeeUpdated(PLATFORM_FEE, newFee);

        blockTix.updatePlatformFee(newFee);

        assertEq(blockTix.platformFeePercentage(), newFee);
    }

    function test_UpdatePlatformFee_RevertNotOwner() public {
        vm.startPrank(buyer1);

        vm.expectRevert();
        blockTix.updatePlatformFee(500);

        vm.stopPrank();
    }

    function test_UpdatePlatformFee_RevertExceedsMax() public {
        vm.expectRevert(BlockTixMain.InvalidParameters.selector);
        blockTix.updatePlatformFee(1001); // Over 10%
    }

    // ============ View Functions Tests ============

    function test_GetEvent() public {
        vm.prank(organizer);
        uint256 eventId = blockTix.createEvent("Concert", 100, 1 ether, block.timestamp + 30 days, 2000);

        BlockTixMain.Event memory eventData = blockTix.getEvent(eventId);

        assertEq(eventData.eventId, eventId);
        assertEq(eventData.organizer, organizer);
        assertEq(eventData.name, "Concert");
    }

    function test_GetEvent_RevertInvalidId() public {
        vm.expectRevert(BlockTixMain.InvalidEventId.selector);
        blockTix.getEvent(999);
    }

    function test_GetTicket() public {
        vm.prank(organizer);
        uint256 eventId = blockTix.createEvent("Concert", 100, 1 ether, block.timestamp + 30 days, 2000);

        vm.prank(buyer1);
        uint256 ticketId = blockTix.purchaseTicket{value: 1 ether}(eventId);

        BlockTixMain.Ticket memory ticket = blockTix.getTicket(ticketId);

        assertEq(ticket.ticketId, ticketId);
        assertEq(ticket.eventId, eventId);
        assertEq(ticket.currentOwner, buyer1);
    }
}
