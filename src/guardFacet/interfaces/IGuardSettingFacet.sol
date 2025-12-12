pragma solidity >=0.8.30;
// SPDX-License-Identifier: MIT

/*
 * ===========================================================================
 * Author: Hoang <ginz1504@gmail.com>
 * Contact: https://github.com/0x76agabond
 * ===========================================================================
 * Interface: IGuardSettingFacet
 * Description:
 *   Diamond Guard Setting Facet interface for managing runtime configuration.
 *   Provides initialization, getter, whitelist, and allowance configuration.
 *   Compatible with Diamond Standard (EIP-2535) ownership control.
 * ===========================================================================
 */

interface IGuardSettingFacet {
    // =========================================================
    //                        EVENTS
    // =========================================================

    event LockedStatusChanged(bool locked);
    event ModuleLockedStatusChanged(bool locked);
    event ActivatedStatusChanged(bool activated);
    event ModuleCheckActivatedChanged(bool activated);
    event EnforceExecutorChanged(bool enforced);
    event DelegateCallAllowedChanged(bool allowed);
    event ModuleDelegateCallAllowedChanged(bool allowed);
    event WhitelistStatusChanged(bool enabled);
    event WhitelistUpdated(address indexed safe, address indexed target, bool enabled);

    // Allowance-related events
    event DailyAmountLimitChanged(address indexed safe, uint128 limit);
    event DailyTxLimitChanged(address indexed safe, uint64 limit);
    event DailyAllowanceUpdated(address indexed safe, uint64 txLimit, uint128 amountLimit);

    // =========================================================
    //                      INITIALIZER
    // =========================================================

    /**
     * @notice Initializes the Guard settings.
     * @dev Can be called only once by diamond owner.
     */
    function init() external;

    // =========================================================
    //                       GETTERS
    // =========================================================

    function getLockedStatus() external view returns (bool);
    function getModuleLockedStatus() external view returns (bool);
    function getActivatedStatus() external view returns (bool);
    function getModuleCheckActivated() external view returns (bool);
    function getEnforceExecutor() external view returns (bool);
    function getDelegateCallAllowed() external view returns (bool);
    function getModuleDelegateCallAllowed() external view returns (bool);

    // Whitelist
    function getWhitelistEnabled() external view returns (bool);
    function isWhitelisted(address safe, address target) external view returns (bool);

    // Allowance getter
    function getAllowance(address safe)
        external
        view
        returns (uint64 date, uint64 txDate, uint64 txCount, uint64 txLimit, uint128 spent, uint128 amountLimit);

    // =========================================================
    //                       SETTERS
    // =========================================================

    // Core switches
    function setLockedStatus(bool locked) external;
    function setModuleLockedStatus(bool locked) external;
    function setActivatedStatus(bool activated) external;
    function setModuleCheckActivated(bool activated) external;
    function setEnforceExecutor(bool enforced) external;
    function setDelegateCallAllowed(bool allowed) external;
    function setModuleDelegateCallAllowed(bool allowed) external;

    // Whitelist config
    function setWhitelistEnabled(bool enabled) external;
    function setWhitelist(address safe, address target, bool enabled) external;
    function setWhitelistBatch(address safe, address[] calldata targets, bool enabled) external;

    // Allowance config
    function setDailyAmountLimit(address safe, uint128 limit) external;
    function setDailyTxLimit(address safe, uint64 limit) external;
    function setDailyAllowance(address safe, uint64 txLimit, uint128 amountLimit) external;
}
