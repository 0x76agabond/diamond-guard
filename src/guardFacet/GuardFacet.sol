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

import {LibSafeGuard} from "./libraries/LibSafeGuard.sol";
import {ISafe} from "./interfaces/ISafe.sol";

contract GuardFacet {

    // Safe call this function before execute transaction
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        LibSafeGuard.SafeOperation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address executor
    ) external view {
        bytes32 txHash;
        uint256 nonce;
        {
            ISafe safe = ISafe(payable(msg.sender));
            nonce = safe.nonce();
            txHash = safe.getTransactionHash(
                to, value, data, operation, safeTxGas, baseGas, gasPrice, gasToken, refundReceiver, nonce - 1
            );
        }
    }

    // Safe call this function after execute transaction
    function checkAfterExecution(bytes32 txHash, bool success) external pure {
        
    }

    // Safe call this function before execute transaction using module
    function checkModuleTransaction(
        address to,
        uint256 value,
        bytes memory data,
        LibSafeGuard.SafeOperation operation,
        address module
    ) external pure returns (bytes32 moduleTxHash) {
        
    }

    // Safe call this function after execute transaction using module
    function checkAfterModuleExecution(bytes32 txHash, bool success) external pure {
     
    }
}
