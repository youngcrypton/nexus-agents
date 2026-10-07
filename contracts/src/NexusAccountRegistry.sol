// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC6551Registry} from "./interfaces/IERC6551Registry.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

/// @title NexusAccountRegistry
/// @notice ERC-6551 compliant Registry that deploys deterministic Token-Bound Accounts for Nexus Agents
contract NexusAccountRegistry is IERC6551Registry {
    function createAccount(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external override returns (address) {
        bytes memory code = _creationCode(implementation, chainId, tokenContract, tokenId, salt);

        address _account = Create2.computeAddress(salt, keccak256(code));

        if (_account.code.length == 0) {
            _account = Create2.deploy(0, salt, code);
            emit ERC6551AccountCreated(_account, implementation, salt, chainId, tokenContract, tokenId);
        }

        return _account;
    }

    function account(
        address implementation,
        bytes32 salt,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId
    ) external view override returns (address) {
        bytes memory code = _creationCode(implementation, chainId, tokenContract, tokenId, salt);
        return Create2.computeAddress(salt, keccak256(code));
    }

    function _creationCode(
        address implementation,
        uint256 chainId,
        address tokenContract,
        uint256 tokenId,
        bytes32 salt
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                hex"3d60ad80600a3d3981f3363d3d373d3d3d363d73",
                implementation,
                hex"5af43d82803e903d91602b57fd5bf3",
                abi.encode(salt, chainId, tokenContract, tokenId)
            );
    }
}
