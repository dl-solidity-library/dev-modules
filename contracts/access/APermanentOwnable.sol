// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @notice The PermanentOwnable module
 *
 * Contract module which provides a basic access control mechanism, where there is
 * an account (an owner) that can be granted exclusive access to specific functions.
 *
 * The owner is set to the address provided by the deployer. The ownership cannot be further changed.
 *
 * This module will make available the modifier `onlyOwner`, which can be applied
 * to your functions to restrict their use to the owners.
 */
abstract contract APermanentOwnable {
    address private immutable _OWNER;

    error InvalidOwner();
    error UnauthorizedAccount(address account);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /**
     * @notice Initializes the contract setting the address provided by the deployer as the owner.
     * @param owner_ the address of the permanent owner.
     */
    constructor(address owner_) {
        if (owner_ == address(0)) revert InvalidOwner();

        _OWNER = owner_;
    }

    /**
     * @notice Returns the address of the owner.
     * @return the permanent owner.
     */
    function owner() public view virtual returns (address) {
        return _OWNER;
    }

    function _onlyOwner() internal view virtual {
        if (_OWNER != msg.sender) revert UnauthorizedAccount(msg.sender);
    }
}
