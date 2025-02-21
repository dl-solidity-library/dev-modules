// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IRBACGroupable} from "../../interfaces/access/extensions/IRBACGroupable.sol";

import {DynamicSet} from "../../libs/data-structures/DynamicSet.sol";
import {SetHelper} from "../../libs/arrays/SetHelper.sol";

import {ARBAC} from "../ARBAC.sol";

/**
 * @notice The Role Based Access Control (RBAC) module
 *
 * This contract is an extension for the RBAC contract to provide the ability to organize roles
 * into groups and assign users to them.
 *
 * The contract also supports default groups that all users may be in by default.
 *
 * The RBAC structure becomes the following:
 *
 * ((PERMISSION >- RESOURCE) >- ROLE) >- GROUP
 *
 * Where ROLE and GROUP are assignable to users
 */
abstract contract ARBACGroupable is IRBACGroupable, ARBAC {
    using DynamicSet for DynamicSet.StringSet;
    using SetHelper for DynamicSet.StringSet;

    uint256 private _defaultGroupEnabled;

    mapping(address => DynamicSet.StringSet) private _userGroups;
    mapping(string => DynamicSet.StringSet) private _groupRoles;

    error EmptyGroups();

    /**
     * @notice The initialization function
     */
    function __ARBACGroupable_init() internal onlyInitializing {
        __ARBAC_init();
    }

    /**
     * @notice The function to assign the user to groups
     * @param who_ the user to be assigned
     * @param groupsToAddTo_ the list of groups to assign the user to
     */
    function addUserToGroups(
        address who_,
        string[] memory groupsToAddTo_
    ) public virtual override onlyPermission(RBAC_RESOURCE, CREATE_PERMISSION) {
        if (groupsToAddTo_.length == 0) revert EmptyGroups();

        _addUserToGroups(who_, groupsToAddTo_);
    }

    /**
     * @notice The function to remove the user from groups
     * @param who_ the user to be removed from groups
     * @param groupsToRemoveFrom_ the list of groups to remove the user from
     */
    function removeUserFromGroups(
        address who_,
        string[] memory groupsToRemoveFrom_
    ) public virtual override onlyPermission(RBAC_RESOURCE, DELETE_PERMISSION) {
        if (groupsToRemoveFrom_.length == 0) revert EmptyGroups();

        _removeUserFromGroups(who_, groupsToRemoveFrom_);
    }

    /**
     * @notice The function to grant roles to the group
     * @param groupTo_ the group to grant roles to
     * @param rolesToGrant_ the list of roles to grant
     */
    function grantGroupRoles(
        string memory groupTo_,
        string[] memory rolesToGrant_
    ) public virtual override onlyPermission(RBAC_RESOURCE, CREATE_PERMISSION) {
        if (rolesToGrant_.length == 0) revert EmptyRoles();

        _grantGroupRoles(groupTo_, rolesToGrant_);
    }

    /**
     * @notice The function to revoke roles from the group
     * @param groupFrom_ the group to revoke roles from
     * @param rolesToRevoke_ the list of roles to revoke
     */
    function revokeGroupRoles(
        string memory groupFrom_,
        string[] memory rolesToRevoke_
    ) public virtual override onlyPermission(RBAC_RESOURCE, DELETE_PERMISSION) {
        if (rolesToRevoke_.length == 0) revert EmptyRoles();

        _revokeGroupRoles(groupFrom_, rolesToRevoke_);
    }

    /**
     * @notice The function to toggle the default group state. When `defaultGroupEnabled` is set
     * to true, the default group is enabled, otherwise it is disabled
     */
    function toggleDefaultGroup()
        public
        virtual
        override
        onlyPermission(RBAC_RESOURCE, UPDATE_PERMISSION)
    {
        _defaultGroupEnabled ^= 1;

        emit ToggledDefaultGroup(getDefaultGroupEnabled());
    }

    /**
     * @notice The function to get the list of user groups
     * @param who_ the user
     * @return groups_ the list of user groups
     */
    function getUserGroups(address who_) public view override returns (string[] memory groups_) {
        DynamicSet.StringSet storage userGroups = _userGroups[who_];

        uint256 userGroupsLength_ = userGroups.length();

        groups_ = new string[](userGroupsLength_ + _defaultGroupEnabled);

        for (uint256 i = 0; i < userGroupsLength_; ++i) {
            groups_[i] = userGroups.at(i);
        }
    }

    /**
     * @notice The function to get the list of groups roles
     * @param group_ the group
     * @return roles_ the list of group roles
     */
    function getGroupRoles(
        string memory group_
    ) public view override returns (string[] memory roles_) {
        return _groupRoles[group_].values();
    }

    /**
     * @notice The function to get the current state of the default group
     * @return defaultGroupEnabled_ the boolean indicating whether the default group is enabled
     */
    function getDefaultGroupEnabled() public view returns (bool defaultGroupEnabled_) {
        return _defaultGroupEnabled > 0;
    }

    /**
     * @dev DO NOT call `super.hasPermission(...)` in derived contracts, because this method
     * handles not 2 but 3 states: NO PERMISSION, ALLOWED, DISALLOWED
     * @notice The function to check the user's possession of the role. Unlike the base method,
     * this method also looks up the required permission in the user's groups
     * @param who_ the user
     * @param resource_ the resource the user has to have the permission of
     * @param permission_ the permission the user has to have
     * @return isAllowed_ true if the user has the permission, false otherwise
     */
    function hasPermission(
        address who_,
        string memory resource_,
        string memory permission_
    ) public view virtual override returns (bool isAllowed_) {
        string[] memory roles_ = getUserRoles(who_);

        for (uint256 i = 0; i < roles_.length; i++) {
            string memory role_ = roles_[i];

            if (_isDisallowed(role_, resource_, permission_)) {
                return false;
            }

            isAllowed_ = isAllowed_ || _isAllowed(role_, resource_, permission_);
        }

        string[] memory groups_ = getUserGroups(who_);

        for (uint256 i = 0; i < groups_.length; i++) {
            roles_ = getGroupRoles(groups_[i]);

            for (uint256 j = 0; j < roles_.length; j++) {
                string memory role_ = roles_[j];

                if (_isDisallowed(role_, resource_, permission_)) {
                    return false;
                }

                isAllowed_ = isAllowed_ || _isAllowed(role_, resource_, permission_);
            }
        }
    }

    /**
     * @notice The internal function to assign groups to the user
     * @param who_ the user to assign groups to
     * @param groupsToAddTo_ the list of groups to be assigned
     */
    function _addUserToGroups(address who_, string[] memory groupsToAddTo_) internal {
        _userGroups[who_].add(groupsToAddTo_);

        emit AddedToGroups(who_, groupsToAddTo_);
    }

    /**
     * @notice The internal function to remove the user from groups
     * @param who_ the user to be removed from groups
     * @param groupsToRemoveFrom_ the list of groups to remove the user from
     */
    function _removeUserFromGroups(address who_, string[] memory groupsToRemoveFrom_) internal {
        _userGroups[who_].remove(groupsToRemoveFrom_);

        emit RemovedFromGroups(who_, groupsToRemoveFrom_);
    }

    /**
     * @notice The internal function to grant roles to the group
     * @param groupTo_ the group to grant roles to
     * @param rolesToGrant_ the list of roles to grant
     */
    function _grantGroupRoles(string memory groupTo_, string[] memory rolesToGrant_) internal {
        _groupRoles[groupTo_].add(rolesToGrant_);

        emit GrantedGroupRoles(groupTo_, rolesToGrant_);
    }

    /**
     * @notice The internal function to revoke roles from the group
     * @param groupFrom_ the group to revoke roles from
     * @param rolesToRevoke_ the list of roles to revoke
     */
    function _revokeGroupRoles(string memory groupFrom_, string[] memory rolesToRevoke_) internal {
        _groupRoles[groupFrom_].remove(rolesToRevoke_);

        emit RevokedGroupRoles(groupFrom_, rolesToRevoke_);
    }
}
