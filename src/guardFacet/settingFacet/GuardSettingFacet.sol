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

    event ModuleLockedStatusChanged(bool locked);
    event ActivatedStatusChanged(bool activated);
    event ModuleCheckActivatedChanged(bool activated);
    event EnforceExecutorChanged(bool enforced);
    event DelegateCallAllowedChanged(bool allowed);
    event ModuleDelegateCallAllowedChanged(bool allowed);
    event WhitelistStatusChanged(bool enabled);
    event WhitelistUpdated(address indexed safe, address indexed target, bool enabled);

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

    // =========================================================
    //                      SETTERS
    // =========================================================

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
        if (safe == address(0)) {
            revert SafeAddressZero();
        }

        if (target == address(0)) {
            revert WhitelistAddressZero();
        }

        LibDiamond.enforceIsContractOwner();
        LibSafeGuard.SafeGuardStorage storage s = LibSafeGuard.getStorage();
        if (s.whitelist[safe][target] == enabled) return;
        s.whitelist[safe][target] = enabled;
        emit WhitelistUpdated(safe, target, enabled);
    }
}
