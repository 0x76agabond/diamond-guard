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

library LibSafeHandler {
    bytes32 internal constant DOMAIN_SEPARATOR_TYPEHASH =
        0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;
    bytes32 internal constant SAFE_TX_TYPEHASH = 0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8;

    enum SafeOperation {
        Call,
        DelegateCall
    }

    // EIP-712 domain separator
    function domainSeparator(address owner) internal view returns (bytes32 sep) {
        uint256 chainId;
        assembly {
            chainId := chainid()

            let ptr := mload(0x40)
            mstore(ptr, DOMAIN_SEPARATOR_TYPEHASH)
            mstore(add(ptr, 0x20), chainId)
            mstore(add(ptr, 0x40), owner)

            sep := keccak256(ptr, 0x60)
        }
    }

    function getModuleTransactionHash(
        address to,
        uint256 value,
        bytes memory data,
        SafeOperation operation,
        address module
    ) internal pure returns (bytes32 moduleTxHash) {
        assembly {
            // Lấy pointer trống (free memory pointer)
            let ptr := mload(0x40)

            mstore(ptr, to) // 0x00..0x20
            mstore(add(ptr, 0x20), value) // 0x20..0x40
            let dataLen := mload(data)
            let dataPtr := add(data, 0x20)

            // copy full bytes array (data)
            for { let i := 0 } lt(i, dataLen) { i := add(i, 0x20) } {
                mstore(add(add(ptr, 0x40), i), mload(add(dataPtr, i)))
            }
            let offsetAfterData := add(add(ptr, 0x40), dataLen)
            mstore(offsetAfterData, operation)
            mstore(add(offsetAfterData, 0x20), module)

            // length = 0x20 (to) + 0x20 (value) + dataLen + 0x20 (operation) + 0x20 (module)
            let totalLen := add(add(add(0x60, dataLen), 0x20), 0x00)
            moduleTxHash := keccak256(ptr, totalLen)
        }
    }

    function getTransactionHash(
        address owner,
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
    ) internal view returns (bytes32 txHash) {
        bytes32 domainHash = domainSeparator(owner);

        assembly {
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
            mstore(ptr, SAFE_TX_TYPEHASH)
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
}
