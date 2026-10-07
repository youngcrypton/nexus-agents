import { ethers } from "ethers";
import { OrderIntentParams, ExecutionReceipt } from "../types.js";

const CORE_WRITER_ABI = [
  "function placeLimitOrder(uint64 tickerIndex, bool isBuy, uint64 price, uint64 size, bool reduceOnly, uint64 orderNonce) external payable returns (bytes32 intentId)",
  "function cancelOrder(uint64 tickerIndex, uint64 orderNonce) external payable returns (bytes32 intentId)"
];

export class CoreWriterPlugin {
  public readonly coreWriterAddress: string;
  private signer: ethers.Signer;
  private contract: ethers.Contract;

  constructor(
    signer: ethers.Signer,
    coreWriterAddress: string = "0x0000000000000000000000000000000000000200"
  ) {
    this.coreWriterAddress = coreWriterAddress;
    this.signer = signer;
    this.contract = new ethers.Contract(coreWriterAddress, CORE_WRITER_ABI, signer);
  }

  async emitLimitOrder(params: OrderIntentParams): Promise<ExecutionReceipt> {
    const value = ethers.parseEther(params.callbackEscrowHype || "0.01");

    const tx = await this.contract.placeLimitOrder(
      params.tickerIndex,
      params.isBuy,
      params.price,
      params.size,
      params.reduceOnly,
      params.orderNonce,
      { value }
    );

    const receipt = await tx.wait();

    return {
      success: true,
      intentId: receipt.hash,
      tickerIndex: params.tickerIndex,
      isBuy: params.isBuy,
      price: params.price,
      size: params.size,
      timestamp: Date.now()
    };
  }

  async emitCancelOrder(tickerIndex: bigint, orderNonce: bigint): Promise<string> {
    const value = ethers.parseEther("0.005");
    const tx = await this.contract.cancelOrder(tickerIndex, orderNonce, { value });
    const receipt = await tx.wait();
    return receipt.hash;
  }
}
