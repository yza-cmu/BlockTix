// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ITicketNFT} from "./interfaces/ITicketNFT.sol";
import {IPriceOracle} from "./interfaces/IPriceOracle.sol";

/**
 * @title BlockTixMain
 * @notice Primary contract for decentralized event ticketing platform
 * @dev Manages event creation, ticket sales, transfers, and resale with configurable rules
 */
contract BlockTixMain is ReentrancyGuard, Ownable {
    // State Variables
    ITicketNFT public ticketNFT;
    IPriceOracle public priceOracle;

    uint256 public eventCount;
    uint256 public platformFeePercentage; // basis points, 100 = 1%

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
        uint256 maxResaleMarkup; // Basis points
    }

    struct Ticket {
        uint256 ticketId;
        uint256 eventId;
        address currentOwner;
        uint256 purchasePrice;
        bool isUsed;
    }

    // Mappings
    mapping(uint256 => Event) public events;
    mapping(uint256 => Ticket) public tickets;
    mapping(uint256 => uint256) public ticketToEvent; // ticketId => eventId
    mapping(address => uint256) public pendingWithdrawals;

    // Events
    event EventCreated(
        uint256 indexed eventId,
        address indexed organizer,
        string name,
        uint256 totalTickets,
        uint256 basePrice,
        uint256 eventDate
    );

    event TicketPurchased(
        uint256 indexed ticketId,
        uint256 indexed eventId,
        address indexed buyer,
        uint256 price
    );

    event TicketTransferred(
        uint256 indexed ticketId,
        address indexed from,
        address indexed to,
        uint256 price
    );

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
     * @notice Constructor
     * @param _ticketNFT Address of TicketNFT contract
     * @param _priceOracle Address of PriceOracle contract
     * @param _platformFee Initial platform fee in basis points
     */
    constructor(
        address _ticketNFT,
        address _priceOracle,
        uint256 _platformFee
    ) Ownable(msg.sender) {
        if (_ticketNFT == address(0) || _priceOracle == address(0)) revert InvalidParameters();

        ticketNFT = ITicketNFT(_ticketNFT);
        priceOracle = IPriceOracle(_priceOracle);
        platformFeePercentage = _platformFee;
    }

    /**
     * @notice Create a new event
     * @param name Event name
     * @param totalTickets Total number of tickets available
     * @param basePrice Base price per ticket in wei
     * @param eventDate Unix timestamp of event date
     * @param maxResaleMarkup Maximum allowed resale markup in basis points
     */
    function createEvent(
        string calldata name,
        uint256 totalTickets,
        uint256 basePrice,
        uint256 eventDate,
        uint256 maxResaleMarkup
    ) external returns (uint256) {
        if (totalTickets == 0 || basePrice == 0 || eventDate <= block.timestamp) {
            revert InvalidParameters();
        }

        uint256 eventId = eventCount++;

        events[eventId] = Event({
            eventId: eventId,
            organizer: msg.sender,
            name: name,
            totalTickets: totalTickets,
            ticketsSold: 0,
            basePrice: basePrice,
            eventDate: eventDate,
            isActive: true,
            maxResaleMarkup: maxResaleMarkup
        });

        emit EventCreated(eventId, msg.sender, name, totalTickets, basePrice, eventDate);

        return eventId;
    }

    /**
     * @notice Purchase a ticket for an event
     * @param eventId ID of the event
     */
    function purchaseTicket(uint256 eventId) external payable nonReentrant returns (uint256) {
        if (eventId >= eventCount) revert InvalidEventId();

        Event storage eventData = events[eventId];

        if (!eventData.isActive) revert EventNotActive();
        if (eventData.ticketsSold >= eventData.totalTickets) revert SoldOut();

        // 🔹 Use full dynamic pricing: surge + time decay (via PriceOracle)
        uint256 price = priceOracle.calculatePriceWithTimeDecay(
            eventId,
            eventData.basePrice,
            eventData.ticketsSold,
            eventData.totalTickets,
            eventData.eventDate
        );

        if (msg.value < price) revert InsufficientPayment();

        uint256 ticketId = ticketNFT.mint(msg.sender, eventId);

        tickets[ticketId] = Ticket({
            ticketId: ticketId,
            eventId: eventId,
            currentOwner: msg.sender,
            purchasePrice: price,
            isUsed: false
        });

        ticketToEvent[ticketId] = eventId;
        eventData.ticketsSold++;

        // Calculate and distribute fees
        uint256 platformFee = (price * platformFeePercentage) / 10000;
        uint256 organizerAmount = price - platformFee;

        pendingWithdrawals[eventData.organizer] += organizerAmount;
        pendingWithdrawals[owner()] += platformFee;

        // Refund excess payment
        if (msg.value > price) {
            (bool success, ) = msg.sender.call{value: msg.value - price}("");
            if (!success) revert WithdrawalFailed();
        }

        emit TicketPurchased(ticketId, eventId, msg.sender, price);

        return ticketId;
    }

    /**
     * @notice Transfer ticket to another address (resale)
     * @param ticketId ID of the ticket
     * @param to Address of the buyer
     */
    function transferTicket(uint256 ticketId, address to) external payable nonReentrant {
        Ticket storage ticket = tickets[ticketId];

        if (ticket.currentOwner != msg.sender) revert NotTicketOwner();
        if (ticket.isUsed) revert TicketAlreadyUsed();

        uint256 eventId = ticket.eventId;
        Event storage eventData = events[eventId];

        if (!eventData.isActive) revert EventNotActive();

        // 🔹 Validate resale price via PriceOracle
        bool isValid = priceOracle.validateResalePrice(
            ticket.purchasePrice,
            msg.value,
            eventData.maxResaleMarkup
        );
        if (!isValid) revert ResaleMarkupExceeded();

        // Calculate fees
        uint256 platformFee = (msg.value * platformFeePercentage) / 10000;
        uint256 sellerAmount = msg.value - platformFee;

        pendingWithdrawals[msg.sender] += sellerAmount;
        pendingWithdrawals[owner()] += platformFee;

        // Update ticket ownership
        ticket.currentOwner = to;
        ticket.purchasePrice = msg.value;

        // Transfer NFT
        ticketNFT.transferFrom(msg.sender, to, ticketId);

        emit TicketTransferred(ticketId, msg.sender, to, msg.value);
    }

    /**
     * @notice Mark a ticket as used
     * @param ticketId ID of the ticket
     * @dev Only callable by event organizer
     */
    function useTicket(uint256 ticketId) external {
        Ticket storage ticket = tickets[ticketId];
        Event storage eventData = events[ticket.eventId];

        if (msg.sender != eventData.organizer) revert NotTicketOwner();
        if (ticket.isUsed) revert TicketAlreadyUsed();

        ticket.isUsed = true;

        emit TicketUsed(ticketId, ticket.eventId);
    }

    /**
     * @notice Cancel an event
     * @param eventId ID of the event
     * @dev Only callable by event organizer
     */
    function cancelEvent(uint256 eventId) external {
        if (eventId >= eventCount) revert InvalidEventId();

        Event storage eventData = events[eventId];

        if (msg.sender != eventData.organizer) revert NotTicketOwner();

        eventData.isActive = false;

        emit EventCancelled(eventId);
    }

    /**
     * @notice Withdraw accumulated funds
     */
    function withdraw() external nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];

        if (amount == 0) revert NoWithdrawalAvailable();

        pendingWithdrawals[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: amount}("");
        if (!success) {
            pendingWithdrawals[msg.sender] = amount; // Restore on failure
            revert WithdrawalFailed();
        }

        emit WithdrawalProcessed(msg.sender, amount);
    }

    /**
     * @notice Update platform fee percentage
     * @param newFee New fee in basis points
     * @dev Only callable by owner
     */
    function updatePlatformFee(uint256 newFee) external onlyOwner {
        if (newFee > 1000) revert InvalidParameters(); // Max 10%

        uint256 oldFee = platformFeePercentage;
        platformFeePercentage = newFee;

        emit PlatformFeeUpdated(oldFee, newFee);
    }

    /**
     * @notice Get event details
     * @param eventId ID of the event
     */
    function getEvent(uint256 eventId) external view returns (Event memory) {
        if (eventId >= eventCount) revert InvalidEventId();
        return events[eventId];
    }

    /**
     * @notice Get ticket details
     * @param ticketId ID of the ticket
     */
    function getTicket(uint256 ticketId) external view returns (Ticket memory) {
        return tickets[ticketId];
    }
}
