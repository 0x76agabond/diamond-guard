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
 * Safe transaction execution flow:
 * ---------------------------------------------------------------------------
 * checkTransaction (Guard) -> executeTransaction (Safe) -> checkAfterExecution (Guard)
 * ---------------------------------------------------------------------------
 *
 * Some transaction context data must be shared between these calls.
 *
 * During `checkTransaction`, values such as `nonce` and `txHash` are extracted
 * and stored in dedicated storage slots.
 *
 * During `checkAfterExecution`, the same values are retrieved from those slots
 * for post-execution validation or accounting.
 *
 * Since all of these calls occur within the same transaction,
 * EIP-1153 transient storage is used to hold this context and is automatically
 * cleared at the end of the transaction.
 */

/**
 * @dev
 * Storage slots used for transaction context.
 *
 * Since transaction context data should not be persisted across transactions,
 * this contract uses ERC-8110 storage identifiers to define isolated context domains.
 *
 * Transient storage does not work reliably with structs, so each context value
 * is stored in an individual storage slot.
 *
 * Context fields such as `nonce`, `txHash`, and `transactionType` belong to the
 * `context` domain and therefore use sub-domain identifiers.
 *
 * ERC-8110 Storage Identifiers
 * ---------------------------------------------------------------------------
 *   {org}.{project}.{domain-type}.{domain}.{version}
 *
 * ERC-8110 Sub-Domain Identifiers
 * ---------------------------------------------------------------------------
 *   {org}.{project}.{domain-type}.{domain}.{version}.{sub-domain}
 */

/**
 * @dev Storage identifier format:
 * ---------------------------------------------------------------------------
 * {org}.{project}.{domain-type}.{domain}.{version}.{sub-domain}
 *
 * Minimal format:
 * ---------------------------------------------------------------------------
 * {project}.{domain}.{version}.{sub-domain}
 *
 * Example (minimal):
 * project.context.v1.nonce
 *
 * @custom:storage-location erc8042:org.project.business.context.v1.nonce
 */

bytes32 constant SLOT_NONCE = keccak256("org.project.business.context.v1.nonce");

function getNonce() view returns (uint256 v) {
    bytes32 position = SLOT_NONCE;
    assembly {
        v := tload(position)
    }
}

function setNonce(uint256 nonce) {
    bytes32 position = SLOT_NONCE;
    assembly {
        tstore(position, nonce)
    }
}

/**
 * @dev
 * Example (minimal):
 * project.context.v1.txhash
 * ---------------------------------
 * @custom:storage-location erc8042:org.project.business.context.v1.txhash
 */

bytes32 constant SLOT_TX_HASH = keccak256("org.project.business.context.v1.txhash");

function getTxHash() view returns (bytes32 v) {
    bytes32 position = SLOT_TX_HASH;
    assembly {
        v := tload(position)
    }
}

function setTxHash(bytes32 txHash) {
    bytes32 position = SLOT_TX_HASH;
    assembly {
        tstore(position, txHash)
    }
}

/**
 * @dev
 * A Safe supports two types of transactions: regular transactions and module transactions.
 *
 * Regular transactions:
 * - Initiated by an externally owned account (EOA)
 * - Require a sufficient number of owner signatures to meet the threshold
 *
 * Module transactions:
 * - Initiated by an enabled module
 * - Do not require owner signatures
 */

enum transactionType {
    NORMAL,
    MODULE
}

/**
 * @dev Example (minimal):
 * project.context.v1.txtype
 * ---------------------------------
 * @custom:storage-location erc8042:org.project.business.context.v1.txtype
 */

bytes32 constant SLOT_TX_TYPE = keccak256("org.project.business.context.v1.txtype");

function getTxType() view returns (transactionType txType) {
    bytes32 position = SLOT_TX_TYPE;
    assembly {
        txType := tload(position)
    }
}

function setTxType(transactionType txType) {
    bytes32 position = SLOT_TX_TYPE;
    assembly {
        tstore(position, txType)
    }
}

