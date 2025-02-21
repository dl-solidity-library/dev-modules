// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {APermanentOwnable} from "../../access/APermanentOwnable.sol";
import {IAdminableProxy} from "./AdminableProxy.sol";

/**
 * @notice The proxies module
 *
 * This is the lightweight helper contract that may be used as a AdminableProxy admin.
 */
contract AdminableProxyUpgrader is APermanentOwnable {
    constructor() APermanentOwnable(msg.sender) {}

    /**
     * @notice The function to upgrade the implementation contract
     * @dev an attempt to upgrade a non-proxy contract will result in revert
     * @param what_ the proxy contract to upgrade
     * @param to_ the new implementation contract
     * @param data_ arbitrary data the proxy will be called with after the upgrade
     */
    function upgrade(address what_, address to_, bytes calldata data_) external virtual onlyOwner {
        IAdminableProxy(payable(what_)).upgradeToAndCall(to_, data_);
    }

    /**
     * @notice The function to get the address of the proxy implementation
     * @dev an attempt to get implementation from a non-proxy contract will result in revert
     * @param what_ the proxy contract to observe
     * @return the implementation address
     */
    function getImplementation(address what_) public view virtual returns (address) {
        return IAdminableProxy(what_).implementation();
    }
}
