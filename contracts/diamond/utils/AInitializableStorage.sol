// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @notice The Diamond standard module
 *
 * This is a modified version of the OpenZeppelin Initializable contract to be compatible
 * with the Diamond Standard.
 */
abstract contract AInitializableStorage {
    bytes32 internal constant INITIALIZABLE_STORAGE_SLOT =
        keccak256("diamond.standard.initializable.storage");

    struct IStorage {
        // storage slot => { 0: not initialized, 1: initializing, 2: initialized }
        mapping(bytes32 => uint8) initializingStorage;
    }

    event Initialized(bytes32 storageSlot);

    error AlreadyInitialized();
    error InvalidInitialization();
    error NotInitializing();

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most
     * once for a particular storage in a Diamond proxy that begins with {storageSlot_}.
     * In its scope, `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer(bytes32 storageSlot_) {
        uint8 initializing_ = _getInitializing(storageSlot_);

        if (initializing_ != 0) revert AlreadyInitialized();

        _setInitializing(storageSlot_, 1);
        _;
        _setInitializing(storageSlot_, 2);

        emit Initialized(storageSlot_);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing(bytes32 storageSlot_) {
        if (_getInitializing(storageSlot_) != 1) revert NotInitializing();
        _;
    }

    function _getInitializableStorage() internal pure returns (IStorage storage _iss) {
        bytes32 slot_ = INITIALIZABLE_STORAGE_SLOT;

        assembly {
            _iss.slot := slot_
        }
    }

    /**
     * @dev Locks the contract.
     * It is recommended to use this to lock Diamond Facets contracts.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers(bytes32 storageSlot_) internal virtual {
        uint8 initializing_ = _getInitializing(storageSlot_);

        if (initializing_ != 0) revert InvalidInitialization();

        _setInitializing(storageSlot_, 2);

        emit Initialized(storageSlot_);
    }

    /**
     * @dev Internal function that returns the initializing for the specified storage slot.
     */
    function _getInitializing(bytes32 storageSlot_) internal view returns (uint8) {
        return _getInitializableStorage().initializingStorage[storageSlot_];
    }

    /**
     * @dev Internal function that sets the initializingStorage value.
     */
    function _setInitializing(bytes32 storageSlot_, uint8 value_) private {
        _getInitializableStorage().initializingStorage[storageSlot_] = value_;
    }
}
