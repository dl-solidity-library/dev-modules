// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC1967} from "@openzeppelin/contracts/interfaces/IERC1967.sol";

/**
 * @notice The proxies module
 *
 * Interface for AdminableProxy.
 **/
interface IAdminableProxy is IERC1967 {
    /**
     * @notice The function to upgrade the implementation contract with additional setup call if data is nonempty.
     */
    function upgradeToAndCall(address, bytes calldata) external payable;

    /**
     * @notice The function to return the current implementation address.
     */
    function implementation() external view returns (address);
}
