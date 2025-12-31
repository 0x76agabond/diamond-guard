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

library LibContext {
    // EIP-1153
    // Storage slots for context data
    bytes32 internal constant SLOT_NONCE = keccak256("vag.context.nonce");
    bytes32 internal constant SLOT_TXHASH = keccak256("vag.context.txhash");
    bytes32 internal constant SLOT_TX_TYPE = keccak256("vag.context.txtype");

    // Safe workflow
    // checkTransaction (Guard) => executeTransaction (Safe) => checkAfterExecution (Guard)
    // We need to store some context data between these calls
    // On checkTransaction, we get nonce and txHash and store them in specific storage slots
    // On checkAfterExecution, we retrieve these data from storage slots for further use

    // Getters
    function getNonce() internal view returns (uint256 v) {
        bytes32 position = SLOT_NONCE;
        assembly {
            v := tload(position)
        }
    }

    function getTxHash() internal view returns (bytes32 v) {
        bytes32 position = SLOT_TXHASH;
        assembly {
            v := tload(position)
        }
    }

    // 0 = normal tx
    // 1 = module tx
    function getTxType() internal view returns (uint256 v) {
        bytes32 position = SLOT_TX_TYPE;
        assembly {
            v := tload(position)
        }
    }

    //  Setters
    function setNonce(uint256 v) internal {
        bytes32 position = SLOT_NONCE;
        assembly {
            tstore(position, v)
        }
    }

    function setTxHash(bytes32 v) internal {
        bytes32 position = SLOT_TXHASH;
        assembly {
            tstore(position, v)
        }
    }

    function setTxType(uint256 v) internal {
        bytes32 position = SLOT_TX_TYPE;
        assembly {
            tstore(position, v)
        }
    }
}
