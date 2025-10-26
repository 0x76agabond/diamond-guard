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

library LibReentrancy {
    // ERC-8042
    bytes32 internal constant SYSTEM_REENTRANCY_STORAGE_POSITION = keccak256("diamondguard.system.reentrancy.v0.0.0.1");
    uint256 internal constant _NOT_ENTERED = 1;
    uint256 internal constant _ENTERED = 2;

    error ReentrantCall();

    struct ReentrancyStorage {
        uint256 status;
    }

    function getStorage() internal pure returns (ReentrancyStorage storage s) {
        bytes32 slot = SYSTEM_REENTRANCY_STORAGE_POSITION;
        assembly { s.slot := slot }
    }

    function enter() internal {
        ReentrancyStorage storage s = getStorage();

        // Initialize if unset
        if (s.status == 0) {
            s.status = _NOT_ENTERED;
        }

        if (s.status == _ENTERED) {
            revert ReentrantCall();
        }
        s.status = _ENTERED;
    }

    function exit() internal {
        getStorage().status = _NOT_ENTERED;
    }
}
