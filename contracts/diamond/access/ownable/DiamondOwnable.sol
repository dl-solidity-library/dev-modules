// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ADiamondOwnableStorage} from "./ADiamondOwnableStorage.sol";

/**
 * @notice The Diamond standard module
 *
 * This is modified version of OpenZeppelin's Ownable contract to be used as a Storage contract
 * by the Diamond Standard.
 */
contract DiamondOwnable is ADiamondOwnableStorage {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    error InvalidOwner();

    /**
     * @notice Transfers ownership to `msg.sender`
     */
    function __DiamondOwnable_init() internal onlyInitializing(DIAMOND_OWNABLE_STORAGE_SLOT) {
        _transferOwnership(msg.sender);
    }

    /**
     * @notice The function to transfer the Diamond ownership
     * @param newOwner_ the new owner of the Diamond
     */
    function transferOwnership(address newOwner_) public virtual onlyOwner {
        if (newOwner_ == address(0)) revert InvalidOwner();

        _transferOwnership(newOwner_);
    }

    /**
     * @notice The function to leave Diamond without an owner
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @notice The function to appoint a new Diamond owner
     */
    function _transferOwnership(address newOwner_) internal virtual {
        address previousOwner_ = _getDiamondOwnableStorage().owner;

        _getDiamondOwnableStorage().owner = newOwner_;

        emit OwnershipTransferred(previousOwner_, newOwner_);
    }
}
