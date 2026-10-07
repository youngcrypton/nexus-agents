# Elysium Precompiles & CoreWriter

Elysium introduces native primitives that bridge the Arbitrum Nitro EVM execution environment directly into HyperCore’s sub-second matching engine. Nexus Agents utilizes these primitives to deliver sub-second reflexes without centralized oracles.

---

## 1. HyperCore Market Data Precompile (`0x...0801`)

Located at precompile address `0x0000000000000000000000000000000000000801`, this precompile allows smart contracts and off-chain agents to read live L1/L2 orderbook state synchronously.

### Interface

```solidity
interface IHyperCoreMarketData {
    struct SpotMarketSummary {
        uint64 blockHeight;
        uint64 blockTime;
        uint64 midPrice;          // 6 decimal fixed-point
        uint64 bestBid;           // 6 decimal fixed-point
        uint64 bestAsk;           // 6 decimal fixed-point
        uint64 flowImbalanceBps;  // Basis points
    }

    struct Level {
        uint64 px;
        uint64 sz;
    }

    function getSpotMarket(uint64 tickerIndex) external view returns (SpotMarketSummary memory);
    function getOrderbookDepth(uint64 tickerIndex, uint8 depth) external view returns (Level[] memory bids, Level[] memory asks);
    function getExpectedSlippage(uint64 tickerIndex, uint64 size, bool isBuy) external view returns (uint64 slippageBps);
}
```

### Key Advantages
1. **Zero Oracle Gas**: Reading through `eth_call` incurs **0 gas**. Reading inside a smart contract transaction costs ordinary EVM precompile gas (~2,100 gas) rather than tens of thousands for chainlink push relays.
2. **~70 ms Freshness**: Queries reflect the co-located HyperCore consensus round, preventing toxic stale-oracle exploitation.

---

## 2. ElysiumCoreWriter Predeploy (`0x...0802`)

Located at `0x0000000000000000000000000000000000000802`, the `ElysiumCoreWriter` is the non-custodial fast-write pipeline.

### Interface

```solidity
interface IElysiumCoreWriter {
    event OrderIntentEmitted(
        address indexed account,
        uint64 indexed tickerIndex,
        bool isBuy,
        uint64 price,
        uint64 size,
        uint64 indexed orderNonce,
        uint256 callbackEscrow
    );

    event OrderExecutedCallback(
        address indexed account,
        uint64 indexed orderNonce,
        bool success,
        uint64 filledSize,
        uint64 avgPrice
    );

    function placeLimitOrder(
        uint64 tickerIndex,
        bool isBuy,
        uint64 price,
        uint64 size,
        bool reduceOnly,
        uint64 orderNonce
    ) external payable returns (bytes32 intentId);

    function cancelOrder(
        uint64 tickerIndex,
        uint64 orderNonce
    ) external payable returns (bytes32 intentId);
}
```

### Execution Flow

```
[Nexus Agent TBA]
       │
       ▼ (1) placeLimitOrder(tickerIndex, isBuy, px, sz, reduceOnly, nonce) + msg.value (HYPE)
[ElysiumCoreWriter (0x0802)]
       │
       ▼ (2) Emits OrderIntentEmitted Event
[Keeper Relayer Daemon]
       │
       ▼ (3) Dispatches Intent with Agent Session Key Signature
[HyperCore CLOB]
       │
       ▼ (4) Order matched on L1 Orderbook
[ElysiumCoreWriter]
       │
       ▼ (5) Emits OrderExecutedCallback(account, nonce, success, filledSize, avgPrice)
[Nexus Agent TBA / Client]
```

---

## Next Steps
* [Explore Node Agent Runtime](../04-runtime-and-tooling/node-agent-runtime.md)
* [Review Developer Quickstart](../09-developer-guide/quickstart.md)
