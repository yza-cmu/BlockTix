// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title ITicketNFT
 * @notice Interface for TicketNFT contract
 * @dev extends IERC721 with ticket specific functionality
 */
interface ITicketNFT is IERC721 {
    // Events
    event TicketMinted(uint256 indexed tokenId, address indexed to, uint256 indexed eventId);
    event TicketBurned(uint256 indexed tokenId);
    event BaseURIUpdated(string newBaseURI);
    event BlockTixMainUpdated(address indexed oldAddress, address indexed newAddress);

    // Errors
    error OnlyBlockTixMain();
    error TokenAlreadyBurned();
    error InvalidAddress();

    /**
     * @notice Mint new ticket NFT
     * @param to Address to mint ticket to
     * @param eventId ID of event this ticket is for
     * @return tokenId ID of newly minted ticket
     */
    function mint(address to, uint256 eventId) external returns (uint256);

    /**
     * @notice Batch mint multiple tickets
     * @param to Address to mint tickets to
     * @param eventId ID of the event
     * @param amount Number of tickets to mint
     * @return tokenIds Array of minted token IDs
     */
    function batchMint(address to, uint256 eventId, uint256 amount) external returns (uint256[] memory);

    /**
     * @notice Burn a ticket NFT
     * @param tokenId ID of the ticket to burn
     */
    function burn(uint256 tokenId) external;

    /**
     * @notice Set the token URI for a specific token
     * @param tokenId ID of the token
     * @param uri Metadata URI for the token
     */
    function setTokenURI(uint256 tokenId, string memory uri) external;

    /**
     * @notice Update the base URI for all tokens
     * @param newBaseURI New base URI
     */
    function setBaseURI(string memory newBaseURI) external;

    /**
     * @notice Update the BlockTixMain contract address
     * @param newBlockTixMain New BlockTixMain address
     */
    function setBlockTixMain(address newBlockTixMain) external;

    /**
     * @notice Get the event ID for a given token
     * @param tokenId ID of the token
     * @return eventId The event ID
     */
    function getEventId(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Get the current token counter
     * @return Current token ID counter
     */
    function getCurrentTokenId() external view returns (uint256);

    /**
     * @notice Check if a token exists
     * @param tokenId ID of the token
     * @return bool True if token exists and is not burned
     */
    function exists(uint256 tokenId) external view returns (bool);

    /**
     * @notice Get the BlockTixMain contract address
     * @return Address of BlockTixMain
     */
    function blockTixMain() external view returns (address);
}
