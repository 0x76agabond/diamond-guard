pragma solidity >=0.8.30;
// SPDX-License-Identifier: MIT

/*
 * ===========================================================================
 * Author: Hoang (0x76agabond)
 * ===========================================================================
 * Diamond Guard - Diamond as Gnosis Safe Guard
 * ===========================================================================
 */

import "../modules/safeGuardMod.sol" as SafeGuardMod;
import "../../access/Owner/OwnerMod.sol" as OwnerMod;
import "../modules/safeGuardEvent.sol";

/**
 * @dev
 * Facet used to manage Safe Guard settings.
 * Provides getters and setters for various configuration flags.
 * Only the contract owner is allowed to modify these settings.
 *
 * Since this facet only manages simple state variables,
 * it does not require additional getter and setter.
 *
 * This facet is mainly intended for off-chain communication
 * and configuration management.
 */

contract GuardSettingFacet {
    // =========================================================
    //                      INITIALIZER
    // =========================================================

    function init() external {
        OwnerMod.requireOwner();
        SafeGuardMod.GuardStateStorage storage state = SafeGuardMod.getStateStorage();

        if (state.isInitialized) {
            revert GuardInitialized();
        }

        state.isInitialized = true;
        state.isLocked = false;
        state.isModuleLocked = false;
        state.isActivated = true;
        state.isModuleCheckActivated = true;
        state.isWhitelistEnabled = false;
        state.isEnforceExecutor = false;
        state.isDelegateCallAllowed = false;
        state.isModuleDelegateCallAllowed = false;
    }

    function getInitStatus() external view returns (bool) {
        return SafeGuardMod.getStateStorage().isInitialized;
    }

    // =========================================================
    //                      GETTERS
    // =========================================================

    function getLockedStatus() external view returns (bool) {
        return SafeGuardMod.getStateStorage().isLocked;
    }

    function getModuleLockedStatus() external view returns (bool) {
        return SafeGuardMod.getStateStorage().isModuleLocked;
    }

    function getActivatedStatus() external view returns (bool) {
        return SafeGuardMod.getStateStorage().isActivated;
    }

    function getModuleCheckActivatedStatus() external view returns (bool) {
        return SafeGuardMod.getStateStorage().isModuleCheckActivated;
    }

    function getWhitelistEnabledStatus() external view returns (bool) {
        return SafeGuardMod.getStateStorage().isWhitelistEnabled;
    }

    function getEnforceExecutorStatus() external view returns (bool) {
        return SafeGuardMod.getStateStorage().isEnforceExecutor;
    }

    function getDelegateCallAllowedStatus() external view returns (bool) {
        return SafeGuardMod.getStateStorage().isDelegateCallAllowed;
    }

    function getModuleDelegateCallAllowedStatus() external view returns (bool) {
        return SafeGuardMod.getStateStorage().isModuleDelegateCallAllowed;
    }

    // =========================================================
    //                      SETTERs
    // =========================================================

    function setLockedStatus(bool locked) external {
        OwnerMod.requireOwner();
        SafeGuardMod.GuardStateStorage storage state = SafeGuardMod.getStateStorage();

        if (!state.isInitialized) revert GuardNotInitialized();
        if (state.isLocked == locked) return;

        state.isLocked = locked;
        emit LockedStatusChanged(locked);
    }

    function setModuleLockedStatus(bool locked) external {
        OwnerMod.requireOwner();
        SafeGuardMod.GuardStateStorage storage state = SafeGuardMod.getStateStorage();

        if (!state.isInitialized) revert GuardNotInitialized();
        if (state.isModuleLocked == locked) return;

        state.isModuleLocked = locked;
        emit ModuleLockedStatusChanged(locked);
    }

    function setActivatedStatus(bool activated) external {
        OwnerMod.requireOwner();
        SafeGuardMod.GuardStateStorage storage state = SafeGuardMod.getStateStorage();

        if (!state.isInitialized) revert GuardNotInitialized();
        if (state.isActivated == activated) return;

        state.isActivated = activated;
        emit ActivatedStatusChanged(activated);
    }

    function setModuleCheckActivatedStatus(bool activated) external {
        OwnerMod.requireOwner();
        SafeGuardMod.GuardStateStorage storage state = SafeGuardMod.getStateStorage();

        if (!state.isInitialized) revert GuardNotInitialized();
        if (state.isModuleCheckActivated == activated) return;

        state.isModuleCheckActivated = activated;
        emit ModuleCheckActivatedChanged(activated);
    }

    function setEnforceExecutorStatus(bool enforced) external {
        OwnerMod.requireOwner();
        SafeGuardMod.GuardStateStorage storage state = SafeGuardMod.getStateStorage();

        if (!state.isInitialized) revert GuardNotInitialized();
        if (state.isEnforceExecutor == enforced) return;

        state.isEnforceExecutor = enforced;
        emit EnforceExecutorChanged(enforced);
    }

    function setDelegateCallAllowedStatus(bool allowed) external {
        OwnerMod.requireOwner();
        SafeGuardMod.GuardStateStorage storage state = SafeGuardMod.getStateStorage();

        if (!state.isInitialized) revert GuardNotInitialized();
        if (state.isDelegateCallAllowed == allowed) return;

        state.isDelegateCallAllowed = allowed;
        emit DelegateCallAllowedChanged(allowed);
    }

    function setModuleDelegateCallAllowedStatus(bool allowed) external {
        OwnerMod.requireOwner();
        SafeGuardMod.GuardStateStorage storage state = SafeGuardMod.getStateStorage();

        if (!state.isInitialized) revert GuardNotInitialized();
        if (state.isModuleDelegateCallAllowed == allowed) return;

        state.isModuleDelegateCallAllowed = allowed;
        emit ModuleDelegateCallAllowedChanged(allowed);
    }

    function setWhitelistEnabledStatus(bool enabled) external {
        OwnerMod.requireOwner();
        SafeGuardMod.GuardStateStorage storage state = SafeGuardMod.getStateStorage();

        if (!state.isInitialized) revert GuardNotInitialized();
        if (state.isWhitelistEnabled == enabled) return;

        state.isWhitelistEnabled = enabled;
        emit WhitelistStatusChanged(enabled);
    }

    function setWhitelist(address safe, address target, bool enabled) external {
        OwnerMod.requireOwner();

        if (safe == address(0)) {
            revert SafeAddressZero();
        }

        if (target == address(0)) {
            revert WhitelistAddressZero();
        }

        SafeGuardMod.GuardStorage storage s = SafeGuardMod.getGuardStorage();
        if (s.whitelist[safe][target] == enabled) return;
        s.whitelist[safe][target] = enabled;
        emit WhitelistUpdated(safe, target, enabled);
    }

    function setWhitelistBatch(address safe, address[] calldata targets, bool enabled) external {
        OwnerMod.requireOwner();

        if (safe == address(0)) {
            revert SafeAddressZero();
        }

        SafeGuardMod.GuardStorage storage s = SafeGuardMod.getGuardStorage();
        uint256 len = targets.length;
        for (uint256 i; i < len; i++) {
            address target = targets[i];

            if (target == address(0)) {
                revert WhitelistAddressZero();
            }

            if (s.whitelist[safe][target] != enabled) {
                s.whitelist[safe][target] = enabled;
                emit WhitelistUpdated(safe, target, enabled);
            }            
        }
    }
}

