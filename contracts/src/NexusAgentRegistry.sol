// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC6551Registry} from "./interfaces/IERC6551Registry.sol";

/// @title NexusAgentRegistry
/// @notice Master registry for autonomous AI agents on Elysium. Issues Agent Identity NFTs and enforces performance bonds.
contract NexusAgentRegistry is ERC721, Ownable {
    using SafeERC20 for IERC20;

    enum StrategyType {
        SENTRY,   // Automated Market Maker for Ascend & HyperCore
        ARBITER,  // Cross-Venue Arbitrageur between Elysium AMMs & HyperCore
        APEX,     // Sentiment & High-Frequency Momentum Trader
        VANGUARD, // Portfolio & kHYPE Staking Optimizer
        CUSTOM    // Developer-defined custom agentic model
    }

    struct AgentProfile {
        string name;
        StrategyType strategyType;
        string metadataUri;
        address accountAddress;
        uint256 registeredAt;
        uint256 stakedBond;
        bool isActive;
    }

    IERC20 public immutable nexusToken;
    IERC6551Registry public immutable accountRegistry;
    address public immutable accountImplementation;

    uint256 public nextAgentId = 1;
    uint256 public minimumBondAmount;
    uint256 public bondCooldownDuration = 3 days;

    mapping(uint256 => AgentProfile) public agents;
    mapping(uint256 => uint256) public deactivationTimestamp;
    mapping(address => bool) public authorizedSlashers;

    event AgentRegistered(
        uint256 indexed agentId,
        address indexed creator,
        address indexed accountAddress,
        StrategyType strategyType,
        string name,
        uint256 stakedBond
    );
    event AgentBondSlashed(uint256 indexed agentId, uint256 amount, address recipient, string reason);
    event AgentBondToppedUp(uint256 indexed agentId, uint256 amount);
    event AgentStatusChanged(uint256 indexed agentId, bool isActive);
    event AgentBondWithdrawn(uint256 indexed agentId, address indexed recipient, uint256 amount);

    constructor(
        address _nexusToken,
        address _accountRegistry,
        address _accountImplementation,
        uint256 _minimumBondAmount
    ) ERC721("Nexus Agent Identity", "NEXUS-AGENT") Ownable(msg.sender) {
        nexusToken = IERC20(_nexusToken);
        accountRegistry = IERC6551Registry(_accountRegistry);
        accountImplementation = _accountImplementation;
        minimumBondAmount = _minimumBondAmount;
    }

    function setAuthorizedSlasher(address slasher, bool authorized) external onlyOwner {
        authorizedSlashers[slasher] = authorized;
    }

    function setMinimumBondAmount(uint256 newMinimum) external onlyOwner {
        minimumBondAmount = newMinimum;
    }

    function setBondCooldownDuration(uint256 newCooldown) external onlyOwner {
        bondCooldownDuration = newCooldown;
    }

    /// @notice Register a new autonomous AI agent, lock performance bond, and deploy its ERC-6551 Smart Account
    function registerAgent(
        string calldata name,
        StrategyType strategyType,
        string calldata metadataUri,
        uint256 bondAmount
    ) external returns (uint256 agentId, address account) {
        require(bondAmount >= minimumBondAmount, "Registry: bond below minimum");

        agentId = nextAgentId++;
        _safeMint(msg.sender, agentId);

        // Pull performance bond
        if (bondAmount > 0) {
            nexusToken.safeTransferFrom(msg.sender, address(this), bondAmount);
        }

        // Deploy Token-Bound Account (salt is keccak of agentId)
        bytes32 salt = bytes32(agentId);
        account = accountRegistry.createAccount(
            accountImplementation,
            salt,
            block.chainid,
            address(this),
            agentId
        );

        agents[agentId] = AgentProfile({
            name: name,
            strategyType: strategyType,
            metadataUri: metadataUri,
            accountAddress: account,
            registeredAt: block.timestamp,
            stakedBond: bondAmount,
            isActive: true
        });

        emit AgentRegistered(agentId, msg.sender, account, strategyType, name, bondAmount);
    }

    /// @notice Top up performance bond for an existing agent
    function topUpBond(uint256 agentId, uint256 amount) external {
        require(_ownerOf(agentId) != address(0), "Registry: agent does not exist");
        require(amount > 0, "Registry: amount must be > 0");

        nexusToken.safeTransferFrom(msg.sender, address(this), amount);
        agents[agentId].stakedBond += amount;

        emit AgentBondToppedUp(agentId, amount);
    }

    /// @notice Slash bond in case of verified SLA violations or downtime
    function slashBond(
        uint256 agentId,
        uint256 amount,
        address recipient,
        string calldata reason
    ) external {
        require(authorizedSlashers[msg.sender] || msg.sender == owner(), "Registry: unauthorized slasher");
        AgentProfile storage profile = agents[agentId];
        require(profile.stakedBond >= amount, "Registry: slash exceeds bond");

        profile.stakedBond -= amount;
        nexusToken.safeTransfer(recipient, amount);

        emit AgentBondSlashed(agentId, amount, recipient, reason);
    }

    /// @notice Deactivate an agent (initiates cooldown for bond withdrawal)
    function deactivateAgent(uint256 agentId) external {
        require(ownerOf(agentId) == msg.sender, "Registry: not agent owner");
        AgentProfile storage profile = agents[agentId];
        require(profile.isActive, "Registry: already inactive");

        profile.isActive = false;
        deactivationTimestamp[agentId] = block.timestamp;

        emit AgentStatusChanged(agentId, false);
    }

    /// @notice Reactivate an agent
    function reactivateAgent(uint256 agentId) external {
        require(ownerOf(agentId) == msg.sender, "Registry: not agent owner");
        AgentProfile storage profile = agents[agentId];
        require(!profile.isActive, "Registry: already active");
        require(profile.stakedBond >= minimumBondAmount, "Registry: bond below minimum");

        profile.isActive = true;
        deactivationTimestamp[agentId] = 0;

        emit AgentStatusChanged(agentId, true);
    }

    /// @notice Withdraw performance bond after deactivation cooldown has expired
    function withdrawBond(uint256 agentId, uint256 amount) external {
        require(ownerOf(agentId) == msg.sender, "Registry: not agent owner");
        AgentProfile storage profile = agents[agentId];
        require(!profile.isActive, "Registry: agent must be deactivated");
        require(
            block.timestamp >= deactivationTimestamp[agentId] + bondCooldownDuration,
            "Registry: cooldown not elapsed"
        );
        require(profile.stakedBond >= amount, "Registry: insufficient bond");

        profile.stakedBond -= amount;
        nexusToken.safeTransfer(msg.sender, amount);

        emit AgentBondWithdrawn(agentId, msg.sender, amount);
    }

    function getAgent(uint256 agentId) external view returns (AgentProfile memory) {
        require(_ownerOf(agentId) != address(0), "Registry: agent does not exist");
        return agents[agentId];
    }
}
