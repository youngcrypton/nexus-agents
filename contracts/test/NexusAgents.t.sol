// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {NexusAccount} from "../src/NexusAccount.sol";
import {NexusAccountRegistry} from "../src/NexusAccountRegistry.sol";
import {NexusAgentRegistry} from "../src/NexusAgentRegistry.sol";
import {NexusEscrow} from "../src/NexusEscrow.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {MockHyperCorePrecompile} from "../src/mocks/MockHyperCorePrecompile.sol";
import {MockElysiumCoreWriter} from "../src/mocks/MockElysiumCoreWriter.sol";
import {IHyperCoreMarketData} from "../src/interfaces/IHyperCoreMarketData.sol";

contract NexusAgentsTest is Test {
    MockERC20 public nexusToken;
    MockERC20 public usdc;

    NexusAccount public accountImplementation;
    NexusAccountRegistry public accountRegistry;
    NexusAgentRegistry public agentRegistry;
    NexusEscrow public escrow;

    MockHyperCorePrecompile public mockPrecompile;
    MockElysiumCoreWriter public mockCoreWriter;

    address public deployer = address(0x1);
    address public creator = address(0x2);
    address public client = address(0x3);
    address public burnPool = address(0x4);
    address public tradeAgentKey = address(0x5);

    uint256 public constant MINIMUM_BOND = 1000 * 1e18;

    function setUp() public {
        vm.startPrank(deployer);

        // Deploy Tokens
        nexusToken = new MockERC20("Nexus Protocol", "NEXUS", 18);
        usdc = new MockERC20("USD Coin", "USDC", 6);

        // Deploy Mocks
        mockPrecompile = new MockHyperCorePrecompile();
        mockCoreWriter = new MockElysiumCoreWriter();

        // Deploy ERC-6551 Infrastructure
        accountImplementation = new NexusAccount();
        accountRegistry = new NexusAccountRegistry();

        // Deploy Agent Registry
        agentRegistry = new NexusAgentRegistry(
            address(nexusToken),
            address(accountRegistry),
            address(accountImplementation),
            MINIMUM_BOND
        );

        // Deploy Escrow
        escrow = new NexusEscrow(address(agentRegistry), burnPool);

        // Fund creator and client
        nexusToken.mint(creator, 50000 * 1e18);
        usdc.mint(client, 100000 * 1e6);

        vm.deal(creator, 10 ether);
        vm.deal(client, 10 ether);

        vm.stopPrank();
    }

    function testRegisterAgent() public {
        vm.startPrank(creator);
        nexusToken.approve(address(agentRegistry), MINIMUM_BOND);

        (uint256 agentId, address account) = agentRegistry.registerAgent(
            "Sentry Quoter Alpha",
            NexusAgentRegistry.StrategyType.SENTRY,
            "ipfs://QmSentryMetadataHash",
            MINIMUM_BOND
        );

        assertEq(agentId, 1);
        assertEq(agentRegistry.ownerOf(agentId), creator);
        assertTrue(account != address(0));

        NexusAgentRegistry.AgentProfile memory profile = agentRegistry.getAgent(agentId);
        assertEq(profile.name, "Sentry Quoter Alpha");
        assertEq(profile.stakedBond, MINIMUM_BOND);
        assertTrue(profile.isActive);
        assertEq(profile.accountAddress, account);
        vm.stopPrank();
    }

    function testAccountExecutionAndDelegation() public {
        // Register Agent
        vm.startPrank(creator);
        nexusToken.approve(address(agentRegistry), MINIMUM_BOND);
        (, address account) = agentRegistry.registerAgent(
            "Sentry",
            NexusAgentRegistry.StrategyType.SENTRY,
            "ipfs://sentry",
            MINIMUM_BOND
        );

        NexusAccount agentAccount = NexusAccount(payable(account));

        // Creator delegates trade-only key
        agentAccount.setTradeOnlyAgentKey(tradeAgentKey);
        assertEq(agentAccount.tradeOnlyAgentKey(), tradeAgentKey);

        // Fund agent account with HYPE gas
        vm.deal(account, 1 ether);
        vm.stopPrank();

        // Authorized tradeAgentKey executes an order on CoreWriter via agent account
        vm.startPrank(tradeAgentKey);
        bytes memory callData = abi.encodeWithSelector(
            mockCoreWriter.placeLimitOrder.selector,
            uint64(1234), // tickerIndex
            true,         // isBuy
            uint64(2000000), // price $2.00
            uint64(5000),    // size
            false,
            uint64(1)        // nonce
        );

        bytes memory result = agentAccount.execute(
            address(mockCoreWriter),
            0.01 ether, // callback escrow
            callData,
            0
        );

        assertTrue(result.length > 0);
        assertEq(mockCoreWriter.getRecordedOrdersCount(), 1);
        vm.stopPrank();

        // Unauthorized caller fails
        vm.startPrank(address(0x999));
        vm.expectRevert("NexusAccount: unauthorized");
        agentAccount.execute(address(mockCoreWriter), 0, callData, 0);
        vm.stopPrank();
    }

    function testTaskEscrowFlowUSDC() public {
        // 1. Register Agent
        vm.startPrank(creator);
        nexusToken.approve(address(agentRegistry), MINIMUM_BOND);
        (uint256 agentId, address account) = agentRegistry.registerAgent(
            "Arbiter Alpha",
            NexusAgentRegistry.StrategyType.ARBITER,
            "ipfs://arbiter",
            MINIMUM_BOND
        );
        vm.stopPrank();

        // 2. Client creates task escrow for $1,000 USDC
        uint256 taskAmount = 1000 * 1e6;
        vm.startPrank(client);
        usdc.approve(address(escrow), taskAmount);

        uint256 taskId = escrow.createTaskEscrow(
            agentId,
            address(usdc),
            taskAmount,
            24 hours,
            keccak256("RebalanceTask_1")
        );
        assertEq(taskId, 1);
        vm.stopPrank();

        // 3. Client confirms task completion -> release escrow
        vm.startPrank(client);
        escrow.releaseTaskEscrow(taskId);
        vm.stopPrank();

        // Verify 80/20 split: 80% to agent account ($800), 20% to burn pool ($200)
        assertEq(usdc.balanceOf(account), 800 * 1e6);
        assertEq(usdc.balanceOf(burnPool), 200 * 1e6);
    }

    function testTaskEscrowNativeHYPE() public {
        // 1. Register Agent
        vm.startPrank(creator);
        nexusToken.approve(address(agentRegistry), MINIMUM_BOND);
        (uint256 agentId, address account) = agentRegistry.registerAgent(
            "Apex Alpha",
            NexusAgentRegistry.StrategyType.APEX,
            "ipfs://apex",
            MINIMUM_BOND
        );
        vm.stopPrank();

        // 2. Client creates task escrow for 1 HYPE
        uint256 taskAmount = 1 ether;
        vm.startPrank(client);
        uint256 taskId = escrow.createTaskEscrow{value: taskAmount}(
            agentId,
            address(0), // native HYPE
            taskAmount,
            12 hours,
            keccak256("ApexSignal_1")
        );
        vm.stopPrank();

        // 3. Release escrow
        vm.startPrank(client);
        escrow.releaseTaskEscrow(taskId);
        vm.stopPrank();

        // Verify 80/20 native split: 0.8 HYPE to agent, 0.2 HYPE to burn pool
        assertEq(account.balance, 0.8 ether);
        assertEq(burnPool.balance, 0.2 ether);
    }

    function testTimeoutRefundCircuitBreaker() public {
        // Register Agent
        vm.startPrank(creator);
        nexusToken.approve(address(agentRegistry), MINIMUM_BOND);
        (uint256 agentId, ) = agentRegistry.registerAgent(
            "Slow Agent",
            NexusAgentRegistry.StrategyType.CUSTOM,
            "ipfs://slow",
            MINIMUM_BOND
        );
        vm.stopPrank();

        // Client deposits $500 USDC with 6-hour timeout
        uint256 depositAmount = 500 * 1e6;
        vm.startPrank(client);
        usdc.approve(address(escrow), depositAmount);

        uint256 taskId = escrow.createTaskEscrow(
            agentId,
            address(usdc),
            depositAmount,
            6 hours,
            keccak256("SlowTask")
        );

        // Attempting refund before timeout reverts
        vm.expectRevert("Escrow: timeout has not expired");
        escrow.claimTimeoutRefund(taskId);

        // Advance time past 6 hours
        vm.warp(block.timestamp + 6 hours + 1);

        // Client claims 100% refund
        uint256 balanceBefore = usdc.balanceOf(client);
        escrow.claimTimeoutRefund(taskId);
        uint256 balanceAfter = usdc.balanceOf(client);

        assertEq(balanceAfter - balanceBefore, depositAmount);
        vm.stopPrank();
    }

    function testStreamingSubscriptionVestingAndCancel() public {
        // Register Agent
        vm.startPrank(creator);
        nexusToken.approve(address(agentRegistry), MINIMUM_BOND);
        (uint256 agentId, address account) = agentRegistry.registerAgent(
            "Streamer Agent",
            NexusAgentRegistry.StrategyType.VANGUARD,
            "ipfs://vanguard",
            MINIMUM_BOND
        );
        vm.stopPrank();

        // Client subscribes for 10 days at 1000 USDC
        uint256 totalAmount = 1000 * 1e6;
        vm.startPrank(client);
        usdc.approve(address(escrow), totalAmount);

        uint256 subId = escrow.createSubscriptionEscrow(
            agentId,
            address(usdc),
            totalAmount,
            10 days
        );

        // Fast forward 5 days (50% vested = 500 USDC)
        vm.warp(block.timestamp + 5 days);

        // Client cancels subscription
        escrow.cancelSubscription(subId);

        // Client gets back unvested 500 USDC
        // Agent gets 80% of 500 USDC = 400 USDC
        // Burn pool gets 20% of 500 USDC = 100 USDC
        assertEq(usdc.balanceOf(account), 400 * 1e6);
        assertEq(usdc.balanceOf(burnPool), 100 * 1e6);
        vm.stopPrank();
    }

    function testSlashBond() public {
        vm.startPrank(creator);
        nexusToken.approve(address(agentRegistry), MINIMUM_BOND);
        (uint256 agentId, ) = agentRegistry.registerAgent(
            "Unstable Agent",
            NexusAgentRegistry.StrategyType.CUSTOM,
            "ipfs://unstable",
            MINIMUM_BOND
        );
        vm.stopPrank();

        // Deployer (governance) slashes 500 NEXUS for downtime
        vm.startPrank(deployer);
        address victim = address(0x777);
        agentRegistry.slashBond(agentId, 500 * 1e18, victim, "Severe downtime SLA violation");

        assertEq(nexusToken.balanceOf(victim), 500 * 1e18);
        NexusAgentRegistry.AgentProfile memory profile = agentRegistry.getAgent(agentId);
        assertEq(profile.stakedBond, 500 * 1e18);
        vm.stopPrank();
    }

    function testFuzzFeeSplits(uint256 amount) public {
        vm.assume(amount > 1000 && amount < 1_000_000_000 * 1e6);

        vm.startPrank(creator);
        nexusToken.approve(address(agentRegistry), MINIMUM_BOND);
        (uint256 agentId, address account) = agentRegistry.registerAgent(
            "Fuzz Agent",
            NexusAgentRegistry.StrategyType.SENTRY,
            "ipfs://fuzz",
            MINIMUM_BOND
        );
        vm.stopPrank();

        usdc.mint(client, amount);
        vm.startPrank(client);
        usdc.approve(address(escrow), amount);

        uint256 taskId = escrow.createTaskEscrow(
            agentId,
            address(usdc),
            amount,
            12 hours,
            keccak256("FuzzTask")
        );

        escrow.releaseTaskEscrow(taskId);
        vm.stopPrank();

        uint256 burnShare = (amount * 2000) / 10000;
        uint256 creatorShare = amount - burnShare;

        assertEq(usdc.balanceOf(account), creatorShare);
        assertEq(usdc.balanceOf(burnPool), burnShare);
        assertEq(creatorShare + burnShare, amount);
    }
}
