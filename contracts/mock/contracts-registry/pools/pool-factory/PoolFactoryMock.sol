// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {ContractsRegistryPoolMock} from "../ContractsRegistryPoolMock.sol";
import {PoolContractsRegistryMock} from "../PoolContractsRegistryMock.sol";

import {APoolFactory} from "../../../../contracts-registry/pools/pool-factory/APoolFactory.sol";

contract PoolFactoryMock is APoolFactory {
    address public poolContractsRegistry;

    function setDependencies(address contractsRegistry_, bytes memory data_) public override {
        super.setDependencies(contractsRegistry_, data_);

        poolContractsRegistry = ContractsRegistryPoolMock(contractsRegistry_)
            .getPoolContractsRegistryContract();
    }

    function deployPool() external {
        string memory poolType_ = PoolContractsRegistryMock(poolContractsRegistry).POOL_1_NAME();

        address poolProxy_ = _deploy(poolContractsRegistry, poolType_);

        _register(poolContractsRegistry, poolType_, poolProxy_);
        _injectDependencies(poolContractsRegistry, poolProxy_);
    }

    function deploy2Pool(string calldata salt_) external {
        string memory poolType_ = PoolContractsRegistryMock(poolContractsRegistry).POOL_1_NAME();

        address poolProxy_ = _deploy2(poolContractsRegistry, poolType_, bytes32(bytes(salt_)));

        _register(poolContractsRegistry, poolType_, poolProxy_);
        _injectDependencies(poolContractsRegistry, poolProxy_);
    }

    function predictPoolAddress(string calldata salt_) external view returns (address) {
        return
            _predictPoolAddress(
                poolContractsRegistry,
                PoolContractsRegistryMock(poolContractsRegistry).POOL_1_NAME(),
                bytes32(bytes(salt_))
            );
    }
}
