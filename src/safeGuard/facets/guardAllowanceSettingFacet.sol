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
 * When used together with the whitelist, the Allowance mechanism creates
 * an additional layer of protection.
 *
 * Each wallet that registers a Guard is required to register its own Allowance.
 * This Allowance is used to limit the maximum transfer amount and/or the maximum
 * number of transactions a wallet can perform per day.
 *
 * The allowance values are expected to be relatively small and are primarily
 * intended for routine, low-value daily transactions.
 *
 * When a wallet needs to perform a transaction that exceeds its allowance,
 * it must rely on the whitelist mechanism, depending on the asset type:
 * - For ETH transfers, the recipient address ("to") must be whitelisted.
 * - For token transfers, both the token address and the recipient address ("to")
 *   must be whitelisted.
 *
 * Since this feature interacts with multiple domains and sub-domains,
 * getter and setter functions are used to improve clarity and maintainability.
 */

contract GuardAllowanceSettingFacet {}
