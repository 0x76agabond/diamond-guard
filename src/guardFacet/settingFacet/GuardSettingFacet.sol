pragma solidity = 0.8.26;
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
import {LibReentrancy} from "../../system/libraries/LibReentrancyy.sol";

contract GuardFacet {
    // =========================================================
    //                      EVENTS
    // =========================================================
    event ModuleLockedStatusChanged(bool locked);
    event ActivatedStatusChanged(bool activated);
    event ModuleCheckActivatedChanged(bool activated);
    event EnforceExecutorChanged(bool enforced);
    event DelegateCallAllowedChanged(bool allowed);
    event ModuleDelegateCallAllowedChanged(bool allowed);
    event WhitelistStatusChanged(bool enabled);
    event WhitelistUpdated(address indexed safe, address indexed target, bool enabled);

    // =========================================================
    //                      GETTERS
    // =========================================================
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

    // =========================================================
    //                      SETTERS
    // =========================================================
    function setModuleLockedStatus(bool locked) external {
        LibReentrancy.enter();
        LibDiamond.enforceIsContractOwner();
        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();
        if (s.isModuleLocked == locked) return;
        s.isModuleLocked = locked;
        emit ModuleLockedStatusChanged(locked);
        LibReentrancy.exit();
    }

    function setActivatedStatus(bool activated) external {
        LibReentrancy.enter();
        LibDiamond.enforceIsContractOwner();
        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();
        if (s.isActivated == activated) return;
        s.isActivated = activated;
        emit ActivatedStatusChanged(activated);
        LibReentrancy.exit();
    }

    function setModuleCheckActivated(bool activated) external {
        LibReentrancy.enter();
        LibDiamond.enforceIsContractOwner();
        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();
        if (s.isModuleCheckActivated == activated) return;
        s.isModuleCheckActivated = activated;
        emit ModuleCheckActivatedChanged(activated);
        LibReentrancy.exit();
    }

    function setEnforceExecutor(bool enforced) external {
        LibReentrancy.enter();
        LibDiamond.enforceIsContractOwner();
        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();
        if (s.isEnforceExecutor == enforced) return;
        s.isEnforceExecutor = enforced;
        emit EnforceExecutorChanged(enforced);
        LibReentrancy.exit();
    }

    function setDelegateCallAllowed(bool allowed) external {
        LibReentrancy.enter();
        LibDiamond.enforceIsContractOwner();
        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();
        if (s.isDelegateCallAllowed == allowed) return;
        s.isDelegateCallAllowed = allowed;
        emit DelegateCallAllowedChanged(allowed);
        LibReentrancy.exit();
    }

    function setModuleDelegateCallAllowed(bool allowed) external {
        LibReentrancy.enter();
        LibDiamond.enforceIsContractOwner();
        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();
        if (s.isModuleDelegateCallAllowed == allowed) return;
        s.isModuleDelegateCallAllowed = allowed;
        emit ModuleDelegateCallAllowedChanged(allowed);
        LibReentrancy.exit();
    }

    function setWhitelistEnabled(bool enabled) external {
        LibReentrancy.enter();
        LibDiamond.enforceIsContractOwner();
        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();
        if (s.isWhitelistEnabled == enabled) return;
        s.isWhitelistEnabled = enabled;
        emit WhitelistStatusChanged(enabled);
        LibReentrancy.exit();
    }

    function updateWhitelist(address safe, address target, bool enabled) external {
        LibReentrancy.enter();
        LibDiamond.enforceIsContractOwner();
        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();
        if (s.whitelist[safe][target] == enabled) return;
        s.whitelist[safe][target] = enabled;
        emit WhitelistUpdated(safe, target, enabled);
        LibReentrancy.exit();
    }
}
