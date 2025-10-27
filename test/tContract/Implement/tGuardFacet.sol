// SPDX-License-Identifier: MIT
/*
/// Author: Hoang <ginz1504@gmail.com>
/// Contact: https://github.com/0x76agabond
/// =============================================================================
/// Diamond Testing via OOP (DTO)
*/

pragma solidity ^0.8.26;

import {IDiamondCut} from "../../../src/diamond/interfaces/IDiamondCut.sol";
import {IGuardFacet} from "../../../src/guardFacet/interfaces/IGuardFacet.sol";
import {GuardFacet} from "../../../src/guardFacet/implementFacet/GuardFacet.sol";
import {tPrototype} from "../tPrototype.sol";

contract tGuardFacet is tPrototype {
    // for main call
    GuardFacet public facet;

    // set up here
    function setUp() public override {
        // Generate based on Facet
        facet = new GuardFacet();

        // Generate based on Interface
        uint256 i;
        selectors = new bytes4[](4);
        selectors[i++] = IGuardFacet.checkTransaction.selector;
        selectors[i++] = IGuardFacet.checkAfterExecution.selector;
        selectors[i++] = IGuardFacet.checkModuleTransaction.selector;
        selectors[i++] = IGuardFacet.checkAfterModuleExecution.selector;
    }

    // basically same in all sub contract
    function buildCut() external view override returns (IDiamondCut.FacetCut[] memory) {
        return baseCut(address(facet));
    }
}
