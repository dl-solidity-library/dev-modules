// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {ADependant} from "../../../contracts-registry/ADependant.sol";

import {ContractsRegistryPoolMock} from "./ContractsRegistryPoolMock.sol";

contract PoolMock is ADependant {
    address public token;

    function setDependencies(address contractsRegistry_, bytes memory) public override dependant {
        token = ContractsRegistryPoolMock(contractsRegistry_).getTokenContract();
    }
}
