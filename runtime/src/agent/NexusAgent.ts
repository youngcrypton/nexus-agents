import { ethers } from "ethers";
import { AgentConfig, StrategyType, SpotMarketSummary, ExecutionReceipt } from "../types.js";
import { HyperCorePrecompilePlugin } from "../plugins/HyperCorePrecompilePlugin.js";
import { CoreWriterPlugin } from "../plugins/CoreWriterPlugin.js";
import { AscendHookPoolPlugin } from "../plugins/AscendHookPoolPlugin.js";
import { SentryStrategy } from "../strategies/SentryStrategy.js";
import { ArbiterStrategy } from "../strategies/ArbiterStrategy.js";

export class NexusAgent {
  public readonly config: AgentConfig;
  private precompilePlugin: HyperCorePrecompilePlugin;
  private coreWriterPlugin: CoreWriterPlugin;
  private ascendPlugin?: AscendHookPoolPlugin;
  private sentryStrategy?: SentryStrategy;
  private arbiterStrategy?: ArbiterStrategy;

  private isRunning: boolean = false;
  private timer: NodeJS.Timeout | null = null;
  private executionLog: ExecutionReceipt[] = [];

  constructor(
    config: AgentConfig,
    provider: ethers.Provider,
    signer: ethers.Signer,
    ascendPoolAddress?: string
  ) {
    this.config = config;

    this.precompilePlugin = new HyperCorePrecompilePlugin(
      provider,
      config.precompileAddress || "0x0000000000000000000000000000000000000801"
    );

    this.coreWriterPlugin = new CoreWriterPlugin(
      signer,
      config.coreWriterAddress || "0x0000000000000000000000000000000000000802"
    );

    if (ascendPoolAddress) {
      this.ascendPlugin = new AscendHookPoolPlugin(ascendPoolAddress, signer);
    }

    if (config.strategyType === StrategyType.SENTRY) {
      this.sentryStrategy = new SentryStrategy(config);
    } else if (config.strategyType === StrategyType.ARBITER) {
      this.arbiterStrategy = new ArbiterStrategy(config);
    }
  }

  /**
   * @notice Start the autonomous agent loop at specified interval (default: 200 ms for Elysium blocks)
   */
  public start(intervalMs: number = 200) {
    if (this.isRunning) return;
    this.isRunning = true;
    console.log(`[NexusAgent ${this.config.name}] Started autonomous loop with ${intervalMs}ms tick interval`);

    this.timer = setInterval(async () => {
      try {
        await this.tick();
      } catch (err: any) {
        console.error(`[NexusAgent ${this.config.name}] Tick error:`, err?.message || err);
      }
    }, intervalMs);
  }

  /**
   * @notice Stop the autonomous agent loop
   */
  public stop() {
    if (!this.isRunning) return;
    this.isRunning = false;
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
    console.log(`[NexusAgent ${this.config.name}] Stopped autonomous loop`);
  }

  /**
   * @notice Single tick execution of the strategy
   */
  public async tick(): Promise<void> {
    // 1. Zero-latency read from HyperCore state precompile (0x0801)
    const market = await this.precompilePlugin.getSpotMarket(this.config.tickerIndex);

    if (this.config.strategyType === StrategyType.SENTRY && this.sentryStrategy) {
      const quotes = this.sentryStrategy.computeQuotes(market);

      // Submit two-sided quotes to CoreWriter
      const bidReceipt = await this.coreWriterPlugin.emitLimitOrder(quotes.bidOrder);
      const askReceipt = await this.coreWriterPlugin.emitLimitOrder(quotes.askOrder);

      this.executionLog.push(bidReceipt, askReceipt);
      console.log(
        `[SentryTick] Quoted mid: $${(Number(market.midPrice) / 1e6).toFixed(4)} | Bid: $${(
          Number(quotes.bidOrder.price) / 1e6
        ).toFixed(4)} | Ask: $${(Number(quotes.askOrder.price) / 1e6).toFixed(4)}`
      );
    } else if (this.config.strategyType === StrategyType.ARBITER && this.arbiterStrategy && this.ascendPlugin) {
      const ascendPrice = await this.ascendPlugin.getPoolPrice();
      const opp = this.arbiterStrategy.evaluateSpread(market, ascendPrice);

      if (opp.hasOpportunity) {
        console.log(
          `[ArbiterAlert] Opportunity detected! Spread: ${opp.spreadBps} bps | Direction: ${opp.direction} | Net Profit Est: $${opp.estimatedNetProfitUsdc.toFixed(2)}`
        );
        const intent = this.arbiterStrategy.buildHyperCoreIntent(opp);
        if (intent) {
          const receipt = await this.coreWriterPlugin.emitLimitOrder(intent);
          this.executionLog.push(receipt);
        }
      }
    }
  }

  public getExecutionLog(): ExecutionReceipt[] {
    return [...this.executionLog];
  }
}
