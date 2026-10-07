# Elysium L2 Integration

## The Technical Execution Advantage

Nexus Agents is engineered natively for **Elysium**, taking full advantage of the specific characteristics of its Arbitrum Orbit (Nitro/ArbOS) architecture.

---

## 1. 100–200 ms Canonical Block Cadence

On standard optimistic rollups, transaction confirmation requires waiting for multi-second sequencers or synthetic preconfirmations. Elysium produces **real canonical blocks every 100–200 ms**, with an end-to-end perceived transaction receipt of approximately **300 ms**.

| Blockchain / Layer | Block / Slot Cadence | Perceived Finality / Receipt | Execution Environment |
| :--- | :--- | :--- | :--- |
| **Ethereum L1** | 12,000 ms slots | ~12–64 seconds | EVM (15 Mgas/s) |
| **HyperEVM** | 1,000 ms blocks | ~1,000 ms | Custom EVM (3 Mgas/s cap) |
| **Solana** | ~400 ms slots | ~400–800 ms | SVM |
| **Base (OP Stack)** | ~2,000 ms blocks | ~300–500 ms preconfirms | EVM |
| **Elysium L2 (Nitro)** | **100–200 ms canonical** | **~300 ms final receipt** | **Nitro Orbit (300 Mgas/s, HYPE Gas)** |

For autonomous agents, this rapid canonical cadence means:
* **Real-time quote adjustments**: Agents can adjust limit quotes 5–10 times per second, keeping spreads tight and minimizing front-running risk.
* **Deterministic receipts**: Smart accounts and escrow contracts receive fast transaction confirmations without having to manage complex re-organization or preconfirmation states.

---

## 2. 300 Mgas/s Execution Target

While HyperEVM is constrained to 3M gas per second (with a 30M spike only once every 60 seconds), Elysium is tuned for high-throughput institutional workloads:
* **Target Throughput**: 300 Mgas/s.
* **Fee Tuning**: The fee schedule is deliberately calibrated so that cancelling and refreshing orders repeatedly costs fractions of a cent.
* **Complex Strategy Execution**: Multi-legged algorithmic execution—such as evaluating cross-pair volatility, checking multi-token balances, and executing conditional rebalances—can run within a single transaction without hitting block gas limits.

---

## 3. Native HYPE Gas (`msg.value`)

Elysium uses **HYPE as its native gas token end-to-end**:
* HYPE bridges 1:1 from HyperEVM as native gas and withdraws 1:1.
* There is no wrapper token (e.g., no WETH or wrapped HYPE required for gas).
* Agents pay all network execution fees and keeper escrow deposits directly in `msg.value` HYPE, eliminating balance-wrapping logic and ERC-20 approval transactions.

---

## 4. AnyTrust Data Availability with HyperEVM Fallback

To maintain low execution costs for high-frequency agent actions, Elysium utilizes **AnyTrust Data Availability (DAC)**:
* A Data Availability Committee (DAC) stores full transaction batch data off-chain and posts a compact ~100-byte certificate to HyperEVM.
* If the DAC ever becomes unresponsive, Elysium automatically falls back to posting full batch data directly to HyperEVM.
* This ensures that Nexus agents benefit from minimal settlement overhead while retaining verifiable security guarantees on Hyperliquid’s base EVM.
