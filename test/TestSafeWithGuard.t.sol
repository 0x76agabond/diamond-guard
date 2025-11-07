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
import {GuardFacet} from "../../src/guardFacet/implementFacet/GuardFacet.sol";
import {GuardSettingFacet} from "../../src/guardFacet/settingFacet/GuardSettingFacet.sol";

import {IGuardFacet, tGuardFacet} from "./tContract/Implement/tGuardFacet.sol";
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
    GuardFacet guardFacet;
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
            console.log(CutUtil.cutHelper(diamond, new tGuardFacet(), ""));

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
    //                      TEST: GuardSettingFacet CRUD
    // =======================================================================
    function test_CRUD() public {
        console.log("=================================");
        console.log("Check Init Setting");

        // Attach GuardSettingFacet interface to Diamond
        vm.startPrank(ks.addrs[4]);
        IGuardSettingFacet setting = IGuardSettingFacet(address(diamond));

        {
            // Verify initial settings after init()
            bool activated = setting.getActivatedStatus();
            bool moduleCheck = setting.getModuleCheckActivated();
            bool whitelistEnabled = setting.getWhitelistEnabled();

            console.log("GuardSettingFacet activated:", activated);
            console.log("ModuleCheckActivated:", moduleCheck);
            console.log("WhitelistEnabled:", whitelistEnabled);

            assertTrue(activated, "Guard should be activated after init");
            assertTrue(moduleCheck, "Module check should be active after init");
            assertFalse(whitelistEnabled, "Whitelist should be disabled by default");
            vm.stopPrank();
        }

        // Enforce owner-only access control
        console.log("=================================");
        console.log("Check Ownership Enforcement");

        {
            // Expect revert when called by non-owner
            vm.startPrank(ks.addrs[1]);
            try setting.setDelegateCallAllowed(true) {
                fail("Non-owner was able to set delegate call allowed");
            } catch Error(string memory reason) {
                console.log("Expected revert caught:", reason);
            }
            vm.stopPrank();
        }

        // Owner modifies Guard settings
        console.log("=================================");
        console.log("Check Owner CRUD ");

        vm.startPrank(ks.addrs[4]);
        setting.setDelegateCallAllowed(true);
        setting.setWhitelistEnabled(true);
        setting.setEnforceExecutor(true);

        assertTrue(setting.getDelegateCallAllowed(), "DelegateCallAllowed should be true");
        console.log("DelegateCallAllowed set to:", setting.getDelegateCallAllowed());

        assertTrue(setting.getWhitelistEnabled(), "Whitelist should be true");
        console.log("WhitelistEnabled set to:", setting.getWhitelistEnabled());

        assertTrue(setting.getEnforceExecutor(), "EnforceExecutor should be true");
        console.log("EnforceExecutor set to:", setting.getEnforceExecutor());

        // Toggle whitelist and verify
        console.log("=================================");
        console.log("Check Whitelist Toggle ");

        setting.setWhitelist(address(safeWallet), address(token), true);
        bool isWhitelisted = setting.isWhitelisted(address(safeWallet), address(token));
        assertTrue(isWhitelisted, "Token address should be whitelisted");
        console.log("Token is whitelisted for safeWallet:", isWhitelisted);

        // Flip delegatecall flag back to false
        setting.setDelegateCallAllowed(false);
        assertFalse(setting.getDelegateCallAllowed(), "DelegateCallAllowed should be false after toggle");
        console.log("DelegateCallAllowed set to:", setting.getDelegateCallAllowed());

        vm.stopPrank();
        console.log("GuardSettingFacet CRUD test passed.");
    }

    // =======================================================================
    //                  HELPER: Setup whitelist and guard
    // =======================================================================
    function setup_whitelist_test() public {
        IGuardSettingFacet setting = IGuardSettingFacet(address(diamond));

        // Display current Guard configuration
        console.log("================================= ");
        console.log("Check Current Setting ");
        console.log("is Guard activated", setting.getActivatedStatus());
        console.log("is Module Guard activated", setting.getModuleCheckActivated());
        console.log("is whitelist require", setting.getWhitelistEnabled());

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
    //                      TEST: Whitelist fail path
    // =======================================================================
    function test_whitelist_fail_path() public {
        // Setup environment: Guard + whitelist enabled
        vm.startPrank(ks.addrs[4]);
        setup_whitelist_test();

        // Explicitly remove token from whitelist
        IGuardSettingFacet setting = IGuardSettingFacet(address(diamond));
        setting.setWhitelist(address(safeWallet), address(token), false);
        console.log("is Token whitelisted", setting.isWhitelisted(address(safeWallet), address(token)));
        vm.stopPrank();

        // Generate Safe transaction and valid signatures
        vm.startPrank(ks.addrs[0]);
        bytes32 txHash = Transaction.getTransactionHash(
            address(safeWallet),
            address(token),
            0,
            abi.encodeWithSelector(token.transfer.selector, ks.addrs[4], 1e18),
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            address(0),
            safeWallet.nonce()
        );

        bytes memory sig1 = generateSignature(txHash, ks.keys[1]);
        bytes memory sig2 = generateSignature(txHash, ks.keys[2]);
        bytes memory sigs = bytes.concat(sig1, sig2);

        // Execute Safe transaction and expect revert from GuardFacet
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
            console.log("Test fail, token wasn't added:", success);
        } catch Error(string memory reason) {
            console.log("Transaction failed as expected due to whitelist restriction:", reason);
        } catch (bytes memory bytes_reason) {
            console.log("Transaction reverted as expected with custom error");
            console.logBytes(bytes_reason);
        }

        vm.stopPrank();
    }

    // =======================================================================
    //                      TEST: Whitelist success path
    // =======================================================================
    function test_whitelist_success_path() public {
        // Setup environment: Guard + whitelist enabled
        vm.startPrank(ks.addrs[4]);
        setup_whitelist_test();

        // Add token to whitelist
        IGuardSettingFacet setting = IGuardSettingFacet(address(diamond));
        setting.setWhitelist(address(safeWallet), address(token), true);
        console.log("is Token whitelisted", setting.isWhitelisted(address(safeWallet), address(token)));
        vm.stopPrank();

        // Generate Safe transaction and valid signatures
        vm.startPrank(ks.addrs[0]);
        bytes32 txHash = Transaction.getTransactionHash(
            address(safeWallet),
            address(token),
            0,
            abi.encodeWithSelector(token.transfer.selector, ks.addrs[4], 1e18),
            Enum.Operation.Call,
            0,
            0,
            0,
            address(0),
            address(0),
            safeWallet.nonce()
        );

        bytes memory sig1 = generateSignature(txHash, ks.keys[1]);
        bytes memory sig2 = generateSignature(txHash, ks.keys[2]);
        bytes memory sigs = bytes.concat(sig1, sig2);

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

        vm.stopPrank();
    }
}
