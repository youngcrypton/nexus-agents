import assert from "node:assert";
import { ethers } from "ethers";
import {
  SentryStrategy,
  ArbiterStrategy,
  KeeperRelayer,
  AgentConfig,
  StrategyType,
  SpotMarketSummary
} from "../src/index.js";

async function runE2ETest() {
  console.log("===============================================================");
  console.log("   NEXUS AGENTS — END-TO-END PIPELINE INTEGRATION TEST         ");
  console.log("===============================================================\n");

  const config: AgentConfig = {
    agentId: 42,
    name: "Nexus-E2E-Agent",
    strategyType: StrategyType.ARBITER,
    tickerIndex: 1,
    rpcUrl: "http://127.0.0.1:8545",
    accountAddress: "0x1234567890123456789012345678901234567890",
    targetSpreadBps: 25,
    rebalanceThresholdBps: 50,
    maxInventoryToken: 10000n * 1000000n,
    maxInventoryUsdc: 20000n * 1000000n
  };

  // Step 1: Precompile market snapshot simulation
  console.log("Step 1: Ingesting precompile 0x0801 snapshot...");
  const marketState: SpotMarketSummary = {
    blockHeight: 12051000n,
    blockTime: BigInt(Math.floor(Date.now() / 1000)),
    midPrice: 2000000n, // $2.00 USDC
    bestBid: 1995000n,
    bestAsk: 2005000n,
    flowImbalanceBps: 10n
  };

  // Step 2: Cross-venue spread evaluation (Ascend AMM pool @ $1.88, HyperCore @ $2.00)
  console.log("Step 2: Evaluating cross-venue Arbiter strategy...");
  const arbiter = new ArbiterStrategy(config);
  const opp = arbiter.evaluateSpread(marketState, 1.88);

  assert.strictEqual(opp.hasOpportunity, true);
  assert.strictEqual(opp.direction, "BUY_ASCEND_SELL_HYPERCORE");
  console.log(`   ✔ Opportunity detected: ${opp.spreadBps} bps spread | Direction: ${opp.direction}`);
  console.log(`   ✔ Estimated net profit: $${opp.estimatedNetProfitUsdc.toFixed(2)} USDC`);

  // Step 3: Construct Order Intent
  console.log("Step 3: Constructing HyperCore Order Intent...");
  const intent = arbiter.buildHyperCoreIntent(opp);
  assert(intent !== null);
  assert.strictEqual(intent.tickerIndex, 1n);
  assert.strictEqual(intent.isBuy, false);
  console.log(`   ✔ Intent generated: Nonce #${intent.orderNonce} | Price: $${Number(intent.price) / 1e6} | Size: ${Number(intent.size) / 1e6}`);

  // Step 4: Keeper Relayer Dispatch
  console.log("Step 4: Dispatching via Keeper Relayer Daemon...");
  const dummyProvider = new ethers.JsonRpcProvider("http://127.0.0.1:8545");
  const relayer = new KeeperRelayer(dummyProvider);

  const relayed = await relayer.relayToHyperCore({
    account: config.accountAddress,
    tickerIndex: intent.tickerIndex,
    isBuy: intent.isBuy,
    price: intent.price,
    size: intent.size,
    orderNonce: intent.orderNonce,
    callbackEscrow: ethers.parseEther(intent.callbackEscrowHype)
  });

  assert.strictEqual(relayed.status, "CONFIRMED");
  assert(relayed.hyperCoreTxHash.startsWith("0x"));
  assert.strictEqual(relayed.orderNonce, intent.orderNonce);

  console.log(`   ✔ Keeper confirmation received: Status = ${relayed.status}`);
  console.log(`   ✔ HyperCore Tx Hash: ${relayed.hyperCoreTxHash}`);

  console.log("\n===============================================================");
  console.log("   E2E PIPELINE INTEGRATION TEST COMPLETED SUCCESSFULLY!       ");
  console.log("===============================================================\n");
}

runE2ETest().catch((err) => {
  console.error("E2E Test Failed:", err);
  process.exit(1);
});
