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
    returns (
        SafeGuardMod.GuardStorage storage guardStorage,
        SafeGuardMod.GuardStateStorage storage stateStorage,
        AllowanceStorage storage allowanceStorage
    )
{
    bytes32 guardPos = SafeGuardMod.GUARD_STORAGE_MAIN_POSITION;
    bytes32 statePos = SafeGuardMod.GUARD_STORAGE_STATE_POSITION;
    bytes32 allowancePos = ALLOWANCE_STORAGE_POSITION;
    assembly {
        guardStorage.slot := guardPos
        stateStorage.slot := statePos
        allowanceStorage.slot := allowancePos
    }
}

// =========================================================
//                      ALLOWANCE Helper
// =========================================================

function dayStamp() view returns (uint64) {
    return uint64(block.timestamp / 1 days);
}

function resolveAllowanceTargetAndAmount(address to, uint256 value, bytes memory data, SafeOperation operation)
    pure
    returns (address target, uint256 amount)
{
    if (operation == SafeOperation.Call && data.length > 4) {
        bytes4 selector = bytes4(data);
        if (selector == SELECTOR_TRANSFER) {
            address ercTo;
            uint256 ercValue;

            if (data.length < 68) {
                revert ERC20TransferDataInvalid();
            }

            assembly {
                ercTo := mload(add(data, 36)) // arg1
                ercValue := mload(add(data, 68)) // arg2
            }
            return (ercTo, ercValue);
        }

        if (selector == SELECTOR_TRANSFER_FROM) {
            address ercTo;
            uint256 ercValue;

            if (data.length < 100) {
                revert ERC20TransferFromDataInvalid();
            }

            assembly {
                ercTo := mload(add(data, 68)) // to
                ercValue := mload(add(data, 100)) // amount
            }
            return (ercTo, ercValue);
        }
    }

    return (to, value);
}
