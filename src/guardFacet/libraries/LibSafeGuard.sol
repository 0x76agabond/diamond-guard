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

library LibSafeGuard {
    // ERC-8042
    bytes32 internal constant SAFEGUARD_STORAGE_POSITION = keccak256("diamondguard.service.guardfacet.v.0.0.1");

    struct TxContext {
        uint256 nonce;
        bytes32 txHash;
    }

    // add more attributes here if needed

    struct SafeGuardStorage {
        mapping(address => TxContext) walletContext;
        mapping(address => mapping(address => bool)) whitelist;
        bool isLocked;
        bool isModuleLocked;
        bool isActivated;
        bool isModuleCheckActivated;
        bool isWhitelistEnabled;
        bool isEnforceExecutor;
        bool isDelegateCallAllowed;
        bool isModuleDelegateCallAllowed;
    }

    // add more attributes here if needed

    function getStorage() internal pure returns (SafeGuardStorage storage s) {
        bytes32 pos = SAFEGUARD_STORAGE_POSITION;
        assembly {
            s.slot := pos
        }
    }
}
