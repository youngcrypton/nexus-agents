// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {NexusAccount} from "../src/NexusAccount.sol";
import {NexusAccountRegistry} from "../src/NexusAccountRegistry.sol";
import {NexusAgentRegistry} from "../src/NexusAgentRegistry.sol";
import {NexusEscrow} from "../src/NexusEscrow.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

/// @title DeployNexus
/// @notice Deployment script for Nexus Agents on Elysium Testnet (99801) and HyperEVM
contract DeployNexus is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envOr("DEPLOYER_PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Test Tokens (for Testnet demonstration)
        MockERC20 nexusToken = new MockERC20("Nexus Protocol", "NEXUS", 18);
        console.log("Deployed NEXUS Token:", address(nexusToken));

        MockERC20 usdcToken = new MockERC20("USD Coin", "USDC", 6);
        console.log("Deployed Mock USDC:", address(usdcToken));

        // 2. Deploy ERC-6551 Infrastructure
        NexusAccount accountImpl = new NexusAccount();
        console.log("Deployed NexusAccount Implementation:", address(accountImpl));

        NexusAccountRegistry accountReg = new NexusAccountRegistry();
        console.log("Deployed NexusAccountRegistry:", address(accountReg));

        // 3. Deploy Agent Registry (Minimum bond: 1,000 NEXUS)
        uint256 minimumBond = 1000 * 1e18;
        NexusAgentRegistry agentRegistry = new NexusAgentRegistry(
            address(nexusToken),
            address(accountReg),
            address(accountImpl),
            minimumBond
        );
        console.log("Deployed NexusAgentRegistry:", address(agentRegistry));

        // 4. Deploy Escrow (burnPool initially set to deployer)
        address burnPool = vm.addr(deployerPrivateKey);
        NexusEscrow escrow = new NexusEscrow(address(agentRegistry), burnPool);
        console.log("Deployed NexusEscrow:", address(escrow));

        vm.stopBroadcast();
    }
}
