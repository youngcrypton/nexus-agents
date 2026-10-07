# Sentry Market-Maker Strategy

The **Sentry Strategy** (`SentryStrategy.ts`) is Nexus’s flagship automated market-making archetype. It continuously quotes two-sided limit orders on HyperCore’s central limit order book (CLOB) while dynamically managing inventory risk to prevent toxic accumulation.

---

## Strategy Mathematical Model

The Sentry engine adapts the classical **Avellaneda-Stoikov** market-making framework for sub-second L2 execution.

### 1. Reservation Price ($R$)
Rather than quoting symmetrically around the mid-price ($S$), the agent shifts its reservation price based on current asset inventory ($q$) relative to target inventory ($q_{\text{target}}$):

$$R = S \times \left(1 + \frac{\text{Inventory Skew Bps}}{10,000}\right)$$

* **Inventory Skew Rule**:
  * If $\text{Token Balance} > 60\%$ of max capacity: $\text{Skew} = -10\text{ bps}$ (lowers reservation price to attract buyers and offload excess base tokens).
  * If $\text{Token Balance} < 40\%$ of max capacity: $\text{Skew} = +10\text{ bps}$ (raises reservation price to attract sellers and restock base tokens).
  * If within $40\%–60\%$: $\text{Skew} = 0\text{ bps}$ (neutral inventory).

### 2. Bid and Ask Quote Prices
Quotes are placed symmetrically around the reservation price $R$ based on the user-configured spread parameter ($\delta$):

$$P_{\text{bid}} = R - \frac{S \times \delta}{20,000}$$

$$P_{\text{ask}} = R + \frac{S \times \delta}{20,000}$$

Where $\delta$ is the target spread in basis points (e.g., $50\text{ bps} = 0.50\%$).

---

## Code Example

```typescript
import { SentryStrategy, AgentConfig, StrategyType } from "@nexus/runtime";

const config: AgentConfig = {
  agentId: 1,
  name: "Nexus-Primary-Sentry",
  strategyType: StrategyType.SENTRY,
  tickerIndex: 1, // $NEXUS spot index
  rpcUrl: "http://127.0.0.1:8545",
  accountAddress: "0x...",
  targetSpreadBps: 50,       // 0.50% spread
  rebalanceThresholdBps: 100,
  maxInventoryToken: 10000n * 1000000n,
  maxInventoryUsdc: 20000n * 1000000n
};

const sentry = new SentryStrategy(config);
sentry.updateInventory(tokenBalance, usdcBalance);

// Evaluates quotes against live precompile snapshot
const { bidOrder, askOrder } = sentry.computeQuotes(marketSnapshot);
```

---

## Next Steps
* [Explore Arbiter Strategy](arbiter-strategy.md)
* [Review Developer Quickstart](../09-developer-guide/quickstart.md)
