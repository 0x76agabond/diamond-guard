// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

// Diamond core
import {Diamond} from "../src/diamond/Diamond.sol";
import {DiamondCutFacet} from "../src/diamond/facet/DiamondCutFacet.sol";

// Cut helper + tFacets
import {tDiamondLoupe} from "../test/tContract/Implement/tDiamondLoupe.sol";
import {IGuardSettingFacet, tGuardSettingFacet} from "../test/tContract/Implement/tGuardSettingFacet.sol";
import {CutUtil} from "../test/tContract/tPrototype.sol";
import {tGuardFacetAllowance} from "../test/tContract/Implement/tGuardFacetAllowance.sol";

contract DeployDiamondGuardScript is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address owner = vm.addr(pk);

        vm.startBroadcast(pk);

        /*
        I do this because I use testnet
        This extremely cost gas so avoid it.

        DiamondCutFacet: 0xFF1f81b302149C6A426A194267997F9518b26312
        Diamond: 0x7B967c855b855e071359eDa1C6D7D691C31697Af
        DiamondLoupe facet: 0x489900c6FC0cae836E91521B3087644A9306ef00
        GuardFacetAllowance facet: 0x37267983a3064c3C09d9dCC82Ed21d8de3b4195F
        GuardSettingFacet attached and init() called
        Diamond Guard deployment finished
        Diamond address: 0x7B967c855b855e071359eDa1C6D7D691C31697Af

        $ forge script script/DeployDiamondGuard.s.sol:DeployDiamondGuardScript     --rpc-url opbnb     --broadcast

         */

        // Deploy DiamondCutFacet
        DiamondCutFacet cutFacet = new DiamondCutFacet();
        console2.log("DiamondCutFacet:", address(cutFacet));

        // Deploy Diamond (owner = owner from PRIVATE_KEY)
        Diamond diamond = new Diamond(owner, address(cutFacet));
        console2.log("Diamond:", address(diamond));

        // Attach loupe facet for introspection
        {
            address facetAddr = CutUtil.cutHelper(diamond, new tDiamondLoupe(), "");
            console2.log("DiamondLoupe facet:", facetAddr);
        }

        // Attach GuardFacetAllowance
        {
            address facetAddr = CutUtil.cutHelper(diamond, new tGuardFacetAllowance(), "");
            console2.log("GuardFacetAllowance facet:", facetAddr);
        }

        // Attach GuardSettingFacet and run init()
        {
            CutUtil.cutHelper(
                diamond, new tGuardSettingFacet(), abi.encodeWithSelector(IGuardSettingFacet.init.selector)
            );
            console2.log("GuardSettingFacet attached and init() called");
        }

        console2.log("Diamond Guard deployment finished");
        console2.log("Diamond address:", address(diamond));

        vm.stopBroadcast();
    }
}
