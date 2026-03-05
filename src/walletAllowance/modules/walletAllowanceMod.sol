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

struct Allowance {
    uint64 date;
    uint64 txDate;
    uint64 txCount;
    uint64 txLimit;
    uint128 spent;
    uint128 amountLimit;
}

/**
 * @dev Minimal Form:
 * diamondGuard.business.walletAllowance
 * ---------------------------------
 * @custom:storage-location erc8042:org.diamondGuard.business.walletAllowance.v1
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

