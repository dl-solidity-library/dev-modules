// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

/**
 * @notice The proxies module
 *
 * The helper BeaconProxy that can be deployed by the factories.
 *
 * Note that the external `implementation()` function is added to the contract to provide compatibility with
 * Etherscan. This means that the implementation contract must not have such a function declared.
 */
contract PublicBeaconProxy is BeaconProxy {
    constructor(address beacon_, bytes memory data_) payable BeaconProxy(beacon_, data_) {}

    /**
     * @notice The function that returns implementation contract this proxy points to
     * @return address the implementation address
     */
    function implementation() public view virtual returns (address) {
        return _implementation();
    }
}
