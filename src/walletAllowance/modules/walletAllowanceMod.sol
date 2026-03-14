pragma solidity >=0.8.30;
// SPDX-License-Identifier: MIT

/*
 * ===========================================================================
 * Author: Hoang (0x76agabond)
 * ===========================================================================
 * Diamond Guard - Diamond as Gnosis Safe Guard
 * ===========================================================================
 */

import "../../safeGuard/modules/safeGuardMod.sol" as SafeGuardMod;
import {WhitelistRequired} from "../../safeGuard/modules/safeGuardEvent.sol";
import {SafeOperation} from "../../safe/safeHandlerMod.sol";
import "./walletEvent.sol";

struct Allowance {
    uint128 amountLimit;
    uint128 spent;
    uint64 date;
    uint64 txCount;
    uint64 txLimit;
}

struct AllowanceSetting {
    address safe;
    uint64 txLimit;
    uint128 amountLimit;
}

// transfer(address,uint256)
bytes4 constant SELECTOR_TRANSFER = 0xa9059cbb;

// transferFrom(address,address,uint256)
bytes4 constant SELECTOR_TRANSFER_FROM = 0x23b872dd;

/**
 * @dev Minimal Form:
 * diamondGuard.business.walletallowance
 * ---------------------------------
 * @custom:storage-location erc8042:org.diamondguard.business.walletallowance.v1
 */

bytes32 constant ALLOWANCE_STORAGE_POSITION = keccak256("org.diamondguard.business.walletallowance.v1");

struct AllowanceStorage {
    mapping(address => Allowance) allowances;
}

function getAllowanceStorage() pure returns (AllowanceStorage storage s) {
    bytes32 pos = ALLOWANCE_STORAGE_POSITION;
    assembly {
        s.slot := pos
    }
}

function getGuardAndAllowanceStorage()
    pure
    returns (SafeGuardMod.GuardStorage storage guardStorage, AllowanceStorage storage allowanceStorage)
{
    bytes32 guardPos = SafeGuardMod.GUARD_STORAGE_MAIN_POSITION;
    bytes32 allowancePos = ALLOWANCE_STORAGE_POSITION;
    assembly {
        guardStorage.slot := guardPos
        allowanceStorage.slot := allowancePos
    }
}

// =========================================================
//                      ALLOWANCE Helper
// =========================================================

function resolveAllowanceTargetAndAmount(address to, uint256 value, bytes memory data)
    pure
    returns (address target, uint256 amount)
{
    if (data.length > 4) {
        bytes4 selector = bytes4(data);
        if (selector == SELECTOR_TRANSFER) {
            if (data.length < 68) {
                revert ERC20TransferDataInvalid();
            }

            assembly {
                target := mload(add(data, 36)) // arg1
                amount := mload(add(data, 68)) // arg2
            }
            return (target, amount);
        }

        if (selector == SELECTOR_TRANSFER_FROM) {
            if (data.length < 100) {
                revert ERC20TransferFromDataInvalid();
            }

            assembly {
                target := mload(add(data, 68)) // to
                amount := mload(add(data, 100)) // amount
            }
            return (target, amount);
        }
    }

    return (to, value);
}

function checkWhitelist(uint256 nonce1, address to, uint256 value, bytes memory data, bytes32 txHash) {
    // Resolve real target + amount for allowance and whitelist
    (address target, uint256 amount) = resolveAllowanceTargetAndAmount(to, value, data);

    if (amount > type(uint128).max) {
        revert AmountTooLarge();
    }

    uint64 today = uint64(block.timestamp / 1 days);

    (SafeGuardMod.GuardStorage storage gs, AllowanceStorage storage ast) = getGuardAndAllowanceStorage();
    Allowance storage a = ast.allowances[msg.sender];

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
        if (!gs.whitelist[msg.sender][target]) {
            revert WhitelistRequired(msg.sender, nonce1, txHash, target);
        }

        // whitelist is one-time use when bypass is triggered
        gs.whitelist[msg.sender][target] = false;

        // (we don't emit WhitelistUpdated here to avoid cross-facet event duplication)
        // whitelist's transaction don't trigger allowance update.
        return;
    } else {
        // update counters after all checks
        a.spent += uint128(amount);
        a.txCount += 1;
    }
}
