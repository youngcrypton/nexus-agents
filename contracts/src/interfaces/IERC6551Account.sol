// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IERC6551Account
/// @notice Standard interface for Token-Bound Accounts (ERC-6551)
interface IERC6551Account {
    receive() external payable;

    function token()
        external
        view
        returns (uint256 chainId, address tokenContract, uint256 tokenId);

    function state() external view returns (uint256);

    function isValidSigner(
        address signer,
        bytes calldata context
    ) external view returns (bytes4 magicValue);

    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        uint8 operation
    ) external payable returns (bytes memory result);
}
