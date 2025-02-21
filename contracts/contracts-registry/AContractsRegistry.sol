// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {AdminableProxyUpgrader} from "../proxy/adminable/AdminableProxyUpgrader.sol";
import {AdminableProxy} from "../proxy/adminable/AdminableProxy.sol";
import {ADependant} from "./ADependant.sol";

/**
 * @notice The ContractsRegistry module
 *
 * For more information please refer to [EIP-6224](https://eips.ethereum.org/EIPS/eip-6224).
 *
 * The purpose of this module is to provide an organized registry of the project's smart contracts
 * together with the upgradeability and dependency injection mechanisms.
 *
 * The ContractsRegistry should be used as the highest level smart contract that is aware of any other
 * contract present in the system. The contracts that demand other system's contracts would then inherit
 * special `ADependant` contract and override `setDependencies()` function to enable ContractsRegistry
 * to inject dependencies into them.
 *
 * The ContractsRegistry will help with the following use cases:
 *
 * 1) Making the system upgradeable
 * 2) Making the system contracts-interchangeable
 * 3) Simplifying the contracts management and deployment
 *
 * The ContractsRegistry acts as a AdminableProxy deployer. One can add proxy-compatible implementations to the registry
 * and deploy proxies to them. Then these proxies can be upgraded easily using the provided interface.
 * The ContractsRegistry itself can be deployed behind a proxy as well.
 *
 * The dependency injection system may come in handy when one wants to substitute a contract `A` with a contract `B`
 * (for example contract `A` got exploited) without a necessity of redeploying the whole system. One would just add
 * a new `B` contract to a ContractsRegistry and re-inject all the required dependencies. Dependency injection mechanism
 * is also meant to be compatible with factories.
 *
 * Users may also fetch all the contracts present in the system as they are now located in a single place.
 */
abstract contract AContractsRegistry is Initializable {
    AdminableProxyUpgrader private _proxyUpgrader;

    mapping(string => address) private _contracts;
    mapping(address => bool) private _isProxy;

    event ContractAdded(string name, address contractAddress);
    event ProxyContractAdded(string name, address contractAddress, address implementation);
    event ProxyContractUpgraded(string name, address newImplementation);
    event ContractRemoved(string name);

    error NoMappingExists(string contractName);
    error NotAProxy(string contractName, address contractProxy);
    error ZeroAddressProvided(string contractName);

    /**
     * @notice The initialization function
     */
    function __AContractsRegistry_init() internal onlyInitializing {
        _proxyUpgrader = new AdminableProxyUpgrader();
    }

    /**
     * @notice The function that returns an associated contract with the name
     * @param name_ the name of the contract
     * @return the address of the contract
     */
    function getContract(string memory name_) public view returns (address) {
        address contractAddress_ = _contracts[name_];

        _checkIfMappingExist(contractAddress_, name_);

        return contractAddress_;
    }

    /**
     * @notice The function that checks if a contract with a given name has been added
     * @param name_ the name of the contract
     * @return true if the contract is present in the registry
     */
    function hasContract(string memory name_) public view returns (bool) {
        return _contracts[name_] != address(0);
    }

    /**
     * @notice The function that returns the admin of the added proxy contracts
     * @return the proxy admin address
     */
    function getProxyUpgrader() public view returns (address) {
        return address(_proxyUpgrader);
    }

    /**
     * @notice The function that returns an implementation of the given proxy contract
     * @param name_ the name of the contract
     * @return the implementation address
     */
    function getImplementation(string memory name_) public view returns (address) {
        address contractProxy_ = _contracts[name_];

        if (contractProxy_ == address(0)) revert NoMappingExists(name_);
        if (!_isProxy[contractProxy_]) revert NotAProxy(name_, contractProxy_);

        return _proxyUpgrader.getImplementation(contractProxy_);
    }

    /**
     * @notice The function that injects the dependencies into the given contract
     * @param name_ the name of the contract
     */
    function _injectDependencies(string memory name_) internal virtual {
        _injectDependenciesWithData(name_, bytes(""));
    }

    /**
     * @notice The function that injects the dependencies into the given contract with data
     * @param name_ the name of the contract
     * @param data_ the extra context data
     */
    function _injectDependenciesWithData(
        string memory name_,
        bytes memory data_
    ) internal virtual {
        address contractAddress_ = _contracts[name_];

        _checkIfMappingExist(contractAddress_, name_);

        ADependant dependant_ = ADependant(contractAddress_);
        dependant_.setDependencies(address(this), data_);
    }

    /**
     * @notice The function to upgrade added proxy contract with a new implementation
     * @param name_ the name of the proxy contract
     * @param newImplementation_ the new implementation the proxy should be upgraded to
     *
     * It is the Owner's responsibility to ensure the compatibility between implementations
     */
    function _upgradeContract(string memory name_, address newImplementation_) internal virtual {
        _upgradeContractAndCall(name_, newImplementation_, bytes(""));
    }

    /**
     * @notice The function to upgrade added proxy contract with a new implementation, providing data
     * @param name_ the name of the proxy contract
     * @param newImplementation_ the new implementation the proxy should be upgraded to
     * @param data_ the data that the new implementation will be called with. This can be an ABI encoded function call
     *
     * It is the Owner's responsibility to ensure the compatibility between implementations
     */
    function _upgradeContractAndCall(
        string memory name_,
        address newImplementation_,
        bytes memory data_
    ) internal virtual {
        address contractToUpgrade_ = _contracts[name_];

        if (contractToUpgrade_ == address(0)) revert NoMappingExists(name_);
        if (!_isProxy[contractToUpgrade_]) revert NotAProxy(name_, contractToUpgrade_);

        _proxyUpgrader.upgrade(contractToUpgrade_, newImplementation_, data_);

        emit ProxyContractUpgraded(name_, newImplementation_);
    }

    /**
     * @notice The function to add pure contracts to the ContractsRegistry. These should either be
     * the contracts the system does not have direct upgradeability control over, or the contracts that are not upgradeable
     * @param name_ the name to associate the contract with
     * @param contractAddress_ the address of the contract
     */
    function _addContract(string memory name_, address contractAddress_) internal virtual {
        if (contractAddress_ == address(0)) revert ZeroAddressProvided(name_);

        _contracts[name_] = contractAddress_;

        emit ContractAdded(name_, contractAddress_);
    }

    /**
     * @notice The function to add the contracts and deploy the proxy above them. It should be used to add
     * contract that the ContractsRegistry should be able to upgrade
     * @param name_ the name to associate the contract with
     * @param contractAddress_ the address of the implementation
     */
    function _addProxyContract(string memory name_, address contractAddress_) internal virtual {
        _addProxyContractAndCall(name_, contractAddress_, bytes(""));
    }

    /**
     * @notice The function to add the contracts and deploy the proxy above them. It should be used to add
     * contract that the ContractsRegistry should be able to upgrade
     * @param name_ the name to associate the contract with
     * @param contractAddress_ the address of the implementation
     * @param data_ the additional proxy initialization data
     */
    function _addProxyContractAndCall(
        string memory name_,
        address contractAddress_,
        bytes memory data_
    ) internal virtual {
        if (contractAddress_ == address(0)) revert ZeroAddressProvided(name_);

        address proxyAddr_ = _deployProxy(contractAddress_, address(_proxyUpgrader), data_);

        _contracts[name_] = proxyAddr_;
        _isProxy[proxyAddr_] = true;

        emit ProxyContractAdded(name_, proxyAddr_, contractAddress_);
    }

    /**
     * @notice The function to add the already deployed proxy to the ContractsRegistry. This might be used
     * when the system migrates to a new ContractRegistry. This means that the new ProxyUpgrader must have the
     * credentials to upgrade the added proxies
     * @param name_ the name to associate the contract with
     * @param contractAddress_ the address of the proxy
     */
    function _justAddProxyContract(
        string memory name_,
        address contractAddress_
    ) internal virtual {
        if (contractAddress_ == address(0)) revert ZeroAddressProvided(name_);

        _contracts[name_] = contractAddress_;
        _isProxy[contractAddress_] = true;

        emit ProxyContractAdded(
            name_,
            contractAddress_,
            _proxyUpgrader.getImplementation(contractAddress_)
        );
    }

    /**
     * @notice The function to remove the contract from the ContractsRegistry
     * @param name_ the associated name with the contract
     */
    function _removeContract(string memory name_) internal virtual {
        address contractAddress_ = _contracts[name_];

        _checkIfMappingExist(contractAddress_, name_);

        delete _isProxy[contractAddress_];
        delete _contracts[name_];

        emit ContractRemoved(name_);
    }

    /**
     * @notice The utility function to deploy a Transparent Proxy contract to be used within the registry
     * @param contractAddress_ the implementation address
     * @param admin_ the proxy admin to be set
     * @param data_ the proxy initialization data
     * @return the address of a Transparent Proxy
     */
    function _deployProxy(
        address contractAddress_,
        address admin_,
        bytes memory data_
    ) internal virtual returns (address) {
        return address(new AdminableProxy(contractAddress_, admin_, data_));
    }

    function _checkIfMappingExist(address contractAddress_, string memory name_) internal pure {
        if (contractAddress_ == address(0)) revert NoMappingExists(name_);
    }
}
