pragma solidity =0.8.26;
// SPDX-License-Identifier: MIT

/*
 * ===========================================================================
 * Author: Hoang <ginz1504@gmail.com>
 * Contact: https://github.com/0x76agabond
 * ===========================================================================
 * Interface: IGuardFacet
 * Description: 
 *   Diamond Guard interface for Gnosis Safe-compatible Guard Facet.
 *   Defines the required hooks and events used by Gnosis Safe or any Safe-like
 *   modular account to validate transactions before and after execution.
 * ===========================================================================
 */

import {LibSafeHandler} from ".././libraries/LibSafeHandler.sol";

interface IGuardFacet {
    // =========================================================
    //                       ERRORS
    // =========================================================
    error SafeExecutionBlocked(address safe, uint256 nonce, bytes32 txHash);
    error SafeModuleExecutionBlocked(address safe);
    error DelegateCallBlocked(address safe, uint256 nonce, bytes32 txHash, LibSafeHandler.SafeOperation operation);
    error ModuleDelegateCallBlocked(address safe, bytes32 moduleTxHash, LibSafeHandler.SafeOperation operation);
    error WhitelistRequired(address safe, uint256 nonce, bytes32 txHash, address to);
    error ExecutorSignatureMissing(address safe, uint256 nonce, bytes32 txHash, address executor);

    // =========================================================
    //                       EVENTS
    // =========================================================
    event CheckTransactionSucceeded(
        address indexed safe,
        uint256 nonce,
        bytes32 indexed txHash,
        LibSafeHandler.SafeOperation operation,
        uint256 value,
        bytes32 indexed dataHash
    );
    event CheckAfterExecutionSucceeded(address indexed safe, bytes32 indexed txHash, bool success);

    event CheckModuleTransactionSucceeded(
        address indexed safe,
        bytes32 indexed moduleTxHash,
        LibSafeHandler.SafeOperation operation,
        uint256 value,
        bytes32 indexed dataHash
    );
    event CheckModuleAfterExecutionSucceeded(address indexed safe, bytes32 indexed txHash, bool success);

    // =========================================================
    //                      CORE HOOKS
    // =========================================================

    /**
     * @notice Called by Gnosis Safe before transaction execution.
     * @param to              The target address.
     * @param value           The ETH value sent with the transaction.
     * @param data            The transaction calldata.
     * @param operation       The operation type (CALL or DELEGATECALL).
     * @param safeTxGas       Gas that should be used for the Safe transaction.
     * @param baseGas         Base gas fee.
     * @param gasPrice        Gas price.
     * @param gasToken        Gas token address.
     * @param refundReceiver  Address receiving leftover gas refund.
     * @param signatures      Packed signature bytes.
     * @param executor        Address executing the transaction.
     */
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
    ) external;

    /**
     * @notice Called by Gnosis Safe after transaction execution.
     * @param txHash  Transaction hash.
     * @param success Boolean indicating execution success.
     */
    function checkAfterExecution(bytes32 txHash, bool success) external;

    /**
     * @notice Called by Gnosis Safe module before transaction execution.
     * @param to        The target address.
     * @param value     The ETH value sent with the transaction.
     * @param data      The transaction calldata.
     * @param operation The operation type (CALL or DELEGATECALL).
     * @param module    The module address initiating the transaction.
     * @return moduleTxHash Hash of the module transaction.
     */
    function checkModuleTransaction(
        address to,
        uint256 value,
        bytes memory data,
        LibSafeHandler.SafeOperation operation,
        address module
    ) external returns (bytes32 moduleTxHash);

    /**
     * @notice Called by Gnosis Safe module after transaction execution.
     * @param txHash  Transaction hash.
     * @param success Boolean indicating execution success.
     */
    function checkAfterModuleExecution(bytes32 txHash, bool success) external;
}
