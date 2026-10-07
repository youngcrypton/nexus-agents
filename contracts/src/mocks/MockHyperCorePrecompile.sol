// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IHyperCoreMarketData} from "../interfaces/IHyperCoreMarketData.sol";

/// @title MockHyperCorePrecompile
/// @notice Mock implementation of Elysium's HyperCore Market Data Precompile for testing
contract MockHyperCorePrecompile is IHyperCoreMarketData {
    mapping(uint64 => SpotMarketSummary) public markets;
    mapping(uint64 => uint64) public slippageBps;

    function setSpotMarket(
        uint64 tickerIndex,
        uint64 midPrice,
        uint64 bestBid,
        uint64 bestAsk,
        uint64 flowImbalanceBps
    ) external {
        markets[tickerIndex] = SpotMarketSummary({
            blockHeight: uint64(block.number),
            blockTime: uint64(block.timestamp),
            midPrice: midPrice,
            bestBid: bestBid,
            bestAsk: bestAsk,
            flowImbalanceBps: flowImbalanceBps
        });
    }

    function setSlippage(uint64 tickerIndex, uint64 _slippageBps) external {
        slippageBps[tickerIndex] = _slippageBps;
    }

    function getSpotMarket(uint64 tickerIndex) external view override returns (SpotMarketSummary memory summary) {
        summary = markets[tickerIndex];
        if (summary.midPrice == 0) {
            // Default mock market if unset: $2.00 mid, $1.99 bid, $2.01 ask
            summary = SpotMarketSummary({
                blockHeight: uint64(block.number),
                blockTime: uint64(block.timestamp),
                midPrice: 2_000_000, // 2.00 * 1e6
                bestBid: 1_995_000,
                bestAsk: 2_005_000,
                flowImbalanceBps: 0
            });
        }
    }

    function getOrderbookDepth(
        uint64 tickerIndex,
        uint8 depth
    ) external view override returns (BookLevel[] memory bids, BookLevel[] memory asks) {
        SpotMarketSummary memory summary = markets[tickerIndex];
        uint64 basePrice = summary.midPrice > 0 ? summary.midPrice : 2_000_000;

        bids = new BookLevel[](depth);
        asks = new BookLevel[](depth);

        for (uint8 i = 0; i < depth; i++) {
            bids[i] = BookLevel({px: basePrice - (uint64(i + 1) * 5_000), sz: 10_000 * 1e6});
            asks[i] = BookLevel({px: basePrice + (uint64(i + 1) * 5_000), sz: 10_000 * 1e6});
        }
    }

    function getExpectedSlippage(
        uint64 tickerIndex,
        uint64 /* size */,
        bool /* isBuy */
    ) external view override returns (uint64) {
        return slippageBps[tickerIndex] > 0 ? slippageBps[tickerIndex] : 15; // default 15 bps (0.15%)
    }
}
