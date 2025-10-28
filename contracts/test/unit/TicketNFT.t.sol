// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {TicketNFT} from "../../src/TicketNFT.sol";

/**
 * @title TicketNFTTest
 * @notice Comprehensive unit tests for TicketNFT contract
 */
contract TicketNFTTest is Test {
    TicketNFT public ticketNFT;

    address public owner;
    address public blockTixMain;
    address public user1;
    address public user2;

    string public constant BASE_URI = "https://blocktix.io/metadata/";

    event TicketMinted(uint256 indexed tokenId, address indexed to, uint256 indexed eventId);
    event TicketBurned(uint256 indexed tokenId);
    event BaseURIUpdated(string newBaseURI);
    event BlockTixMainUpdated(address indexed oldAddress, address indexed newAddress);

    function setUp() public {
        owner = address(this);
        blockTixMain = makeAddr("blockTixMain");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        ticketNFT = new TicketNFT(owner, blockTixMain, BASE_URI);
    }

    // ============ Constructor Tests ============

    function test_Constructor_Success() public view {
        assertEq(ticketNFT.name(), "BlockTix Ticket");
        assertEq(ticketNFT.symbol(), "BTIX");
        assertEq(ticketNFT.owner(), owner);
        assertEq(ticketNFT.blockTixMain(), blockTixMain);
    }

    function test_Constructor_RevertInvalidAddress() public {
        vm.expectRevert(TicketNFT.InvalidAddress.selector);
        new TicketNFT(owner, address(0), BASE_URI);
    }

    // ============ Minting Tests ============

    function test_Mint_Success() public {
        uint256 eventId = 1;

        vm.startPrank(blockTixMain);

        vm.expectEmit(true, true, true, false);
        emit TicketMinted(0, user1, eventId);

        uint256 tokenId = ticketNFT.mint(user1, eventId);

        assertEq(tokenId, 0);
        assertEq(ticketNFT.ownerOf(tokenId), user1);
        assertEq(ticketNFT.getEventId(tokenId), eventId);
        assertEq(ticketNFT.getCurrentTokenId(), 1);
        assertTrue(ticketNFT.exists(tokenId));

        vm.stopPrank();
    }

    function test_Mint_MultipleTimes() public {
        vm.startPrank(blockTixMain);

        uint256 tokenId1 = ticketNFT.mint(user1, 1);
        uint256 tokenId2 = ticketNFT.mint(user2, 2);
        uint256 tokenId3 = ticketNFT.mint(user1, 1);

        assertEq(tokenId1, 0);
        assertEq(tokenId2, 1);
        assertEq(tokenId3, 2);
        assertEq(ticketNFT.getCurrentTokenId(), 3);

        assertEq(ticketNFT.ownerOf(tokenId1), user1);
        assertEq(ticketNFT.ownerOf(tokenId2), user2);
        assertEq(ticketNFT.ownerOf(tokenId3), user1);

        vm.stopPrank();
    }

    function test_Mint_RevertNotBlockTixMain() public {
        vm.startPrank(user1);

        vm.expectRevert(TicketNFT.OnlyBlockTixMain.selector);
        ticketNFT.mint(user1, 1);

        vm.stopPrank();
    }

    // ============ Batch Minting Tests ============

    function test_BatchMint_Success() public {
        uint256 eventId = 1;
        uint256 amount = 5;

        vm.startPrank(blockTixMain);

        uint256[] memory tokenIds = ticketNFT.batchMint(user1, eventId, amount);

        assertEq(tokenIds.length, amount);

        for (uint256 i = 0; i < amount; i++) {
            assertEq(tokenIds[i], i);
            assertEq(ticketNFT.ownerOf(tokenIds[i]), user1);
            assertEq(ticketNFT.getEventId(tokenIds[i]), eventId);
            assertTrue(ticketNFT.exists(tokenIds[i]));
        }

        assertEq(ticketNFT.getCurrentTokenId(), amount);

        vm.stopPrank();
    }

    function test_BatchMint_SingleTicket() public {
        vm.startPrank(blockTixMain);

        uint256[] memory tokenIds = ticketNFT.batchMint(user1, 1, 1);

        assertEq(tokenIds.length, 1);
        assertEq(tokenIds[0], 0);

        vm.stopPrank();
    }

    function test_BatchMint_RevertNotBlockTixMain() public {
        vm.startPrank(user1);

        vm.expectRevert(TicketNFT.OnlyBlockTixMain.selector);
        ticketNFT.batchMint(user1, 1, 5);

        vm.stopPrank();
    }

    // ============ Burning Tests ============

    function test_Burn_ByOwner() public {
        vm.prank(blockTixMain);
        uint256 tokenId = ticketNFT.mint(user1, 1);

        vm.startPrank(user1);

        vm.expectEmit(true, false, false, false);
        emit TicketBurned(tokenId);

        ticketNFT.burn(tokenId);

        assertFalse(ticketNFT.exists(tokenId));
        assertTrue(ticketNFT.isBurned(tokenId));

        vm.stopPrank();
    }

    function test_Burn_ByBlockTixMain() public {
        vm.prank(blockTixMain);
        uint256 tokenId = ticketNFT.mint(user1, 1);

        vm.startPrank(blockTixMain);

        ticketNFT.burn(tokenId);

        assertFalse(ticketNFT.exists(tokenId));
        assertTrue(ticketNFT.isBurned(tokenId));

        vm.stopPrank();
    }

    function test_Burn_RevertNotAuthorized() public {
        vm.prank(blockTixMain);
        uint256 tokenId = ticketNFT.mint(user1, 1);

        vm.startPrank(user2);

        vm.expectRevert(TicketNFT.OnlyBlockTixMain.selector);
        ticketNFT.burn(tokenId);

        vm.stopPrank();
    }

    function test_Burn_RevertAlreadyBurned() public {
        vm.prank(blockTixMain);
        uint256 tokenId = ticketNFT.mint(user1, 1);

        vm.prank(user1);
        ticketNFT.burn(tokenId);

        vm.startPrank(user1);

        // After burn, token doesn't exist, so it reverts with nonexistent token error
        vm.expectRevert();
        ticketNFT.burn(tokenId);

        vm.stopPrank();
    }

    // ============ Token URI Tests ============

    function test_SetTokenURI_Success() public {
        vm.prank(blockTixMain);
        uint256 tokenId = ticketNFT.mint(user1, 1);

        string memory customURI = "ipfs://custom-metadata";

        vm.startPrank(blockTixMain);

        ticketNFT.setTokenURI(tokenId, customURI);

        string memory retrievedURI = ticketNFT.tokenURI(tokenId);
        // ERC721URIStorage concatenates baseURI with the custom URI when set
        string memory expectedURI = string(abi.encodePacked(BASE_URI, customURI));
        assertEq(retrievedURI, expectedURI);

        vm.stopPrank();
    }

    function test_SetTokenURI_RevertNotBlockTixMain() public {
        vm.prank(blockTixMain);
        uint256 tokenId = ticketNFT.mint(user1, 1);

        vm.startPrank(user1);

        vm.expectRevert(TicketNFT.OnlyBlockTixMain.selector);
        ticketNFT.setTokenURI(tokenId, "ipfs://test");

        vm.stopPrank();
    }

    function test_TokenURI_WithBaseURI() public {
        vm.prank(blockTixMain);
        uint256 tokenId = ticketNFT.mint(user1, 1);

        // Token URI should default to baseURI + tokenId when not explicitly set
        string memory actualURI = ticketNFT.tokenURI(tokenId);

        // Verify the URI is constructed with base URI
        assertTrue(bytes(actualURI).length > 0);
    }

    // ============ Base URI Tests ============

    function test_SetBaseURI_Success() public {
        string memory newBaseURI = "https://new-base-uri.com/";

        vm.expectEmit(false, false, false, true);
        emit BaseURIUpdated(newBaseURI);

        ticketNFT.setBaseURI(newBaseURI);
    }

    function test_SetBaseURI_RevertNotOwner() public {
        vm.startPrank(user1);

        vm.expectRevert();
        ticketNFT.setBaseURI("https://new-uri.com/");

        vm.stopPrank();
    }

    // ============ BlockTixMain Address Tests ============

    function test_SetBlockTixMain_Success() public {
        address newBlockTixMain = makeAddr("newBlockTixMain");

        vm.expectEmit(true, true, false, false);
        emit BlockTixMainUpdated(blockTixMain, newBlockTixMain);

        ticketNFT.setBlockTixMain(newBlockTixMain);

        assertEq(ticketNFT.blockTixMain(), newBlockTixMain);
    }

    function test_SetBlockTixMain_RevertInvalidAddress() public {
        vm.expectRevert(TicketNFT.InvalidAddress.selector);
        ticketNFT.setBlockTixMain(address(0));
    }

    function test_SetBlockTixMain_RevertNotOwner() public {
        vm.startPrank(user1);

        vm.expectRevert();
        ticketNFT.setBlockTixMain(makeAddr("newAddress"));

        vm.stopPrank();
    }

    // ============ ERC721 Standard Tests ============

    function test_Transfer_Success() public {
        vm.prank(blockTixMain);
        uint256 tokenId = ticketNFT.mint(user1, 1);

        vm.startPrank(user1);

        ticketNFT.transferFrom(user1, user2, tokenId);

        assertEq(ticketNFT.ownerOf(tokenId), user2);

        vm.stopPrank();
    }

    function test_Approve_Success() public {
        vm.prank(blockTixMain);
        uint256 tokenId = ticketNFT.mint(user1, 1);

        vm.startPrank(user1);

        ticketNFT.approve(user2, tokenId);

        assertEq(ticketNFT.getApproved(tokenId), user2);

        vm.stopPrank();
    }

    function test_SetApprovalForAll_Success() public {
        vm.startPrank(user1);

        ticketNFT.setApprovalForAll(user2, true);

        assertTrue(ticketNFT.isApprovedForAll(user1, user2));

        vm.stopPrank();
    }

    function test_SafeTransferFrom_Success() public {
        vm.prank(blockTixMain);
        uint256 tokenId = ticketNFT.mint(user1, 1);

        vm.startPrank(user1);

        ticketNFT.safeTransferFrom(user1, user2, tokenId);

        assertEq(ticketNFT.ownerOf(tokenId), user2);

        vm.stopPrank();
    }

    function test_BalanceOf() public {
        vm.startPrank(blockTixMain);

        ticketNFT.mint(user1, 1);
        ticketNFT.mint(user1, 1);
        ticketNFT.mint(user2, 2);

        assertEq(ticketNFT.balanceOf(user1), 2);
        assertEq(ticketNFT.balanceOf(user2), 1);

        vm.stopPrank();
    }

    // ============ View Function Tests ============

    function test_GetEventId() public {
        vm.startPrank(blockTixMain);

        uint256 eventId1 = 5;
        uint256 eventId2 = 10;

        uint256 tokenId1 = ticketNFT.mint(user1, eventId1);
        uint256 tokenId2 = ticketNFT.mint(user2, eventId2);

        assertEq(ticketNFT.getEventId(tokenId1), eventId1);
        assertEq(ticketNFT.getEventId(tokenId2), eventId2);

        vm.stopPrank();
    }

    function test_GetCurrentTokenId() public {
        assertEq(ticketNFT.getCurrentTokenId(), 0);

        vm.startPrank(blockTixMain);

        ticketNFT.mint(user1, 1);
        assertEq(ticketNFT.getCurrentTokenId(), 1);

        ticketNFT.mint(user2, 2);
        assertEq(ticketNFT.getCurrentTokenId(), 2);

        vm.stopPrank();
    }

    function test_Exists() public {
        vm.startPrank(blockTixMain);

        uint256 tokenId = ticketNFT.mint(user1, 1);

        assertTrue(ticketNFT.exists(tokenId));
        assertFalse(ticketNFT.exists(999));

        vm.stopPrank();
    }

    function test_Exists_AfterBurn() public {
        vm.prank(blockTixMain);
        uint256 tokenId = ticketNFT.mint(user1, 1);

        assertTrue(ticketNFT.exists(tokenId));

        vm.prank(user1);
        ticketNFT.burn(tokenId);

        assertFalse(ticketNFT.exists(tokenId));
    }

    // ============ Edge Cases ============

    function test_MintToZeroAddress_Reverts() public {
        vm.startPrank(blockTixMain);

        vm.expectRevert();
        ticketNFT.mint(address(0), 1);

        vm.stopPrank();
    }

    function test_TransferToZeroAddress_Reverts() public {
        vm.prank(blockTixMain);
        uint256 tokenId = ticketNFT.mint(user1, 1);

        vm.startPrank(user1);

        vm.expectRevert();
        ticketNFT.transferFrom(user1, address(0), tokenId);

        vm.stopPrank();
    }

    function test_ApproveToSelf_Allowed() public {
        vm.prank(blockTixMain);
        uint256 tokenId = ticketNFT.mint(user1, 1);

        vm.startPrank(user1);

        // OpenZeppelin ERC721 allows approving to self in newer versions
        ticketNFT.approve(user1, tokenId);
        assertEq(ticketNFT.getApproved(tokenId), user1);

        vm.stopPrank();
    }
}
