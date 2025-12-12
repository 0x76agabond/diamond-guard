pragma solidity =0.8.30;
// SPDX-License-Identifier: MIT

/*
 * ===========================================================================
 * Author: Hoang <ginz1504@gmail.com>
 * Contact: https://github.com/0x76agabond
 * ===========================================================================
 * Diamond as Gnosis Safe Guard (Diamond Guard)
 * ===========================================================================
 */

import {LibSafeGuard} from ".././libraries/LibSafeGuard.sol";
import {LibDiamond} from "../../diamond/libraries/LibDiamond.sol";

contract GuardSettingFacet {
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
    error GuardInitialized(address guardAddress);

    // =========================================================
    //                      INITIALIZER
    // =========================================================

    function init() external {
        LibDiamond.enforceIsContractOwner();
        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();
        if (s.isInitialized) {
            revert GuardInitialized(address(this));
        }

        s.isInitialized = true;
        s.isLocked = false;
        s.isModuleLocked = false;
        s.isActivated = true;
        s.isModuleCheckActivated = true;
        s.isWhitelistEnabled = false;
        s.isEnforceExecutor = false;
        s.isDelegateCallAllowed = false;
        s.isModuleDelegateCallAllowed = false;
    }

    // =========================================================
    //                      GETTERS
    // =========================================================

    function getLockedStatus() external view returns (bool) {
        return LibSafeGuard.getStorage().isLocked;
    }

    function getModuleLockedStatus() external view returns (bool) {
        return LibSafeGuard.getStorage().isModuleLocked;
    }

    function getActivatedStatus() external view returns (bool) {
        return LibSafeGuard.getStorage().isActivated;
    }

    function getModuleCheckActivated() external view returns (bool) {
        return LibSafeGuard.getStorage().isModuleCheckActivated;
    }

    function getEnforceExecutor() external view returns (bool) {
        return LibSafeGuard.getStorage().isEnforceExecutor;
    }

    function getDelegateCallAllowed() external view returns (bool) {
        return LibSafeGuard.getStorage().isDelegateCallAllowed;
    }

    function getModuleDelegateCallAllowed() external view returns (bool) {
        return LibSafeGuard.getStorage().isModuleDelegateCallAllowed;
    }

    function getWhitelistEnabled() external view returns (bool) {
        return LibSafeGuard.getStorage().isWhitelistEnabled;
    }

    function isWhitelisted(address safe, address target) external view returns (bool) {
        return LibSafeGuard.getStorage().whitelist[safe][target];
    }

    function getAllowance(address safe)
        external
        view
        returns (uint64 date, uint64 txDate, uint64 txCount, uint64 txLimit, uint128 spent, uint128 amountLimit)
    {
        LibSafeGuard.Allowance storage a = LibSafeGuard.getStorage().allowances[safe];
        return (a.date, a.txDate, a.txCount, a.txLimit, a.spent, a.amountLimit);
    }

    // =========================================================
    //                      SETTERS
    // =========================================================

    function setLockedStatus(bool locked) external {
        LibDiamond.enforceIsContractOwner();
        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();
        if (s.isLocked == locked) return;
        s.isLocked = locked;
        emit LockedStatusChanged(locked);
    }

    function setModuleLockedStatus(bool locked) external {
        LibDiamond.enforceIsContractOwner();
        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();
        if (s.isModuleLocked == locked) return;
        s.isModuleLocked = locked;
        emit ModuleLockedStatusChanged(locked);
    }

    function setActivatedStatus(bool activated) external {
        LibDiamond.enforceIsContractOwner();
        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();
        if (s.isActivated == activated) return;
        s.isActivated = activated;
        emit ActivatedStatusChanged(activated);
    }

    function setModuleCheckActivated(bool activated) external {
        LibDiamond.enforceIsContractOwner();
        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();
        if (s.isModuleCheckActivated == activated) return;
        s.isModuleCheckActivated = activated;
        emit ModuleCheckActivatedChanged(activated);
    }

    function setEnforceExecutor(bool enforced) external {
        LibDiamond.enforceIsContractOwner();
        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();
        if (s.isEnforceExecutor == enforced) return;
        s.isEnforceExecutor = enforced;
        emit EnforceExecutorChanged(enforced);
    }

    function setDelegateCallAllowed(bool allowed) external {
        LibDiamond.enforceIsContractOwner();
        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();
        if (s.isDelegateCallAllowed == allowed) return;
        s.isDelegateCallAllowed = allowed;
        emit DelegateCallAllowedChanged(allowed);
    }

    function setModuleDelegateCallAllowed(bool allowed) external {
        LibDiamond.enforceIsContractOwner();
        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();
        if (s.isModuleDelegateCallAllowed == allowed) return;
        s.isModuleDelegateCallAllowed = allowed;
        emit ModuleDelegateCallAllowedChanged(allowed);
    }

    function setWhitelistEnabled(bool enabled) external {
        LibDiamond.enforceIsContractOwner();
        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();
        if (s.isWhitelistEnabled == enabled) return;
        s.isWhitelistEnabled = enabled;
        emit WhitelistStatusChanged(enabled);
    }

    function setWhitelist(address safe, address target, bool enabled) external {
        LibDiamond.enforceIsContractOwner();

        if (safe == address(0)) {
            revert SafeAddressZero();
        }

        if (target == address(0)) {
            revert WhitelistAddressZero();
        }

        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();
        if (s.whitelist[safe][target] == enabled) return;
        s.whitelist[safe][target] = enabled;
        emit WhitelistUpdated(safe, target, enabled);
    }

    function setWhitelistBatch(address safe, address[] calldata targets, bool enabled) external {
        LibDiamond.enforceIsContractOwner();

        if (safe == address(0)) {
            revert SafeAddressZero();
        }

        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();
        for (uint256 i; i < targets.length; i++) {
            if (targets[i] == address(0)) {
                revert WhitelistAddressZero();
            }

            if (s.whitelist[safe][targets[i]] != enabled) {
                s.whitelist[safe][targets[i]] = enabled;
                emit WhitelistUpdated(safe, targets[i], enabled);
            }
        }
    }

    function setDailyAmountLimit(address safe, uint128 limit) external {
        LibDiamond.enforceIsContractOwner();
        if (safe == address(0)) revert SafeAddressZero();

        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();
        LibSafeGuard.Allowance storage a = s.allowances[safe];

        if (a.amountLimit == limit) return;
        a.amountLimit = limit;

        emit DailyAmountLimitChanged(safe, limit);
    }

    function setDailyTxLimit(address safe, uint64 limit) external {
        LibDiamond.enforceIsContractOwner();
        if (safe == address(0)) revert SafeAddressZero();

        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();
        LibSafeGuard.Allowance storage a = s.allowances[safe];

        if (a.txLimit == limit) return;
        a.txLimit = limit;

        emit DailyTxLimitChanged(safe, limit);
    }

    function setDailyAllowance(address safe, uint64 txLimit, uint128 amountLimit) external {
        LibDiamond.enforceIsContractOwner();
        if (safe == address(0)) revert SafeAddressZero();

        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();
        LibSafeGuard.Allowance storage a = s.allowances[safe];

        // Early exit if nothing changed
        if (a.txLimit == txLimit && a.amountLimit == amountLimit) return;

        a.txLimit = txLimit;
        a.amountLimit = amountLimit;

        emit DailyAllowanceUpdated(safe, txLimit, amountLimit);
    }
}
