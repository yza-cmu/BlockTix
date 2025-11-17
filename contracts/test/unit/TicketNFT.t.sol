// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/TicketNFT.sol";

contract TicketNFTTest is Test {
    TicketNFT public ticketNFT;

    address owner = address(0xA1);
    address blockTixMain = address(0xB1);
    address user = address(0xC1);
    address other = address(0xD1);

    function setUp() public {
        vm.startPrank(owner);
        ticketNFT = new TicketNFT(owner, blockTixMain, "https://base/");
        vm.stopPrank();
    }

    // ----------------------------------------------------------
    // MINT TESTS
    // ----------------------------------------------------------

    function testMint_Success() public {
        vm.prank(blockTixMain);

        uint256 tokenId = ticketNFT.mint(user, 10);

        assertEq(ticketNFT.ownerOf(tokenId), user);
        assertEq(ticketNFT.tokenToEvent(tokenId), 10);
    }

    function testMint_OnlyBlockTixMain() public {
        vm.expectRevert(TicketNFT.OnlyBlockTixMain.selector);
        ticketNFT.mint(user, 1);
    }

    // ----------------------------------------------------------
    // BATCH MINT TESTS
    // ----------------------------------------------------------

    function testBatchMint_Success() public {
        vm.prank(blockTixMain);

        uint256[] memory minted = ticketNFT.batchMint(user, 99, 3);

        assertEq(minted.length, 3);

        for (uint256 i = 0; i < minted.length; i++) {
            assertEq(ticketNFT.ownerOf(minted[i]), user);
            assertEq(ticketNFT.tokenToEvent(minted[i]), 99);
        }
    }

    function testBatchMint_OnlyBlockTixMain() public {
        vm.expectRevert(TicketNFT.OnlyBlockTixMain.selector);
        ticketNFT.batchMint(user, 1, 5);
    }

    // ----------------------------------------------------------
    // BURN TESTS
    // ----------------------------------------------------------

    function testBurn_ByOwner() public {
        vm.prank(blockTixMain);
        uint256 tokenId = ticketNFT.mint(user, 1);

        vm.prank(user);
        ticketNFT.burn(tokenId);

        assertTrue(ticketNFT.isBurned(tokenId));
    }

    function testBurn_ByBlockTixMain() public {
        // mint
        vm.prank(blockTixMain);
        uint256 tokenId = ticketNFT.mint(user, 1);

        // burn
        vm.prank(blockTixMain);
        ticketNFT.burn(tokenId);

        assertTrue(ticketNFT.isBurned(tokenId));
    }

    function testBurn_RejectIfNotOwnerOrMain() public {
        vm.prank(blockTixMain);
        uint256 tokenId = ticketNFT.mint(user, 1);

        vm.prank(other);
        vm.expectRevert(TicketNFT.OnlyBlockTixMain.selector);
        ticketNFT.burn(tokenId);
    }

    // ----------------------------------------------------------
    // TOKEN URI TESTS
    // ----------------------------------------------------------

    function testSetTokenURI_OnlyBlockTixMain() public {
        vm.prank(blockTixMain);
        uint256 tokenId = ticketNFT.mint(user, 123);

        vm.prank(blockTixMain);
        ticketNFT.setTokenURI(tokenId, "ipfs://metadata.json");
    }

    function testSetTokenURI_RejectNonMain() public {
        vm.prank(blockTixMain);
        uint256 tokenId = ticketNFT.mint(user, 5);

        vm.prank(other);
        vm.expectRevert(TicketNFT.OnlyBlockTixMain.selector);
        ticketNFT.setTokenURI(tokenId, "ipfs://bad.json");
    }

    // ----------------------------------------------------------
    // BASE URI TESTS
    // ----------------------------------------------------------

    function testSetBaseURI_OnlyOwner() public {
        vm.prank(owner);
        ticketNFT.setBaseURI("https://new-base/");
    }

    function testSetBaseURI_RejectNonOwner() public {
        vm.prank(other);
        vm.expectRevert("Ownable: caller is not the owner");
        ticketNFT.setBaseURI("https://evil/");
    }

    // ----------------------------------------------------------
    // SET BLOCKTIXMAIN TESTS
    // ----------------------------------------------------------

    function testSetBlockTixMain_OnlyOwner() public {
        vm.prank(owner);
        ticketNFT.setBlockTixMain(address(0x1111));

        assertEq(ticketNFT.blockTixMain(), address(0x1111));
    }

    function testSetBlockTixMain_RejectZero() public {
        vm.prank(owner);
        vm.expectRevert(TicketNFT.InvalidAddress.selector);
        ticketNFT.setBlockTixMain(address(0));
    }

    function testSetBlockTixMain_RejectNonOwner() public {
        vm.prank(other);
        vm.expectRevert("Ownable: caller is not the owner");
        ticketNFT.setBlockTixMain(address(0x9999));
    }
}
