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

import "../../src/walletAllowance/facets/walletAllowanceFacet.sol";

contract TestB is TestManager {
    address safe = address(0x123);

    function setUp() public {
        WalletAllowanceMod.AllowanceStorage storage s = WalletAllowanceMod.getAllowanceStorage();
        WalletAllowanceMod.Allowance storage a = s.allowances[safe];

        uint64 txLimit = 1;
        uint128 amountLimit = 1000;

        a.txLimit = txLimit;
        a.amountLimit = amountLimit;
    }

    function test_assembly() public {
        uint64 txLimit = 1;
        uint128 amountLimit = 2000;

        if (safe == address(0)) revert SafeAddressZero();

        WalletAllowanceMod.AllowanceStorage storage s = WalletAllowanceMod.getAllowanceStorage();
        WalletAllowanceMod.Allowance storage a = s.allowances[safe];

        // Early exit if nothing changed
        if (a.txLimit == txLimit && a.amountLimit == amountLimit) return;

        a.txLimit = txLimit;
        a.amountLimit = amountLimit;

        emit DailyAllowanceUpdated(safe, txLimit, amountLimit);
    }
}
