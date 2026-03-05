pragma solidity >=0.8.30;
// SPDX-License-Identifier: MIT

/*
 * ===========================================================================
 * Author: Hoang (0x76agabond)
 * ===========================================================================
 * Diamond Guard - Diamond as Gnosis Safe Guard
 * ===========================================================================
 */

import "../modules/walletEvent.sol";
import "../../access/Owner/OwnerMod.sol" as OwnerMod;
import "../modules/walletAllowanceMod.sol" as WalletAllowanceMod;

contract WalletAllowanceFacet {
    function setDailyAmountLimit(address safe, uint128 amountLimit) external {
        OwnerMod.requireOwner();
        if (safe == address(0)) revert SafeAddressZero();

        WalletAllowanceMod.AllowanceStorage storage s = WalletAllowanceMod.getAllowanceStorage();
        WalletAllowanceMod.Allowance storage a = s.allowances[safe];
        if (a.amountLimit == amountLimit) return;
        a.amountLimit = amountLimit;

        emit DailyAmountLimitChanged(safe, amountLimit);
    }

    function setDailyTxLimit(address safe, uint64 txLimit) external {
        OwnerMod.requireOwner();
        if (safe == address(0)) revert SafeAddressZero();

        WalletAllowanceMod.AllowanceStorage storage s = WalletAllowanceMod.getAllowanceStorage();
        WalletAllowanceMod.Allowance storage a = s.allowances[safe];

        if (a.txLimit == txLimit) return;
        a.txLimit = txLimit;

        emit DailyTxLimitChanged(safe, txLimit);
    }

    function setDailyAllowance(address safe, uint64 txLimit, uint128 amountLimit) external {
        OwnerMod.requireOwner();
        if (safe == address(0)) revert SafeAddressZero();

        WalletAllowanceMod.AllowanceStorage storage s = WalletAllowanceMod.getAllowanceStorage();
        WalletAllowanceMod.Allowance storage a = s.allowances[safe];

        // Early exit if nothing changed
        if (a.txLimit == txLimit && a.amountLimit == amountLimit) return;

        if (a.txLimit != txLimit) {
            a.txLimit = txLimit;
        }

        if (a.amountLimit != amountLimit) {
            a.amountLimit = amountLimit;
        }

        emit DailyAllowanceUpdated(safe, txLimit, amountLimit);
    }
}
