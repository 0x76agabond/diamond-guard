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
event WhitelistUpdatedBatch(address indexed safe, address[] indexed targets, bool enabled);

// =========================================================
//                      ERRORS
// =========================================================
error SafeAddressZero();
error WhitelistAddressZero();
error GuardInitialized();
error GuardNotInitialized();
