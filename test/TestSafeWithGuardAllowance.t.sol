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

contract TestSafeWithGuard is TestManager {
    // =======================================================================
    //                         CORE TEST VARIABLES
    // =======================================================================
    // KeySet includes private keys and corresponding addresses
    KeySet ks;

    // Mock BEP20 token used for transfer simulation
    BEP20Token token;

    // Mock Gnosis Safe wallet for testing
    NotSafe safeWallet;

    // Diamond system and facets under test
    Diamond diamond;
    GuardFacetAllowance guardFacet;
    GuardSettingFacet guardSettingFacet;

    // =======================================================================
    //                              SETUP
    // =======================================================================
    function setUp() public {
        // Create a fork from opBNB for reproducibility
        vm.createSelectFork(vm.rpcUrl("opbnb"));

        // Generate key set (5 owners, deterministic)
        ks = ownerSummoner(5, "seed");

        // Deploy test token under owner[4]
        vm.startPrank(ks.addrs[4]);
        token = new BEP20Token();

        // Deploy NotSafe (mock Gnosis Safe)
        safeWallet = new NotSafe();

        // Deploy Diamond and attach facets
        {
            DiamondCutFacet cutFacet = new DiamondCutFacet();
            diamond = new Diamond(address(ks.addrs[4]), address(cutFacet));

            // Attach loupe facet for introspection
            console.log(CutUtil.cutHelper(diamond, new tDiamondLoupe(), ""));

            // Attach GuardFacet
            console.log(CutUtil.cutHelper(diamond, new tGuardFacetAllowance(), ""));

            // Attach GuardSettingFacet and run init()
            CutUtil.cutHelper(
                diamond, new tGuardSettingFacet(), abi.encodeWithSelector(IGuardSettingFacet.init.selector)
            );
        }

        // Configure Safe owners and threshold
        {
            address[] memory owners1 = new address[](3);
            for (uint256 i = 0; i < 3; i++) {
                owners1[i] = ks.addrs[i];
            }
            safeWallet.setOwnersAndThreshold(owners1, 2);
        }

        // Display Safe setup result
        {
            console.log(" ================================= ");
            console.log("threshold:", safeWallet.threshold());
            address[] memory list1 = safeWallet.getOwners();
            for (uint256 i = 0; i < list1.length; i++) {
                console.log("Owner:", list1[i]);
            }

            console.log(" ================================= ");

            // Fund Safe with test tokens for later transfer tests
            vm.startPrank(ks.addrs[4]);
            token.transfer(address(safeWallet), 1e19);
            console.log("Balance of safeWallet: ", token.balanceOf(address(safeWallet)));
        }
    }

    // =======================================================================
    //                  HELPER: Setup whitelist and guard
    // =======================================================================
    function setup_whitelist_test() public {
        IGuardSettingFacet setting = IGuardSettingFacet(address(diamond));

        // Enable whitelist requirement
        console.log("================================= ");
        console.log("Setup Whitelist ");
        setting.setWhitelistEnabled(true);
        console.log("is whitelist require", setting.getWhitelistEnabled());

        // Attach GuardFacet to Safe
        console.log("================================= ");
        console.log("Setup Guard ");
        safeWallet.setGuard(address(diamond));
        console.log("Guard Address: ", safeWallet.guardAddress());
    }

    // =======================================================================
    //                      TEST: Whitelist success path
    // =======================================================================
    function test_whitelist_allowance() public {
        // Setup environment: Guard + whitelist enabled
        vm.startPrank(ks.addrs[4]);
        setup_whitelist_test();

        // turn off activate signature to focus on allowance test
        safeWallet.changeActivateSignature(false);

        // setup allowance
        IGuardSettingFacet setting = IGuardSettingFacet(address(diamond));
        setting.setDailyAllowance(address(safeWallet), 1, 5e18); // 2 txs, 5 tokens per day

        // Generate Safe transaction and valid signatures
        vm.startPrank(ks.addrs[0]);

        bytes memory sigs = "";
        // Execute Safe transaction and expect success
        try safeWallet.execTransaction(
            address(token),
            0,
            abi.encodeWithSelector(token.transfer.selector, ks.addrs[4], 1e18),
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            payable(address(0)),
            sigs
        ) returns (
            bool success
        ) {
            console.log("Transaction success as expected:", success);
        } catch Error(string memory reason) {
            console.log("Transaction failed:", reason);
        }

        // Execute Safe transaction and expect failure (1 txs per day)
        try safeWallet.execTransaction(
            address(token),
            0,
            abi.encodeWithSelector(token.transfer.selector, ks.addrs[4], 1e18),
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            payable(address(0)),
            sigs
        ) returns (
            bool success
        ) {
            console.log("Transaction unexpected success", success);
        } catch {
            console.log("Transaction failed as expected");
        }

        // add target to whitelist
        console.log("=============================");
        console.log("add target to whitelist");
        vm.startPrank(ks.addrs[4]);
        setting.setWhitelist(address(safeWallet), ks.addrs[4], true);
        console.log(ks.addrs[4]);
        console.log("is whitelisted:", setting.isWhitelisted(address(safeWallet), ks.addrs[4]));
        console.log("=============================");

        // Execute Safe transaction and expect success
        vm.startPrank(ks.addrs[0]);
        try safeWallet.execTransaction(
            address(token),
            0,
            abi.encodeWithSelector(token.transfer.selector, ks.addrs[4], 1e18),
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            payable(address(0)),
            sigs
        ) returns (
            bool success
        ) {
            console.log("Transaction success as expected:", success);
        } catch {
            console.log("Transaction failed");
        }

        // Execute Safe transaction and expect fail (whitelist reset)
        vm.startPrank(ks.addrs[0]);
        try safeWallet.execTransaction(
            address(token),
            0,
            abi.encodeWithSelector(token.transfer.selector, ks.addrs[4], 1e18),
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            payable(address(0)),
            sigs
        ) returns (
            bool success
        ) {
            console.log("Transaction success", success);
        } catch {
            console.log("Transaction failed as expected");
        }

        vm.stopPrank();
    }
}
