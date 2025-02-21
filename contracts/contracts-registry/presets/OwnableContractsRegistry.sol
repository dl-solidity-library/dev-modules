// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {AContractsRegistry} from "../AContractsRegistry.sol";

/**
 * @notice The Ownable preset of ContractsRegistry
 */
contract OwnableContractsRegistry is AContractsRegistry, OwnableUpgradeable {
    /**
     * @notice The initialization function
     */
    function __OwnableContractsRegistry_init() public initializer {
        __Ownable_init(msg.sender);
        __AContractsRegistry_init();
    }

    /**
     * @notice The function to inject dependencies to the specified contract
     * @param name_ the name of the contract to inject dependencies to
     */
    function injectDependencies(string calldata name_) external onlyOwner {
        _injectDependencies(name_);
    }

    /**
     * @notice The function to inject dependencies with data to the specified contract
     * @param name_ the name of the contract to inject dependencies to
     * @param data_ the data to be passed to `setDependencies()` function
     */
    function injectDependenciesWithData(
        string calldata name_,
        bytes calldata data_
    ) external onlyOwner {
        _injectDependenciesWithData(name_, data_);
    }

    /**
     * @notice The function to upgrade the specified proxy contract
     * @param name_ the name of the proxy contract to upgrade
     * @param newImplementation_ the new implementation
     */
    function upgradeContract(
        string calldata name_,
        address newImplementation_
    ) external onlyOwner {
        _upgradeContract(name_, newImplementation_);
    }

    /**
     * @notice The function to upgrade the specified proxy contract with data
     * @param name_ the name of the proxy contract to upgrade
     * @param newImplementation_ the new implementation
     * @param data_ the data the proxy contract will be called after the upgrade
     */
    function upgradeContractAndCall(
        string calldata name_,
        address newImplementation_,
        bytes calldata data_
    ) external onlyOwner {
        _upgradeContractAndCall(name_, newImplementation_, data_);
    }

    /**
     * @notice The function to add the regular contract to the registry
     * @param name_ the associative name of the contract
     * @param contractAddress_ the address of the contract to add
     */
    function addContract(string calldata name_, address contractAddress_) external onlyOwner {
        _addContract(name_, contractAddress_);
    }

    /**
     * @notice The function to add the proxy contract to the registry (deploys AdminableProxy on top)
     * @param name_ the associative name of the contract
     * @param contractAddress_ the address of the implementation contract to add
     */
    function addProxyContract(string calldata name_, address contractAddress_) external onlyOwner {
        _addProxyContract(name_, contractAddress_);
    }

    /**
     * @notice The function to add the proxy contract to the registry with immediate call (deploys AdminableProxy on top)
     * @param name_ the associative name of the contract
     * @param contractAddress_ the address of the implementation contract to add
     * @param data_ the data the proxy contract will be called after the addition
     */
    function addProxyContractAndCall(
        string calldata name_,
        address contractAddress_,
        bytes calldata data_
    ) external onlyOwner {
        _addProxyContractAndCall(name_, contractAddress_, data_);
    }

    /**
     * @notice The function to add proxy contract to the registry as is
     * @param name_ the associative name of the contract
     * @param contractAddress_ the address of the proxy contract to add
     */
    function justAddProxyContract(
        string calldata name_,
        address contractAddress_
    ) external onlyOwner {
        _justAddProxyContract(name_, contractAddress_);
    }

    /**
     * @notice The function to remove the contract from the registry
     * @param name_ the the associative name of the contract to remove
     */
    function removeContract(string calldata name_) external onlyOwner {
        _removeContract(name_);
    }
}
