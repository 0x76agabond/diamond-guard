pragma solidity = 0.8.26;
// SPDX-License-Identifier: MIT

/*
 * ===========================================================================
 * Author: Hoang <ginz1504@gmail.com>
 * Contact: https://github.com/0x76agabond
 * ===========================================================================
 * Diamond as Gnosis Safe Guard (Diamond Guard)
 * ===========================================================================
 */

import {ISafe} from "./interfaces/ISafe.sol";
import {ISafeGuard} from "./interfaces/ISafeGuard.sol";
import {LibSafeGuard} from "./libraries/LibSafeGuard.sol";
import {LibSafeHandler} from "./libraries/LibSafeHandler.sol";
import {LibSignatureHandler} from "./libraries/LibSignatureHandler.sol";

contract GuardFacet {
    function checkTransactionInner(
        address safe,
        address to,
        uint256 value,
        bytes calldata data,
        address executor,
        uint256 nonce,
        bytes32 txHash,
        bytes memory signatures
    ) external {
        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();

        if (s.isLocked) {
            revert("GuardFacet: Safe is locked");
        }

        if (s.isActive) {}
    }

    // Safe call this function before execute transaction
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        LibSafeHandler.SafeOperation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address executor
    ) external {
        bytes32 txHash;
        uint256 nonce;
        {
            ISafe safe = ISafe(payable(msg.sender));
            nonce = safe.nonce();
            txHash = safe.getTransactionHash(
                to, value, data, operation, safeTxGas, baseGas, gasPrice, gasToken, refundReceiver, nonce - 1
            );
        }

        ISafeGuard(address(this)).checkTransactionInner(
            msg.sender, to, value, data, executor, nonce - 1, txHash, signatures
        );
    }

    // Safe call this function after execute transaction
    function checkAfterExecution(bytes32 txHash, bool success) external pure {}

    // Safe call this function before execute transaction using module
    function checkModuleTransaction(
        address to,
        uint256 value,
        bytes memory data,
        LibSafeHandler.SafeOperation operation,
        address module
    ) external pure returns (bytes32 moduleTxHash) {}

    // Safe call this function after execute transaction using module
    function checkAfterModuleExecution(bytes32 txHash, bool success) external pure {}
}
