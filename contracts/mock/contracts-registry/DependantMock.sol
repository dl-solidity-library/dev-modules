// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {ADependant} from "../../contracts-registry/ADependant.sol";

import {ContractsRegistryMock} from "./ContractsRegistryMock.sol";

contract DependantMock is ADependant {
    address public token;

    function setDependencies(address contractsRegistry_, bytes memory) public override dependant {
        token = ContractsRegistryMock(contractsRegistry_).getTokenContract();
    }
}
