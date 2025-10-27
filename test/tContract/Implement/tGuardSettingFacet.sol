// SPDX-License-Identifier: MIT

/*
/// Author: Hoang <ginz1504@gmail.com>
/// Contact: https://github.com/0x76agabond
/// =============================================================================
/// Diamond Testing via OOP (DTO)
*/

pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {IDiamondCut} from "../../../src/diamond/interfaces/IDiamondCut.sol";
import {IGuardSettingFacet} from "../../../src/guardFacet/interfaces/IGuardSettingFacet.sol";
import {GuardSettingFacet} from "../../../src/guardFacet/settingFacet/GuardSettingFacet.sol";
import {tPrototype} from "../tPrototype.sol";

contract tGuardSettingFacet is tPrototype {
    // =========================================================
    //                        FIELDS
    // =========================================================
    GuardSettingFacet public facet;

    // =========================================================
    //                        SETUP
    // =========================================================
    function setUp() public override {
        // Instantiate implementation
        facet = new GuardSettingFacet();

        // Collect function selectors from IGuardSettingFacet
        uint256 i;
        selectors = new bytes4[](17);

        // Initializer
        selectors[i++] = IGuardSettingFacet.init.selector;

        // Getters
        selectors[i++] = IGuardSettingFacet.getModuleLockedStatus.selector;
        selectors[i++] = IGuardSettingFacet.getActivatedStatus.selector;
        selectors[i++] = IGuardSettingFacet.getModuleCheckActivated.selector;
        selectors[i++] = IGuardSettingFacet.getEnforceExecutor.selector;
        selectors[i++] = IGuardSettingFacet.getDelegateCallAllowed.selector;
        selectors[i++] = IGuardSettingFacet.getModuleDelegateCallAllowed.selector;
        selectors[i++] = IGuardSettingFacet.getWhitelistEnabled.selector;
        selectors[i++] = IGuardSettingFacet.isWhitelisted.selector;

        // Setters
        selectors[i++] = IGuardSettingFacet.setModuleLockedStatus.selector;
        selectors[i++] = IGuardSettingFacet.setActivatedStatus.selector;
        selectors[i++] = IGuardSettingFacet.setModuleCheckActivated.selector;
        selectors[i++] = IGuardSettingFacet.setEnforceExecutor.selector;
        selectors[i++] = IGuardSettingFacet.setDelegateCallAllowed.selector;
        selectors[i++] = IGuardSettingFacet.setModuleDelegateCallAllowed.selector;
        selectors[i++] = IGuardSettingFacet.setWhitelistEnabled.selector;
        selectors[i++] = IGuardSettingFacet.setWhitelist.selector;
    }

    // =========================================================
    //                       BUILD CUT
    // =========================================================
    function buildCut() external view override returns (IDiamondCut.FacetCut[] memory) {
        return baseCut(address(facet));
    }
}
