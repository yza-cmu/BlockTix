// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;

    function setUp() public {
        counter = new Counter();
    }

    function test_InitialValueIsZero() public {
        assertEq(counter.number(), 0);
    }

    function test_SetNumber() public {
        counter.setNumber(10);
        assertEq(counter.number(), 10);
    }

    function test_Increment() public {
        counter.setNumber(5);
        counter.increment();
        assertEq(counter.number(), 6);
    }

    function test_IncrementAfterMultipleSets() public {
        counter.setNumber(100);
        counter.setNumber(50);
        counter.increment();
        assertEq(counter.number(), 51);
    }
}
