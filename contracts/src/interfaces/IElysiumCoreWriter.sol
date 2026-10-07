// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IElysiumCoreWriter
/// @notice Interface for Elysium's keeper fast-write lane predeploy
/// @dev Predeploy address on Elysium that emits non-custodial order intents to HyperCore
interface IElysiumCoreWriter {
    struct OrderIntent {
        address account;
        uint64 tickerIndex;
        bool isBuy;
        uint64 price;
        uint64 size;
        bool reduceOnly;
        uint64 orderNonce;
    }

    event OrderIntentEmitted(
        address indexed account,
        uint64 indexed tickerIndex,
        bool isBuy,
        uint64 price,
        uint64 size,
        uint64 indexed orderNonce,
        uint256 callbackEscrow
    );

    event OrderExecutedCallback(
        address indexed account,
        uint64 indexed orderNonce,
        bool success,
        uint64 filledSize,
        uint64 avgPrice
    );

    /// @notice Emit a limit order intent to HyperCore with attached HYPE callback escrow
    /// @param tickerIndex The HyperCore token index
    /// @param isBuy True for buy, false for sell
    /// @param price Limit price
    /// @param size Order size
    /// @param reduceOnly Whether order is reduce-only
    /// @param orderNonce Unique order nonce for deduplication
    function placeLimitOrder(
        uint64 tickerIndex,
        bool isBuy,
        uint64 price,
        uint64 size,
        bool reduceOnly,
        uint64 orderNonce
    ) external payable returns (bytes32 intentId);

    /// @notice Emit an order cancellation intent to HyperCore
    /// @param tickerIndex The HyperCore token index
    /// @param orderNonce The nonce of the order to cancel
    function cancelOrder(
        uint64 tickerIndex,
        uint64 orderNonce
    ) external payable returns (bytes32 intentId);
}
