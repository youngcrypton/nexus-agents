import assert from "node:assert";
import { SentryStrategy } from "../src/strategies/SentryStrategy.js";
import { ArbiterStrategy } from "../src/strategies/ArbiterStrategy.js";
import { AgentConfig, StrategyType, SpotMarketSummary } from "../src/types.js";

console.log("Running @nexus/runtime Unit Tests...");

const baseConfig: AgentConfig = {
  agentId: 1,
  name: "TestAgent",
  strategyType: StrategyType.SENTRY,
  tickerIndex: 1,
  rpcUrl: "http://127.0.0.1:8545",
  accountAddress: "0x1111111111111111111111111111111111111111",
  targetSpreadBps: 50,
  rebalanceThresholdBps: 100,
  maxInventoryToken: 10000n * 1000000n,
  maxInventoryUsdc: 20000n * 1000000n
};

const market: SpotMarketSummary = {
  blockHeight: 100n,
  blockTime: 1700000000n,
  midPrice: 2000000n, // $2.00
  bestBid: 1990000n,
  bestAsk: 2010000n,
  flowImbalanceBps: 0n
};

// Test 1: Sentry Strategy Symmetric Quoting
{
  const sentry = new SentryStrategy(baseConfig);
  sentry.updateInventory(5000n * 1000000n, 10000n * 1000000n); // Neutral 50%
  const { bidOrder, askOrder } = sentry.computeQuotes(market);

  assert.strictEqual(bidOrder.isBuy, true);
  assert.strictEqual(askOrder.isBuy, false);
  assert(bidOrder.price < market.midPrice, "Bid price must be below mid");
  assert(askOrder.price > market.midPrice, "Ask price must be above mid");
  assert(askOrder.price > bidOrder.price, "Ask must be higher than Bid");
  console.log("✔ SentryStrategy symmetric quote test passed");
}

// Test 2: Sentry Strategy Inventory Skew
{
  const sentry = new SentryStrategy(baseConfig);
  // Heavy token inventory (>60% of max 10,000)
  sentry.updateInventory(8000n * 1000000n, 5000n * 1000000n);
  const skewedQuotes = sentry.computeQuotes(market);

  // When holding heavy token, quote prices should be skewed lower to shed inventory
  assert(skewedQuotes.bidOrder.price < 1995000n, "Bid should skew lower when inventory is heavy");
  console.log("✔ SentryStrategy inventory skew test passed");
}

// Test 3: Arbiter Strategy Cross-Venue Filter
{
  const arbConfig: AgentConfig = {
    ...baseConfig,
    strategyType: StrategyType.ARBITER,
    targetSpreadBps: 20
  };
  const arbiter = new ArbiterStrategy(arbConfig);

  // If Ascend price is $1.90 and HyperCore is $2.00, spread is ~526 bps. Net of 1% Ascend fee = ~426 bps > 20 bps target
  const opp = arbiter.evaluateSpread(market, 1.90);
  assert.strictEqual(opp.hasOpportunity, true);
  assert.strictEqual(opp.direction, "BUY_ASCEND_SELL_HYPERCORE");
  assert(opp.estimatedNetProfitUsdc > 0, "Arbitrage should be profitable");

  const intent = arbiter.buildHyperCoreIntent(opp);
  assert(intent !== null);
  assert.strictEqual(intent.isBuy, false, "HyperCore leg should sell high");
  console.log("✔ ArbiterStrategy profitable spread detection passed");
}

// Test 4: Arbiter Strategy Rejection on Tight Spread
{
  const arbConfig: AgentConfig = {
    ...baseConfig,
    strategyType: StrategyType.ARBITER,
    targetSpreadBps: 50
  };
  const arbiter = new ArbiterStrategy(arbConfig);

  // Ascend price $1.99 vs $2.00 is ~50 bps raw, minus 100 bps Ascend fee = negative net spread
  const tightOpp = arbiter.evaluateSpread(market, 1.99);
  assert.strictEqual(tightOpp.hasOpportunity, false);
  console.log("✔ ArbiterStrategy tight spread rejection passed");
}

console.log("\nAll @nexus/runtime unit tests passed successfully! (4/4)");
