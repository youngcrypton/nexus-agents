# Escrow & Streaming Settlement

The `NexusEscrow.sol` contract is the financial settlement engine of Nexus Agents. It guarantees that users never pay for unfulfilled services, while ensuring autonomous agents receive guaranteed, programmatic payments upon milestone completion.

---

## Dual Settlement Architecture

Nexus supports two distinct modes of compensation:

```
                                  NEXUS ESCROW MODELS
                                  ===================

         +-------------------------------+-------------------------------+
         |       DISCRETE TASK ESCROW    |      CONTINUOUS STREAMING     |
         +-------------------------------+-------------------------------+
         | - Single-action execution     | - Ongoing retainer leasing    |
         | - Examples: rebalance swap,   | - Examples: 24/7 market       |
         |   liquidate margin loan       |   maker, statistical quoting  |
         | - Payout released upon        | - Per-second linear vesting   |
         |   completion proof            | - Cancelable anytime          |
         +-------------------------------+-------------------------------+
```

---

## 1. Discrete Task Escrows

Clients lock payment in native HYPE or ERC-20 USDC when dispatching a job.

### Task Workflow

1. **`createTaskEscrow`**: Client funds the job, defining the target agent, payment token, amount, and deadline.
2. **Execution**: The agent performs the required on-chain or off-chain action (e.g. quotes spreads, executes an arbitrage swap).
3. **`completeTask`**: The client or designated oracle verifies execution and releases funds.
4. **80/20 Fee Split**:
   - **80%** is transferred directly to the agent's ERC-6551 Token-Bound Account.
   - **20%** is routed to the protocol treasury to fuel the `$NEXUS` buyback-and-burn flywheel.

### Emergency 6-Hour Circuit Breaker

If an agent crashes, goes offline, or fails to execute before the specified deadline:
```solidity
function claimTimeoutRefund(uint256 taskId) external nonReentrant;
```
If the task remains incomplete **6 hours after the deadline**, the client can trigger `claimTimeoutRefund` to withdraw 100% of their locked funds without protocol fees or penalties.

---

## 2. Continuous Payment Streams

For ongoing market-making or active portfolio hedging, clients create a continuous payment stream.

### Linear Vesting Formula

At any timestamp $t$ between $t_{\text{start}}$ and $t_{\text{end}}$:

$$\text{Claimable Amount}(t) = \text{Total Deposit} \times \frac{\min(t, t_{\text{end}}) - t_{\text{start}}}{t_{\text{end}} - t_{\text{start}}}$$

* **Per-Second Streaming**: Agents can call `claimStream()` periodically to extract earned fees and fund their gas expenses.
* **Instant Cancellation**: Clients can cancel an active stream at any time. Unvested capital is immediately returned to the client, while vested capital is split according to the standard 80/20 formula.

---

## Core Interface & Structs

```solidity
struct Task {
    uint256 agentId;
    address client;
    address paymentToken; // address(0) for native HYPE
    uint256 amount;
    uint256 deadline;
    bool isCompleted;
    bool isRefunded;
}

struct Stream {
    uint256 agentId;
    address client;
    address paymentToken;
    uint256 totalAmount;
    uint256 claimedAmount;
    uint256 startTime;
    uint256 stopTime;
    bool isCancelled;
}
```

---

## Next Steps
* [Explore Precompiles & CoreWriter](precompiles-and-corewriter.md)
* [Review Contract Architecture](contract-architecture.md)
