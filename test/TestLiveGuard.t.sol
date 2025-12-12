pragma solidity >=0.8.30;
// SPDX-License-Identifier: MIT

import "forge-std/console2.sol";
import "forge-std/Test.sol";
import {TestManager} from "./TestManager/TestManager.sol";
import {Enum, NotSafe} from "./NotSafe/NotSafe.sol";
import {BEP20Token} from "./ERC20/ERC20.sol";
import {GuardFacetAllowance} from "../../src/guardFacet/implementFacet/GuardFacetAllowance.sol";
import {GuardSettingFacet} from "../../src/guardFacet/settingFacet/GuardSettingFacet.sol";

import {IGuardFacet, tGuardFacetAllowance} from "./tContract/Implement/tGuardFacetAllowance.sol";
import {IGuardSettingFacet, tGuardSettingFacet} from "./tContract/Implement/tGuardSettingFacet.sol";

import {Diamond, CutUtil} from "../test/tContract/tPrototype.sol";
import {IDiamondCut} from "../../src/diamond/interfaces/IDiamondCut.sol";
import {DiamondCutFacet} from "../../src/diamond/facet/DiamondCutFacet.sol";
import {IDiamondLoupe, tDiamondLoupe} from "../test/tContract/Implement/tDiamondLoupe.sol";

import {Transaction} from "./NotSafe/libraries/Transaction.sol";

contract LiveDiamondTest is Test {
    uint256 key_manager;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("opbnb"));
        key_manager = vm.envUint("PRIVATE_KEY");
    }

    function test_LightDiamond_Guard() public view {
        //address diamondAddress = 0x7B967c855b855e071359eDa1C6D7D691C31697Af;
        //IDiamondLoupe loupe = IDiamondLoupe(diamondAddress);
        //vm.startPrank(vm.addr(key_manager));
        //address[] memory facets = loupe.facetAddresses();
        //for (uint256 index; index < facets.length; index++)
        //{
        //    console.log(address(facets[index]));
        //}

        bytes memory data =
            hex"a9059cbb000000000000000000000000bf1a6ae4bdcb66dbaea6797c114c1d944781ef350000000000000000000000000000000000000000000000000de0b6b3a7640000";
        console2.logBytes(data);

        console.log(" ======================== ");

        bytes4 selector = bytes4(data);
        console2.logBytes4(selector);

        address ercTo;
        uint256 ercValue;
        assembly {
            ercTo := mload(add(data, 36)) // arg1
            ercValue := mload(add(data, 68)) // arg2
        }

        console.log(" to: ", ercTo);
        console.log(" value: ", ercValue);

        address ercTo2;
        uint256 ercValue2;

        assembly {
            ercTo2 := mload(add(data, 68)) // to
            ercValue2 := mload(add(data, 100)) // amount
        }
        console.log(" to: ", ercTo2);
        console.log(" value: ", ercValue2);
    }
}
