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
 *   Provides initialization, getter, and setter functions for Guard state
 *   management. Compatible with Diamond Standard (EIP-2535) ownership control.
 * ===========================================================================
 */

interface IGuardSettingFacet {
    // =========================================================
    //                        EVENTS
    // =========================================================

    event ModuleLockedStatusChanged(bool locked);
    event ActivatedStatusChanged(bool activated);
    event ModuleCheckActivatedChanged(bool activated);
    event EnforceExecutorChanged(bool enforced);
    event DelegateCallAllowedChanged(bool allowed);
    event ModuleDelegateCallAllowedChanged(bool allowed);
    event WhitelistStatusChanged(bool enabled);
    event WhitelistUpdated(address indexed safe, address indexed target, bool enabled);

    // =========================================================
    //                      INITIALIZER
    // =========================================================

    /**
     * @notice Initializes the Guard settings.
     * @dev Can only be called once by the Diamond owner.
     *      Sets default configuration values for GuardFacet.
     *      Reverts if already initialized.
     */
    function init() external;

    // =========================================================
    //                       GETTERS
    // =========================================================

    function getModuleLockedStatus() external view returns (bool);
    function getActivatedStatus() external view returns (bool);
    function getModuleCheckActivated() external view returns (bool);
    function getEnforceExecutor() external view returns (bool);
    function getDelegateCallAllowed() external view returns (bool);
    function getModuleDelegateCallAllowed() external view returns (bool);
    function getWhitelistEnabled() external view returns (bool);
    function isWhitelisted(address safe, address target) external view returns (bool);

    // =========================================================
    //                       SETTERS
    // =========================================================

    function setModuleLockedStatus(bool locked) external;
    function setActivatedStatus(bool activated) external;
    function setModuleCheckActivated(bool activated) external;
    function setEnforceExecutor(bool enforced) external;
    function setDelegateCallAllowed(bool allowed) external;
    function setModuleDelegateCallAllowed(bool allowed) external;
    function setWhitelistEnabled(bool enabled) external;
    function setWhitelist(address safe, address target, bool enabled) external;
}
