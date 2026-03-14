pragma solidity >=0.8.30;
// SPDX-License-Identifier: MIT

/*
 * ===========================================================================
 * Author: Hoang (0x76agabond)
 * ===========================================================================
 * Diamond Guard - Diamond as Gnosis Safe Guard
 * ===========================================================================
 */

import "../modules/safeGuardEvent.sol";
import "../modules/safeGuardMod.sol" as SafeGuardMod;
import "../../interfaces/ISafe.sol" as SafeInterface;
import "../../safe/safeHandlerMod.sol" as SafeHandlerMod;
import "../../txContext/modules/txContextMod.sol" as txContextMod;

contract GuardHandlerFacet {
    function checkTransactionInner(
        address safe,
        address to,
        uint256 value,
        bytes memory data,
        SafeOperation operation,
        address executor,
        uint256 nonce,
        bytes32 txHash,
        bytes memory signatures
    ) internal {
        (SafeGuardMod.GuardStorage storage gs, SafeGuardMod.GuardStateStorage storage ss) =
            SafeGuardMod.getFullGuardStorage();

        // if the guard is blocked, revert
        if (ss.isLocked) {
            revert SafeExecutionBlocked(safe, nonce, txHash);
        }

        // if the guard is activated, perform checks
        if (!ss.isActivated) {
            return;
        }

        // if whitelist is enabled, check if the 'to' address is in the whitelist
        // I personally this feature is useful for Bybit case
        if (ss.isWhitelistEnabled) {
            if (!gs.whitelist[safe][to]) {
                revert WhitelistRequired(safe, nonce, txHash, to);
            }
        }

        // if the operation is delegatecall and it's not allowed, revert
        if (operation == SafeHandlerMod.SafeOperation.DelegateCall && !ss.isDelegateCallAllowed) {
            revert DelegateCallBlocked(safe, nonce, txHash, operation);
        }

        // if enforce executor is enabled, check if the executor has signed the tx
        if (ss.isEnforceExecutor) {
            if (!SafeHandlerMod.recoverSignerAccount(txHash, signatures, executor)) {
                revert ExecutorSignatureMissing(safe, nonce, txHash, executor);
            }
        }
    }

    // Safe call this function before execute transaction
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        SafeOperation operation,
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

            SafeInterface.ISafe safe = SafeInterface.ISafe(payable(msg.sender));
            unchecked {
                nonce = safe.nonce() - 1;
            }

            txHash = safe.getTransactionHash(
                to, value, data, operation, safeTxGas, baseGas, gasPrice, gasToken, refundReceiver, nonce
            );

            // Gnosis Safe flow is checktransaction -> execTransaction -> checkAfterExecution
            // we store the tx context here for further use in other guards or after execution
            // if you want to add more data to the context, you can modify LibContext struct
            // you should check the file for pattern

            txContextMod.setTxType(txContextMod.transactionType.NORMAL); // normal tx
            txContextMod.setNonce(nonce);
            txContextMod.setTxHash(txHash);
        }

        //checkTransactionInner(msg.sender, to, value, data, operation, executor, nonce, txHash, signatures);
        //
        //emit CheckTransactionSucceeded(msg.sender, nonce, txHash, operation, value, keccak256(data));
    }

    // Safe call this function after execute transaction
    function checkAfterExecution(bytes32 txHash, bool success) external {
        SafeGuardMod.GuardStateStorage storage ss = SafeGuardMod.getStateStorage();

        if (!ss.isActivated) {
            return;
        }

        // this is how you retrieve context data
        // bytes32 contextTxHash = txContextMod.getTxHash();
        // uint256 contextInt = txContextMod.getNonce();

        emit CheckAfterExecutionSucceeded(msg.sender, txHash, success);
    }

    // Safe call this function before execute transaction using module
    function checkModuleTransaction(
        address to,
        uint256 value,
        bytes memory data,
        SafeOperation operation,
        address module
    ) external returns (bytes32 moduleTxHash) {
        (SafeGuardMod.GuardStorage storage gs, SafeGuardMod.GuardStateStorage storage ss) =
            SafeGuardMod.getFullGuardStorage();

        if (ss.isModuleLocked) {
            revert SafeModuleExecutionBlocked(msg.sender);
        }

        moduleTxHash = SafeHandlerMod.getModuleTransactionHash(to, value, data, operation, module);

        if (!ss.isModuleCheckActivated) {
            return moduleTxHash;
        }

        // if whitelist is enabled, check if the 'to' address is in the whitelist
        if (ss.isWhitelistEnabled) {
            if (!gs.whitelist[msg.sender][to]) {
                revert WhitelistRequired(msg.sender, txContextMod.getNonce(), moduleTxHash, to);
            }
        }

        // if the operation is delegatecall and it's not allowed, revert
        if (operation == SafeHandlerMod.SafeOperation.DelegateCall && !ss.isModuleDelegateCallAllowed) {
            revert ModuleDelegateCallBlocked(msg.sender, moduleTxHash, operation);
        }

        // module tx does not have nonce
        txContextMod.setTxType(txContextMod.transactionType.MODULE); // module tx
        txContextMod.setNonce(0);
        txContextMod.setTxHash(moduleTxHash);

        emit CheckModuleTransactionSucceeded(msg.sender, moduleTxHash, operation, value, keccak256(data));
    }

    // Safe call this function after execute transaction using module
    function checkAfterModuleExecution(bytes32 txHash, bool success) external {
        SafeGuardMod.GuardStateStorage storage ss = SafeGuardMod.getStateStorage();

        if (!ss.isModuleCheckActivated) {
            return;
        }

        emit CheckModuleAfterExecutionSucceeded(msg.sender, txHash, success);
    }
}
