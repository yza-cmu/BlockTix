// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/BlockTixMain.sol";
import "../src/TicketNFT.sol";
import "../src/PriceOracle.sol";

contract BlockTixMainTest is Test {
    BlockTixMain public main;
    TicketNFT public nft;
    PriceOracle public oracle;

    address owner = address(0xA1);
    address organizer = address(0xB1);
    address buyer1 = address(0xC1);
    address buyer2 = address(0xD1);

    function setUp() public {
        vm.startPrank(owner);

        // Deploy placeholder NFT & Oracle
        nft = new TicketNFT(owner, address(0), "https://base/");
        oracle = new PriceOracle(owner, address(0), 0, 0);

        // Deploy main contract
        main = new BlockTixMain(
            address(nft),
            address(oracle),
            500 // 5% platform fee
        );

        // Wire the contracts together
        nft.setBlockTixMain(address(main));
        oracle.setBlockTixMain(address(main));

        vm.stopPrank();

        // Fund buyers
        vm.deal(buyer1, 50 ether);
        vm.deal(buyer2, 50 ether);
    }

    // ------------------------------------------------------------
    // EVENT CREATION
    // ------------------------------------------------------------

    function test_CreateEvent_Success() public {
        vm.prank(organizer);
        uint256 eventId = main.createEvent(
            "Football Final",
            100,
            1 ether,
            block.timestamp + 10 days,
            2000 // 20% markup allowed
        );

        (,,,,, uint256 basePrice,,,,) = main.getEvent(eventId);

        assertEq(basePrice, 1 ether);
    }

    function test_CreateEvent_RevertInvalidParams() public {
        vm.startPrank(organizer);

        // zero tickets
        vm.expectRevert(BlockTixMain.InvalidParameters.selector);
        main.createEvent(
            "Bad",
            0,
            1 ether,
            block.timestamp + 10 days,
            2000
        );

        // base price zero
        vm.expectRevert(BlockTixMain.InvalidParameters.selector);
        main.createEvent(
            "Bad",
            10,
            0,
            block.timestamp + 10 days,
            2000
        );

        // past event
        vm.expectRevert(BlockTixMain.InvalidParameters.selector);
        main.createEvent(
            "Bad",
            10,
            1 ether,
            block.timestamp - 1,
            2000
        );

        vm.stopPrank();
    }

    // ------------------------------------------------------------
    // TICKET PURCHASE
    // ------------------------------------------------------------

    function _createBasicEvent() internal returns (uint256) {
        vm.prank(organizer);
        return main.createEvent(
            "Match",
            10,
            1 ether,
            block.timestamp + 1000,
            2000
        );
    }

    function test_PurchaseTicket_Success() public {
        uint256 eventId = _createBasicEvent();

        vm.prank(buyer1);
        uint256 ticketId = main.purchaseTicket{value: 1 ether}(eventId);

        BlockTixMain.Ticket memory t = main.getTicket(ticketId);

        assertEq(t.currentOwner, buyer1);
        assertEq(t.eventId, eventId);
    }

    function test_PurchaseTicket_RevertSoldOut() public {
        uint256 eventId = _createBasicEvent();

        // only 10 tickets
        for (uint i = 0; i < 10; i++) {
            vm.prank(buyer1);
            main.purchaseTicket{value: 1 ether}(eventId);
        }

        vm.prank(buyer1);
        vm.expectRevert(BlockTixMain.SoldOut.selector);
        main.purchaseTicket{value: 1 ether}(eventId);
    }

    function test_PurchaseTicket_RefundExtraETH() public {
        uint256 eventId = _createBasicEvent();

        uint256 before = buyer1.balance;

        vm.prank(buyer1);
        main.purchaseTicket{value: 2 ether}(eventId); // send 2, price 1

        uint256 afterBal = buyer1.balance;

        assertApproxEqAbs(afterBal, before - 1 ether, 1e12);
    }

    // ------------------------------------------------------------
    // TRANSFER (RESALE)
    // ------------------------------------------------------------

    function test_TransferTicket_Success() public {
        uint256 eventId = _createBasicEvent();

        // buyer1 buys ticket
        vm.prank(buyer1);
        uint256 ticketId = main.purchaseTicket{value: 1 ether}(eventId);

        // buyer2 resells (within markup limit)
        uint256 resalePrice = 1.1 ether; // within 20% markup

        vm.prank(buyer1);
        main.transferTicket{value: resalePrice}(ticketId, buyer2);

        BlockTixMain.Ticket memory t = main.getTicket(ticketId);
        assertEq(t.currentOwner, buyer2);
        assertEq(t.purchasePrice, resalePrice);
    }

    function test_TransferTicket_RevertNotOwner() public {
        uint256 eventId = _createBasicEvent();

        vm.prank(buyer1);
        uint256 ticketId = main.purchaseTicket{value: 1 ether}(eventId);

        vm.prank(buyer2);
        vm.expectRevert(BlockTixMain.NotTicketOwner.selector);
        main.transferTicket{value: 1 ether}(ticketId, buyer2);
    }

    // ------------------------------------------------------------
    // USE TICKET
    // ------------------------------------------------------------

    function test_UseTicket_Success() public {
        uint256 eventId = _createBasicEvent();

        vm.prank(buyer1);
        uint256 ticketId = main.purchaseTicket{value: 1 ether}(eventId);

        vm.prank(organizer);
        main.useTicket(ticketId);

        BlockTixMain.Ticket memory t = main.getTicket(ticketId);
        assertTrue(t.isUsed);
    }

    function test_UseTicket_RevertAlreadyUsed() public {
        uint256 eventId = _createBasicEvent();

        vm.prank(buyer1);
        uint256 ticketId = main.purchaseTicket{value: 1 ether}(eventId);

        vm.prank(organizer);
        main.useTicket(ticketId);

        vm.prank(organizer);
        vm.expectRevert(BlockTixMain.TicketAlreadyUsed.selector);
        main.useTicket(ticketId);
    }

    function test_UseTicket_RevertNotOrganizer() public {
        uint256 eventId = _createBasicEvent();

        vm.prank(buyer1);
        uint256 ticketId = main.purchaseTicket{value: 1 ether}(eventId);

        vm.prank(buyer1);
        vm.expectRevert(BlockTixMain.NotTicketOwner.selector);
        main.useTicket(ticketId);
    }

    // ------------------------------------------------------------
    // CANCEL EVENT
    // ------------------------------------------------------------

    function test_CancelEvent_Success() public {
        uint256 eventId = _createBasicEvent();

        vm.prank(organizer);
        main.cancelEvent(eventId);

        BlockTixMain.Event memory e = main.getEvent(eventId);
        assertFalse(e.isActive);
    }

    function test_CancelEvent_RevertNotOrganizer() public {
        uint256 eventId = _createBasicEvent();

        vm.prank(buyer1);
        vm.expectRevert(BlockTixMain.NotTicketOwner.selector);
        main.cancelEvent(eventId);
    }

    // ------------------------------------------------------------
    // WITHDRAW
    // ------------------------------------------------------------

    function test_Withdraw_Success() public {
        uint256 eventId = _createBasicEvent();

        vm.prank(buyer1);
        main.purchaseTicket{value: 1 ether}(eventId);

        uint256 balBefore = organizer.balance;

        vm.prank(organizer);
        main.withdraw();

        uint256 balAfter = organizer.balance;
        assertGt(balAfter, balBefore);
    }

    function test_Withdraw_Revert_NoFunds() public {
        vm.prank(buyer1);
        vm.expectRevert(BlockTixMain.NoWithdrawalAvailable.selector);
        main.withdraw();
    }

    // ------------------------------------------------------------
    // PLATFORM FEE UPDATE
    // ------------------------------------------------------------

    function test_UpdatePlatformFee_Success() public {
        vm.prank(owner);
        main.updatePlatformFee(800);

        assertEq(main.platformFeePercentage(), 800);
    }

    function test_UpdatePlatformFee_RevertTooHigh() public {
        vm.prank(owner);
        vm.expectRevert(BlockTixMain.InvalidParameters.selector);
        main.updatePlatformFee(20000);
    }
}
