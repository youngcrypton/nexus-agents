import { ethers } from "ethers";
import { BookLevel, SpotMarketSummary } from "../types.js";

const PRECOMPILE_ABI = [
  "function getSpotMarket(uint64 tickerIndex) external view returns (tuple(uint64 blockHeight, uint64 blockTime, uint64 midPrice, uint64 bestBid, uint64 bestAsk, uint64 flowImbalanceBps))",
  "function getOrderbookDepth(uint64 tickerIndex, uint8 depth) external view returns (tuple(uint64 px, uint64 sz)[] bids, tuple(uint64 px, uint64 sz)[] asks)",
  "function getExpectedSlippage(uint64 tickerIndex, uint64 size, bool isBuy) external view returns (uint64 slippageBps)"
];

export class HyperCorePrecompilePlugin {
  public readonly precompileAddress: string;
  private contract: ethers.Contract;

  constructor(
    provider: ethers.Provider,
    precompileAddress: string = "0x0000000000000000000000000000000000000100"
  ) {
    this.precompileAddress = precompileAddress;
    this.contract = new ethers.Contract(precompileAddress, PRECOMPILE_ABI, provider);
  }

  async getSpotMarket(tickerIndex: number): Promise<SpotMarketSummary> {
    const raw = await this.contract.getSpotMarket(BigInt(tickerIndex));
    return {
      blockHeight: BigInt(raw[0]),
      blockTime: BigInt(raw[1]),
      midPrice: BigInt(raw[2]),
      bestBid: BigInt(raw[3]),
      bestAsk: BigInt(raw[4]),
      flowImbalanceBps: BigInt(raw[5])
    };
  }

  async getOrderbookDepth(tickerIndex: number, depth: number = 5): Promise<{ bids: BookLevel[]; asks: BookLevel[] }> {
    const raw = await this.contract.getOrderbookDepth(BigInt(tickerIndex), depth);
    const bids: BookLevel[] = raw.bids.map((b: any) => ({ px: BigInt(b.px), sz: BigInt(b.sz) }));
    const asks: BookLevel[] = raw.asks.map((a: any) => ({ px: BigInt(a.px), sz: BigInt(a.sz) }));
    return { bids, asks };
  }

  async getExpectedSlippage(tickerIndex: number, size: bigint, isBuy: boolean): Promise<bigint> {
    return await this.contract.getExpectedSlippage(BigInt(tickerIndex), size, isBuy);
  }
}
