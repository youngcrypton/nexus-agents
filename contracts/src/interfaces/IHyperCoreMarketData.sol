// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IHyperCoreMarketData
/// @notice Interface for Elysium's chain-native HyperCore Market Data Precompile
/// @dev Located at precompile address 0x0000000000000000000000000000000000000100
interface IHyperCoreMarketData {
    struct BookLevel {
        uint64 px; // Price in fixed-point decimal
        uint64 sz; // Size in token base units
    }

    struct SpotMarketSummary {
        uint64 blockHeight;
        uint64 blockTime;
        uint64 midPrice;
        uint64 bestBid;
        uint64 bestAsk;
        uint64 flowImbalanceBps; // Flow imbalance in basis points (-10000 to +10000)
    }

    /// @notice Read live spot market summary for a given token index
    /// @param tickerIndex The HyperCore token index (e.g., 0 for USDC, 1234 for token)
    function getSpotMarket(uint64 tickerIndex) external view returns (SpotMarketSummary memory summary);

    /// @notice Read orderbook ladder depth up to a specified number of levels
    /// @param tickerIndex The HyperCore token index
    /// @param depth Number of bid/ask levels to return (e.g. 5)
    function getOrderbookDepth(
        uint64 tickerIndex,
        uint8 depth
    ) external view returns (BookLevel[] memory bids, BookLevel[] memory asks);

    /// @notice Calculate expected slippage for an order size on HyperCore
    /// @param tickerIndex The HyperCore token index
    /// @param size The size of the order
    /// @param isBuy True for buy, false for sell
    function getExpectedSlippage(
        uint64 tickerIndex,
        uint64 size,
        bool isBuy
    ) external view returns (uint64 slippageBps);
}
