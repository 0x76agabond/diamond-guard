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

library LibSignatureHandler {
    uint256 internal constant SIGNATURE_SIZE = 0x41; // 65 bytes

    // check if at least there are one signature
    function validateSignatures(bytes memory signatures) internal pure {
        require(signatures.length > 0, "No signatures");
        require(signatures.length % SIGNATURE_SIZE == 0, "Invalid signature format");
    }

    //Decodes signatures encoded as bytes, loop byte signature size
    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        assembly {
            r := mload(add(signatures, add(pos, 0x20)))
            s := mload(add(signatures, add(pos, 0x40)))
            v := byte(0, mload(add(signatures, add(pos, 0x60))))
        }
    }

    // recover signer from signature
    // Safe will send verified signature here
    // So we want to recover the signer address from signature
    function recoverSigner(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address signer) {
        if (v == 1 || v == 0) {
            // If v is 1 then it is an approved hash
            // When handling approved hashes the address of the approver is encoded into r
            // If v is 0 then it is a contract signature (1271)
            // When handling approved hashes the address of the approver is also encoded into r
            signer = address(uint160(uint256(r)));
        } else if (v > 30) {
            // If v > 30 then default va (27,28) has been adjusted for eth_sign flow
            // To support eth_sign and similar we adjust v and hash the messageHash with the Ethereum message prefix before applying ecrecover
            bytes32 signed;
            assembly {
                // Store prefix "\x19Ethereum Signed Message:\n32"
                mstore(0x00, 0x19457468657265756d2053696764204d6573736167653a0a3332)
                mstore(0x1c, hash)
                signed := keccak256(0x00, 0x3c)
            }
            signer = ecrecover(signed, v - 4, r, s);
        } else {
            // Standard EOA
            signer = ecrecover(hash, v, r, s);
        }
    }

    function recoverSignerAccount(bytes32 txHash, bytes memory signatures, address target)
        internal
        pure
        returns (bool)
    {
        validateSignatures(signatures);

        // Loop over each signature and recover signer
        for (uint256 i = 0; i < signatures.length; i += SIGNATURE_SIZE) {
            (uint8 v, bytes32 r, bytes32 s_) = signatureSplit(signatures, i);
            address recovered = recoverSigner(txHash, v, r, s_);
            require(recovered != address(0), "Invalid Owner");

            if (recovered == target) {
                return true;
            }
        }

        return false;
    }
}
