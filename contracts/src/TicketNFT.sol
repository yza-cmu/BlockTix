// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TicketNFT
 * @notice ERC-721 NFT contract for event tickets
 * @dev Each ticket is represented as unique NFT token
 */
contract TicketNFT is ERC721URIStorage, Ownable {
    // State Variables
    uint256 private _tokenIdCounter;
    address public blockTixMain;
    string private _baseTokenURI;

    // Mappings
    mapping(uint256 => uint256) public tokenToEvent; // maps tokenId to eventId
    mapping(uint256 => bool) public isBurned;

    // Events
    event TicketMinted(uint256 indexed tokenId, address indexed to, uint256 indexed eventId);
    event TicketBurned(uint256 indexed tokenId);
    event BaseURIUpdated(string newBaseURI);
    event BlockTixMainUpdated(address indexed oldAddress, address indexed newAddress);

    // Errors
    error OnlyBlockTixMain();
    error TokenAlreadyBurned();
    error InvalidAddress();

    // Modifiers
    modifier onlyBlockTixMain() {
        if (msg.sender != blockTixMain) revert OnlyBlockTixMain();
        _;
    }

    /**
     * @notice Constructor
     * @param initialOwner Address of the contract owner
     * @param _blockTixMain Address of the BlockTixMain contract
     * @param baseURI Base URI for token metadata
     */
    constructor(
        address initialOwner,
        address _blockTixMain,
        string memory baseURI
    ) ERC721("BlockTix Ticket", "BTIX") Ownable(initialOwner) {
        if (_blockTixMain == address(0)) revert InvalidAddress();

        blockTixMain = _blockTixMain;
        _baseTokenURI = baseURI;
    }

    /**
     * @notice Mint new ticket NFT
     * @param to Address to mint ticket to
     * @param eventId ID of event this ticket is for
     * @return tokenId ID of newly minted ticket
     */
    function mint(address to, uint256 eventId) external onlyBlockTixMain returns (uint256) {
        uint256 tokenId = _tokenIdCounter++;

        // Set state before external call (checks-effects-interactions pattern)
        tokenToEvent[tokenId] = eventId;

        _safeMint(to, tokenId);

        emit TicketMinted(tokenId, to, eventId);

        return tokenId;
    }

    /**
     * @notice Batch mint multiple tickets
     * @param to Address to mint tickets to
     * @param eventId ID of the event
     * @param amount Number of tickets to mint
     * @return tokenIds Array of minted token IDs
     */
    function batchMint(
        address to,
        uint256 eventId,
        uint256 amount
    ) external onlyBlockTixMain returns (uint256[] memory) {
        uint256[] memory tokenIds = new uint256[](amount);

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = _tokenIdCounter++;

            // Set state before external call (checks-effects-interactions pattern)
            tokenToEvent[tokenId] = eventId;
            tokenIds[i] = tokenId;

            _safeMint(to, tokenId);

            emit TicketMinted(tokenId, to, eventId);
        }

        return tokenIds;
    }

    /**
     * @notice Burn ticket NFT
     * @param tokenId ID of ticket to burn
     * @dev can be called by token owner or BlockTixMain contract
     */
    function burn(uint256 tokenId) external {
        if (msg.sender != ownerOf(tokenId) && msg.sender != blockTixMain) {
            revert OnlyBlockTixMain();
        }
        if (isBurned[tokenId]) revert TokenAlreadyBurned();

        isBurned[tokenId] = true;
        _burn(tokenId);

        emit TicketBurned(tokenId);
    }

    /**
     * @notice Set token URI for specific token
     * @param tokenId ID of token
     * @param uri Metadata URI for token
     */
    function setTokenURI(uint256 tokenId, string memory uri) external onlyBlockTixMain {
        _setTokenURI(tokenId, uri);
    }

    /**
     * @notice Update the base URI for all tokens
     * @param newBaseURI New base URI
     * @dev Only callable by owner
     */
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        _baseTokenURI = newBaseURI;
        emit BaseURIUpdated(newBaseURI);
    }

    /**
     * @notice Update the BlockTixMain contract address
     * @param newBlockTixMain New BlockTixMain address
     * @dev Only callable by owner
     */
    function setBlockTixMain(address newBlockTixMain) external onlyOwner {
        if (newBlockTixMain == address(0)) revert InvalidAddress();

        address oldAddress = blockTixMain;
        blockTixMain = newBlockTixMain;

        emit BlockTixMainUpdated(oldAddress, newBlockTixMain);
    }

    /**
     * @notice Get the base URI
     * @return Base URI string
     */
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @notice Get event ID for given token
     * @param tokenId ID of token
     * @return eventId event ID
     */
    function getEventId(uint256 tokenId) external view returns (uint256) {
        return tokenToEvent[tokenId];
    }

    /**
     * @notice Get the current token counter
     * @return Current token ID counter
     */
    function getCurrentTokenId() external view returns (uint256) {
        return _tokenIdCounter;
    }

    /**
     * @notice Check if a token exists
     * @param tokenId ID of the token
     * @return bool True if token exists and is not burned
     */
    function exists(uint256 tokenId) external view returns (bool) {
        return _ownerOf(tokenId) != address(0) && !isBurned[tokenId];
    }
}
