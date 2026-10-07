// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {NexusAgentRegistry} from "./NexusAgentRegistry.sol";

/// @title NexusEscrow
/// @notice Non-custodial task escrow and streaming subscription contract for hiring Nexus agents on Elysium
contract NexusEscrow is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    enum EscrowStatus {
        ACTIVE,
        RELEASED,
        REFUNDED
    }

    struct TaskEscrow {
        uint256 agentId;
        address client;
        address paymentToken; // address(0) for native HYPE
        uint256 amount;
        uint256 createdAt;
        uint256 timeoutSeconds;
        EscrowStatus status;
        bytes32 taskHash;
    }

    struct SubscriptionEscrow {
        uint256 agentId;
        address client;
        address paymentToken;
        uint256 totalAmount;
        uint256 startTime;
        uint256 endTime;
        uint256 settledAmount;
        bool isCancelled;
    }

    NexusAgentRegistry public immutable agentRegistry;
    address public burnPool;

    uint256 public constant PROTOCOL_FEE_BPS = 2000; // 20% to protocol buyback & burn
    uint256 public constant CREATOR_FEE_BPS = 8000;  // 80% to agent smart account
    uint256 public constant BPS_DENOMINATOR = 10000;

    uint256 public nextTaskId = 1;
    uint256 public nextSubscriptionId = 1;

    mapping(uint256 => TaskEscrow) public tasks;
    mapping(uint256 => SubscriptionEscrow) public subscriptions;

    event TaskEscrowCreated(
        uint256 indexed taskId,
        uint256 indexed agentId,
        address indexed client,
        address paymentToken,
        uint256 amount,
        uint256 timeoutSeconds,
        bytes32 taskHash
    );
    event TaskEscrowReleased(uint256 indexed taskId, uint256 creatorShare, uint256 burnShare);
    event TaskEscrowRefunded(uint256 indexed taskId, address indexed client, uint256 amount);

    event SubscriptionCreated(
        uint256 indexed subscriptionId,
        uint256 indexed agentId,
        address indexed client,
        address paymentToken,
        uint256 totalAmount,
        uint256 startTime,
        uint256 endTime
    );
    event SubscriptionSettled(uint256 indexed subscriptionId, uint256 amountSettled);
    event SubscriptionCancelled(uint256 indexed subscriptionId, uint256 refundedToClient);

    constructor(address _agentRegistry, address _burnPool) Ownable(msg.sender) {
        agentRegistry = NexusAgentRegistry(_agentRegistry);
        burnPool = _burnPool;
    }

    function setBurnPool(address _newBurnPool) external onlyOwner {
        require(_newBurnPool != address(0), "Escrow: burn pool cannot be zero");
        burnPool = _newBurnPool;
    }

    /// @notice Create a task-based escrow with milestone verification and timeout refund
    function createTaskEscrow(
        uint256 agentId,
        address paymentToken,
        uint256 amount,
        uint256 timeoutSeconds,
        bytes32 taskHash
    ) external payable nonReentrant returns (uint256 taskId) {
        require(timeoutSeconds >= 1 hours && timeoutSeconds <= 30 days, "Escrow: invalid timeout");
        NexusAgentRegistry.AgentProfile memory profile = agentRegistry.getAgent(agentId);
        require(profile.isActive, "Escrow: agent is not active");

        if (paymentToken == address(0)) {
            require(msg.value == amount, "Escrow: native HYPE amount mismatch");
        } else {
            require(msg.value == 0, "Escrow: unexpected native value");
            IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), amount);
        }

        taskId = nextTaskId++;
        tasks[taskId] = TaskEscrow({
            agentId: agentId,
            client: msg.sender,
            paymentToken: paymentToken,
            amount: amount,
            createdAt: block.timestamp,
            timeoutSeconds: timeoutSeconds,
            status: EscrowStatus.ACTIVE,
            taskHash: taskHash
        });

        emit TaskEscrowCreated(taskId, agentId, msg.sender, paymentToken, amount, timeoutSeconds, taskHash);
    }

    /// @notice Release task escrow upon milestone completion (80% to agent account, 20% to burn pool)
    function releaseTaskEscrow(uint256 taskId) external nonReentrant {
        TaskEscrow storage task = tasks[taskId];
        require(task.status == EscrowStatus.ACTIVE, "Escrow: task not active");

        NexusAgentRegistry.AgentProfile memory profile = agentRegistry.getAgent(task.agentId);
        address agentOwner = agentRegistry.ownerOf(task.agentId);

        // Either client confirms completion, or agent owner/account triggers with client pre-authorization
        require(msg.sender == task.client || msg.sender == agentOwner, "Escrow: unauthorized release");

        task.status = EscrowStatus.RELEASED;

        uint256 burnShare = (task.amount * PROTOCOL_FEE_BPS) / BPS_DENOMINATOR;
        uint256 creatorShare = task.amount - burnShare;

        if (task.paymentToken == address(0)) {
            (bool s1, ) = profile.accountAddress.call{value: creatorShare}("");
            require(s1, "Escrow: HYPE transfer to agent failed");

            (bool s2, ) = burnPool.call{value: burnShare}("");
            require(s2, "Escrow: HYPE transfer to burn pool failed");
        } else {
            IERC20(task.paymentToken).safeTransfer(profile.accountAddress, creatorShare);
            IERC20(task.paymentToken).safeTransfer(burnPool, burnShare);
        }

        emit TaskEscrowReleased(taskId, creatorShare, burnShare);
    }

    /// @notice Emergency circuit breaker: client claims 100% refund if task is incomplete after timeout
    function claimTimeoutRefund(uint256 taskId) external nonReentrant {
        TaskEscrow storage task = tasks[taskId];
        require(task.status == EscrowStatus.ACTIVE, "Escrow: task not active");
        require(msg.sender == task.client, "Escrow: only client can claim refund");
        require(
            block.timestamp >= task.createdAt + task.timeoutSeconds,
            "Escrow: timeout has not expired"
        );

        task.status = EscrowStatus.REFUNDED;

        if (task.paymentToken == address(0)) {
            (bool success, ) = task.client.call{value: task.amount}("");
            require(success, "Escrow: native refund failed");
        } else {
            IERC20(task.paymentToken).safeTransfer(task.client, task.amount);
        }

        emit TaskEscrowRefunded(taskId, task.client, task.amount);
    }

    /// @notice Create a linear streaming subscription escrow
    function createSubscriptionEscrow(
        uint256 agentId,
        address paymentToken,
        uint256 totalAmount,
        uint256 durationSeconds
    ) external payable nonReentrant returns (uint256 subscriptionId) {
        require(durationSeconds >= 1 days && durationSeconds <= 365 days, "Escrow: invalid duration");
        NexusAgentRegistry.AgentProfile memory profile = agentRegistry.getAgent(agentId);
        require(profile.isActive, "Escrow: agent is not active");

        if (paymentToken == address(0)) {
            require(msg.value == totalAmount, "Escrow: native amount mismatch");
        } else {
            require(msg.value == 0, "Escrow: unexpected native value");
            IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), totalAmount);
        }

        subscriptionId = nextSubscriptionId++;
        subscriptions[subscriptionId] = SubscriptionEscrow({
            agentId: agentId,
            client: msg.sender,
            paymentToken: paymentToken,
            totalAmount: totalAmount,
            startTime: block.timestamp,
            endTime: block.timestamp + durationSeconds,
            settledAmount: 0,
            isCancelled: false
        });

        emit SubscriptionCreated(
            subscriptionId,
            agentId,
            msg.sender,
            paymentToken,
            totalAmount,
            block.timestamp,
            block.timestamp + durationSeconds
        );
    }

    /// @notice Settle vested streaming subscription funds to agent and burn pool
    function settleSubscription(uint256 subscriptionId) external nonReentrant {
        SubscriptionEscrow storage sub = subscriptions[subscriptionId];
        require(!sub.isCancelled, "Escrow: subscription cancelled");

        uint256 vested = _calculateVested(sub);
        uint256 claimable = vested - sub.settledAmount;
        require(claimable > 0, "Escrow: nothing claimable");

        sub.settledAmount = vested;
        NexusAgentRegistry.AgentProfile memory profile = agentRegistry.getAgent(sub.agentId);

        uint256 burnShare = (claimable * PROTOCOL_FEE_BPS) / BPS_DENOMINATOR;
        uint256 creatorShare = claimable - burnShare;

        if (sub.paymentToken == address(0)) {
            (bool s1, ) = profile.accountAddress.call{value: creatorShare}("");
            require(s1, "Escrow: HYPE transfer to agent failed");

            (bool s2, ) = burnPool.call{value: burnShare}("");
            require(s2, "Escrow: HYPE transfer to burn pool failed");
        } else {
            IERC20(sub.paymentToken).safeTransfer(profile.accountAddress, creatorShare);
            IERC20(sub.paymentToken).safeTransfer(burnPool, burnShare);
        }

        emit SubscriptionSettled(subscriptionId, claimable);
    }

    /// @notice Client cancels subscription, settling vested portion and returning unvested balance
    function cancelSubscription(uint256 subscriptionId) external nonReentrant {
        SubscriptionEscrow storage sub = subscriptions[subscriptionId];
        require(msg.sender == sub.client, "Escrow: only client can cancel");
        require(!sub.isCancelled, "Escrow: already cancelled");

        uint256 vested = _calculateVested(sub);
        uint256 claimable = vested - sub.settledAmount;
        uint256 refundAmount = sub.totalAmount - vested;

        sub.isCancelled = true;
        sub.settledAmount = vested;

        NexusAgentRegistry.AgentProfile memory profile = agentRegistry.getAgent(sub.agentId);

        // Settle vested claimable if any
        if (claimable > 0) {
            uint256 burnShare = (claimable * PROTOCOL_FEE_BPS) / BPS_DENOMINATOR;
            uint256 creatorShare = claimable - burnShare;

            if (sub.paymentToken == address(0)) {
                (bool s1, ) = profile.accountAddress.call{value: creatorShare}("");
                require(s1, "Escrow: creator payout failed");
                (bool s2, ) = burnPool.call{value: burnShare}("");
                require(s2, "Escrow: burn payout failed");
            } else {
                IERC20(sub.paymentToken).safeTransfer(profile.accountAddress, creatorShare);
                IERC20(sub.paymentToken).safeTransfer(burnPool, burnShare);
            }
        }

        // Refund unvested to client
        if (refundAmount > 0) {
            if (sub.paymentToken == address(0)) {
                (bool success, ) = sub.client.call{value: refundAmount}("");
                require(success, "Escrow: native refund failed");
            } else {
                IERC20(sub.paymentToken).safeTransfer(sub.client, refundAmount);
            }
        }

        emit SubscriptionCancelled(subscriptionId, refundAmount);
    }

    function _calculateVested(SubscriptionEscrow memory sub) internal view returns (uint256) {
        if (block.timestamp >= sub.endTime) {
            return sub.totalAmount;
        }
        if (block.timestamp <= sub.startTime) {
            return 0;
        }
        uint256 elapsed = block.timestamp - sub.startTime;
        uint256 totalDuration = sub.endTime - sub.startTime;
        return (sub.totalAmount * elapsed) / totalDuration;
    }
}
