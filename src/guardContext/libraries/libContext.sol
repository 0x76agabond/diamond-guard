pragma solidity = 0.8.26;
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
    uint256 internal constant SLOT_NONCE = 0;
    uint256 internal constant SLOT_TXHASH = 1;

    // Safe workflow
    // checkTransaction (Guard) => executeTransaction (Safe) => checkAfterExecution (Guard)
    // We need to store some context data between these calls
    // On checkTransaction, we get nonce and txHash and store them in specific storage slots
    // On checkAfterExecution, we retrieve these data from storage slots for further use

    // Getters
    function getNonce() internal view returns (uint256 v) {
        assembly {
            v := tload(SLOT_NONCE)
        }
    }

    function getTxHash() internal view returns (bytes32 v) {
        assembly {
            v := tload(SLOT_TXHASH)
        }
    }

    //  Setters
    function setNonce(uint256 v) internal {
        assembly {
            tstore(SLOT_NONCE, v)
        }
    }

    function setTxHash(bytes32 v) internal {
        assembly {
            tstore(SLOT_TXHASH, v)
        }
    }
}
