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

    function getWalletAllowance(address safe) external view returns (WalletAllowanceMod.Allowance memory) {
        WalletAllowanceMod.AllowanceStorage storage s = WalletAllowanceMod.getAllowanceStorage();
        return s.allowances[safe];
    }

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

    function setDailyAllowance(WalletAllowanceMod.AllowanceSetting memory setting) external {
        OwnerMod.requireOwner();
        if (setting.safe == address(0)) revert SafeAddressZero();

        WalletAllowanceMod.AllowanceStorage storage s = WalletAllowanceMod.getAllowanceStorage();
        WalletAllowanceMod.Allowance storage a = s.allowances[setting.safe];

        // Early exit if nothing changed
        if (a.txLimit == setting.txLimit && a.amountLimit == setting.amountLimit) {
            return;
        }

        a.txLimit = setting.txLimit;
        a.amountLimit = setting.amountLimit;

        emit DailyAllowanceUpdated(setting.safe, setting.txLimit, setting.amountLimit);
    }

    function setDailyAllowanceBatch(WalletAllowanceMod.AllowanceSetting[] memory settings) external {
        OwnerMod.requireOwner();
        WalletAllowanceMod.AllowanceStorage storage s = WalletAllowanceMod.getAllowanceStorage();

        uint256 len = settings.length;
        for (uint256 i; i < len; i++) {
            WalletAllowanceMod.AllowanceSetting memory setting = settings[i];

            if (setting.safe == address(0)) revert SafeAddressZero();

            WalletAllowanceMod.Allowance storage a = s.allowances[setting.safe];

            // Early exit if nothing changed
            if (a.txLimit == setting.txLimit && a.amountLimit == setting.amountLimit) {
                continue;
            }

            a.txLimit = setting.txLimit;
            a.amountLimit = setting.amountLimit;

            emit DailyAllowanceUpdated(setting.safe, setting.txLimit, setting.amountLimit);
        }
        
    }
}
