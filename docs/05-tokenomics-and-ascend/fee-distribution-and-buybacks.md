# Fee Distribution & Burn Flywheel

## Accounting for Every Dollar

Nexus Agents adheres to Ascend's foundational design principle: **"Incentives should have identifiable funding sources."** Every fee collected across the platform is accounted for in strict compliance with the Ascend financial framework.

---

## 1. The 1% Token Trading Fee Breakdown

When `$NEXUS` trades within Ascend launch pools on Elysium, a **1% token trading fee** is applied. This revenue is routed as follows:

```mermaid
graph TD
    Gross["$100 Gross Trading Fee (1% on Ascend Pool)"]
    Creator["Creator / Operator (25% - 50%)<br/>Funds Ongoing Development & Infrastructure"]
    Protocol["Net Protocol Revenue (50% - 75%)"]
    HYPE["50% HYPE Allocation"]
    KNTQ["50% KNTQ Allocation"]

    Gross --> Creator
    Gross --> Protocol
    Protocol --> HYPE
    Protocol --> KNTQ

    subgraph HYPE Breakdown
        H1["40% kHYPE Protocol Staking (Yield burns ecosystem tokens)"]
        H2["30% Ecosystem Buybacks (Treasury reserve for Spot listing)"]
        H3["20% Operations & Core Infrastructure"]
        H4["10% Direct HYPE Staker Rewards"]
    end

    subgraph KNTQ Breakdown
        K1["60% Permanent KNTQ Burn at 0xfefe...fefe"]
        K2["20% KNTQ / kHYPE Liquidity Pool"]
        K3["20% Ascend Loyalty Points Program"]
    end

    HYPE --> H1 & H2 & H3 & H4
    KNTQ --> K1 & K2 & K3
```

### The 50% HYPE Allocation:
* **40% Protocol-Owned Staking**: Converted into `kHYPE` to build a permanent protocol-owned staking position. Ecosystem tokens purchased with this yield are permanently burned.
* **30% Ecosystem-Token Buybacks**: Retained in Ascend’s treasury to help support the future HyperCore spot listing.
* **20% Treasury and Operations**: Supports ongoing developer operations and infrastructure.
* **10% Direct Staker Rewards**: Distributed directly in HYPE to eligible stakers on Ascend.

### The 50% KNTQ Allocation:
* **60% Permanent KNTQ Burn**: Sent directly to the Hyperliquid Assistance Fund (`0xfefefefefefefefefefefefefefefefefefefefe`) on HyperCore or HyperEVM.
* **20% KNTQ / kHYPE Liquidity**: Paired to deepen native KNTQ liquidity on Elysium.
* **20% Ascend Points Program**: Distributed to active users participating in Ascend's trading profiles and TVL staking.

---

## 2. Marketplace Performance Fee Routing

In addition to the 1% trading fee, commercial activity within the **Nexus Agentic Marketplace** generates task performance and subscription fees:
* **80% to Agent Creator / Operator**: Distributed directly into the Agent Smart Account.
* **20% Protocol Platform Share**: Automatically routes through the Ascend `$NEXUS/USDC` pool to buy and burn `$NEXUS`, creating a direct correlation between marketplace utility and circulating supply reduction.
