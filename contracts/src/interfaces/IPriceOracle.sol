// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IPriceOracle
 * @notice Interface for the PriceOracle contract
 * @dev Defines pricing and validation functions for the ticketing system
 */
interface IPriceOracle {
    // Structs
    struct PriceHistory {
        uint256 timestamp;
        uint256 price;
        uint256 ticketsSold;
    }

    // Events
    event PriceCalculated(uint256 indexed eventId, uint256 price, uint256 ticketsSold);
    event DemandMultiplierUpdated(uint256 oldMultiplier, uint256 newMultiplier);
    event TimeDecayUpdated(uint256 oldDecay, uint256 newDecay);
    event SurgeMultipliersUpdated(uint256 surge1, uint256 surge2, uint256 surge3);
    event BlockTixMainUpdated(address indexed oldAddress, address indexed newAddress);

    // Errors
    error OnlyBlockTixMain();
    error InvalidParameters();
    error InvalidAddress();

    /**
     * @notice Calculate dynamic price for a ticket
     * @param eventId ID of the event
     * @param basePrice Base price of the ticket
     * @param ticketsSold Number of tickets already sold
     * @return Calculated price in wei
     */
    function calculatePrice(uint256 eventId, uint256 basePrice, uint256 ticketsSold) external returns (uint256);

    /**
     * @notice Calculate price with time-based adjustment
     * @param eventId ID of the event
     * @param basePrice Base price of the ticket
     * @param ticketsSold Number of tickets already sold
     * @param totalTickets Total tickets available
     * @param eventDate Unix timestamp of the event
     * @return Calculated price with time adjustment
     */
    function calculatePriceWithTimeDecay(
        uint256 eventId,
        uint256 basePrice,
        uint256 ticketsSold,
        uint256 totalTickets,
        uint256 eventDate
    ) external returns (uint256);

    /**
     * @notice Validate resale price against markup limits
     * @param originalPrice Original purchase price
     * @param resalePrice Proposed resale price
     * @param maxMarkupBasisPoints Maximum allowed markup in basis points
     * @return bool True if resale price is valid
     */
    function validateResalePrice(
        uint256 originalPrice,
        uint256 resalePrice,
        uint256 maxMarkupBasisPoints
    ) external pure returns (bool);

    /**
     * @notice Update demand multiplier
     * @param newMultiplier New multiplier in basis points
     */
    function setDemandMultiplier(uint256 newMultiplier) external;

    /**
     * @notice Update time decay percentage
     * @param newDecay New decay in basis points
     */
    function setTimeDecay(uint256 newDecay) external;

    /**
     * @notice Update surge multipliers
     * @param _surge1 Multiplier for 50% threshold
     * @param _surge2 Multiplier for 75% threshold
     * @param _surge3 Multiplier for 90% threshold
     */
    function setSurgeMultipliers(uint256 _surge1, uint256 _surge2, uint256 _surge3) external;

    /**
     * @notice Update BlockTixMain contract address
     * @param newBlockTixMain New address
     */
    function setBlockTixMain(address newBlockTixMain) external;

    /**
     * @notice Pause the contract
     */
    function pause() external;

    /**
     * @notice Unpause the contract
     */
    function unpause() external;

    /**
     * @notice Get price history for an event
     * @param eventId ID of the event
     * @return PriceHistory array
     */
    function getPriceHistory(uint256 eventId) external view returns (PriceHistory[] memory);

    /**
     * @notice Get the latest price for an event
     * @param eventId ID of the event
     * @return Latest price
     */
    function getLatestPrice(uint256 eventId) external view returns (uint256);

    /**
     * @notice Get demand multiplier
     * @return Demand multiplier in basis points
     */
    function demandMultiplierBasisPoints() external view returns (uint256);

    /**
     * @notice Get time decay value
     * @return Time decay in basis points
     */
    function timeDecayBasisPoints() external view returns (uint256);

    /**
     * @notice Get BlockTixMain address
     * @return Address of BlockTixMain
     */
    function blockTixMain() external view returns (address);
}
