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

import {ISafe} from ".././interfaces/ISafe.sol";
import {LibSafeGuard} from ".././libraries/LibSafeGuard.sol";
import {LibSafeHandler} from ".././libraries/LibSafeHandler.sol";
import {LibSignatureHandler} from ".././libraries/LibSignatureHandler.sol";

contract GuardFacet {
    // Every guarded tx (success or fail) emits events for off-chain indexing.
    // If there are a transaction executed unexpectedly, you can immediately know from the event logs
    // Turn on islocked / isModuleLocked will block all transactions through this guard
    // You can bricked all the Safe wallets using this guard in case of emergency

    // Another useful feature is whitelist
    // You can enable whitelist to restrict the 'to' address of the transaction
    // Only the 'to' address in the whitelist can be executed
    // This feature is useful for Bybit case since the attacker can't add new 'to' address to steal funds

    // This is just a POC implementation, you can extend more features as your need
    // In my case, I probably add daily count and amount limit for each wallet for daily spending
    // Force to use whitelist and executor signature for unlimited transaction

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

        // Gnosis Safe flow is checktransaction -> execTransaction -> checkAfterExecution
        // we store the tx context here for further use in other guards or after execution
        // if you want to add more data to the context, you can modify the LibSafeGuard.TxContext struct
        // add new variables to last of the struct to avoid storage collision
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
            // =========================================================================
            // Gnosis Safe transaction hash calculation flow
            // nonce += 1 before call check transaction, so we need to decrease nonce by 1 to get the correct txHash
            // =========================================================================
            // step 1: encode transaction data
            // txHashData = encodeTransactionData( ... );
            // step 2: increase nonce
            // nonce++;
            // step 3: verify signatures
            // checkSignatures(txHash, sigs);
            // step 4: pre-execution check
            // guard.checkTransaction(...);
            // step 5: execute core tx
            // success = execute(...);
            // step 6: post-execution check
            // guard.checkAfterExecution(...);

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

        // module tx does not have nonce
        LibSafeGuard.TxContext storage context = s.walletContext[msg.sender];
        context.nonce = 0;
        context.txHash = moduleTxHash;

        emit CheckModuleTransactionSucceeded(msg.sender, moduleTxHash, operation, value, keccak256(data));
    }

    // Safe call this function after execute transaction using module
    function checkAfterModuleExecution(bytes32 txHash, bool success) external {
        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();

        if (!s.isModuleCheckActivated) {
            return;
        }

        emit CheckModuleAfterExecutionSucceeded(msg.sender, txHash, success);
    }
}
