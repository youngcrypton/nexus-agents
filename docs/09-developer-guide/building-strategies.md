# Building Custom Trading Strategies

The `@nexus/runtime` SDK is designed to be fully extensible. Developers can build specialized market-making algorithms, statistical arbitrage models, sentiment trackers, or AI/LLM-driven executors by following the strategy plugin pattern.

---

## Strategy Architecture

A Nexus strategy typically consumes market data from Elysium plugins and outputs one or more `OrderIntentParams`.

```
                    +------------------------------------+
                    |       Sensory Plugins              |
                    |  - HyperCorePrecompilePlugin       |
                    |  - AscendHookPoolPlugin            |
                    +-----------------+------------------+
                                      |
                                      v Market State Snapshot
                    +-----------------+------------------+
                    |       Your Custom Strategy         |
                    |  - Quantitative Calculation        |
                    |  - Inventory Management            |
                    |  - Risk Checks                     |
                    +-----------------+------------------+
                                      |
                                      v OrderIntentParams
                    +-----------------+------------------+
                    |       Action Plugins               |
                    |  - CoreWriterPlugin.emitLimitOrder |
                    +------------------------------------+
```

---

## Creating a Custom Strategy Class

```typescript
import {
  SpotMarketSummary,
  OrderIntentParams,
  AgentConfig
} from "@nexus/runtime";

export class MomentumScalperStrategy {
  private config: AgentConfig;
  private lastMidPrice: bigint = 0n;
  private currentNonce: bigint = 1n;

  constructor(config: AgentConfig) {
    this.config = config;
  }

  public evaluateTick(market: SpotMarketSummary): OrderIntentParams | null {
    if (this.lastMidPrice === 0n) {
      this.lastMidPrice = market.midPrice;
      return null;
    }

    // Detect rapid tick surge (> 0.25% in a single block)
    const priceChangeBps =
      ((market.midPrice - this.lastMidPrice) * 10000n) / this.lastMidPrice;

    this.lastMidPrice = market.midPrice;

    if (priceChangeBps > 25n) {
      // Strong upward momentum detected -> execute scalp buy order
      return {
        tickerIndex: BigInt(this.config.tickerIndex),
        isBuy: true,
        price: market.bestAsk,
        size: 500n * 1000000n, // 500 tokens
        reduceOnly: false,
        orderNonce: this.currentNonce++,
        callbackEscrowHype: "0.005"
      };
    }

    return null;
  }
}
```

---

## Best Practices & Safety Guidelines

1. **Deterministic Nonces**: Always increment `orderNonce` monotonically to prevent duplicate orders or replay attacks.
2. **Slippage Bounds**: Never place naked market orders on low-liquidity pairs. Always specify a limit price relative to `bestBid` or `bestAsk`.
3. **Inventory Ceilings**: Check `maxInventoryToken` and `maxInventoryUsdc` before generating new buy or sell intents.

---

## Next Steps
* [Run a Keeper Relayer](keeper-operations.md)
* [Local Testing with Anvil](local-testing.md)
