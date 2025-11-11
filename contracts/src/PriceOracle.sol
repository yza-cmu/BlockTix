// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title PriceOracle
 * @notice Handles dynamic pricing for ticket sales based on demand and time
 * @dev implements surge pricing and time based adjustments
 */
contract PriceOracle is Ownable, Pausable {
    // State Variables
    uint256 public demandMultiplierBasisPoints; // basis points, 100 = 1%
    uint256 public timeDecayBasisPoints; // basis points for time based discount
    address public blockTixMain;

    // Price adjustment thresholds
    uint256 public constant SURGE_THRESHOLD_1 = 50; // 50% sold (or 50 tickets depending on usage)
    uint256 public constant SURGE_THRESHOLD_2 = 75; // 75% sold
    uint256 public constant SURGE_THRESHOLD_3 = 90; // 90% sold

    // Surge multipliers in basis points
    uint256 public surgeMultiplier1 = 500; // 5% increase
    uint256 public surgeMultiplier2 = 1000; // 10% increase
    uint256 public surgeMultiplier3 = 2000; // 20% increase

    // Mappings
    mapping(uint256 => PriceHistory[]) public eventPriceHistory;

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

    // Modifiers
    modifier onlyBlockTixMain() {
        if (msg.sender != blockTixMain) revert OnlyBlockTixMain();
        _;
    }

    /**
     * @notice Constructor
     * @param initialOwner Address of the contract owner
     * @param _blockTixMain Address of BlockTixMain contract
     * @param _demandMultiplier Initial demand multiplier in basis points
     * @param _timeDecay Initial time decay in basis points
     */
    constructor(
        address initialOwner,
        address _blockTixMain,
        uint256 _demandMultiplier,
        uint256 _timeDecay
    ) Ownable(initialOwner) {
        if (_blockTixMain == address(0)) revert InvalidAddress();

        blockTixMain = _blockTixMain;
        demandMultiplierBasisPoints = _demandMultiplier;
        timeDecayBasisPoints = _timeDecay;
    }

    /**
     * @notice Calculate dynamic price for ticket (surge only)
     * @param eventId ID of event
     * @param basePrice Base price of ticket
     * @param ticketsSold Number of tickets sold already
     * @return Calculated price in wei
     */
    function calculatePrice(
        uint256 eventId,
        uint256 basePrice,
        uint256 ticketsSold
    ) external whenNotPaused onlyBlockTixMain returns (uint256) {
        uint256 price = basePrice;

        // Apply surge + demand multiplier
        price = _applySurgePricing(price, ticketsSold);

        // Record price in history
        eventPriceHistory[eventId].push(
            PriceHistory({timestamp: block.timestamp, price: price, ticketsSold: ticketsSold})
        );

        emit PriceCalculated(eventId, price, ticketsSold);

        return price;
    }

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
    ) external whenNotPaused onlyBlockTixMain returns (uint256) {
        if (totalTickets == 0) revert InvalidParameters();

        uint256 price = basePrice;

        // Apply surge pricing (percentage-based) + demand multiplier
        uint256 soldPercentage = (ticketsSold * 100) / totalTickets;
        price = _applySurgePricingWithPercentage(price, soldPercentage);

        // Apply time decay if applicable
        if (block.timestamp < eventDate) {
            uint256 timeUntilEvent = eventDate - block.timestamp;
            uint256 oneWeek = 7 days;

            // Apply discount if event is more than 1 week away
            if (timeUntilEvent > oneWeek) {
                uint256 discount = (price * timeDecayBasisPoints) / 10000;
                price = price - discount;
            }
        }

        // Record price in history
        eventPriceHistory[eventId].push(
            PriceHistory({timestamp: block.timestamp, price: price, ticketsSold: ticketsSold})
        );

        emit PriceCalculated(eventId, price, ticketsSold);

        return price;
    }

    /**
     * @notice Validate resale price against markup limits
     * @param originalPrice Original purchase price
     * @param resalePrice Proposed resale price
     * @param maxMarkupBasisPoints Maximum allowed markup in basis points
     * @return bool true if resale price is valid
     */
    function validateResalePrice(
        uint256 originalPrice,
        uint256 resalePrice,
        uint256 maxMarkupBasisPoints
    ) external pure returns (bool) {
        uint256 maxAllowedPrice = originalPrice + (originalPrice * maxMarkupBasisPoints) / 10000;
        return resalePrice <= maxAllowedPrice;
    }

    /**
     * @notice Internal function to apply surge pricing based on tickets sold
     *         Also applies demand multiplier if set
     */
    function _applySurgePricing(uint256 basePrice, uint256 ticketsSold) internal view returns (uint256) {
        uint256 price = basePrice;

        if (ticketsSold >= SURGE_THRESHOLD_3) {
            price = basePrice + (basePrice * surgeMultiplier3) / 10000;
        } else if (ticketsSold >= SURGE_THRESHOLD_2) {
            price = basePrice + (basePrice * surgeMultiplier2) / 10000;
        } else if (ticketsSold >= SURGE_THRESHOLD_1) {
            price = basePrice + (basePrice * surgeMultiplier1) / 10000;
        }

        // Apply demand multiplier on top if configured
        if (demandMultiplierBasisPoints > 0) {
            uint256 demandIncrease = (price * demandMultiplierBasisPoints) / 10000;
            price = price + demandIncrease;
        }

        return price;
    }

    /**
     * @notice Internal function to apply surge pricing based on percentage
     *         Also applies demand multiplier if set
     */
    function _applySurgePricingWithPercentage(
        uint256 basePrice,
        uint256 soldPercentage
    ) internal view returns (uint256) {
        uint256 price = basePrice;

        if (soldPercentage >= SURGE_THRESHOLD_3) {
            price = basePrice + (basePrice * surgeMultiplier3) / 10000;
        } else if (soldPercentage >= SURGE_THRESHOLD_2) {
            price = basePrice + (basePrice * surgeMultiplier2) / 10000;
        } else if (soldPercentage >= SURGE_THRESHOLD_1) {
            price = basePrice + (basePrice * surgeMultiplier1) / 10000;
        }

        // Apply demand multiplier on top if configured
        if (demandMultiplierBasisPoints > 0) {
            uint256 demandIncrease = (price * demandMultiplierBasisPoints) / 10000;
            price = price + demandIncrease;
        }

        return price;
    }

    /**
     * @notice Update demand multiplier
     * @param newMultiplier New multiplier in basis points
     */
    function setDemandMultiplier(uint256 newMultiplier) external onlyOwner {
        if (newMultiplier > 5000) revert InvalidParameters(); // Max 50%

        uint256 oldMultiplier = demandMultiplierBasisPoints;
        demandMultiplierBasisPoints = newMultiplier;

        emit DemandMultiplierUpdated(oldMultiplier, newMultiplier);
    }

    /**
     * @notice Update time decay percentage
     * @param newDecay New decay in basis points
     */
    function setTimeDecay(uint256 newDecay) external onlyOwner {
        if (newDecay > 5000) revert InvalidParameters(); // Max 50%

        uint256 oldDecay = timeDecayBasisPoints;
        timeDecayBasisPoints = newDecay;

        emit TimeDecayUpdated(oldDecay, newDecay);
    }

    /**
     * @notice Update surge multipliers
     * @param _surge1 Multiplier for 50% threshold
     * @param _surge2 Multiplier for 75% threshold
     * @param _surge3 Multiplier for 90% threshold
     */
    function setSurgeMultipliers(uint256 _surge1, uint256 _surge2, uint256 _surge3) external onlyOwner {
        if (_surge1 > _surge2 || _surge2 > _surge3) revert InvalidParameters();

        surgeMultiplier1 = _surge1;
        surgeMultiplier2 = _surge2;
        surgeMultiplier3 = _surge3;

        emit SurgeMultipliersUpdated(_surge1, _surge2, _surge3);
    }

    /**
     * @notice Update BlockTixMain contract address
     * @param newBlockTixMain New address
     */
    function setBlockTixMain(address newBlockTixMain) external onlyOwner {
        if (newBlockTixMain == address(0)) revert InvalidAddress();

        address oldAddress = blockTixMain;
        blockTixMain = newBlockTixMain;

        emit BlockTixMainUpdated(oldAddress, newBlockTixMain);
    }

    /**
     * @notice Pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Get price history for an event
     * @param eventId ID of the event
     * @return PriceHistory array
     */
    function getPriceHistory(uint256 eventId) external view returns (PriceHistory[] memory) {
        return eventPriceHistory[eventId];
    }

    /**
     * @notice Get the latest price for an event
     * @param eventId ID of the event
     * @return Latest price
     */
    function getLatestPrice(uint256 eventId) external view returns (uint256) {
        PriceHistory[] memory history = eventPriceHistory[eventId];
        if (history.length == 0) return 0;
        return history[history.length - 1].price;
    }
}

