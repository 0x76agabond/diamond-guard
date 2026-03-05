pragma solidity >=0.8.30;
// SPDX-License-Identifier: MIT

/*
 * ===========================================================================
 * Author: Hoang (0x76agabond)
 * ===========================================================================
 * Diamond Guard - Diamond as Gnosis Safe Guard
 * ===========================================================================
 */

/**
 * @dev
 * Storage used to manage Safe Guard settings and state.
 * Sub-domains are used to separate boolean variables in order to optimize packing.
 *
 * In practice, developers may design sub-domains differently depending on their needs.
 *
 * For example:
 * - Group settings that are commonly accessed together.
 * - Separate state by data type to improve packing efficiency.
 * - Any other layout that better fits the system’s usage patterns.
 *
 * In general, sub-domains are a way to organize storage to improve flexibility and optimize gas cost.
 * Developers are free to structure sub-domains in whatever way best suits their requirements.
 */

import "../../access/Owner/OwnerMod.sol" as OwnerMod;
import "./safeGuardEvent.sol";

/**
 * @dev Minimal Form:
 * diamondGuard.business.guard
 * ---------------------------------
 * @custom:storage-location erc8042:org.diamondGuard.business.guard.v1
 */

bytes32 constant GUARD_STORAGE_MAIN_POSITION = keccak256("org.diamondguard.business.guard.v1");

struct GuardStorage {
    mapping(address => mapping(address => bool)) whitelist;
}

function getGuardStorage() pure returns (GuardStorage storage s) {
    bytes32 pos = GUARD_STORAGE_MAIN_POSITION;
    assembly {
        s.slot := pos
    }
}

/**
 * @dev Minimal Form:
 * diamondGuard.business.guard.state
 * ---------------------------------
 * @custom:storage-location erc8042:org.diamondGuard.business.guard.v1.state
 */

bytes32 constant GUARD_STORAGE_STATE_POSITION = keccak256("org.diamondguard.business.guard.v1.state");

struct GuardStateStorage {
    bool isInitialized;
    bool isLocked;
    bool isModuleLocked;
    bool isActivated;
    bool isModuleCheckActivated;
    bool isWhitelistEnabled;
    bool isEnforceExecutor;
    bool isDelegateCallAllowed;
    bool isModuleDelegateCallAllowed;
}

function getStateStorage() pure returns (GuardStateStorage storage s) {
    bytes32 pos = GUARD_STORAGE_STATE_POSITION;
    assembly {
        s.slot := pos
    }
}

function getAllStorage() pure returns (GuardStorage storage guardStorage, GuardStateStorage storage stateStorage) {
    bytes32 posGuard = GUARD_STORAGE_MAIN_POSITION;
    bytes32 posState = GUARD_STORAGE_STATE_POSITION;
    assembly {
        guardStorage.slot := posGuard
        stateStorage.slot := posState
    }
}
