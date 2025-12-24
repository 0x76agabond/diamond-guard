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

import {LibSafeHandler} from "./LibSafeHandler.sol";

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

    // =========================================================
    //                      CONSTANTS
    // =========================================================

    // ERC20 selectors
    bytes4 internal constant SELECTOR_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 internal constant SELECTOR_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    // =========================================================
    //                      INTERNAL HELPERS
    // =========================================================

    function dayStamp() internal view returns (uint64) {
        return uint64(block.timestamp / 1 days);
    }

    function resolveAllowanceTargetAndAmount(
        address to,
        uint256 value,
        bytes memory data,
        LibSafeHandler.SafeOperation operation
    ) internal pure returns (address target, uint256 amount) {
        target = to;
        amount = value;

        if (operation != LibSafeHandler.SafeOperation.Call || data.length < 4) {
            return (target, amount);
        }

        bytes4 selector = bytes4(data);

        // ERC20 transfer(address,uint256)
        if (selector == SELECTOR_TRANSFER) {
            address ercTo;
            uint256 ercValue;

            assembly {
                ercTo := mload(add(data, 36)) // arg1
                ercValue := mload(add(data, 68)) // arg2
            }

            return (ercTo, ercValue);
        }

        // ERC20 transferFrom(address,address,uint256)
        if (selector == SELECTOR_TRANSFER_FROM) {
            address ercTo;
            uint256 ercValue;

            assembly {
                ercTo := mload(add(data, 68)) // to
                ercValue := mload(add(data, 100)) // amount
            }

            return (ercTo, ercValue);
        }

        return (target, amount);
    }
}
