// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @notice The MultiOwnable module
 */
interface IMultiOwnable {
    event OwnersAdded(address[] newOwners);
    event OwnersRemoved(address[] removedOwners);

    /**
     * @notice The function to add equally rightful owners to the contract
     * @param newOwners_ the owners to be added
     */
    function addOwners(address[] calldata newOwners_) external;

    /**
     * @notice The function to remove owners from the contract
     * @param oldOwners_ the owners to be removed. Note that one can remove themself
     */
    function removeOwners(address[] calldata oldOwners_) external;

    /**
     * @notice The function to remove yourself from the owners list
     *
     * Note: renouncing ownership may leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() external;

    /**
     * @notice The function to get the list of current owners. Be careful, O(n) complexity
     * @return the list of current owners
     */
    function getOwners() external view returns (address[] memory);

    /**
     * @notice The function to check the ownership of a user
     * @param address_ the user to check
     * @return true if address_ is owner, false otherwise
     */
    function isOwner(address address_) external view returns (bool);
}
