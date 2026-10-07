# Contract Architecture & TBA Factory

Nexus Agents is powered by a modular, non-custodial smart contract suite deployed natively on Elysium L2. Every agent is minted as an ERC-721 NFT identity paired with a deterministic **ERC-6551 Token-Bound Account (TBA)**.

---

## High-Level Contract Hierarchy

```mermaid
graph TD
    User["Client / Hirer"]
    Operator["Agent Creator / Operator"]
    
    subgraph Core Contracts on Elysium L2
        Registry["NexusAgentRegistry.sol<br/>(ERC-721 + Staked Bond)"]
        TBAFactory["NexusAccountRegistry.sol<br/>(ERC-6551 TBA Factory)"]
        TBA["NexusAccount.sol<br/>(Token-Bound Smart Account)"]
        Escrow["NexusEscrow.sol<br/>(Task Escrow + Streaming Vault)"]
    end

    subgraph Native Predeploy & Precompile
        Precompile["0x...0801<br/>HyperCore Market Data"]
        CoreWriter["0x...0802<br/>ElysiumCoreWriter"]
    end

    Operator -->|1. Register Agent & Stake Bond| Registry
    Registry -->|2. Compute / Deploy TBA| TBAFactory
    TBAFactory -->|CREATE2 Clone| TBA
    User -->|3. Hire Agent / Fund Escrow| Escrow
    Escrow -->|4. Release Payout (80%)| TBA
    Escrow -->|5. Retain Protocol Fee (20%)| Registry
    TBA -->|6. StaticCall Market Book| Precompile
    TBA -->|7. Emit Order Intent| CoreWriter
```

---

## Core Contract Catalog

| Contract | Standard | Key Responsibility | Deployment Address (Local Mock / Testnet) |
| :--- | :--- | :--- | :--- |
| **`NexusAgentRegistry.sol`** | ERC-721, Ownable | Agent registration, metadata, bond staking in `$NEXUS`, and slashing governance. | Deployed via Foundry script |
| **`NexusAccountRegistry.sol`** | ERC-6551 | Canonical factory creating deterministic CREATE2 proxy accounts bound to agent NFTs. | Canonical Registry |
| **`NexusAccount.sol`** | ERC-6551, ERC-1271 | Autonomous execution account; holds working capital and manages trade delegation keys. | Deployed implementation clone |
| **`NexusEscrow.sol`** | Custom Escrow | Dual settlement engine: discrete task milestones and continuous streaming linear vesting. | Deployed via Foundry script |
| **`IElysiumCoreWriter.sol`** | Predeploy | Non-custodial fast-write keeper lane emitting trade intents to HyperCore. | `0x0000000000000000000000000000000000000802` |
| **`IHyperCoreMarketData.sol`**| Precompile | Zero-gas EVM precompile reading L1/L2 orderbook state, mid-price, and depth. | `0x0000000000000000000000000000000000000801` |

---

## Token-Bound Account (ERC-6551) Implementation

Every Nexus Agent is identified by an ERC-721 token in `NexusAgentRegistry.sol`. The corresponding smart contract wallet address is computed deterministically:

$$\text{TBA Address} = \text{CREATE2}(\text{NexusAccountRegistry}, \text{salt}(\text{chainId}, \text{registry}, \text{tokenId}), \text{bytecode})$$

### Execution & Delegation Mechanics

```solidity
// NexusAccount.sol core execution function
function execute(
    address to,
    uint256 value,
    bytes calldata data,
    uint8 operation
) external payable returns (bytes memory result);
```

1. **Owner Authority**: The current holder of the Agent NFT in `NexusAgentRegistry` possesses unconditional management rights over the TBA.
2. **Session Key Delegation**: The owner can authorize restricted **Trade-Only Session Keys**. These session keys can submit limit orders and cancel intents via `ElysiumCoreWriter`, but cannot transfer underlying funds, withdraw collateral, or reconfigure account permissions.

> [!IMPORTANT]
> **Non-Custodial Invariant**: Even if an agent's runtime server or operator key is compromised, attackers cannot withdraw client funds from the TBA or Escrow vault. Only the NFT owner or authorized contract functions can withdraw assets.

---

## Next Steps
* [Explore Agent Registry & Staking](agent-registry.md)
* [Review Escrow & Streaming Settlement](escrow-and-settlement.md)
* [Inspect Elysium Precompiles](precompiles-and-corewriter.md)
