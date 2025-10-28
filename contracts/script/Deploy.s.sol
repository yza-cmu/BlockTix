// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {BlockTixMain} from "../src/BlockTixMain.sol";
import {TicketNFT} from "../src/TicketNFT.sol";
import {PriceOracle} from "../src/PriceOracle.sol";

/**
 * @title Deploy
 * @notice Deployment script for BlockTix contracts
 * @dev deploys all contracts in correct order and configures dependencies
 */
contract Deploy is Script {
    // Deployment configuration
    uint256 public constant PLATFORM_FEE = 250; // 2.5%
    uint256 public constant DEMAND_MULTIPLIER = 1000; // 10%
    uint256 public constant TIME_DECAY = 500; // 5%
    string public constant BASE_URI = "https://blocktix.io/metadata/";

    // Deployed contract instances
    BlockTixMain public blockTixMain;
    TicketNFT public ticketNFT;
    PriceOracle public priceOracle;

    function run() external {
        // Get deployer address
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("===========================================");
        console.log("BlockTix Deployment Script");
        console.log("===========================================");
        console.log("Deployer address:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Step 1: Deploy PriceOracle
        console.log("Step 1: Deploying PriceOracle...");
        priceOracle = new PriceOracle(
            deployer, // owner
            address(1), // temp blockTixMain address, will be updated later
            DEMAND_MULTIPLIER,
            TIME_DECAY
        );
        console.log("PriceOracle deployed at:", address(priceOracle));
        console.log("");

        // Step 2: Deploy TicketNFT
        console.log("Step 2: Deploying TicketNFT...");
        ticketNFT = new TicketNFT(
            deployer, // owner
            address(1), // temporary blockTixMain address (will be updated)
            BASE_URI
        );
        console.log("TicketNFT deployed at:", address(ticketNFT));
        console.log("");

        // Step 3: Deploy BlockTixMain
        console.log("Step 3: Deploying BlockTixMain...");
        blockTixMain = new BlockTixMain(address(ticketNFT), address(priceOracle), PLATFORM_FEE);
        console.log("BlockTixMain deployed at:", address(blockTixMain));
        console.log("");

        // Step 4: Configure cross-contract references
        console.log("Step 4: Configuring contract references...");

        ticketNFT.setBlockTixMain(address(blockTixMain));
        console.log("- TicketNFT.blockTixMain set to:", address(blockTixMain));

        priceOracle.setBlockTixMain(address(blockTixMain));
        console.log("- PriceOracle.blockTixMain set to:", address(blockTixMain));
        console.log("");

        // Step 5: Verify deployment
        console.log("Step 5: Verifying deployment...");
        require(ticketNFT.blockTixMain() == address(blockTixMain), "TicketNFT configuration failed");
        require(priceOracle.blockTixMain() == address(blockTixMain), "PriceOracle configuration failed");
        require(address(blockTixMain.ticketNFT()) == address(ticketNFT), "BlockTixMain NFT reference failed");
        require(address(blockTixMain.priceOracle()) == address(priceOracle), "BlockTixMain Oracle reference failed");
        require(blockTixMain.platformFeePercentage() == PLATFORM_FEE, "Platform fee configuration failed");
        console.log("All verifications passed!");
        console.log("");

        vm.stopBroadcast();

        // Print deployment summary
        printDeploymentSummary(deployer);
    }

    function printDeploymentSummary(address deployer) internal view {
        console.log("===========================================");
        console.log("Deployment Summary");
        console.log("===========================================");
        console.log("Network: Chain ID", block.chainid);
        console.log("Deployer:", deployer);
        console.log("");
        console.log("Deployed Contracts:");
        console.log("-------------------------------------------");
        console.log("BlockTixMain:", address(blockTixMain));
        console.log("TicketNFT:", address(ticketNFT));
        console.log("PriceOracle:", address(priceOracle));
        console.log("");
        console.log("Configuration:");
        console.log("-------------------------------------------");
        console.log("Platform Fee:", PLATFORM_FEE, "bp (2.5%)");
        console.log("Demand Multiplier:", DEMAND_MULTIPLIER, "bp (10%)");
        console.log("Time Decay:", TIME_DECAY, "bp (5%)");
        console.log("Base URI:", BASE_URI);
        console.log("");
        console.log("Ownership:");
        console.log("-------------------------------------------");
        console.log("BlockTixMain Owner:", blockTixMain.owner());
        console.log("TicketNFT Owner:", ticketNFT.owner());
        console.log("PriceOracle Owner:", priceOracle.owner());
        console.log("===========================================");
    }

    /**
     * @notice Helper function to deploy with custom parameters
     * @dev can be called directly for custom deployments
     */
    function deployWithParams(
        address owner,
        uint256 platformFee,
        uint256 demandMultiplier,
        uint256 timeDecay,
        string memory baseURI
    ) public returns (address, address, address) {
        vm.startBroadcast();

        // Deploy contracts
        PriceOracle oracle = new PriceOracle(owner, address(1), demandMultiplier, timeDecay);
        TicketNFT nft = new TicketNFT(owner, address(1), baseURI);
        BlockTixMain main = new BlockTixMain(address(nft), address(oracle), platformFee);

        // Configure references
        nft.setBlockTixMain(address(main));
        oracle.setBlockTixMain(address(main));

        vm.stopBroadcast();

        return (address(main), address(nft), address(oracle));
    }
}
