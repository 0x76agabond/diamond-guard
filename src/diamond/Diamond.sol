// SPDX-License-Identifier: MIT
pragma solidity >=0.8.30;

/* Compose
 * https://compose.diamonds
 */

import "./DiamondMod.sol" as DiamondMod;
import "../access/Owner/OwnerMod.sol" as OwnerMod;

contract Diamond {
    /**
     * @notice Initializes the diamond contract with facets, owner and other data.
     * @dev Adds all provided facets to the diamond's function selector mapping and sets the contract owner.
     *      Each facet in the array will have its function selectors registered to enable delegatecall routing.
     * @param _facets Array of facet addresses and their corresponding function selectors to add to the diamond.
     * @param _diamondOwner Address that will be set as the owner of the diamond contract.
     */
    constructor(address[] memory _facets, address _diamondOwner) {
        DiamondMod.addFacets(_facets);

        /*************************************
         * Initialize storage variables
         ************************************/

        /**
         * Setting the contract owner
         */
        OwnerMod.setContractOwner(_diamondOwner);
    }

    fallback() external payable {
        DiamondMod.diamondFallback();
    }

    receive() external payable {}
}
