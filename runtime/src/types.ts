export enum StrategyType {
  SENTRY = 0,   // Automated Market Maker for Ascend & HyperCore
  ARBITER = 1,  // Cross-Venue Arbitrageur between Elysium AMMs & HyperCore
  APEX = 2,     // Sentiment & High-Frequency Momentum Trader
  VANGUARD = 3, // Portfolio & kHYPE Staking Optimizer
  CUSTOM = 4    // Developer-defined custom model
}

export interface BookLevel {
  px: bigint;
  sz: bigint;
}

export interface SpotMarketSummary {
  blockHeight: bigint;
  blockTime: bigint;
  midPrice: bigint;
  bestBid: bigint;
  bestAsk: bigint;
  flowImbalanceBps: bigint;
}

export interface OrderIntentParams {
  tickerIndex: bigint;
  isBuy: boolean;
  price: bigint;
  size: bigint;
  reduceOnly: boolean;
  orderNonce: bigint;
  callbackEscrowHype: string; // in ether units, e.g. "0.01"
}

export interface AgentConfig {
  agentId: number;
  name: string;
  strategyType: StrategyType;
  tickerIndex: number;
  rpcUrl: string;
  accountAddress: string;
  precompileAddress?: string;
  coreWriterAddress?: string;
  targetSpreadBps: number;
  rebalanceThresholdBps: number;
  maxInventoryToken: bigint;
  maxInventoryUsdc: bigint;
}

export interface ExecutionReceipt {
  success: boolean;
  intentId: string;
  tickerIndex: bigint;
  isBuy: boolean;
  price: bigint;
  size: bigint;
  timestamp: number;
}
