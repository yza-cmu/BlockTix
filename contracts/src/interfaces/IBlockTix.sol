// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IBlockTix
 * @notice Interface for the BlockTixMain contract
 * @dev Defines core ticketing system functionality
 */
interface IBlockTix {
    // Structs
    struct Event {
        uint256 eventId;
        address organizer;
        string name;
        uint256 totalTickets;
        uint256 ticketsSold;
        uint256 basePrice;
        uint256 eventDate;
        bool isActive;
        uint256 maxResaleMarkup;
    }

    struct Ticket {
        uint256 ticketId;
        uint256 eventId;
        address currentOwner;
        uint256 purchasePrice;
        bool isUsed;
    }

    // Events
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

    // Errors
    error InvalidEventId();
    error InvalidTicketId();
    error EventNotActive();
    error SoldOut();
    error InsufficientPayment();
    error NotTicketOwner();
    error TicketAlreadyUsed();
    error ResaleMarkupExceeded();
    error NoWithdrawalAvailable();
    error WithdrawalFailed();
    error InvalidParameters();

    /**
     * @notice Create a new event
     * @param name Event name
     * @param totalTickets Total number of tickets available
     * @param basePrice Base price per ticket in wei
     * @param eventDate Unix timestamp of event date
     * @param maxResaleMarkup Maximum allowed resale markup in basis points
     * @return eventId ID of the created event
     */
    function createEvent(
        string calldata name,
        uint256 totalTickets,
        uint256 basePrice,
        uint256 eventDate,
        uint256 maxResaleMarkup
    ) external returns (uint256);

    /**
     * @notice Purchase a ticket for an event
     * @param eventId ID of the event
     * @return ticketId ID of the purchased ticket
     */
    function purchaseTicket(uint256 eventId) external payable returns (uint256);

    /**
     * @notice Transfer ticket to another address (resale)
     * @param ticketId ID of the ticket
     * @param to Address of the buyer
     */
    function transferTicket(uint256 ticketId, address to) external payable;

    /**
     * @notice Mark a ticket as used
     * @param ticketId ID of the ticket
     */
    function useTicket(uint256 ticketId) external;

    /**
     * @notice Cancel an event
     * @param eventId ID of the event
     */
    function cancelEvent(uint256 eventId) external;

    /**
     * @notice Withdraw accumulated funds
     */
    function withdraw() external;

    /**
     * @notice Update platform fee percentage
     * @param newFee New fee in basis points
     */
    function updatePlatformFee(uint256 newFee) external;

    /**
     * @notice Get event details
     * @param eventId ID of the event
     * @return Event struct
     */
    function getEvent(uint256 eventId) external view returns (Event memory);

    /**
     * @notice Get ticket details
     * @param ticketId ID of the ticket
     * @return Ticket struct
     */
    function getTicket(uint256 ticketId) external view returns (Ticket memory);

    /**
     * @notice Get total number of events
     * @return Event count
     */
    function eventCount() external view returns (uint256);

    /**
     * @notice Get platform fee percentage
     * @return Platform fee in basis points
     */
    function platformFeePercentage() external view returns (uint256);

    /**
     * @notice Get pending withdrawal for an address
     * @param account Address to check
     * @return Pending withdrawal amount
     */
    function pendingWithdrawals(address account) external view returns (uint256);

    /**
     * @notice Get TicketNFT contract address
     * @return Address of TicketNFT
     */
    function ticketNFT() external view returns (address);

    /**
     * @notice Get PriceOracle contract address
     * @return Address of PriceOracle
     */
    function priceOracle() external view returns (address);
}
