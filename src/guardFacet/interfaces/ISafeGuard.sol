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
import {LibSafeHandler} from ".././libraries/LibSafeHandler.sol";

interface ISafeGuard {
    // ========== Guard Hook Functions ==========

    function checkTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        LibSafeHandler.SafeOperation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes calldata signatures,
        address executor
    ) external;

    function checkTransactionInner(
        address safe,
        address to,
        uint256 value,
        bytes calldata data,
        address executor,
        uint256 nonce,
        bytes32 txHash,
        bytes memory signatures
    ) external;

    function checkAfterExecution(bytes32 txHash, bool success) external;

    function checkModuleTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        LibSafeHandler.SafeOperation operation,
        address module
    ) external pure returns (bytes32 moduleTxHash);

    function checkAfterModuleExecution(bytes32 txHash, bool success) external;
}
