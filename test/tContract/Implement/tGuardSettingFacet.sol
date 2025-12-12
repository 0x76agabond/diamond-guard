// SPDX-License-Identifier: MIT

/*
/// Author: Hoang <ginz1504@gmail.com>
*/

pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {IDiamondCut} from "../../../src/diamond/interfaces/IDiamondCut.sol";
import {IGuardSettingFacet} from "../../../src/guardFacet/interfaces/IGuardSettingFacet.sol";
import {GuardSettingFacet} from "../../../src/guardFacet/settingFacet/GuardSettingFacet.sol";
import {tPrototype} from "../tPrototype.sol";

contract tGuardSettingFacet is tPrototype {
    GuardSettingFacet public facet;

    function setUp() public override {
        facet = new GuardSettingFacet();

        uint256 i;
        selectors = new bytes4[](23);

        //
        //  INITIALIZER
        //
        selectors[i++] = IGuardSettingFacet.init.selector;

        //
        //  GETTERS
        //
        selectors[i++] = IGuardSettingFacet.setLockedStatus.selector;
        selectors[i++] = IGuardSettingFacet.getModuleLockedStatus.selector;
        selectors[i++] = IGuardSettingFacet.getActivatedStatus.selector;
        selectors[i++] = IGuardSettingFacet.getModuleCheckActivated.selector;
        selectors[i++] = IGuardSettingFacet.getEnforceExecutor.selector;
        selectors[i++] = IGuardSettingFacet.getDelegateCallAllowed.selector;
        selectors[i++] = IGuardSettingFacet.getModuleDelegateCallAllowed.selector;
        selectors[i++] = IGuardSettingFacet.getWhitelistEnabled.selector;
        selectors[i++] = IGuardSettingFacet.isWhitelisted.selector;

        // NEW — Allowance getter
        selectors[i++] = IGuardSettingFacet.getAllowance.selector;

        //
        //  SETTERS
        //
        selectors[i++] = IGuardSettingFacet.setModuleLockedStatus.selector;
        selectors[i++] = IGuardSettingFacet.setActivatedStatus.selector;
        selectors[i++] = IGuardSettingFacet.setModuleCheckActivated.selector;
        selectors[i++] = IGuardSettingFacet.setEnforceExecutor.selector;
        selectors[i++] = IGuardSettingFacet.setDelegateCallAllowed.selector;
        selectors[i++] = IGuardSettingFacet.setModuleDelegateCallAllowed.selector;
        selectors[i++] = IGuardSettingFacet.setWhitelistEnabled.selector;
        selectors[i++] = IGuardSettingFacet.setWhitelist.selector;

        // NEW — whitelist batch
        selectors[i++] = IGuardSettingFacet.setWhitelistBatch.selector;

        // NEW — allowance setters
        selectors[i++] = IGuardSettingFacet.setDailyAmountLimit.selector;
        selectors[i++] = IGuardSettingFacet.setDailyTxLimit.selector;
        selectors[i++] = IGuardSettingFacet.setDailyAllowance.selector;
    }

    function buildCut() external view override returns (IDiamondCut.FacetCut[] memory) {
        return baseCut(address(facet));
    }
}
