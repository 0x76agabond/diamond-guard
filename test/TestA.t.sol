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

import "forge-std/console2.sol";
import "forge-std/Test.sol";
import {TestManager} from "./TestManager/TestManager.sol";
import {Enum, NotSafe} from "./NotSafe/NotSafe.sol";
import {BEP20Token} from "./ERC20/ERC20.sol";

import {IGuardFacet, tGuardFacet} from "./tContract/Implement/tGuardFacet.sol";
import {IGuardSettingFacet, tGuardSettingFacet} from "./tContract/Implement/tGuardSettingFacet.sol";

import {Diamond, CutUtil} from "../test/tContract/tPrototype.sol";

import {IDiamondLoupe, tDiamondLoupe} from "../test/tContract/Implement/tDiamondLoupe.sol";

import {Transaction} from "./NotSafe/libraries/Transaction.sol";

contract TestSafeWithGuard is TestManager {
    function setUp() public {}

    function test_assembly() {}
}
