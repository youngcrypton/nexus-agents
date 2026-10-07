// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IElysiumCoreWriter} from "../interfaces/IElysiumCoreWriter.sol";

/// @title MockElysiumCoreWriter
/// @notice Mock implementation of ElysiumCoreWriter predeploy for local unit and integration tests
contract MockElysiumCoreWriter is IElysiumCoreWriter {
    uint64 private nonceCounter;

    struct RecordedOrder {
        address account;
        uint64 tickerIndex;
        bool isBuy;
        uint64 price;
        uint64 size;
        bool reduceOnly;
        uint64 orderNonce;
        uint256 callbackEscrow;
    }

    RecordedOrder[] public recordedOrders;

    function placeLimitOrder(
        uint64 tickerIndex,
        bool isBuy,
        uint64 price,
        uint64 size,
        bool reduceOnly,
        uint64 orderNonce
    ) external payable override returns (bytes32 intentId) {
        require(msg.value >= 0.001 ether, "Insufficient callback escrow in HYPE");

        recordedOrders.push(
            RecordedOrder({
                account: msg.sender,
                tickerIndex: tickerIndex,
                isBuy: isBuy,
                price: price,
                size: size,
                reduceOnly: reduceOnly,
                orderNonce: orderNonce,
                callbackEscrow: msg.value
            })
        );

        intentId = keccak256(abi.encodePacked(msg.sender, tickerIndex, orderNonce, block.timestamp));

        emit OrderIntentEmitted(msg.sender, tickerIndex, isBuy, price, size, orderNonce, msg.value);
    }

    function cancelOrder(
        uint64 tickerIndex,
        uint64 orderNonce
    ) external payable override returns (bytes32 intentId) {
        intentId = keccak256(abi.encodePacked(msg.sender, tickerIndex, orderNonce, "CANCEL"));
    }

    function getRecordedOrdersCount() external view returns (uint256) {
        return recordedOrders.length;
    }

    function simulateCallback(
        address account,
        uint64 orderNonce,
        bool success,
        uint64 filledSize,
        uint64 avgPrice
    ) external {
        emit OrderExecutedCallback(account, orderNonce, success, filledSize, avgPrice);
    }
}
