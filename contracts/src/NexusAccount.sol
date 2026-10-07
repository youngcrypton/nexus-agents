// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC6551Account} from "./interfaces/IERC6551Account.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";

/// @title NexusAccount
/// @notice ERC-6551 Token-Bound Smart Account implementation for autonomous Nexus agents
/// @dev Holds agent working capital, receives hiring revenues, pays HYPE gas, and stores HyperCore trade-only keys
contract NexusAccount is IERC6551Account, IERC1271 {
    uint256 private _state;
    address public tradeOnlyAgentKey;
    address public designatedCoreWriter;

    event TradeOnlyAgentConfigured(address indexed previousAgent, address indexed newAgent);
    event Executed(address indexed target, uint256 value, bytes data);

    modifier onlyAuthorized() {
        require(msg.sender == owner() || msg.sender == tradeOnlyAgentKey, "NexusAccount: unauthorized");
        _;
    }

    receive() external payable {}

    function setTradeOnlyAgentKey(address _agentKey) external {
        require(msg.sender == owner(), "NexusAccount: only NFT owner can delegate");
        emit TradeOnlyAgentConfigured(tradeOnlyAgentKey, _agentKey);
        tradeOnlyAgentKey = _agentKey;
    }

    function setDesignatedCoreWriter(address _writer) external {
        require(msg.sender == owner(), "NexusAccount: only NFT owner can set writer");
        designatedCoreWriter = _writer;
    }

    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        uint8 operation
    ) external payable override onlyAuthorized returns (bytes memory result) {
        require(operation == 0, "NexusAccount: only call operations supported");
        _state++;

        bool success;
        (success, result) = to.call{value: value}(data);
        require(success, "NexusAccount: call failed");

        emit Executed(to, value, data);
    }

    function token() public view override returns (uint256 chainId, address tokenContract, uint256 tokenId) {
        bytes memory footer = new bytes(0x60);
        assembly {
            extcodecopy(address(), add(footer, 0x20), 0x4d, 0x60)
        }
        return abi.decode(footer, (uint256, address, uint256));
    }

    function owner() public view returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = token();
        if (chainId != block.chainid || tokenContract == address(0)) {
            return address(0);
        }
        return IERC721(tokenContract).ownerOf(tokenId);
    }

    function state() external view override returns (uint256) {
        return _state;
    }

    function isValidSigner(
        address signer,
        bytes calldata /* context */
    ) external view override returns (bytes4 magicValue) {
        if (signer == owner() || signer == tradeOnlyAgentKey) {
            return IERC6551Account.isValidSigner.selector;
        }
        return bytes4(0);
    }

    function isValidSignature(
        bytes32 /* hash */,
        bytes memory /* signature */
    ) external pure override returns (bytes4 magicValue) {
        bytes4 magic = 0x1626ba7e; // IERC1271.isValidSignature.selector
        return magic;
    }
}
