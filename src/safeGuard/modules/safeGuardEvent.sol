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
event LockedStatusChanged(bool locked);
event ModuleLockedStatusChanged(bool locked);
event ActivatedStatusChanged(bool activated);
event ModuleCheckActivatedChanged(bool activated);
event EnforceExecutorChanged(bool enforced);
event DelegateCallAllowedChanged(bool allowed);
event ModuleDelegateCallAllowedChanged(bool allowed);
event WhitelistStatusChanged(bool enabled);
event WhitelistUpdated(address indexed safe, address indexed target, bool enabled);
event DailyAmountLimitChanged(address indexed safe, uint128 limit);
event DailyTxLimitChanged(address indexed safe, uint64 limit);
event DailyAllowanceUpdated(address indexed safe, uint64 txLimit, uint128 amountLimit);

// =========================================================
//                      ERRORS
// =========================================================
error SafeAddressZero();
error WhitelistAddressZero();
error GuardInitialized();
error GuardNotInitialized();
