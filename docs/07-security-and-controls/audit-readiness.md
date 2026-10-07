# Audit Readiness & Formal Verification

Security and capital preservation are paramount for autonomous financial systems. Nexus Agents adheres to rigorous institutional-grade development standards designed to withstand adversarial market conditions and economic exploits.

---

## Security Invariants

The Nexus protocol enforces five core mathematical and execution invariants across all smart contracts:

| Invariant | Description | Enforcement Mechanism |
| :--- | :--- | :--- |
| **INV-1: Non-Custodial Isolation** | An agent's runtime key can never withdraw or transfer client capital from an Escrow or TBA. | Cryptographic trade-only delegation; execution caller checks. |
| **INV-2: 80/20 Fee Conservation** | Under all payout conditions, exactly 80% is allocated to the agent TBA and 20% to protocol fees. | Fuzz-tested fixed-point math with overflow and truncation checks. |
| **INV-3: Circuit Breaker Guarantee** | Any task inactive for $>6\text{ hours}$ past its deadline is guaranteed 100% refundable to the client. | Automated timestamp checks in `claimTimeoutRefund()`. |
| **INV-4: Monotonic Nonce Ordering** | Limit orders cannot be replayed or submitted out of sequence. | Monotonically strictly-increasing order nonces in `NexusAccount` & `CoreWriter`. |
| **INV-5: Slashing Bound** | Slashed bond amounts cannot exceed the agent's current active staked balance. | Underflow assertions and balance check prior to deduction. |

---

## Defensive Engineering Patterns

### 1. Re-Entrancy Protection
All state-modifying external functions across `NexusEscrow.sol` and `NexusAgentRegistry.sol` employ Solady's gas-optimized `ReentrancyGuard` (`nonReentrant` modifier). State updates strictly follow the **Checks-Effects-Interactions (CEI)** pattern prior to external token transfers.

### 2. Pull Over Push Payments
In refund and streaming cancellation workflows, funds are transferred directly to the authenticated caller rather than relying on batch arrays that could be blocked by a malicious reverting receiver contract.

### 3. Safe Token Transfers
All ERC-20 transfers use Solady's `SafeTransferLib`, gracefully handling tokens with missing return values or custom approval requirements (e.g. USDT/USDC).

---

## Static Analysis & Testing Coverage

| Test Suite | Metric / Standard | Status / Result |
| :--- | :--- | :--- |
| **Foundry Unit Tests** | `forge test -vvv` across all contracts | **8 / 8 Passed (100%)** |
| **Foundry Fuzz Testing** | 256 random state fuzz runs per test case | **Passed (Zero Invariant Breaches)** |
| **TypeScript Runtime Unit Tests** | Automated strategy evaluation suite | **4 / 4 Passed (100%)** |
| **End-to-End Pipeline Integration** | Precompile $\to$ Strategy $\to$ Keeper $\to$ CLOB | **100% Verified** |
| **Compiler Hygiene** | Solidity 0.8.24 & TypeScript v5.6 | **0 Warnings / 0 Errors** |

---

## Next Steps
* [Review Non-Custodial Safeguards](non-custodial-safeguards.md)
* [Review Risk Management & Failsafes](risk-management.md)
