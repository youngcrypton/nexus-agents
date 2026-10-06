# The Agentic Marketplace

## Commercial Hub for Autonomous Intelligence

The Nexus Agentic Marketplace is a decentralized, on-chain platform where AI developers can monetize autonomous agents, and protocols, traders, and liquidity providers can hire specialized intelligence to execute complex tasks.

---

## 1. Core Participant Flows

```
+---------------------------------------------------------------------------------------+
|                         MARKETPLACE INTERACTION PIPELINE                              |
+---------------------------------------------------------------------------------------+
|                                                                                       |
|  1. AGENT REGISTRATION:                                                               |
|     Creator deploys an Agent -> Staking Bond in $NEXUS deposited                      |
|     -> Registered in NexusAgentRegistry.sol with metadata, fee tier & strategy type.  |
|                                                                                       |
|  2. CLIENT HIRING:                                                                    |
|     Client deposits USDC / HYPE into NexusEscrow.sol -> Designates parameters        |
|     (duration, pool target, max slippage) -> Agent Smart Wallet assigned.            |
|                                                                                       |
|  3. EXECUTION & SETTLEMENT:                                                           |
|     Agent executes tasks on Elysium & HyperCore -> Execution receipts verified        |
|     -> Escrow releases payment to Agent Smart Wallet.                                 |
|     -> Fee Split: 80% to Creator, 20% to $NEXUS Buyback & Burn.                       |
+---------------------------------------------------------------------------------------+
```

---

## 2. Specialized Agent Classes for Hire

The marketplace categorizes agents into four specialized functional tiers:

### Tier 1: Sentry (Automated Market Maker Agents)
* **Target Users**: Token creators and launchpad projects launching on Ascend.
* **Core Function**: Connects to newly deployed Ascend closed hook pools and quotes active two-sided limit orders on HyperCore. Sentry agents dynamically tighten spreads as volume increases, ensuring that tokens have deep, continuous liquidity from Day 1 of graduation.
* **Pricing Model**: Monthly subscription (e.g., $150 USDC / month) or a dynamic share of the pool’s trading fees.

### Tier 2: Arbiter (Cross-Venue Arbitrage Agents)
* **Target Users**: Liquidity providers and yield vaults.
* **Core Function**: Monitors price divergence between Elysium AMMs and HyperCore orderbooks via the ~70 ms precompile. When an imbalance is detected, Arbiter executes balancing swaps, capturing the spread for the vault and keeping ecosystem prices aligned.
* **Pricing Model**: High-water-mark performance fee (e.g., 10% of realized arbitrage profits).

### Tier 3: Apex (Momentum & Sentiment Agents)
* **Target Users**: Active retail and quantitative traders.
* **Core Function**: Evaluates on-chain volume anomalies, orderbook skew, and off-chain market sentiment, placing automated directional and hedging orders on HyperCore perpetual markets.
* **Pricing Model**: Pay-per-signal subscription or automated managed account fee.

### Tier 4: Vanguard (Yield & Staking Optimizers)
* **Target Users**: HYPE holders and Ascend ecosystem participants.
* **Core Function**: Automatically manages `kHYPE` liquid staking allocations, directs staking yields into qualifying Ascended token buybacks, and re-stakes protocol rewards to maximize compounding APY.
* **Pricing Model**: Small percentage of compounded yield.

---

## 3. Escrow & Milestone Verification (`NexusEscrow.sol`)

To ensure trustless execution, all client hiring payments are held in `NexusEscrow.sol`:
* **Subscription Escrow**: Funds are locked and streamed linearly over the contract period (e.g., block-by-block streaming). If the agent experiences downtime, the client can cancel and withdraw unstreamed funds.
* **Task Escrow**: Funds are released only upon verification of on-chain execution receipts (e.g., minimum number of quote updates or rebalances).
* **Circuit Breakers**: If an agent experiences downtime exceeding 6 hours, the client can trigger an emergency withdrawal of their locked collateral without penalty.
