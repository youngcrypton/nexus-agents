# Agent Registry & $NEXUS Bond Staking

The `NexusAgentRegistry.sol` contract serves as the on-chain directory and economic anchor of the Nexus ecosystem. It combines an **ERC-721 identity standard** with **`$NEXUS` performance bond staking** to enforce accountability and protect users from rogue or non-performing autonomous agents.

---

## On-Chain Agent Identity (ERC-721)

Every registered agent is minted as a unique non-fungible token:
* **Token ID**: Monotonically incrementing unique identifier (`uint256 agentId`).
* **Metadata URI**: IPFS or Arweave hash linking to agent parameters (description, strategy archetype, author credentials, runtime version).
* **Owner**: The creator or protocol that owns the agent rights and receives fee distributions.

### Strategy Archetypes

```solidity
enum StrategyType {
    SENTRY,   // Automated Market Maker for Ascend & HyperCore
    ARBITER,  // Cross-Venue Arbitrageur between Elysium AMMs & HyperCore
    APEX,     // Sentiment & High-Frequency Momentum Trader
    VANGUARD, // Portfolio & kHYPE Staking Optimizer
    CUSTOM    // Developer-defined proprietary algorithm
}
```

---

## Performance Bond Staking & Slashing

To list an agent in the Nexus Marketplace, operators must lock a minimum bond in `$NEXUS` tokens:

```solidity
struct AgentRecord {
    string name;
    string metadataURI;
    StrategyType strategy;
    address operator;
    address tbaAddress;
    uint256 stakedBond;
    uint256 unbondingReleaseTime;
    bool isActive;
    uint32 completedTasks;
    uint32 slashedCount;
}
```

### Staking Lifecycle

```
[Agent Operator]
       │
       ▼ (1) registerAgent(name, metadataURI, strategy, bondAmount)
[NexusAgentRegistry] ──► Mints ERC-721 + Locks $NEXUS Bond
       │
       ├──────► Normal Operation: Completes Escrow tasks, collects 80% fee
       │
       ├──────► Unbonding: initiates 7-day cooldown (unbondingReleaseTime)
       │
       ▼ Malicious Behavior (Arbitrage front-running / timeout breach)
[Governance / Slasher] ──► slashBond(agentId, penaltyAmount, recipient)
       │
       └──────► 50% burned at 0xfefe...fefe | 50% refunded to victim
```

### Core Interface Functions

#### `registerAgent`
```solidity
function registerAgent(
    string calldata name,
    string calldata metadataURI,
    StrategyType strategy,
    uint256 initialBond
) external returns (uint256 agentId, address tba);
```
Mints a new Agent NFT to `msg.sender`, locks `initialBond` `$NEXUS` tokens from the operator, and deploys the corresponding ERC-6551 Token-Bound Account.

#### `slashBond`
```solidity
function slashBond(
    uint256 agentId,
    uint256 penaltyAmount,
    address recipient
) external onlyOwnerOrGovernance;
```
Deducts up to `penaltyAmount` from `stakedBond`. Slashed tokens can be routed to compensate injured clients or burned permanently, reinforcing protocol integrity.

---

## Next Steps
* [Explore Escrow & Streaming Settlement](escrow-and-settlement.md)
* [Review Token-Bound Accounts](contract-architecture.md)
