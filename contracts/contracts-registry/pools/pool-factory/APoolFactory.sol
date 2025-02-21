// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

import {ADependant} from "../../../contracts-registry/ADependant.sol";
import {APoolContractsRegistry} from "../APoolContractsRegistry.sol";

import {PublicBeaconProxy} from "../../../proxy/beacon/PublicBeaconProxy.sol";

/**
 * @notice The PoolContractsRegistry module
 *
 * This is an abstract factory contract that is used in pair with the PoolContractsRegistry contract to
 * deploy, register and inject dependencies to pools. Built via EIP-6224 Contracts Dependencies Registry pattern.
 *
 * The actual `deploy()` function has to be implemented in the descendants of this contract. The deployment
 * is made via the BeaconProxy pattern.
 *
 * Both "create1" and "create2" deployment modes are supported.
 */
abstract contract APoolFactory is ADependant {
    address internal _contractsRegistry;

    /**
     * @notice The function that accepts dependencies from the ContractsRegistry, can be overridden
     * @param contractsRegistry_ the dependency registry
     */
    function setDependencies(
        address contractsRegistry_,
        bytes memory
    ) public virtual override dependant {
        _contractsRegistry = contractsRegistry_;
    }

    /**
     * @notice The internal deploy function that deploys BeaconProxy pointing to the
     * pool implementation taken from the PoolContractRegistry
     */
    function _deploy(
        address poolRegistry_,
        string memory poolType_
    ) internal virtual returns (address) {
        return
            address(
                new PublicBeaconProxy(
                    APoolContractsRegistry(poolRegistry_).getProxyBeacon(poolType_),
                    bytes("")
                )
            );
    }

    /**
     * @notice The internal deploy function that deploys BeaconProxy pointing to the
     * pool implementation taken from the PoolContractRegistry using the create2 mechanism
     */
    function _deploy2(
        address poolRegistry_,
        string memory poolType_,
        bytes32 salt_
    ) internal virtual returns (address) {
        return
            address(
                new PublicBeaconProxy{salt: salt_}(
                    APoolContractsRegistry(poolRegistry_).getProxyBeacon(poolType_),
                    bytes("")
                )
            );
    }

    /**
     * @notice The internal function that registers newly deployed pool in the provided PoolContractRegistry
     */
    function _register(
        address poolRegistry_,
        string memory poolType_,
        address poolProxy_
    ) internal virtual {
        APoolContractsRegistry(poolRegistry_).addProxyPool(poolType_, poolProxy_);
    }

    /**
     * @notice The function that injects dependencies to the newly deployed pool and sets
     * provided PoolContractsRegistry as an injector
     */
    function _injectDependencies(address poolRegistry_, address proxy_) internal virtual {
        ADependant(proxy_).setDependencies(_contractsRegistry, bytes(""));
        ADependant(proxy_).setInjector(poolRegistry_);
    }

    /**
     * @notice The view function that computes the address of the pool if deployed via _deploy2
     */
    function _predictPoolAddress(
        address poolRegistry_,
        string memory poolType_,
        bytes32 salt_
    ) internal view virtual returns (address) {
        bytes32 bytecodeHash = keccak256(
            abi.encodePacked(
                type(PublicBeaconProxy).creationCode,
                abi.encode(
                    APoolContractsRegistry(poolRegistry_).getProxyBeacon(poolType_),
                    bytes("")
                )
            )
        );

        return Create2.computeAddress(salt_, bytecodeHash);
    }
}
