// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

import {IDiamondCut} from "../src/diamond/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../src/diamond/interfaces/IDiamondLoupe.sol";
import {Diamond} from "../src/diamond/Diamond.sol";
import {GuardSettingFacet} from "../src/guardFacet/settingFacet/GuardSettingFacet.sol";
import {IGuardSettingFacet} from "../src/guardFacet/interfaces/IGuardSettingFacet.sol";

contract Communicate2 is Script {
    function run() external {
        uint256 key_manager = vm.envUint("PRIVATE_KEY");
        address manager = vm.addr(key_manager);

        //Diamond diamond;
        address diamond = 0x7B967c855b855e071359eDa1C6D7D691C31697Af;
        console.log("diamond", diamond);
        vm.startBroadcast(key_manager);

        {

            GuardSettingFacet guardsettingFacet = new GuardSettingFacet();
            bytes4[] memory selectors = new bytes4[](2);

            uint256 i;

            //
            //  GETTERS
            //
            selectors[i++] = IGuardSettingFacet.setLockedStatus.selector;

            IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
            cut[0] = IDiamondCut.FacetCut({
                facetAddress: address(guardsettingFacet),
                action: IDiamondCut.FacetCutAction.Add,
                functionSelectors: selectors
            });

            IDiamondCut(diamond).diamondCut(cut, address(diamond), "");

            address[] memory facets = IDiamondLoupe(diamond).facetAddresses();
            console.log("FacetAddress");
            for (uint256 index; index < facets.length; index++) {
                console.log(address(facets[index]));
            }

            bytes4[] memory selectors2 = IDiamondLoupe(diamond).facetFunctionSelectors(address(guardsettingFacet));

            console.log("FuntionSelector");
            for (uint256 index; index < selectors2.length; index++) {
                console.logBytes32(bytes32(selectors2[index]));
            }
        }
    }
}
