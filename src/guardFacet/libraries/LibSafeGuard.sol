pragma solidity >=0.8.30;
// SPDX-License-Identifier: MIT

/*
 * ===========================================================================
 * Author: Hoang <ginz1504@gmail.com>
 * Contact: https://github.com/0x76agabond
 * ===========================================================================
 * Diamond as Gnosis Safe Guard (Diamond Guard)
 * ===========================================================================
 */

library LibSafeGuard {
    // ERC-8042
    // I'm an independent researcher so leave {org} as "eth"
    // this is {org}.{project}.{domain_type}.{domain (lowercase)}.{version}
    bytes32 internal constant SAFEGUARD_STORAGE_POSITION = keccak256("eth.diamondguard.business.guardfacet.v0.0.1");

    // Daily limit structure for future extension
    // Optimized for 2 slots
    struct Allowance {
        uint64 date;
        uint64 txDate;
        uint64 txCount;
        uint64 txLimit;
        uint128 spent;
        uint128 amountLimit;
    }

    struct SafeGuardStorage {
        bool isInitialized;
        bool isLocked;
        bool isModuleLocked;
        bool isActivated;
        bool isModuleCheckActivated;
        bool isWhitelistEnabled;
        bool isEnforceExecutor;
        bool isDelegateCallAllowed;
        bool isModuleDelegateCallAllowed;

        mapping(address => mapping(address => bool)) whitelist;
        mapping(address => Allowance) allowances;
    }

    // add more attributes to the last position of SafeGuardStorage if need to add more feature

    function getStorage() internal pure returns (SafeGuardStorage storage s) {
        bytes32 pos = SAFEGUARD_STORAGE_POSITION;
        assembly {
            s.slot := pos
        }
    }
}
