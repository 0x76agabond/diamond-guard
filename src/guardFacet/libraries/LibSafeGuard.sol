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
    bytes32 internal constant SAFEGUARD_STORAGE_POSITION = keccak256("diamondguard.system.guardfacet.v.0.0.1");

    struct SafeGuardStorage {
        mapping(address => uint256) walletNonces;
        bool isActive;
        bool isLocked;
    }

    function getStorage() internal pure returns (SafeGuardStorage storage s) {
        bytes32 pos = SAFEGUARD_STORAGE_POSITION;
        assembly {
            s.slot := pos
        }
    }
}
