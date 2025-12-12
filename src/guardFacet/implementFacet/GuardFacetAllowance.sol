pragma solidity >=0.8.30;
// SPDX-License-Identifier: MIT

/*
 * ===========================================================================
 * Author: Hoang <ginz1504@gmail.com>
 * Contact: https://github.com/0x76agabond
 * ===========================================================================
 * Diamond as Gnosis Safe Guard (Diamond Guard) – Allowance Variant
 * ===========================================================================
 */

import {ISafe} from ".././interfaces/ISafe.sol";
import {LibSafeGuard} from ".././libraries/LibSafeGuard.sol";
import {LibSafeHandler} from ".././libraries/LibSafeHandler.sol";
import {LibContext} from "../../guardContext/libraries/LibContext.sol";

contract GuardFacetAllowance {
    // =========================================================
    //                      ERRORS
    // =========================================================

    error SafeExecutionBlocked(address safe, uint256 nonce, bytes32 txHash);
    error WhitelistRequired(address safe, uint256 nonce, bytes32 txHash, address to);

    // =========================================================
    //                      EVENTS
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
    //                      CONSTANTS
    // =========================================================

    // ERC20 selectors
    bytes4 internal constant SELECTOR_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 internal constant SELECTOR_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    // =========================================================
    //                      INTERNAL HELPERS
    // =========================================================

    function dayStamp() internal view returns (uint64) {
        return uint64(block.timestamp / 1 days);
    }

    function resolveAllowanceTargetAndAmount(
        address to,
        uint256 value,
        bytes memory data,
        LibSafeHandler.SafeOperation operation
    ) internal pure returns (address target, uint256 amount) {
        target = to;
        amount = value;

        if (operation != LibSafeHandler.SafeOperation.Call || data.length < 4) {
            return (target, amount);
        }

        bytes4 selector = bytes4(data);

        // ERC20 transfer(address,uint256)
        if (selector == SELECTOR_TRANSFER) {
            address ercTo;
            uint256 ercValue;

            assembly {
                ercTo := mload(add(data, 36)) // arg1
                ercValue := mload(add(data, 68)) // arg2
            }

            return (ercTo, ercValue);
        }

        // ERC20 transferFrom(address,address,uint256)
        if (selector == SELECTOR_TRANSFER_FROM) {
            address ercTo;
            uint256 ercValue;

            assembly {
                ercTo := mload(add(data, 68)) // to
                ercValue := mload(add(data, 100)) // amount
            }

            return (ercTo, ercValue);
        }

        return (target, amount);
    }

    function applyAllowanceAndWhitelist(
        LibSafeGuard.SafeGuardStorage storage s,
        address safe,
        address target,
        uint256 amount,
        uint256 nonce,
        bytes32 txHash
    ) internal {
        LibSafeGuard.Allowance storage a = s.allowances[safe];
        uint64 today = dayStamp();

        // reset amount bucket if new day
        if (a.date != today) {
            a.date = today;
            a.spent = 0;
        }

        // reset tx count bucket if new day
        if (a.txDate != today) {
            a.txDate = today;
            a.txCount = 0;
        }

        bool exceedAmount = (a.amountLimit > 0 && a.spent + amount > a.amountLimit);
        bool exceedTx = (a.txLimit > 0 && a.txCount + 1 > a.txLimit);

        if (exceedAmount || exceedTx) {
            // require whitelist as bypass when limit reached
            if (!s.whitelist[safe][target]) {
                revert WhitelistRequired(safe, nonce, txHash, target);
            }

            // whitelist is one-time use when bypass is triggered
            s.whitelist[safe][target] = false;
            // (we don't emit WhitelistUpdated here to avoid cross-facet event duplication)
        }

        // update counters after all checks
        a.spent += uint128(amount);
        a.txCount += 1;
    }

    // =========================================================
    //                      CORE LOGIC
    // =========================================================

    function checkTransactionInner(
        address safe,
        address to,
        uint256 value,
        bytes memory data,
        LibSafeHandler.SafeOperation operation,
        uint256 nonce,
        bytes32 txHash
    ) internal {
        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();

        // global kill-switch
        if (s.isLocked) {
            revert SafeExecutionBlocked(safe, nonce, txHash);
        }

        // Resolve real target + amount for allowance and whitelist
        (address allowanceTarget, uint256 allowanceAmount) = resolveAllowanceTargetAndAmount(to, value, data, operation);

        // Apply daily allowance (amount + tx count) and whitelist bypass
        applyAllowanceAndWhitelist(s, safe, allowanceTarget, allowanceAmount, nonce, txHash);

        emit CheckTransactionSucceeded(safe, nonce, txHash, operation, value, keccak256(data));
    }

    // =========================================================
    //           Safe: checkTransaction / checkAfterExecution
    // =========================================================

    // Safe calls this function before executing a transaction
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
        bytes memory,
        /*signatures*/
        address /*executor*/
    ) external {
        bytes32 txHash;
        uint256 nonce;
        {
            ISafe safe = ISafe(payable(msg.sender));
            unchecked {
                // Safe increments nonce before calling guard, so we subtract 1
                nonce = safe.nonce() - 1;
            }

            txHash = safe.getTransactionHash(
                to, value, data, operation, safeTxGas, baseGas, gasPrice, gasToken, refundReceiver, nonce
            );

            LibContext.setTxType(0); // normal tx
            LibContext.setNonce(nonce);
            LibContext.setTxHash(txHash);
        }

        checkTransactionInner(msg.sender, to, value, data, operation, nonce, txHash);
    }

    // Safe calls this function after executing a transaction
    function checkAfterExecution(bytes32 txHash, bool success) external {
        // Allowance guard variant only emits event for indexing / monitoring.
        emit CheckAfterExecutionSucceeded(msg.sender, txHash, success);
    }

    // =========================================================
    //       Safe Module: checkModuleTransaction / AfterExecution
    // =========================================================

    // Safe calls this function before executing a transaction via module
    function checkModuleTransaction(
        address to,
        uint256 value,
        bytes memory data,
        LibSafeHandler.SafeOperation operation,
        address module
    ) external returns (bytes32 moduleTxHash) {
        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();

        moduleTxHash = LibSafeHandler.getModuleTransactionHash(to, value, data, operation, module);

        // global kill switch also affects module transactions
        if (s.isLocked) {
            revert SafeExecutionBlocked(msg.sender, 0, moduleTxHash);
        }

        // Reuse same ERC resolution logic for modules
        (address allowanceTarget, uint256 allowanceAmount) = resolveAllowanceTargetAndAmount(to, value, data, operation);

        applyAllowanceAndWhitelist(s, msg.sender, allowanceTarget, allowanceAmount, 0, moduleTxHash);

        LibContext.setTxType(1); // module tx
        LibContext.setNonce(0);
        LibContext.setTxHash(moduleTxHash);

        emit CheckModuleTransactionSucceeded(msg.sender, moduleTxHash, operation, value, keccak256(data));
    }

    // Safe calls this function after executing a transaction via module
    function checkAfterModuleExecution(bytes32 txHash, bool success) external {
        emit CheckModuleAfterExecutionSucceeded(msg.sender, txHash, success);
    }
}
