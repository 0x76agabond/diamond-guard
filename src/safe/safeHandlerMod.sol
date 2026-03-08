pragma solidity >=0.8.30;
// SPDX-License-Identifier: MIT

/*
 * ===========================================================================
 * Author: Hoang (0x76agabond)
 * ===========================================================================
 * Diamond Guard - Diamond as Gnosis Safe Guard
 * ===========================================================================
 */

/**
 * @dev
 * Util functions and types for Safe Guard module
 * Compatible with Safe v1.4.1
 */

// =========================================================
//                      TX_HASH Helper
// =========================================================

// keccak256("SafeMessage(bytes message)");
bytes32 constant SAFE_TX_TYPEHASH = 0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8;

enum SafeOperation {
    Call,
    DelegateCall
}

/**
 * @dev
 * EIP-712 domain separator typehash used by Safe.
 *
 * Safe uses the following domain definition:
 * EIP712Domain(uint256 chainId,address verifyingContract)
 *
 * The corresponding typehash is:
 * keccak256("EIP712Domain(uint256 chainId,address verifyingContract)")
 *
 * This implementation mirrors Safe's internal domain separator logic.
 */
bytes32 constant SAFE_DOMAIN_SEPARATOR_TYPEHASH = keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");

function domainSeparator(address walletAddress) view returns (bytes32 sep) {
    uint256 chainId;
    bytes32 domainTypeHash = SAFE_DOMAIN_SEPARATOR_TYPEHASH;
    assembly ("memory-safe") {
        chainId := chainid()
        let ptr := mload(0x40)
        mstore(ptr, domainTypeHash)
        mstore(add(ptr, 0x20), chainId)
        mstore(add(ptr, 0x40), walletAddress)
        sep := keccak256(ptr, 0x60)
    }
}

/**
 * @dev
 * Computes the hash of a module transaction following Safe's internal
 * transaction hashing logic.
 *
 * moduleTxHash = keccak256(abi.encodePacked(to, value, data, operation, module))
 *
 * @param to The target address of the transaction
 * @param value The ETH value sent with the transaction
 * @param data The calldata executed by the transaction
 * @param operation The Safe operation type (CALL or DELEGATECALL)
 * @param module The module address initiating the transaction
 * @return moduleTxHash The computed module transaction hash
 */
function getModuleTransactionHash(address to, uint256 value, bytes memory data, SafeOperation operation, address module)
    pure
    returns (bytes32 moduleTxHash)
{
    moduleTxHash = keccak256(abi.encodePacked(to, value, data, operation, module));
}

/**
 * @dev
 * Computes the Safe transaction hash following Safe's internal
 * EIP-712 transaction hashing logic.
 *
 * The hash is constructed as:
 * keccak256(0x1901 || domainSeparator || keccak256(SafeTx))
 *
 * @param walletAddress The Safe wallet address acting as the EIP-712 verifying contract
 * @param to The target address of the transaction
 * @param value The ETH value sent with the transaction
 * @param data The calldata executed by the transaction
 * @param operation The Safe operation type (CALL or DELEGATECALL)
 * @param safeTxGas The gas limit for the Safe transaction execution
 * @param baseGas The gas costs not related to execution (e.g. signature checks)
 * @param gasPrice The gas price used for refund calculation
 * @param gasToken The token address used to pay gas refunds (zero address for ETH)
 * @param refundReceiver The address receiving the gas refund
 * @param _nonce The Safe transaction nonce
 * @return txHash The computed Safe transaction hash
 */
function getTransactionHash(
    address walletAddress,
    address to,
    uint256 value,
    bytes calldata data,
    SafeOperation operation,
    uint256 safeTxGas,
    uint256 baseGas,
    uint256 gasPrice,
    address gasToken,
    address refundReceiver,
    uint256 _nonce
) view returns (bytes32 txHash) {
    bytes32 domainHash = domainSeparator(walletAddress);
    bytes32 txTypeHash = SAFE_TX_TYPEHASH;
    assembly ("memory-safe") {
        // Get the free memory pointer
        let ptr := mload(0x40)
        // Step 1: Hash the transaction data
        // Copy transaction data to memory and hash it
        calldatacopy(ptr, data.offset, data.length)
        let calldataHash := keccak256(ptr, data.length)
        // Step 2: Prepare the SafeTX struct for hashing
        // Layout in memory:
        // ptr +   0: SAFE_TX_TYPEHASH (constant defining the struct hash)
        // ptr +  32: to address
        // ptr +  64: value
        // ptr +  96: calldataHash
        // ptr + 128: operation
        // ptr + 160: safeTxGas
        // ptr + 192: baseGas
        // ptr + 224: gasPrice
        // ptr + 256: gasToken
        // ptr + 288: refundReceiver
        // ptr + 320: nonce
        mstore(ptr, txTypeHash)
        mstore(add(ptr, 32), to)
        mstore(add(ptr, 64), value)
        mstore(add(ptr, 96), calldataHash)
        mstore(add(ptr, 128), operation)
        mstore(add(ptr, 160), safeTxGas)
        mstore(add(ptr, 192), baseGas)
        mstore(add(ptr, 224), gasPrice)
        mstore(add(ptr, 256), gasToken)
        mstore(add(ptr, 288), refundReceiver)
        mstore(add(ptr, 320), _nonce)
        // Step 3: Calculate the final EIP-712 hash
        // First, hash the SafeTX struct (352 bytes total length)
        mstore(add(ptr, 64), keccak256(ptr, 352))
        // Store the EIP-712 prefix (0x1901), note that integers are left-padded
        // so the EIP-712 encoded data starts at add(ptr, 30)
        mstore(ptr, 0x1901)
        // Store the domain separator
        mstore(add(ptr, 32), domainHash)
        // Calculate the hash
        txHash := keccak256(add(ptr, 30), 66)
    }
    return txHash;
}

// =========================================================
//                      Signature Helper
// =========================================================

uint256 constant SIGNATURE_SIZE = 0x41; // 65 bytes

// check if at least there are one signature
function validateSignatures(bytes memory signatures) pure {
    require(signatures.length > 0, "No signatures");
    require(signatures.length % SIGNATURE_SIZE == 0, "Invalid signature format");
}

//Decodes signatures encoded as bytes, loop byte signature size
function signatureSplit(bytes memory signatures, uint256 pos) pure returns (uint8 v, bytes32 r, bytes32 s) {
    assembly {
        r := mload(add(signatures, add(pos, 0x20)))
        s := mload(add(signatures, add(pos, 0x40)))
        v := byte(0, mload(add(signatures, add(pos, 0x60))))
    }
}

// recover signer from signature
// Safe will send verified signature here
// So we want to recover the signer address from signature
function recoverSigner(bytes32 hash, uint8 v, bytes32 r, bytes32 s) pure returns (address signer) {
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

error InvalidOwner(address signer);

function recoverSignerAccount(bytes32 txHash, bytes memory signatures, address target) pure returns (bool) {
    validateSignatures(signatures);
    // Loop over each signature and recover signer
    for (uint256 i = 0; i < signatures.length; i += SIGNATURE_SIZE) {
        (uint8 v, bytes32 r, bytes32 s_) = signatureSplit(signatures, i);
        address recovered = recoverSigner(txHash, v, r, s_);

        if (recovered == address(0)) {
            revert InvalidOwner(target);
        }

        if (recovered == target) {
            return true;
        }
    }
    return false;
}
