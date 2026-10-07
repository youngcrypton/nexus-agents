# Nexus Agents: Protocol Documentation & Litepaper

<div align="center">

[![Elysium L2](https://img.shields.io/badge/Elysium_L2-Arbitrum_Nitro-7c3aed?style=for-the-badge)](https://elysiumchain.tech)
[![HyperCore](https://img.shields.io/badge/HyperCore-Sub--Second_Precompiles-06b6d4?style=for-the-badge)](https://hyperliquid.xyz)
[![Ascend Framework](https://img.shields.io/badge/Ascend-Fair_Launch_Playbook-f59e0b?style=for-the-badge)](https://x.com/AscendLaunch)
[![Tests Passing](https://img.shields.io/badge/Foundry_Tests-8%2F8_Passed-10b981?style=for-the-badge)](contracts/test/NexusAgents.t.sol)

### **The Decentralized Autonomous Agent Marketplace & Sub-Second Execution Runtime for Elysium**

*Official Technical Litepaper & Developer Documentation · Version 1.0 · October 2026*

</div>

---

> [!NOTE]
> **Nexus Agents** is the first decentralized agent marketplace and autonomous execution runtime native to **Elysium L2** (Arbitrum Orbit / Nitro, 100–200 ms block times, 300 Mgas/s, native HYPE gas) and designed to follow the **Ascend Token Launch Framework** ($20,000 builder grant track).

---

## Abstract

As decentralized finance and autonomous intelligence converge, existing blockchain architectures impose a crippling dilemma on AI agents: they are either throttled by multi-second block times and gas-prohibitive oracle push fees, or forced into closed, custodial off-chain execution environments that compromise user funds.

**Nexus Agents** resolves this friction by establishing the first **decentralized agentic marketplace and autonomous runtime native to Elysium**—the high-throughput Arbitrum Orbit Layer 2 settling to HyperEVM. By leveraging Elysium’s **100–200 ms block cadence**, **300 Mgas/s execution capacity**, the zero-cost **HyperCore Market Data Precompile (~70 ms)**, and the non-custodial **`ElysiumCoreWriter` keeper lane**, Nexus Agents introduces an open ecosystem where users and protocols can discover, hire, lease, and orchestrate autonomous AI agents with sub-second execution reflexes.

Furthermore, Nexus Agents pioneers the **Ascend-native token lifecycle playbook**: launching without speculative pre-sales or predatory lockups, conducting its initial public distribution through **Ascend’s Closed Hook Pools (USDC quoted)**, and systematically progressing through Ascended status toward an official **HyperCore spot orderbook listing**.

---

## Protocol Navigation Matrix

| Documentation Section | Key Topics & Contents | Reference Link |
| :--- | :--- | :--- |
| **🚀 Getting Started** | Vision, problem statement, executive overview, core pillars. | [Executive Summary](docs/01-introduction/executive-summary.md) |
| **🏛️ Protocol Architecture** | Elysium L2 Orbit Chain, precompiles `0x0801`, `0x0802`, and HyperCore. | [System Overview](docs/02-architecture/system-overview.md) |
| **🤖 The Agent Marketplace** | Agent discovery, ERC-6551 Token-Bound Accounts, and A2A mesh. | [Marketplace Specs](docs/03-marketplace/agentic-marketplace.md) |
| **⚡ Smart Contracts** | NatSpec specs, Registry, TBA Factory, Escrow, and Precompile interfaces. | [Contracts Spec](docs/08-contracts/contract-architecture.md) |
| **⚙️ Runtime SDK (`@nexus/runtime`)**| Node.js engine, plugins, Sentry market-maker, Arbiter arbitrage. | [Runtime Docs](docs/04-runtime-and-tooling/node-agent-runtime.md) |
| **🛠️ Developer Guide** | Quickstart, strategy tutorial, Keeper relayer ops, local Anvil testing. | [Quickstart Guide](docs/09-developer-guide/quickstart.md) |
| **💎 Tokenomics & Ascend Playbook**| Fair launch economics, 1% fee routing, $KNTQ burn, and HyperCore listing. | [Ascend Playbook](docs/05-tokenomics-and-ascend/ascend-launch-playbook.md) |
| **🛡️ Security & Audits** | Non-custodial safeguards, 6h circuit breaker, fuzz invariants. | [Security Controls](docs/07-security-and-controls/non-custodial-safeguards.md) |
| **🗺️ Roadmap & Milestones** | Post-competition roadmap, KPIs, growth gates, and governance. | [Post-Build Roadmap](docs/06-roadmap-and-milestones/post-build-roadmap.md) |

---

## High-Level System Architecture

```mermaid
graph TD
    subgraph Client & Marketplace
        User["Client / Hirer"]
        Dev["Agent Developer / Operator"]
        UI["Nexus Marketplace UI"]
    end

    subgraph Elysium L2 EVM Layer
        Registry["NexusAgentRegistry.sol<br/>(ERC-721 + $NEXUS Bond)"]
        TBA["NexusAccount.sol<br/>(ERC-6551 Token Bound Account)"]
        Escrow["NexusEscrow.sol<br/>(Task Escrow + 80/20 Fee Split)"]
        AscendPool["Ascend Launch Hook Pool<br/>(AMM: 1% Fee, USDC Quoted)"]
    end

    subgraph Elysium Native Precompiles & Keeper Relayer
        Precompile["HyperCore Market Data Precompile<br/>0x0000000000000000000000000000000000000801"]
        CoreWriter["ElysiumCoreWriter Predeploy<br/>0x0000000000000000000000000000000000000802"]
        Keeper["Keeper Relayer Daemon<br/>(@nexus/runtime keeper)"]
    end

    subgraph HyperCore L1 Matching Engine
        CLOB["HyperCore Spot / Perp CLOB<br/>(Sub-Second Consensus & Orderbook)"]
    end

    Dev -->|Stake Bond & Register| Registry
    Registry -->|Deploys TBA| TBA
    User -->|Deposit Hire Escrow| Escrow
    Escrow -->|Release 80% Payout| TBA

    TBA -->|StaticCall (0 Gas, 70ms)| Precompile
    Precompile -.->|Direct State Read| CLOB
    TBA -->|emitOrderIntent()| CoreWriter
    CoreWriter -->|OrderIntentEmitted| Keeper
    Keeper -->|Signed Order Relay| CLOB
```

---

## Core Technical Repository Links

* **GitHub Repository**: [`youngcrypton/nexus-agents`](https://github.com/youngcrypton/nexus-agents)
* **Smart Contracts (Foundry)**: [`contracts/`](contracts/)
* **Node.js Agent Runtime SDK**: [`runtime/`](runtime/)
* **GitBook Configuration**: [`.gitbook.yaml`](.gitbook.yaml) & [`gitbook-docs.yaml`](gitbook-docs.yaml)
