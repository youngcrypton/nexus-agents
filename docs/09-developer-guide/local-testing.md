# Local Testing & Anvil Simulation

Nexus provides a comprehensive, multi-tiered testing harness allowing developers to test every layer of the stack locally without risking real capital or needing live testnet faucets.

---

## 1. Smart Contracts Unit & Fuzz Tests (Foundry)

Located in `contracts/`:

```bash
cd contracts
forge test -vvv
```

### Key Test Cases

```
Ran 8 tests for test/NexusAgents.t.sol:NexusAgentsTest
[PASS] testAccountExecutionAndDelegation() (gas: 502439)
[PASS] testFuzzFeeSplits(uint256) (runs: 256, μ: 624240, ~: 624240)
[PASS] testRegisterAgent() (gas: 333242)
[PASS] testSlashBond() (gas: 388786)
[PASS] testStreamingSubscriptionVestingAndCancel() (gas: 642357)
[PASS] testTaskEscrowFlowUSDC() (gas: 638530)
[PASS] testTaskEscrowNativeHYPE() (gas: 592179)
[PASS] testTimeoutRefundCircuitBreaker() (gas: 581955)
Suite result: ok. 8 passed; 0 failed; 0 skipped; finished in 111.04ms
```

---

## 2. Runtime SDK Unit Tests

Located in `runtime/`:

```bash
cd runtime
npm test
```

### Verified Properties
* **Sentry Strategy**: Symmetric quotes, inventory skew adjustments when base token balance exceeds 60%.
* **Arbiter Strategy**: Profitable cross-venue spread detection and rejection of unprofitable tight spreads after deducting Ascend’s 1% fee.

---

## 3. End-to-End Pipeline Integration Test

Verify the complete autonomous trade pipeline from precompile ingestion to keeper dispatch:

```bash
cd runtime
npm run test:e2e
```

### Pipeline Flow
```
Step 1: Ingesting precompile 0x0801 snapshot...
Step 2: Evaluating cross-venue Arbiter strategy...
   [OK] Opportunity detected: 638 bps spread | Direction: BUY_ASCEND_SELL_HYPERCORE
   [OK] Estimated net profit: $50.58 USDC
Step 3: Constructing HyperCore Order Intent...
   [OK] Intent generated: Nonce #1000 | Price: $2 | Size: 500
Step 4: Dispatching via Keeper Relayer Daemon...
   [OK] Keeper confirmation received: Status = CONFIRMED
   [OK] HyperCore Tx Hash: 0xbb886db5842b24f477db15f07f57371bc6e6585e86cd65d3954ca07a5439461a
```

---

## 4. Local Deployment Script (Dry-Run)

Simulate complete contract deployment on an ephemeral Anvil node:

```bash
cd contracts
forge script script/DeployNexus.s.sol
```

---

## Next Steps
* [Explore Security & Safeguards](../07-security-and-controls/non-custodial-safeguards.md)
* [Review Audit Readiness](../07-security-and-controls/audit-readiness.md)
