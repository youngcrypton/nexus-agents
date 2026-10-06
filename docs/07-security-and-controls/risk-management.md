# Risk Management & Failsafes

## Comprehensive Risk Disclosure & Controls

Nexus Agents is an institutional-grade protocol designed with multi-layered defensive controls:

---

## 1. Smart Contract & Execution Risks

| Risk Category | Potential Impact | Protocol Mitigation |
| :--- | :--- | :--- |
| **Precompile Stale Reads** | Agent trades on outdated price data | Precompile responses carry HyperCore block numbers; runtime rejects data older than 2 blocks (~140 ms). |
| **Keeper Relay Downtime** | Intent emitted on Elysium fails to reach HyperCore | Intents are non-custodial and auto-expire; client can trigger timeout refund via `NexusEscrow.sol`. |
| **Smart Wallet Reentrancy** | Malicious agent draining escrow | All contracts utilize OpenZeppelin `ReentrancyGuardUpgradeable` and follow Checks-Effects-Interactions. |
| **Ascend Hook Divergence** | AMM price spikes due to low pool depth | Agents enforce strict maximum slippage tolerances before executing pool swaps. |

---

## 2. Market & Inventory Risk Management

Autonomous market making involves inherent inventory risk:
* **Dynamic Spread Widening**: As market volatility spikes, agents automatically widen their quoted spread to protect against adverse selection.
* **Inventory Skew Limits**: If an agent’s inventory accumulates excessive token exposure relative to USDC, the agent halts buy quotes and increases sell order density to restore inventory equilibrium.
* **Emergency Unwind**: In extreme tail-risk events, the Agent Smart Account can trigger an automated hedge into HyperCore perpetuals to lock in delta-neutrality.

---

## 3. External Infrastructure Dependencies

Nexus depends on:
1. **Elysium L2**: AnyTrust sequencer and HyperEVM settlement.
2. **HyperCore L1**: Consensus matching engine and precompile accuracy.
3. **Ascend Framework**: Launch pool mechanics and treasury buyback allocations.

Disruptions in external validator sets, bridge gateways, or network upgrades are mitigated through fail-closed execution logic, ensuring client funds remain secure under all network conditions.
