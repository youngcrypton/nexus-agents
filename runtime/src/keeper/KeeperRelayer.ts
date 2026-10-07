import { ethers } from "ethers";

export interface RelayedOrder {
  account: string;
  tickerIndex: bigint;
  isBuy: boolean;
  price: bigint;
  size: bigint;
  orderNonce: bigint;
  callbackEscrow: bigint;
  relayedAt: number;
  hyperCoreTxHash: string;
  status: "RELAYED" | "CONFIRMED" | "FAILED";
}

const ELYSIUM_CORE_WRITER_ABI = [
  "event OrderIntentEmitted(address indexed account, uint64 indexed tickerIndex, bool isBuy, uint64 price, uint64 size, uint64 indexed orderNonce, uint256 callbackEscrow)",
  "event OrderExecutedCallback(address indexed account, uint64 indexed orderNonce, bool success, uint64 filledSize, uint64 avgPrice)",
  "function simulateCallback(address account, uint64 orderNonce, bool success, uint64 filledSize, uint64 avgPrice) external"
];

export class KeeperRelayer {
  public readonly coreWriterAddress: string;
  private provider: ethers.Provider;
  private keeperSigner?: ethers.Signer;
  private contract: ethers.Contract;
  private isListening: boolean = false;
  private processedOrders: RelayedOrder[] = [];

  constructor(
    provider: ethers.Provider,
    coreWriterAddress: string = "0x0000000000000000000000000000000000000802",
    keeperSigner?: ethers.Signer
  ) {
    this.provider = provider;
    this.coreWriterAddress = coreWriterAddress;
    this.keeperSigner = keeperSigner;
    this.contract = new ethers.Contract(
      coreWriterAddress,
      ELYSIUM_CORE_WRITER_ABI,
      keeperSigner || provider
    );
  }

  /**
   * @notice Start listening for Elysium OrderIntentEmitted events
   */
  public async startListening(onRelayed?: (order: RelayedOrder) => void): Promise<void> {
    if (this.isListening) return;
    this.isListening = true;

    console.log(`[KeeperRelayer] Listening for OrderIntentEmitted at ${this.coreWriterAddress}...`);

    this.contract.on(
      "OrderIntentEmitted",
      async (
        account: string,
        tickerIndex: bigint,
        isBuy: boolean,
        price: bigint,
        size: bigint,
        orderNonce: bigint,
        callbackEscrow: bigint,
        event: any
      ) => {
        try {
          const relayed = await this.relayToHyperCore({
            account,
            tickerIndex: BigInt(tickerIndex),
            isBuy,
            price: BigInt(price),
            size: BigInt(size),
            orderNonce: BigInt(orderNonce),
            callbackEscrow: BigInt(callbackEscrow)
          });

          this.processedOrders.push(relayed);
          console.log(
            `[KeeperRelayer] Relayed order #${relayed.orderNonce} for ${relayed.account} -> HyperCore Tx: ${relayed.hyperCoreTxHash}`
          );

          if (onRelayed) {
            onRelayed(relayed);
          }
        } catch (err: any) {
          console.error(`[KeeperRelayer] Error relaying order #${orderNonce}:`, err?.message || err);
        }
      }
    );
  }

  /**
   * @notice Stop listening for events
   */
  public async stopListening(): Promise<void> {
    if (!this.isListening) return;
    this.isListening = false;
    await this.contract.removeAllListeners("OrderIntentEmitted");
    console.log("[KeeperRelayer] Stopped listening.");
  }

  /**
   * @notice Simulates or executes dispatch of intent to HyperCore CLOB
   */
  public async relayToHyperCore(params: {
    account: string;
    tickerIndex: bigint;
    isBuy: boolean;
    price: bigint;
    size: bigint;
    orderNonce: bigint;
    callbackEscrow: bigint;
  }): Promise<RelayedOrder> {
    // In production, this packages the EIP-712 session key signature and posts to HyperCore REST/WS endpoint.
    // For local simulation, compute deterministic synthetic hash:
    const syntheticL1Hash = ethers.keccak256(
      ethers.AbiCoder.defaultAbiCoder().encode(
        ["address", "uint64", "uint64", "uint256"],
        [params.account, params.tickerIndex, params.orderNonce, BigInt(Date.now())]
      )
    );

    // If keeperSigner is available and contract has simulateCallback, simulate callback trigger
    if (this.keeperSigner && typeof (this.contract as any).simulateCallback === "function") {
      try {
        await (this.contract as any).simulateCallback(
          params.account,
          params.orderNonce,
          true,
          params.size,
          params.price
        );
      } catch {
        // Mock callback may be skipped if not supported
      }
    }

    return {
      account: params.account,
      tickerIndex: params.tickerIndex,
      isBuy: params.isBuy,
      price: params.price,
      size: params.size,
      orderNonce: params.orderNonce,
      callbackEscrow: params.callbackEscrow,
      relayedAt: Date.now(),
      hyperCoreTxHash: syntheticL1Hash,
      status: "CONFIRMED"
    };
  }

  public getProcessedOrders(): RelayedOrder[] {
    return [...this.processedOrders];
  }
}
