import { SpotMarketSummary, OrderIntentParams, AgentConfig } from "../types.js";

export class SentryStrategy {
  private config: AgentConfig;
  private currentNonce: bigint = 1n;
  private currentInventoryToken: bigint = 0n;
  private currentInventoryUsdc: bigint = 0n;

  constructor(config: AgentConfig) {
    this.config = config;
  }

  public updateInventory(tokenBal: bigint, usdcBal: bigint) {
    this.currentInventoryToken = tokenBal;
    this.currentInventoryUsdc = usdcBal;
  }

  /// @notice Compute two-sided limit orders with dynamic inventory skew
  public computeQuotes(market: SpotMarketSummary): {
    bidOrder: OrderIntentParams;
    askOrder: OrderIntentParams;
  } {
    const mid = market.midPrice;
    const halfSpread = (mid * BigInt(this.config.targetSpreadBps)) / 20000n;

    // Inventory Skew Calculation:
    // If holding excess token -> skew down (lower reservation price to incentivize buyers)
    // If holding excess USDC -> skew up (raise reservation price to incentivize sellers)
    let inventorySkewBps = 0n;
    if (this.config.maxInventoryToken > 0n) {
      const tokenRatio = (this.currentInventoryToken * 10000n) / this.config.maxInventoryToken;
      if (tokenRatio > 6000n) {
        inventorySkewBps = -10n; // Skew down 10 bps
      } else if (tokenRatio < 4000n) {
        inventorySkewBps = 10n;  // Skew up 10 bps
      }
    }

    const reservationPrice = mid + ((mid * inventorySkewBps) / 10000n);
    const bidPrice = reservationPrice - halfSpread;
    const askPrice = reservationPrice + halfSpread;

    const quoteSize = 1000n * 1000000n; // 1,000 tokens

    const bidOrder: OrderIntentParams = {
      tickerIndex: BigInt(this.config.tickerIndex),
      isBuy: true,
      price: bidPrice,
      size: quoteSize,
      reduceOnly: false,
      orderNonce: this.currentNonce++,
      callbackEscrowHype: "0.005"
    };

    const askOrder: OrderIntentParams = {
      tickerIndex: BigInt(this.config.tickerIndex),
      isBuy: false,
      price: askPrice,
      size: quoteSize,
      reduceOnly: false,
      orderNonce: this.currentNonce++,
      callbackEscrowHype: "0.005"
    };

    return { bidOrder, askOrder };
  }
}
