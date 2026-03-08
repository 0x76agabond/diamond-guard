pragma solidity >=0.8.30;
// SPDX-License-Identifier: MIT

/*
 * ===========================================================================
 * Author: Hoang (0x76agabond)
 * ===========================================================================
 * Diamond Guard - Diamond as Gnosis Safe Guard
 * ===========================================================================
 */

import {SafeOperation} from "../../safe/safeHandlerMod.sol";

// =========================================================
//                      EVENTS
// =========================================================

// Events check transaction Succeeded
event CheckTransactionSucceeded(
    address indexed safe,
    uint256 nonce,
    bytes32 indexed txHash,
    SafeOperation operation,
    uint256 value,
    bytes32 indexed dataHash
);
event CheckAfterExecutionSucceeded(address indexed safe, bytes32 indexed txHash, bool success);

// Events check transaction from module Succeeded
event CheckModuleTransactionSucceeded(
    address indexed safe, bytes32 indexed moduleTxHash, SafeOperation operation, uint256 value, bytes32 indexed dataHash
);
event CheckModuleAfterExecutionSucceeded(address indexed safe, bytes32 indexed txHash, bool success);

// =========================================================
//                      ERRORS
// =========================================================

// Revert error when safe execution is blocked
error SafeExecutionBlocked(address safe, uint256 nonce, bytes32 txHash);
error SafeModuleExecutionBlocked(address safe);

// Revert error when delegatecall is blocked
error DelegateCallBlocked(address safe, uint256 nonce, bytes32 txHash, SafeOperation operation);
error ModuleDelegateCallBlocked(address safe, bytes32 moduleTxHash, SafeOperation operation);

// Revert error when whitelist is required but 'to' address is not in whitelist
error WhitelistRequired(address safe, uint256 nonce, bytes32 txHash, address to);

// revert error when executor signature is missing
error ExecutorSignatureMissing(address safe, uint256 nonce, bytes32 txHash, address executor);
