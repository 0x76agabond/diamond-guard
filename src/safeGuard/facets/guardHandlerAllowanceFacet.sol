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
import "../../walletAllowance/modules/walletEvent.sol";

import "../modules/safeGuardMod.sol" as SafeGuardMod;
import "../../walletAllowance/modules/walletAllowanceMod.sol" as WalletAllowanceMod;
import "../../interfaces/ISafe.sol" as SafeInterface;
import "../../safe/safeHandlerMod.sol" as SafeHandlerMod;
import "../../txContext/modules/txContextMod.sol" as txContextMod;

/**
 * @dev
 *
 * This guard facet implements daily allowance feature, which can be used to limit the daily spending of a safe. It can be used as a standalone guard or can be combined with other guard facets (e.g. whitelist) for more complex use cases.
 * This is independent from guardHandlerFacet.
 * I'm implemented this facet as a PoC also, so please check it carefully before using it in production.
 *
 *
 */
contract GuardHandlerAllowanceFacet {
    function checkTransactionInner(
        address safe,
        address to,
        uint256 value,
        bytes memory data,
        SafeOperation operation,
        uint256 nonce,
        bytes32 txHash
    ) internal {
        (
            SafeGuardMod.GuardStorage storage gs,
            SafeGuardMod.GuardStateStorage storage ss,
            WalletAllowanceMod.AllowanceStorage storage ast
        ) = WalletAllowanceMod.getGuardAndAllowanceStorage();

        // global kill-switch
        if (ss.isLocked) {
            revert SafeExecutionBlocked(safe, nonce, txHash);
        }

        // since the guard is no activated, return early
        if (!ss.isActivated) {
            return;
        }

        // whitelist is required for allowance guard to work, so we check it first before resolving allowance target and amount
        if (!ss.isWhitelistEnabled) {
            revert WhitelistMuchBeEnabled();
        }

        // Resolve real target + amount for allowance and whitelist
        (address target, uint256 amount) =
            WalletAllowanceMod.resolveAllowanceTargetAndAmount(to, value, data, operation);

        if (amount > type(uint128).max) {
            revert AmountTooLarge();
        }

        WalletAllowanceMod.Allowance storage a = ast.allowances[safe];
        uint64 today = WalletAllowanceMod.dayStamp();

        // reset amount bucket if new day
        if (a.date != today) {
            a.date = today;
            a.spent = 0;
            a.txCount = 0;
        }

        bool exceedAmount = (a.amountLimit > 0 && (amount > a.amountLimit || a.spent > a.amountLimit - amount));
        bool exceedTx = (a.txLimit > 0 && a.txCount + 1 > a.txLimit);

        if (exceedAmount || exceedTx) {
            // require whitelist as bypass when limit reached
            if (!gs.whitelist[safe][target]) {
                revert WhitelistRequired(safe, nonce, txHash, target);
            }

            // whitelist is one-time use when bypass is triggered
            gs.whitelist[safe][target] = false;

            // (we don't emit WhitelistUpdated here to avoid cross-facet event duplication)
            // whitelist's transaction don't trigger allowance update.
            return;
        }

        // update counters after all checks
        a.spent += uint128(amount);
        a.txCount += 1;
    }

    // Safe calls this function before executing a transaction
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
        bytes memory,
        /*signatures*/
        address /*executor*/
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
                // Safe increments nonce before calling guard, so we subtract 1
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

        checkTransactionInner(msg.sender, to, value, data, operation, nonce, txHash);

        emit CheckTransactionSucceeded(msg.sender, nonce, txHash, operation, value, keccak256(data));
    }

    // Safe calls this function after executing a transaction
    function checkAfterExecution(bytes32 txHash, bool success) external {
        // Allowance guard variant only emits event for indexing / monitoring.

        // this is how you retrieve context data
        // bytes32 contextTxHash = txContextMod.getTxHash();
        // uint256 contextInt = txContextMod.getNonce();

        emit CheckAfterExecutionSucceeded(msg.sender, txHash, success);
    }
}
