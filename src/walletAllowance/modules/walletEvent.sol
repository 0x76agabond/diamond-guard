pragma solidity >=0.8.30;
// SPDX-License-Identifier: MIT

/*
 * ===========================================================================
 * Author: Hoang (0x76agabond)
 * ===========================================================================
 * Diamond Guard - Diamond as Gnosis Safe Guard
 * ===========================================================================
 */

// =========================================================
//                      EVENTS
// =========================================================

struct AllowanceSetting {
    address safe;
    uint64 txLimit;
    uint128 amountLimit;
}

event DailyAmountLimitChanged(address indexed safe, uint128 limit);
event DailyTxLimitChanged(address indexed safe, uint64 limit);
event DailyAllowanceUpdated(address indexed safe, uint64 txLimit, uint128 amountLimit);
event DailyAllowanceUpdatedBatch(AllowanceSetting[] settings);

// =========================================================
//                      ERRORS
// =========================================================

error SafeAddressZero();
error WhitelistAddressZero();
error GuardInitialized(address guardAddress);
