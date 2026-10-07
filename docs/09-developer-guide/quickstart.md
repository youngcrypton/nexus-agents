# Runtime Quickstart

Get started with building, configuring, and running an autonomous trading agent using the official `@nexus/runtime` SDK.

---

## 1. Prerequisites

Ensure your environment has:
* **Node.js**: v20.0.0 or higher
* **npm** or **pnpm**
* **Git**

---

## 2. Installation

Clone the repository and install dependencies:

```bash
git clone https://github.com/youngcrypton/nexus-agents.git
cd nexus-agents/runtime
npm install
```

---

## 3. Running the Smoke Test & Strategy Demo

Run the built-in strategy simulation to verify your local environment:

```bash
npm run demo
```

Expected output:
```
===============================================================
   NEXUS AGENTS RUNTIME ENGINE — VERIFICATION & SMOKE TEST     
===============================================================

1. HYPERCORE PRECOMPILE STATE (0x0801 SIMULATION):
   - Mid Price:       $2.0000
   - Best Bid:        $1.9950
   - Best Ask:        $2.0050
   - Flow Imbalance:  25 bps

2. EVALUATING SENTRY MARKET-MAKER QUOTES:
   - Generated Bid:   $1.9950 | Size: 1000 tokens
   - Generated Ask:   $2.0050 | Size: 1000 tokens

3. EVALUATING ARBITER CROSS-VENUE ARBITRAGE:
   - Direction:        BUY_ASCEND_SELL_HYPERCORE
   - Raw Spread:       526 bps
   - Est Net Profit:   $40.48 USDC
```

---

## 4. Instantiating a Live Agent

```typescript
import { ethers } from "ethers";
import { NexusAgent, AgentConfig, StrategyType } from "@nexus/runtime";

const provider = new ethers.JsonRpcProvider("https://testnet-rpc.elysiumchain.tech");
const signer = new ethers.Wallet(process.env.AGENT_PRIVATE_KEY!, provider);

const config: AgentConfig = {
  agentId: 1,
  name: "MyFirstAgent",
  strategyType: StrategyType.SENTRY,
  tickerIndex: 1,
  rpcUrl: "https://testnet-rpc.elysiumchain.tech",
  accountAddress: "0xYourAgentTBAAddress",
  targetSpreadBps: 50,
  rebalanceThresholdBps: 100,
  maxInventoryToken: 10000n * 1000000n,
  maxInventoryUsdc: 20000n * 1000000n
};

const agent = new NexusAgent(config, provider, signer);

// Start autonomous execution loop (200ms tick cadence)
agent.start(200);
```

---

## Next Steps
* [How to Build Custom Strategies](building-strategies.md)
* [Run a Keeper Relayer Node](keeper-operations.md)
* [Local Testing with Anvil](local-testing.md)
