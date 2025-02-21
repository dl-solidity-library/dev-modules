// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @notice The ContractsRegistry module
 *
 * The contract that must be used as dependencies accepter in the dependency injection mechanism.
 * Upon the injection, the Injector (ContractsRegistry most of the time) will call the `setDependencies()` function.
 * The dependant contract will have to pull the required addresses from the supplied ContractsRegistry as a parameter.
 *
 * The ADependant is fully compatible with proxies courtesy of custom storage slot.
 */
abstract contract ADependant {
    /**
     * @notice The slot where the dependency injector is located.
     *
     * @dev bytes32(uint256(keccak256("eip6224.dependant.slot")) - 1)
     *
     * Only the injector is allowed to inject dependencies.
     * The first to call the setDependencies() (with the modifier applied) function becomes an injector
     */
    bytes32 private constant _INJECTOR_SLOT =
        0x3d1f25f1ac447e55e7fec744471c4dab1c6a2b6ffb897825f9ea3d2e8c9be583;

    error NotAnInjector(address injector, address caller);

    modifier dependant() {
        _checkInjector();
        _;
        _setInjector(msg.sender);
    }

    /**
     * @notice The function that will be called from the ContractsRegistry (or factory) to inject dependencies.
     *
     * The Dependant must apply `dependant()` modifier to this function
     *
     * @param contractsRegistry_ the registry to pull dependencies from
     * @param data_ the extra data that might provide additional context
     */
    function setDependencies(address contractsRegistry_, bytes memory data_) public virtual;

    /**
     * @notice The function is made external to allow for the factories to set the injector to the ContractsRegistry
     * @param injector_ the new injector
     */
    function setInjector(address injector_) external {
        _checkInjector();
        _setInjector(injector_);
    }

    /**
     * @notice The function to get the current injector
     * @return injector_ the current injector
     */
    function getInjector() public view returns (address injector_) {
        bytes32 slot_ = _INJECTOR_SLOT;

        assembly {
            injector_ := sload(slot_)
        }
    }

    /**
     * @notice Internal function that sets the injector
     */
    function _setInjector(address injector_) internal {
        bytes32 slot_ = _INJECTOR_SLOT;

        assembly {
            sstore(slot_, injector_)
        }
    }

    /**
     * @notice Internal function that checks the injector credentials
     */
    function _checkInjector() internal view {
        address injector_ = getInjector();

        if (injector_ != address(0) && injector_ != msg.sender)
            revert NotAnInjector(injector_, msg.sender);
    }
}
