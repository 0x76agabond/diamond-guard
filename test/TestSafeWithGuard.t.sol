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

import {TestManager} from "./TestManager/TestManager.sol";
import {NotSafe} from "./NotSafe/NotSafe.sol";

contract TestSafeWithGuard is TestManager {
    // this is a custom implementation of KeySet for testing purpose
    // helper implemented inside TestManager
    KeySet ks;

    // mock BEP20 token
    BEP20Token token;

    // NotSafe is a mock contract of Gnosis Safe
    NotSafe safeWallet;
}
