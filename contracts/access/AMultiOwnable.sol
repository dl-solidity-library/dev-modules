// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {SetHelper} from "../libs/arrays/SetHelper.sol";
import {TypeCaster} from "../libs/utils/TypeCaster.sol";
import {IMultiOwnable} from "../interfaces/access/IMultiOwnable.sol";

/**
 * @notice The MultiOwnable module
 *
 * Contract module which provides a basic access control mechanism, where there is a list of
 * owner addresses those can be granted exclusive access to specific functions.
 *
 * All owners are equal in their access, they can add new owners, also remove each other and themselves.
 *
 * By default, the owner account will be the one that deploys the contract.
 *
 * This module will make available the modifier `onlyOwner`, which can be applied
 * to your functions to restrict their use to the owners.
 */
abstract contract AMultiOwnable is IMultiOwnable, Initializable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using TypeCaster for address;
    using SetHelper for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _owners;

    error InvalidOwner();
    error UnauthorizedAccount(address account);

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Initializes the contract setting the msg.sender as the initial owner.
     */
    function __AMultiOwnable_init() internal onlyInitializing {
        _addOwners(msg.sender.asSingletonArray());
    }

    /**
     * @notice The function to add equally rightful owners to the contract
     * @param newOwners_ the owners to be added
     */
    function addOwners(address[] memory newOwners_) public override onlyOwner {
        _addOwners(newOwners_);
    }

    /**
     * @notice The function to remove owners from the contract
     * @param oldOwners_ the owners to be removed. Note that one can remove themself
     */
    function removeOwners(address[] memory oldOwners_) public override onlyOwner {
        _removeOwners(oldOwners_);
    }

    /**
     * @notice The function to remove yourself from the owners list
     *
     * Note: renouncing ownership may leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public override onlyOwner {
        _removeOwners(msg.sender.asSingletonArray());
    }

    /**
     * @notice The function to get the list of current owners. Be careful, O(n) complexity
     * @return the list of current owners
     */
    function getOwners() public view override returns (address[] memory) {
        return _owners.values();
    }

    /**
     * @notice The function to check the ownership of a user
     * @param address_ the user to check
     * @return true if address_ is owner, false otherwise
     */
    function isOwner(address address_) public view override returns (bool) {
        return _owners.contains(address_);
    }

    /**
     * @notice Gives ownership of the contract to array of new owners. Null address addition is not allowed.
     * @dev Internal function without access restriction.
     * @param newOwners_ the array of addresses to add to _owners
     */
    function _addOwners(address[] memory newOwners_) private {
        _owners.add(newOwners_);

        if (_owners.contains(address(0))) revert InvalidOwner();

        emit OwnersAdded(newOwners_);
    }

    /**
     * @notice Removes ownership of the contract for every address in array.
     *
     * Note: removing ownership may leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     *
     * @dev Internal function without access restriction.
     * @param oldOwners_ the array of addresses to remove from _owners
     */
    function _removeOwners(address[] memory oldOwners_) private {
        _owners.remove(oldOwners_);

        emit OwnersRemoved(oldOwners_);
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() private view {
        if (!isOwner(msg.sender)) revert UnauthorizedAccount(msg.sender);
    }
}
