# The Ascend Launch Playbook

## Aligning with Ascend’s Token Lifecycle

Nexus Agents rejects external launchpads, private VC allocations, and predatory initial DEX offerings. The `$NEXUS` token conducts its public launch **strictly in accordance with Ascend’s documented lifecycle**:

```
                         THE ASCEND TOKEN LIFECYCLE
                         ==========================

  +----------------------+      +----------------------+      +----------------------+
  |  1. LAUNCH STAGE     |      | 2. ASCENDED STATUS   |      | 3. HYPERCORE SPOT    |
  | Closed Hook Pool     | ===> | Volume & Holders     | ===> | Link Deposit Wallet  |
  | (USDC Quote Asset)   |      | Ascend Buybacks      |      | to 0x20||tokenIndex  |
  +----------------------+      +----------------------+      +----------------------+
```

---

## Stage 1: Launch in Ascend Closed Hook Pool

* **Standardized Launch Pool**: `$NEXUS` launches directly into a closed hook pool on Elysium without an open third-party bonding-curve phase.
* **Quote Asset**: The pool is quoted exclusively in **USDC**, ensuring stable price discovery and deep initial liquidity without draining raw HYPE reserves.
* **No Competing Protocol Token**: Ascend itself issues no protocol token; Nexus aligns directly with this ethos by directing its own value flows into the HYPE and KNTQ ecosystems.

---

## Stage 2: Achieving "Ascended" Status

As marketplace activity grows, `$NEXUS` targets qualification for **Ascended Status** under Ascend's governance criteria:
1. **Sustainable Volume**: Cumulative organic trading volume on the launch pool.
2. **Unique Holder Distribution**: Verified wide distribution without concentrated insider clustering.
3. **Ascend Ecosystem Buybacks**: Qualifying unlocks direct ecosystem-token buybacks funded by Ascend’s **30% ecosystem-buyback allocation**, with tokens held in Ascend’s treasury to prepare for HyperCore spot deployment.

---

## Stage 3: HyperCore Spot Graduation

Once Ascended status is achieved, Ascend coordinates the formal spot deployment ceremony onto **HyperCore L1**:
1. **Ticker Acquisition**: Securing the official 6-character ticker (`NEXUS`) via HyperCore’s recurring Dutch auction.
2. **Deposit Wallet Creation**: Deploying the deterministic `HyperCoreDepositWallet` on HyperEVM via CREATE2.
3. **Safe Genesis Execution**: Staging and finalizing 100% of the maximum supply at the designated system address ($0x20 \parallel \text{tokenIndex}$), ensuring that every unit of Core supply is backed 1:1 by EVM escrow.
4. **Storage Slot Linking**: Proving deployer control via `customStorageSlot` proof.
5. **Spot Orderbook Listing**: Calling `registerSpot` and `registerHyperliquidity` with $n_{\text{orders}} = 0$, opening the live `$NEXUS/USDC` orderbook on Hyperliquid.
