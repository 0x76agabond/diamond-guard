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
import {LibSafeGuard} from "./libraries/LibSafeGuard.sol";
import {LibSafeHandler} from "./libraries/LibSafeHandler.sol";
import {LibSignatureHandler} from "./libraries/LibSignatureHandler.sol";

contract GuardFacet {
    // Revert error when safe execution is blocked
    error SafeExecutionBlocked(address safe, uint256 nonce, bytes32 txHash);
    error SafeModuleExecutionBlocked(address safe);

    // Revert error when delegatecall is blocked
    error DelegateCallBlocked(address safe, uint256 nonce, bytes32 txHash, LibSafeHandler.SafeOperation operation);
    error ModuleDelegateCallBlocked(address safe, bytes32 moduleTxHash, LibSafeHandler.SafeOperation operation);

    // Revert error when whitelist is required but 'to' address is not in whitelist
    error WhitelistRequired(address safe, uint256 nonce, bytes32 txHash, address to);

    // revert error when executor signature is missing
    error ExecutorSignatureMissing(address safe, uint256 nonce, bytes32 txHash, address executor);

    // Events check transaction Succeeded
    event CheckTransactionSucceeded(
        address indexed safe,
        uint256 nonce,
        bytes32 indexed txHash,
        LibSafeHandler.SafeOperation operation,
        uint256 value,
        bytes32 indexed dataHash
    );
    event CheckAfterExecutionSucceeded(address indexed safe, bytes32 indexed txHash, bool success);

    // Events check transaction from module Succeeded
    event CheckModuleTransactionSucceeded(
        address indexed safe,
        bytes32 indexed moduleTxHash,
        LibSafeHandler.SafeOperation operation,
        uint256 value,
        bytes32 indexed dataHash
    );
    event CheckModuleAfterExecutionSucceeded(address indexed safe, bytes32 indexed txHash, bool success);

    function checkTransactionInner(
        address safe,
        address to,
        uint256 value,
        bytes memory data,
        LibSafeHandler.SafeOperation operation,
        address executor,
        uint256 nonce,
        bytes32 txHash,
        bytes memory signatures
    ) internal {
        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();

        // if the guard is blocked, revert
        if (s.isLocked) {
            revert SafeExecutionBlocked(safe, nonce, txHash);
        }

        // if the guard is activated, perform checks
        if (!s.isActivated) {
            return;
        }

        // if whitelist is enabled, check if the 'to' address is in the whitelist
        // I personally this feature is useful for Bybit case
        if (s.isWhitelistEnabled) {
            if (!s.whitelist[safe][to]) {
                revert WhitelistRequired(safe, nonce, txHash, to);
            }
        }

        // if the operation is delegatecall and it's not allowed, revert
        if (operation == LibSafeHandler.SafeOperation.DelegateCall && !s.isDelegateCallAllowed) {
            revert DelegateCallBlocked(safe, nonce, txHash, operation);
        }

        // if enforce executor is enabled, check if the executor has signed the tx
        if (s.isEnforceExecutor) {
            if (!LibSignatureHandler.recoverSignerAccount(txHash, signatures, executor)) {
                revert ExecutorSignatureMissing(safe, nonce, txHash, executor);
            }
        }

        // update txhash and nonce for current context
        // this will allow us to track txhash for each safe individually
        // if add some logic later, we can check for allowance, limits, etc.
        // for now, we just update txhash and nonce
        // idea for counting txs per day address safe => uint256 timestamp => uint256[] nonce // timestamp rotates every 24 hours

        LibSafeGuard.TxContext storage context = s.walletContext[safe];
        context.nonce = nonce;
        context.txHash = txHash;

        emit CheckTransactionSucceeded(safe, nonce, txHash, operation, value, keccak256(data));
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
            unchecked {
                nonce = safe.nonce() - 1;
            }

            txHash = safe.getTransactionHash(
                to, value, data, operation, safeTxGas, baseGas, gasPrice, gasToken, refundReceiver, nonce
            );
        }

        checkTransactionInner(msg.sender, to, value, data, operation, executor, nonce, txHash, signatures);
    }

    // Safe call this function after execute transaction
    function checkAfterExecution(bytes32 txHash, bool success) external {
        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();

        if (!s.isActivated) {
            return;
        }

        emit CheckAfterExecutionSucceeded(msg.sender, txHash, success);
    }

    // Safe call this function before execute transaction using module
    function checkModuleTransaction(
        address to,
        uint256 value,
        bytes memory data,
        LibSafeHandler.SafeOperation operation,
        address module
    ) external returns (bytes32 moduleTxHash) {
        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();

        if (s.isModuleLocked) {
            revert SafeModuleExecutionBlocked(msg.sender);
        }

        moduleTxHash = LibSafeHandler.getModuleTransactionHash(to, value, data, operation, module);

        if (!s.isModuleCheckActivated) {
            return moduleTxHash;
        }

        // if whitelist is enabled, check if the 'to' address is in the whitelist
        if (s.isWhitelistEnabled) {
            if (!s.whitelist[msg.sender][to]) {
                revert WhitelistRequired(msg.sender, s.walletContext[msg.sender].nonce, moduleTxHash, to);
            }
        }

        // if the operation is delegatecall and it's not allowed, revert
        if (operation == LibSafeHandler.SafeOperation.DelegateCall && !s.isModuleDelegateCallAllowed) {
            revert ModuleDelegateCallBlocked(msg.sender, moduleTxHash, operation);
        }

        emit CheckModuleTransactionSucceeded(msg.sender, moduleTxHash, operation, value, keccak256(data));
    }

    // Safe call this function after execute transaction using module
    function checkAfterModuleExecution(bytes32 txHash, bool success) external {
        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();

        if (s.isModuleCheckActivated) {
            emit CheckModuleAfterExecutionSucceeded(msg.sender, txHash, success);
        }
    }
}
