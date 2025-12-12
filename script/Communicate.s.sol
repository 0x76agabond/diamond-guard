// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";

import {IDiamondCut} from "../src/diamond/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../src/diamond/interfaces/IDiamondLoupe.sol";
import {Diamond} from "../src/diamond/Diamond.sol";
import {GuardFacetAllowance} from "../src/guardFacet/implementFacet/GuardFacetAllowance.sol";
import {IGuardFacet} from "../src/guardFacet/interfaces/IGuardFacet.sol";
import {IGuardSettingFacet} from "../src/guardFacet/interfaces/IGuardSettingFacet.sol";

contract Communicate is Script {
    function run() external {
        uint256 key_manager = vm.envUint("PRIVATE_KEY");
        address manager = vm.addr(key_manager);

        /*
              forge script script/Communicate.s.sol:Communicate \
        --rpc-url opbnb \

               */

        //Diamond diamond;
        address diamond = 0x7B967c855b855e071359eDa1C6D7D691C31697Af;
        console.log("diamond", diamond);
        vm.startBroadcast(key_manager);

        {
            console.log(IGuardSettingFacet(diamond).getLockedStatus());
        }
    }
}
