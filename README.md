<div align="center">

# Nexus Agents (`@nexus/runtime`)

### The Decentralized Autonomous Agent Marketplace & Sub-Second Execution Runtime for Elysium

[![Foundry Tests](https://img.shields.io/badge/Foundry_Tests-8%2F8_Passed-10b981?style=for-the-badge&logo=solidity)](contracts/test/NexusAgents.t.sol)
[![Runtime SDK](https://img.shields.io/badge/@nexus/runtime-TypeScript_v5.6-3178c6?style=for-the-badge&logo=typescript)](runtime/)
[![Elysium L2](https://img.shields.io/badge/Elysium_L2-Arbitrum_Nitro_Orbit-7c3aed?style=for-the-badge)](https://elysiumchain.tech)
[![HyperCore](https://img.shields.io/badge/HyperCore-0x0801_Precompile-06b6d4?style=for-the-badge)](https://hyperliquid.xyz)
[![Ascend Standard](https://img.shields.io/badge/Ascend_Launch-Fair_Token_Playbook-f59e0b?style=for-the-badge)](https://x.com/AscendLaunch)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

<br/>

**Nexus Agents** is an open, non-custodial autonomous agent marketplace and sub-second execution engine built natively for **Elysium L2** (Arbitrum Orbit / Nitro, 100–200 ms canonical blocks, 300 Mgas/s throughput, native HYPE gas).

Designed in full alignment with the **Ascend Token Launch Framework** ($20,000 builder grant competition), Nexus Agents bridges on-chain AI intelligence with institutional-grade high-frequency trading on HyperCore.

[Documentation Portal](docs/01-introduction/overview.md) · [Smart Contracts](contracts/) · [Runtime SDK](runtime/) · [Litepaper](docs/01-introduction/executive-summary.md)

</div>

---

## The Problem: The On-Chain AI Agent Trilemma

Autonomous trading and intelligence agents on current blockchains face three fundamental bottlenecks:

1. **The Latency Wall (Execution Lag)**: Standard rollups and L1 chains operate with 1–12 second block times. In high-frequency market-making or statistical arbitrage, multi-second latency leads directly to toxic order flow, front-running, and severe Loss-Versus-Rebalancing (LVR).
2. **The Oracle Cost Wall (Drain on Capital)**: Pushing continuous price updates on-chain via push oracles (Chainlink/Pyth) bankrupts agent gas budgets. High-frequency quoting requires tick-by-tick market depth, not lagged 10-second oracle feeds.
3. **The Custody Wall (Key Compromise Risk)**: Traditional bots force users to deposit capital into custodial off-chain hot wallets or share private keys, risking complete loss of funds upon server compromise.

---

## The Nexus Solution on Elysium

Nexus Agents breaks the trilemma by leveraging the native architectural advantages of **Elysium L2** co-located with **HyperCore**:

```mermaid
graph TD
    subgraph Client Layer
        User["Client / Trader / Protocol"]
        Dev["Agent Developer / Operator"]
    end

    subgraph Elysium L2 Smart Contracts
        Registry["NexusAgentRegistry.sol<br/>(ERC-721 Identity + $NEXUS Staking)"]
        TBA["NexusAccount.sol<br/>(ERC-6551 Token-Bound Account)"]
        Escrow["NexusEscrow.sol<br/>(Task Escrows + Linear Streaming Vaults)"]
        AscendPool["Ascend Launch Hook Pool<br/>(AMM: 1% Fee, USDC Quoted)"]
    end

    subgraph Native Precompiles & Keeper Relayer
        Precompile["HyperCore Market Data Precompile<br/>0x0000000000000000000000000000000000000801"]
        CoreWriter["ElysiumCoreWriter Predeploy<br/>0x0000000000000000000000000000000000000802"]
        Keeper["Keeper Relayer Daemon<br/>(@nexus/runtime KeeperRelayer)"]
    end

    subgraph HyperCore L1 Matching Engine
        CLOB["HyperCore Spot / Perp CLOB<br/>(Sub-Second Consensus & Order Matching)"]
    end

    User -->|Hire Agent / Fund Escrow| Escrow
    Dev -->|Stake $NEXUS Bond & Register| Registry
    Registry -->|Deploys TBA for Agent| TBA
    Escrow -->|Release 80% Payout| TBA

    TBA -->|StaticCall (0 Gas, ~70ms)| Precompile
    Precompile -.->|Direct L1 State Read| CLOB
    TBA -->|placeLimitOrder()| CoreWriter
    CoreWriter -->|OrderIntentEmitted Event| Keeper
    Keeper -->|Signed Order Relay| CLOB
```

* **100–200 ms Canonical Block Times**: Real Arbitrum Nitro execution blocks providing deterministic ~300 ms transaction receipts.
* **Zero-Gas HyperCore Market Precompile (`0x0801`)**: Agents read live L1/L2 orderbook depth, best bids/asks, and expected slippage at ~70ms granularity for zero oracle gas fees.
* **Non-Custodial Keeper Fast-Lane (`0x0802`)**: Agents emit trade intents via `ElysiumCoreWriter`. Keepers relay orders to HyperCore signed with **Trade-Only Session Keys** that cryptographically **cannot transfer or withdraw user capital**.
* **ERC-6551 Token-Bound Accounts (TBAs)**: Every agent is an on-chain NFT that owns its own deterministic smart wallet, holding working capital, receiving hiring fees, and building portable reputation.

---

## Core Capabilities & Features

### 1. The Commercial Agent Marketplace
* **Hire & Lease Agents**: Protocols and token creators hire specialized agents for 24/7 market making, cross-venue arbitrage, or automated portfolio rebalancing.
* **Milestone Escrows & Linear Streaming**:
  * **Discrete Task Escrow**: Funds locked upfront and disbursed upon verified task completion.
  * **Continuous Payment Streaming**: Per-second linear vesting for continuous retainers; cancelable anytime with unvested funds returned instantly.
  * **6-Hour Emergency Circuit Breaker**: If an agent fails to execute within 6 hours past deadline, clients trigger `claimTimeoutRefund()` to recover 100% of their deposit without fees.
* **80/20 Programmatic Revenue Split**:
  * **80%** paid directly to the agent's ERC-6551 Token-Bound Account.
  * **20%** routed to the protocol treasury to buy and burn `$NEXUS`.

### 2. Autonomous Runtime SDK (`@nexus/runtime`)
A containerized TypeScript / Node.js runtime engine equipped with plug-and-play strategies:
* **Sentry Strategy (`SentryStrategy.ts`)**: Automated Market Maker implementing dynamic **Avellaneda-Stoikov inventory skewing**. If holding >60% base tokens, reservation prices skew lower to shed inventory; if <40%, reservation prices skew higher to restock.
* **Arbiter Strategy (`ArbiterStrategy.ts`)**: Cross-venue statistical arbitrageur detecting price divergence between **Ascend Closed Hook Pools (AMM)** and **HyperCore Spot Markets (CLOB)**, factoring in Ascend’s 1% trading fee and Elysium L2 gas.
* **Keeper Relayer Daemon (`KeeperRelayer.ts`)**: Subscribes to `OrderIntentEmitted` events on Elysium and dispatches signed trade payloads to HyperCore CLOB.

### 3. The Ascend Token Launch Playbook (`$NEXUS`)
* **Strict Ascend Lifecycle Alignment**: Zero pre-sales, zero VC token allocations.
* **Launch Stage**: Public fair launch exclusively in **Ascend Closed Hook Pools** quoted in USDC.
* **1% Trading Fee Routing**:
  * **50% Net Revenue $\to$ HYPE**: 40% protocol-owned staking in `kHYPE`, 30% ecosystem-token buybacks for HyperCore listing support, 20% ops, 10% direct stakers.
  * **50% Net Revenue $\to$ KNTQ**: 60% burned permanently at `0xfefefefefefefefefefefefefefefefefefefefe`, 20% `kHYPE` LP, 20% Ascend points.
* **HyperCore Spot Graduation**: Upon reaching Ascended Status milestones, Ascend coordinates the formal spot deployment ceremony linking deposit wallets to $0x20 \parallel \text{tokenIndex}$ for live HyperCore CLOB listing.

---

## Monorepo Architecture

```
nexus-agents/
├── contracts/                     # Foundry Smart Contract Suite (Solidity 0.8.24)
│   ├── src/
│   │   ├── NexusAccount.sol       # ERC-6551 Token-Bound Account with trade delegation
│   │   ├── NexusAccountRegistry.sol # Deterministic CREATE2 TBA factory
│   │   ├── NexusAgentRegistry.sol # ERC-721 Agent Identity & $NEXUS bond staking
│   │   ├── NexusEscrow.sol        # Task escrows, streaming vaults & 6h circuit breaker
│   │   ├── interfaces/            # IElysiumCoreWriter, IHyperCoreMarketData, IERC6551
│   │   └── mocks/                 # MockHyperCorePrecompile, MockElysiumCoreWriter, MockERC20
│   ├── test/
│   │   └── NexusAgents.t.sol      # 8/8 Unit & Fuzz test cases (256 runs)
│   └── script/
│       └── DeployNexus.s.sol      # Local / Testnet deployment orchestration script
├── runtime/                       # Node.js Agent Runtime SDK (@nexus/runtime)
│   ├── src/
│   │   ├── agent/NexusAgent.ts    # Autonomous tick execution loop (200ms cadence)
│   │   ├── plugins/               # Precompile, CoreWriter, and AscendHookPool plugins
│   │   ├── strategies/            # Sentry (AMM) and Arbiter (Arbitrage) strategies
│   │   ├── keeper/KeeperRelayer.ts # Event listener & HyperCore order dispatcher
│   │   ├── demo.ts                # Live strategy simulation runner
│   │   └── types.ts               # Core protocol schemas and interfaces
│   └── test/
│       ├── runtime.test.ts        # Strategy unit tests (4/4 passed)
│       └── e2e.test.ts            # Full pipeline integration test (passed)
├── docs/                          # Comprehensive GitBook Documentation Portal (30 Chapters)
│   ├── 01-introduction/           # Executive summary, problem statement, solution
│   ├── 02-architecture/           # Elysium L2 Nitro integration, HyperCore connectivity
│   ├── 03-marketplace/            # Marketplace discovery, ERC-6551, A2A economy
│   ├── 04-runtime-and-tooling/    # Runtime architecture, Sentry, Arbiter algorithms
│   ├── 05-tokenomics-and-ascend/  # $NEXUS economics, Ascend playbook, fee distribution
│   ├── 06-roadmap-and-milestones/ # Epochs 1-5 timeline and growth gates
│   ├── 07-security-and-controls/  # Non-custodial safeguards, circuit breakers, audit matrix
│   ├── 08-contracts/              # Contract specs, TBA factory, escrow NatSpec
│   └── 09-developer-guide/        # Quickstart, custom strategies, keeper ops, local testing
├── SUMMARY.md                     # GitBook table of contents
└── .gitbook.yaml                  # GitBook space sync configuration
```

---

## Quickstart Guide

### 1. Smart Contracts (Foundry)

#### Prerequisites
* [Foundry](https://book.getfoundry.sh/getting-started/installation) (`forge`, `cast`, `anvil`)

```bash
cd contracts

# Run complete test suite (unit + fuzzing)
forge test -vvv

# Run dry-run deployment simulation
forge script script/DeployNexus.s.sol
```

#### Test Suite Results
```
Ran 8 tests for test/NexusAgents.t.sol:NexusAgentsTest
[PASS] testAccountExecutionAndDelegation() (gas: 502439)
[PASS] testFuzzFeeSplits(uint256) (runs: 256, μ: 624240, ~: 624240)
[PASS] testRegisterAgent() (gas: 333242)
[PASS] testSlashBond() (gas: 388786)
[PASS] testStreamingSubscriptionVestingAndCancel() (gas: 642357)
[PASS] testTaskEscrowFlowUSDC() (gas: 638530)
[PASS] testTaskEscrowNativeHYPE() (gas: 592179)
[PASS] testTimeoutRefundCircuitBreaker() (gas: 581955)
Suite result: ok. 8 passed; 0 failed; 0 skipped; finished in 111.04ms
```

---

### 2. Runtime SDK (`@nexus/runtime`)

#### Prerequisites
* Node.js v20.0.0 or higher
* npm or pnpm

```bash
cd runtime

# Install dependencies
npm install

# Run unit tests
npm test

# Run live strategy simulation demo
npm run demo

# Run end-to-end pipeline test
npm run test:e2e

# Compile TypeScript production bundle
npm run build
```

#### Example: Running an Autonomous Agent
```typescript
import { ethers } from "ethers";
import { NexusAgent, AgentConfig, StrategyType } from "@nexus/runtime";

const provider = new ethers.JsonRpcProvider("https://testnet-rpc.elysiumchain.tech");
const signer = new ethers.Wallet(process.env.AGENT_PRIVATE_KEY!, provider);

const config: AgentConfig = {
  agentId: 1,
  name: "Nexus-Alpha-Sentry",
  strategyType: StrategyType.SENTRY,
  tickerIndex: 1, // $NEXUS spot token index
  rpcUrl: "https://testnet-rpc.elysiumchain.tech",
  accountAddress: "0xYourAgentTBAAddress",
  targetSpreadBps: 50,       // 0.50% target spread
  rebalanceThresholdBps: 100,
  maxInventoryToken: 10000n * 1000000n,
  maxInventoryUsdc: 20000n * 1000000n
};

const agent = new NexusAgent(config, provider, signer);

// Start autonomous execution loop at 200ms Elysium block cadence
agent.start(200);
```

---

## Contract Addresses & Precompiles

| Contract / Interface | Standard | Address / Location | Description |
| :--- | :--- | :--- | :--- |
| **`HyperCore Precompile`** | EVM Precompile | `0x0000000000000000000000000000000000000801` | Zero-gas synchronous L1/L2 orderbook queries (`getSpotMarket`, `getOrderbookDepth`). |
| **`ElysiumCoreWriter`** | Predeploy | `0x0000000000000000000000000000000000000802` | Non-custodial fast-write lane emitting `OrderIntentEmitted` events to keepers. |
| **`NexusAgentRegistry`** | ERC-721 / Staking | *Deployed via script* | Manages agent identities, metadata, and `$NEXUS` performance bond staking/slashing. |
| **`NexusAccountRegistry`** | ERC-6551 Factory | *Canonical Factory* | Computes and deploys deterministic CREATE2 Token-Bound Accounts for Agent NFTs. |
| **`NexusAccount`** | ERC-6551 / ERC-1271 | *Implementation* | Autonomous execution account with trade-only session key delegation. |
| **`NexusEscrow`** | Custom Vault | *Deployed via script* | Milestone-based task escrows, linear payment streams, 80/20 fee split, and 6h circuit breaker. |

---

## Security & Invariants

The protocol enforces 5 strict security invariants verified across fuzzing and integration suites:

1. **INV-1: Non-Custodial Isolation**: Agent session keys can ONLY call `placeLimitOrder()` and `cancelOrder()` via `0x0802`. They have zero authority to transfer or withdraw user capital.
2. **INV-2: 80/20 Fee Conservation**: Exactly 80% of escrow payouts are released to the agent's TBA, and exactly 20% to the protocol buyback engine.
3. **INV-3: Circuit Breaker Guarantee**: Any task incomplete $>6\text{ hours}$ past deadline can be refunded 100% by the client via `claimTimeoutRefund()`.
4. **INV-4: Monotonic Nonce Ordering**: All order intents enforce strictly-increasing nonces to prevent replay attacks across blocks.
5. **INV-5: Slashing Bound**: Slashed bond amounts cannot exceed the operator's active staked `$NEXUS` balance.

---

## Documentation Links

For deep architectural analyses, math models, and governance blueprints, explore the documentation portal:
* 📖 [Protocol Litepaper & Overview](docs/01-introduction/overview.md)
* 🏛️ [Elysium L2 & HyperCore Architecture](docs/02-architecture/system-overview.md)
* ⚡ [Smart Contracts Specification](docs/08-contracts/contract-architecture.md)
* ⚙️ [Runtime SDK & Quantitative Strategies](docs/04-runtime-and-tooling/node-agent-runtime.md)
* 🛠️ [Developer Guide & Tutorials](docs/09-developer-guide/quickstart.md)
* 💎 [The Ascend Launch Playbook](docs/05-tokenomics-and-ascend/ascend-launch-playbook.md)
* 🛡️ [Security, Safeguards & Audit Readiness](docs/07-security-and-controls/non-custodial-safeguards.md)

---

## License

This repository is licensed under the [MIT License](LICENSE).
