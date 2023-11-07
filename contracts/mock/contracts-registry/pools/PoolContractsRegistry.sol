// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ContractsRegistryPool} from "./ContractsRegistryPool.sol";

import {OwnablePoolContractsRegistry} from "../../../contracts-registry/pools/presets/OwnablePoolContractsRegistry.sol";

contract PoolContractsRegistry is OwnablePoolContractsRegistry {
    string public constant POOL_1_NAME = "POOL_1";
    string public constant POOL_2_NAME = "POOL_2";

    address internal _poolFactory;

    modifier onlyPoolFactory() {
        require(_poolFactory == msg.sender, "PoolContractsRegistry: not a factory");
        _;
    }

    function mockInit() external {
        __PoolContractsRegistry_init();
    }

    function setDependencies(address contractsRegistry_, bytes memory data_) public override {
        super.setDependencies(contractsRegistry_, data_);

        _poolFactory = ContractsRegistryPool(contractsRegistry_).getPoolFactoryContract();
    }

    function addProxyPool(
        string calldata name_,
        address poolAddress_
    ) external override onlyPoolFactory {
        _addProxyPool(name_, poolAddress_);
    }
}
