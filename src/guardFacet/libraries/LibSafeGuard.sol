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
    bytes32 constant SAFEGUARD_STORAGE_POSITION = keccak256("independent.middleware.guardfacet.v.0.0.1");    

    enum SafeOperation {
        Call,
        DelegateCall
    }

}