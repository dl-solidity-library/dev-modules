// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {OwnableContractsRegistry} from "../../../contracts-registry/presets/OwnableContractsRegistry.sol";

contract ContractsRegistryPoolMock is OwnableContractsRegistry {
    string public constant POOL_CONTRACTS_REGISTRY_NAME = "POOL_CONTRACTS_REGISTRY";
    string public constant POOL_FACTORY_NAME = "POOL_FACTORY";
    string public constant TOKEN_NAME = "TOKEN";

    function getPoolContractsRegistryContract() external view returns (address) {
        return getContract(POOL_CONTRACTS_REGISTRY_NAME);
    }

    function getPoolFactoryContract() external view returns (address) {
        return getContract(POOL_FACTORY_NAME);
    }

    function getTokenContract() external view returns (address) {
        return getContract(TOKEN_NAME);
    }
}
