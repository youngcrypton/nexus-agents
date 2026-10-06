# Elysium-Native Tooling & Plugins

## The Agent Tool Stack

To interact with Elysium and HyperCore, the Nexus runtime provides modular plugins adhering to standard tool-calling specifications (compatible with LangChain, Eliza, and Model Context Protocol / MCP):

---

## 1. Tool Definitions

### Plugin 1: `HyperCorePrecompilePlugin`
Enables the agent to read live L1 consensus state directly on Elysium without push oracles:
* **`getSpotMarket(tickerIndex: number)`**:
  * Returns: `{ bestBid: string, bestAsk: string, midPrice: string, bookDepth: DepthLadder }`
  * Execution: Calls precompile address `0x0000000000000000000000000000000000000100`.
  * Gas Cost: ~2,500 call gas (no storage writes).
* **`getExpectedSlippage(tickerIndex: number, size: string, isBuy: boolean)`**:
  * Computes projected price impact on HyperCore for a designated order size.

### Plugin 2: `CoreWriterPlugin`
Enables the agent to emit non-custodial orders directly to HyperCore:
* **`placeLimitOrder(params: OrderParams)`**:
  * Encodes parameters: `{ tickerIndex, isBuy, price, size, reduceOnly, nonce }`.
  * Submits to `ElysiumCoreWriter` predeploy with `msg.value` HYPE callback escrow.
* **`cancelOrder(tickerIndex: number, orderId: number)`**:
  * Emits cancellation intent, processed by the keeper within one HyperCore block (~70 ms).

### Plugin 3: `AscendPoolPlugin`
Enables the agent to interact directly with Ascend launch pools on Elysium:
* **`getPoolReserves(tokenAddress: string)`**:
  * Queries real-time token and USDC reserves in the Ascend hook pool.
* **`executeSwap(tokenIn: string, tokenOut: string, amountIn: string, minAmountOut: string)`**:
  * Executes swaps to balance local pool inventory.

---

## 2. Standardized MCP (Model Context Protocol) Support

Nexus agents natively support the Model Context Protocol (MCP), allowing external LLMs and reasoning models (Claude, Gemini, local models) to query Elysium state seamlessly:

```json
{
  "name": "hypercore_market_data",
  "description": "Reads real-time HyperCore orderbook depth and prices on Elysium L2",
  "inputSchema": {
    "type": "object",
    "properties": {
      "tickerIndex": { "type": "number", "description": "Core token index" }
    },
    "required": ["tickerIndex"]
  }
}
```
