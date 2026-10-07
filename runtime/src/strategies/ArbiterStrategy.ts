import { SpotMarketSummary, OrderIntentParams, AgentConfig } from "../types.js";

export interface ArbitrageOpportunity {
  hasOpportunity: boolean;
  spreadBps: number;
  direction: "BUY_ASCEND_SELL_HYPERCORE" | "BUY_HYPERCORE_SELL_ASCEND" | "NONE";
  ascendPriceUsd: number;
  hyperCorePriceUsd: number;
  estimatedNetProfitUsdc: number;
  recommendedSize: bigint;
}

export class ArbiterStrategy {
  private config: AgentConfig;
  private currentNonce: bigint = 1000n;
  // Ascend token launch pools have a 1% protocol trading fee (100 bps)
  private readonly ASCEND_FEE_BPS = 100;
  // Estimated round-trip gas cost on Elysium L2 in USD
  private readonly ESTIMATED_GAS_USD = 0.02;

  constructor(config: AgentConfig) {
    this.config = config;
  }

  /**
   * @notice Evaluates cross-venue price discrepancy between Ascend Hook Pool and HyperCore CLOB
   * @param hyperCoreMarket Latest L1/L2 precompile state from 0x0801
   * @param ascendPriceUsd Spot price quoted by Ascend AMM pool
   * @param tradeSizeToken Number of base tokens to trade
   */
  public evaluateSpread(
    hyperCoreMarket: SpotMarketSummary,
    ascendPriceUsd: number,
    tradeSizeToken: bigint = 500n * 1000000n // 500 tokens
  ): ArbitrageOpportunity {
    // HyperCore midPrice is 6-decimal fixed point (e.g., 2000000 = $2.00)
    const hyperCorePriceUsd = Number(hyperCoreMarket.midPrice) / 1000000;

    if (ascendPriceUsd <= 0 || hyperCorePriceUsd <= 0) {
      return {
        hasOpportunity: false,
        spreadBps: 0,
        direction: "NONE",
        ascendPriceUsd,
        hyperCorePriceUsd,
        estimatedNetProfitUsdc: 0,
        recommendedSize: 0n
      };
    }

    const priceDiff = hyperCorePriceUsd - ascendPriceUsd;
    const rawSpreadBps = Math.round((Math.abs(priceDiff) / ascendPriceUsd) * 10000);

    // Net spread after deducting Ascend 1% fee (100 bps)
    const netSpreadBps = rawSpreadBps - this.ASCEND_FEE_BPS;

    if (netSpreadBps > this.config.targetSpreadBps) {
      const tokenUnits = Number(tradeSizeToken) / 1000000;
      const grossProfit = Math.abs(priceDiff) * tokenUnits;
      const ascendFee = ascendPriceUsd * tokenUnits * 0.01;
      const netProfit = grossProfit - ascendFee - this.ESTIMATED_GAS_USD;

      if (netProfit > 0) {
        const direction =
          hyperCorePriceUsd > ascendPriceUsd
            ? "BUY_ASCEND_SELL_HYPERCORE"
            : "BUY_HYPERCORE_SELL_ASCEND";

        return {
          hasOpportunity: true,
          spreadBps: rawSpreadBps,
          direction,
          ascendPriceUsd,
          hyperCorePriceUsd,
          estimatedNetProfitUsdc: netProfit,
          recommendedSize: tradeSizeToken
        };
      }
    }

    return {
      hasOpportunity: false,
      spreadBps: rawSpreadBps,
      direction: "NONE",
      ascendPriceUsd,
      hyperCorePriceUsd,
      estimatedNetProfitUsdc: 0,
      recommendedSize: 0n
    };
  }

  /**
   * @notice Constructs the HyperCore leg order intent when an arbitrage opportunity is present
   */
  public buildHyperCoreIntent(opportunity: ArbitrageOpportunity): OrderIntentParams | null {
    if (!opportunity.hasOpportunity || opportunity.direction === "NONE") {
      return null;
    }

    const isBuy = opportunity.direction === "BUY_HYPERCORE_SELL_ASCEND";
    // Price scaled to 6 decimals
    const limitPrice = BigInt(Math.round(opportunity.hyperCorePriceUsd * 1000000));

    return {
      tickerIndex: BigInt(this.config.tickerIndex),
      isBuy,
      price: limitPrice,
      size: opportunity.recommendedSize,
      reduceOnly: false,
      orderNonce: this.currentNonce++,
      callbackEscrowHype: "0.01"
    };
  }
}
