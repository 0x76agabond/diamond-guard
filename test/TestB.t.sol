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

import "../src/interfaces/ISafe.sol" as SafeInterface;

import "../src/walletAllowance/modules/walletEvent.sol";
import "../src/walletAllowance/modules/walletAllowanceMod.sol" as WalletAllowanceMod;

import "../src/safeGuard/modules/safeGuardEvent.sol";
import "../src/safeGuard/modules/safeGuardMod.sol" as SafeGuardMod;

import "../src/txContext/modules/txContextMod.sol" as txContextMod;
import {SafeOperation} from "../src/safe/safeHandlerMod.sol";

contract TestB is TestManager {
    address safe_address = address(0x123);

    function setUp() public {}

    function test_check_transaction(
        address to,
        uint256 value,
        bytes memory data,
        SafeOperation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory,
        /*signatures*/
        address /*executor*/
    ) public {
        bytes32 txHash;
        uint256 nonce;
        
    }

    function checkTransactionInner(
        address to,
        uint256 value,
        bytes memory data,
        SafeOperation operation,
        uint256 nonce,
        bytes32 txHash
    ) internal {
       

        
    }
}

