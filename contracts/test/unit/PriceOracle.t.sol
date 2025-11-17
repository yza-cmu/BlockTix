// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/PriceOracle.sol";

contract PriceOracleTest is Test {
    PriceOracle public oracle;

    address owner = address(0xA1);
    address main = address(0xB1);
    address attacker = address(0xC1);

    function setUp() public {
        vm.startPrank(owner);
        oracle = new PriceOracle(
            owner,
            main,
            0,     // demand multiplier
            0      // time decay
        );
        vm.stopPrank();
    }

    // ------------------------------------------------------------
    // ONLY BLOCKTIXMAIN
    // ------------------------------------------------------------

    function test_CalculatePrice_OnlyBlockTixMain() public {
        vm.expectRevert(PriceOracle.OnlyBlockTixMain.selector);
        oracle.calculatePrice(1, 100 ether, 10);
    }

    // ------------------------------------------------------------
    // SURGE PRICING TESTS
    // ------------------------------------------------------------

    function test_Surge_NoIncrease() public {
        vm.prank(main);
        uint256 price = oracle.calculatePrice(1, 100 ether, 10); // < 50 tickets
        assertEq(price, 100 ether);
    }

    function test_Surge_50Percent() public {
        vm.prank(main);
        uint256 price = oracle.calculatePrice(1, 100 ether, 50); // >= 50

        // Default: 5% = 500 basis points
        uint256 expected = 100 ether + (100 ether * 500) / 10000;
        assertEq(price, expected);
    }

    function test_Surge_75Percent() public {
        vm.prank(main);
        uint256 price = oracle.calculatePrice(1, 100 ether, 75);

        uint256 expected = 100 ether + (100 ether * 1000) / 10000;
        assertEq(price, expected);
    }

    function test_Surge_90Percent() public {
        vm.prank(main);
        uint256 price = oracle.calculatePrice(1, 100 ether, 90);

        uint256 expected = 100 ether + (100 ether * 2000) / 10000;
        assertEq(price, expected);
    }

    // ------------------------------------------------------------
    // PRICE HISTORY
    // ------------------------------------------------------------

    function test_PriceHistoryAppends() public {
        vm.prank(main);
        oracle.calculatePrice(1, 100 ether, 10);

        PriceOracle.PriceHistory[] memory h = oracle.getPriceHistory(1);
        assertEq(h.length, 1);
        assertEq(h[0].price, 100 ether);
        assertEq(h[0].ticketsSold, 10);
    }

    // ------------------------------------------------------------
    // TIME DECAY PRICING
    // ------------------------------------------------------------

    function test_TimeDecay_AppliesDiscount() public {
        // enable time decay
        vm.prank(owner);
        oracle.setTimeDecay(1000); // 10%

        uint256 eventDate = block.timestamp + 8 days; // more than 1 week away

        vm.prank(main);
        uint256 price = oracle.calculatePriceWithTimeDecay(
            1,
            100 ether,
            0,
            100,
            eventDate
        );

        uint256 expected = 100 ether - (100 ether * 1000 / 10000);
        assertEq(price, expected);
    }

    function test_TimeDecay_NoDiscount_WhenLessThanWeek() public {
        vm.prank(owner);
        oracle.setTimeDecay(1000);

        uint256 eventDate = block.timestamp + 2 days;

        vm.prank(main);
        uint256 price = oracle.calculatePriceWithTimeDecay(
            1,
            100 ether,
            0,
            100,
            eventDate
        );

        // Should be equal to base price (no surge & no discount)
        assertEq(price, 100 ether);
    }

    // ------------------------------------------------------------
    // OWNER FUNCTIONS
    // ------------------------------------------------------------

    function test_Owner_SetDemandMultiplier() public {
        vm.prank(owner);
        oracle.setDemandMultiplier(2000);

        assertEq(oracle.demandMultiplierBasisPoints(), 2000);
    }

    function test_Owner_SetDemandMultiplier_Revert_TooHigh() public {
        vm.prank(owner);
        vm.expectRevert(PriceOracle.InvalidParameters.selector);
        oracle.setDemandMultiplier(6000);
    }

    function test_Owner_SetTimeDecay() public {
        vm.prank(owner);
        oracle.setTimeDecay(1500);

        assertEq(oracle.timeDecayBasisPoints(), 1500);
    }

    function test_Owner_SetSurgeMultipliers() public {
        vm.prank(owner);
        oracle.setSurgeMultipliers(300, 700, 1500);

        assertEq(oracle.surgeMultiplier1(), 300);
        assertEq(oracle.surgeMultiplier2(), 700);
        assertEq(oracle.surgeMultiplier3(), 1500);
    }

    // ------------------------------------------------------------
    // PAUSE TESTS
    // ------------------------------------------------------------

    function test_Pause_StopsPriceCalculation() public {
        vm.prank(owner);
        oracle.pause();

        vm.prank(main);
        vm.expectRevert("Pausable: paused");
        oracle.calculatePrice(1, 100 ether, 10);
    }

    function test_Unpause_RestoresOperations() public {
        vm.startPrank(owner);
        oracle.pause();
        oracle.unpause();
        vm.stopPrank();

        vm.prank(main);
        uint256 price = oracle.calculatePrice(1, 100 ether, 5);
        assertEq(price, 100 ether);
    }
}
