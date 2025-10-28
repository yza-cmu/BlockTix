// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {PriceOracle} from "../../src/PriceOracle.sol";

/**
 * @title PriceOracleTest
 * @notice Comprehensive unit tests for PriceOracle contract
 */
contract PriceOracleTest is Test {
    PriceOracle public priceOracle;

    address public owner;
    address public blockTixMain;
    address public user;

    uint256 public constant DEMAND_MULTIPLIER = 1000; // 10%
    uint256 public constant TIME_DECAY = 500; // 5%

    event PriceCalculated(uint256 indexed eventId, uint256 price, uint256 ticketsSold);
    event DemandMultiplierUpdated(uint256 oldMultiplier, uint256 newMultiplier);
    event TimeDecayUpdated(uint256 oldDecay, uint256 newDecay);
    event SurgeMultipliersUpdated(uint256 surge1, uint256 surge2, uint256 surge3);
    event BlockTixMainUpdated(address indexed oldAddress, address indexed newAddress);

    function setUp() public {
        owner = address(this);
        blockTixMain = makeAddr("blockTixMain");
        user = makeAddr("user");

        priceOracle = new PriceOracle(owner, blockTixMain, DEMAND_MULTIPLIER, TIME_DECAY);
    }

    // ============ Constructor Tests ============

    function test_Constructor_Success() public view {
        assertEq(priceOracle.owner(), owner);
        assertEq(priceOracle.blockTixMain(), blockTixMain);
        assertEq(priceOracle.demandMultiplierBasisPoints(), DEMAND_MULTIPLIER);
        assertEq(priceOracle.timeDecayBasisPoints(), TIME_DECAY);
        assertFalse(priceOracle.paused());
    }

    function test_Constructor_RevertInvalidAddress() public {
        vm.expectRevert(PriceOracle.InvalidAddress.selector);
        new PriceOracle(owner, address(0), DEMAND_MULTIPLIER, TIME_DECAY);
    }

    // ============ Price Calculation Tests ============

    function test_CalculatePrice_NoSurge() public {
        uint256 basePrice = 1 ether;
        uint256 eventId = 1;
        uint256 ticketsSold = 10; // Under 50%

        vm.startPrank(blockTixMain);

        vm.expectEmit(true, false, false, true);
        emit PriceCalculated(eventId, basePrice, ticketsSold);

        uint256 price = priceOracle.calculatePrice(eventId, basePrice, ticketsSold);

        assertEq(price, basePrice);

        vm.stopPrank();
    }

    function test_CalculatePrice_Surge1() public {
        uint256 basePrice = 1 ether;
        uint256 eventId = 1;
        uint256 ticketsSold = 50; // At 50% threshold

        vm.startPrank(blockTixMain);

        uint256 price = priceOracle.calculatePrice(eventId, basePrice, ticketsSold);

        // 5% surge
        uint256 expectedPrice = basePrice + (basePrice * 500) / 10000;
        assertEq(price, expectedPrice);

        vm.stopPrank();
    }

    function test_CalculatePrice_Surge2() public {
        uint256 basePrice = 1 ether;
        uint256 eventId = 1;
        uint256 ticketsSold = 75; // At 75% threshold

        vm.startPrank(blockTixMain);

        uint256 price = priceOracle.calculatePrice(eventId, basePrice, ticketsSold);

        // 10% surge
        uint256 expectedPrice = basePrice + (basePrice * 1000) / 10000;
        assertEq(price, expectedPrice);

        vm.stopPrank();
    }

    function test_CalculatePrice_Surge3() public {
        uint256 basePrice = 1 ether;
        uint256 eventId = 1;
        uint256 ticketsSold = 90; // At 90% threshold

        vm.startPrank(blockTixMain);

        uint256 price = priceOracle.calculatePrice(eventId, basePrice, ticketsSold);

        // 20% surge
        uint256 expectedPrice = basePrice + (basePrice * 2000) / 10000;
        assertEq(price, expectedPrice);

        vm.stopPrank();
    }

    function test_CalculatePrice_RevertNotBlockTixMain() public {
        vm.startPrank(user);

        vm.expectRevert(PriceOracle.OnlyBlockTixMain.selector);
        priceOracle.calculatePrice(1, 1 ether, 10);

        vm.stopPrank();
    }

    function test_CalculatePrice_RecordsPriceHistory() public {
        uint256 basePrice = 1 ether;
        uint256 eventId = 1;

        vm.startPrank(blockTixMain);

        priceOracle.calculatePrice(eventId, basePrice, 10);
        priceOracle.calculatePrice(eventId, basePrice, 50);
        priceOracle.calculatePrice(eventId, basePrice, 75);

        PriceOracle.PriceHistory[] memory history = priceOracle.getPriceHistory(eventId);

        assertEq(history.length, 3);
        assertEq(history[0].ticketsSold, 10);
        assertEq(history[1].ticketsSold, 50);
        assertEq(history[2].ticketsSold, 75);

        vm.stopPrank();
    }

    // ============ Time Decay Tests ============

    function test_CalculatePriceWithTimeDecay_NoDecay() public {
        uint256 basePrice = 1 ether;
        uint256 eventId = 1;
        uint256 ticketsSold = 10;
        uint256 totalTickets = 100;
        uint256 eventDate = block.timestamp + 5 days; // Less than 1 week away

        vm.startPrank(blockTixMain);

        uint256 price = priceOracle.calculatePriceWithTimeDecay(eventId, basePrice, ticketsSold, totalTickets, eventDate);

        // No decay applied
        assertEq(price, basePrice);

        vm.stopPrank();
    }

    function test_CalculatePriceWithTimeDecay_WithDecay() public {
        uint256 basePrice = 1 ether;
        uint256 eventId = 1;
        uint256 ticketsSold = 10;
        uint256 totalTickets = 100;
        uint256 eventDate = block.timestamp + 14 days; // More than 1 week away

        vm.startPrank(blockTixMain);

        uint256 price = priceOracle.calculatePriceWithTimeDecay(eventId, basePrice, ticketsSold, totalTickets, eventDate);

        // 5% decay applied
        uint256 discount = (basePrice * TIME_DECAY) / 10000;
        uint256 expectedPrice = basePrice - discount;
        assertEq(price, expectedPrice);

        vm.stopPrank();
    }

    function test_CalculatePriceWithTimeDecay_SurgeAndDecay() public {
        uint256 basePrice = 1 ether;
        uint256 eventId = 1;
        uint256 ticketsSold = 50;
        uint256 totalTickets = 100; // 50% sold
        uint256 eventDate = block.timestamp + 14 days;

        vm.startPrank(blockTixMain);

        uint256 price = priceOracle.calculatePriceWithTimeDecay(eventId, basePrice, ticketsSold, totalTickets, eventDate);

        // First apply surge (5%)
        uint256 surgedPrice = basePrice + (basePrice * 500) / 10000;
        // Then apply decay (5%)
        uint256 discount = (surgedPrice * TIME_DECAY) / 10000;
        uint256 expectedPrice = surgedPrice - discount;

        assertEq(price, expectedPrice);

        vm.stopPrank();
    }

    // ============ Resale Price Validation Tests ============

    function test_ValidateResalePrice_Valid() public view {
        uint256 originalPrice = 1 ether;
        uint256 resalePrice = 1.2 ether;
        uint256 maxMarkup = 2000; // 20%

        bool isValid = priceOracle.validateResalePrice(originalPrice, resalePrice, maxMarkup);

        assertTrue(isValid);
    }

    function test_ValidateResalePrice_Invalid() public view {
        uint256 originalPrice = 1 ether;
        uint256 resalePrice = 1.3 ether;
        uint256 maxMarkup = 2000; // 20%

        bool isValid = priceOracle.validateResalePrice(originalPrice, resalePrice, maxMarkup);

        assertFalse(isValid);
    }

    function test_ValidateResalePrice_ExactLimit() public view {
        uint256 originalPrice = 1 ether;
        uint256 maxMarkup = 2000; // 20%
        uint256 resalePrice = originalPrice + (originalPrice * maxMarkup) / 10000;

        bool isValid = priceOracle.validateResalePrice(originalPrice, resalePrice, maxMarkup);

        assertTrue(isValid);
    }

    function test_ValidateResalePrice_ZeroMarkup() public view {
        uint256 originalPrice = 1 ether;
        uint256 resalePrice = 1 ether;
        uint256 maxMarkup = 0;

        bool isValid = priceOracle.validateResalePrice(originalPrice, resalePrice, maxMarkup);

        assertTrue(isValid);
    }

    // ============ Demand Multiplier Tests ============

    function test_SetDemandMultiplier_Success() public {
        uint256 newMultiplier = 2000; // 20%

        vm.expectEmit(false, false, false, true);
        emit DemandMultiplierUpdated(DEMAND_MULTIPLIER, newMultiplier);

        priceOracle.setDemandMultiplier(newMultiplier);

        assertEq(priceOracle.demandMultiplierBasisPoints(), newMultiplier);
    }

    function test_SetDemandMultiplier_RevertExceedsMax() public {
        vm.expectRevert(PriceOracle.InvalidParameters.selector);
        priceOracle.setDemandMultiplier(5001); // Over 50%
    }

    function test_SetDemandMultiplier_RevertNotOwner() public {
        vm.startPrank(user);

        vm.expectRevert();
        priceOracle.setDemandMultiplier(2000);

        vm.stopPrank();
    }

    // ============ Time Decay Tests ============

    function test_SetTimeDecay_Success() public {
        uint256 newDecay = 1000; // 10%

        vm.expectEmit(false, false, false, true);
        emit TimeDecayUpdated(TIME_DECAY, newDecay);

        priceOracle.setTimeDecay(newDecay);

        assertEq(priceOracle.timeDecayBasisPoints(), newDecay);
    }

    function test_SetTimeDecay_RevertExceedsMax() public {
        vm.expectRevert(PriceOracle.InvalidParameters.selector);
        priceOracle.setTimeDecay(5001); // Over 50%
    }

    function test_SetTimeDecay_RevertNotOwner() public {
        vm.startPrank(user);

        vm.expectRevert();
        priceOracle.setTimeDecay(1000);

        vm.stopPrank();
    }

    // ============ Surge Multiplier Tests ============

    function test_SetSurgeMultipliers_Success() public {
        uint256 surge1 = 1000; // 10%
        uint256 surge2 = 2000; // 20%
        uint256 surge3 = 3000; // 30%

        vm.expectEmit(false, false, false, true);
        emit SurgeMultipliersUpdated(surge1, surge2, surge3);

        priceOracle.setSurgeMultipliers(surge1, surge2, surge3);
    }

    function test_SetSurgeMultipliers_RevertInvalidOrder() public {
        vm.expectRevert(PriceOracle.InvalidParameters.selector);
        priceOracle.setSurgeMultipliers(3000, 2000, 1000); // Descending order
    }

    function test_SetSurgeMultipliers_RevertNotOwner() public {
        vm.startPrank(user);

        vm.expectRevert();
        priceOracle.setSurgeMultipliers(1000, 2000, 3000);

        vm.stopPrank();
    }

    // ============ BlockTixMain Address Tests ============

    function test_SetBlockTixMain_Success() public {
        address newBlockTixMain = makeAddr("newBlockTixMain");

        vm.expectEmit(true, true, false, false);
        emit BlockTixMainUpdated(blockTixMain, newBlockTixMain);

        priceOracle.setBlockTixMain(newBlockTixMain);

        assertEq(priceOracle.blockTixMain(), newBlockTixMain);
    }

    function test_SetBlockTixMain_RevertInvalidAddress() public {
        vm.expectRevert(PriceOracle.InvalidAddress.selector);
        priceOracle.setBlockTixMain(address(0));
    }

    function test_SetBlockTixMain_RevertNotOwner() public {
        vm.startPrank(user);

        vm.expectRevert();
        priceOracle.setBlockTixMain(makeAddr("newAddress"));

        vm.stopPrank();
    }

    // ============ Pause/Unpause Tests ============

    function test_Pause_Success() public {
        priceOracle.pause();

        assertTrue(priceOracle.paused());
    }

    function test_Pause_RevertNotOwner() public {
        vm.startPrank(user);

        vm.expectRevert();
        priceOracle.pause();

        vm.stopPrank();
    }

    function test_Unpause_Success() public {
        priceOracle.pause();
        priceOracle.unpause();

        assertFalse(priceOracle.paused());
    }

    function test_Unpause_RevertNotOwner() public {
        priceOracle.pause();

        vm.startPrank(user);

        vm.expectRevert();
        priceOracle.unpause();

        vm.stopPrank();
    }

    function test_CalculatePrice_RevertWhenPaused() public {
        priceOracle.pause();

        vm.startPrank(blockTixMain);

        vm.expectRevert();
        priceOracle.calculatePrice(1, 1 ether, 10);

        vm.stopPrank();
    }

    function test_CalculatePriceWithTimeDecay_RevertWhenPaused() public {
        priceOracle.pause();

        vm.startPrank(blockTixMain);

        vm.expectRevert();
        priceOracle.calculatePriceWithTimeDecay(1, 1 ether, 10, 100, block.timestamp + 30 days);

        vm.stopPrank();
    }

    // ============ Price History Tests ============

    function test_GetPriceHistory_Empty() public view {
        PriceOracle.PriceHistory[] memory history = priceOracle.getPriceHistory(1);

        assertEq(history.length, 0);
    }

    function test_GetPriceHistory_Multiple() public {
        uint256 eventId = 1;
        uint256 basePrice = 1 ether;

        vm.startPrank(blockTixMain);

        priceOracle.calculatePrice(eventId, basePrice, 10);
        priceOracle.calculatePrice(eventId, basePrice, 20);
        priceOracle.calculatePrice(eventId, basePrice, 30);

        PriceOracle.PriceHistory[] memory history = priceOracle.getPriceHistory(eventId);

        assertEq(history.length, 3);
        assertEq(history[0].price, basePrice);
        assertEq(history[1].price, basePrice);
        assertEq(history[2].price, basePrice);

        vm.stopPrank();
    }

    function test_GetLatestPrice_NoHistory() public view {
        uint256 latestPrice = priceOracle.getLatestPrice(1);

        assertEq(latestPrice, 0);
    }

    function test_GetLatestPrice_WithHistory() public {
        uint256 eventId = 1;
        uint256 basePrice = 1 ether;

        vm.startPrank(blockTixMain);

        priceOracle.calculatePrice(eventId, basePrice, 10);
        priceOracle.calculatePrice(eventId, basePrice, 50);

        uint256 latestPrice = priceOracle.getLatestPrice(eventId);

        // Latest should be with 50 tickets sold (5% surge)
        uint256 expectedPrice = basePrice + (basePrice * 500) / 10000;
        assertEq(latestPrice, expectedPrice);

        vm.stopPrank();
    }

    // ============ Edge Cases ============

    function test_CalculatePrice_VeryHighTicketsSold() public {
        uint256 basePrice = 1 ether;
        uint256 eventId = 1;
        uint256 ticketsSold = 1000000;

        vm.startPrank(blockTixMain);

        uint256 price = priceOracle.calculatePrice(eventId, basePrice, ticketsSold);

        // Should apply highest surge (20%)
        uint256 expectedPrice = basePrice + (basePrice * 2000) / 10000;
        assertEq(price, expectedPrice);

        vm.stopPrank();
    }

    function test_CalculatePrice_ZeroBasePrice() public {
        vm.startPrank(blockTixMain);

        uint256 price = priceOracle.calculatePrice(1, 0, 10);

        assertEq(price, 0);

        vm.stopPrank();
    }

    function test_ValidateResalePrice_VeryHighMarkup() public view {
        uint256 originalPrice = 1 ether;
        uint256 resalePrice = 10 ether;
        uint256 maxMarkup = 50000; // 500%

        bool isValid = priceOracle.validateResalePrice(originalPrice, resalePrice, maxMarkup);

        assertFalse(isValid); // 10x is 900% markup, exceeds 500%
    }
}
