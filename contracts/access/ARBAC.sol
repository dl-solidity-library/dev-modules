// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IRBAC} from "../interfaces/access/IRBAC.sol";

import {TypeCaster} from "../libs/utils/TypeCaster.sol";
import {SetHelper} from "../libs/arrays/SetHelper.sol";
import {DynamicSet} from "../libs/data-structures/DynamicSet.sol";

/**
 * @notice The Role Based Access Control (RBAC) module
 *
 * This is advanced module that handles role management for huge systems. One can declare specific permissions
 * for specific resources (contracts) and aggregate them into roles for further assignment to users.
 *
 * Each user can have multiple roles and each role can manage multiple resources. Each resource can posses a set of
 * permissions (CREATE, DELETE) that are only valid for that specific resource.
 *
 * The RBAC model supports antipermissions as well. One can grant antipermissions to users to restrict their access level.
 * There also is a special wildcard symbol "*" that means "everything". This symbol can be applied either to the
 * resources or permissions.
 *
 * By default, the MASTER role is configured with "*" as resources and permissions, allowing masters to do everything.
 *
 * The RBAC structure is the following:
 *
 * (PERMISSION >- RESOURCE) >- ROLE
 *
 * Where ROLE is assignable to users
 */
abstract contract ARBAC is IRBAC, Initializable {
    using DynamicSet for DynamicSet.StringSet;
    using SetHelper for DynamicSet.StringSet;
    using TypeCaster for string;

    string public constant MASTER_ROLE = "MASTER";

    string public constant ALL_RESOURCE = "*";
    string public constant ALL_PERMISSION = "*";

    string public constant CREATE_PERMISSION = "CREATE";
    string public constant READ_PERMISSION = "READ";
    string public constant UPDATE_PERMISSION = "UPDATE";
    string public constant DELETE_PERMISSION = "DELETE";

    string public constant RBAC_RESOURCE = "RBAC_RESOURCE";

    mapping(string => mapping(bool => mapping(string => DynamicSet.StringSet)))
        private _rolePermissions;
    mapping(string => mapping(bool => DynamicSet.StringSet)) private _roleResources;

    mapping(address => DynamicSet.StringSet) private _userRoles;

    error EmptyRoles();
    error NoPermissionForResource(address account, string permission, string resource);

    modifier onlyPermission(string memory resource_, string memory permission_) {
        if (!hasPermission(msg.sender, resource_, permission_))
            revert NoPermissionForResource(msg.sender, permission_, resource_);
        _;
    }

    /**
     * @notice The initialization function
     */
    function __ARBAC_init() internal onlyInitializing {
        _addPermissionsToRole(MASTER_ROLE, ALL_RESOURCE, ALL_PERMISSION.asSingletonArray(), true);
    }

    /**
     * @notice The function to grant roles to a user
     * @param to_ the user to grant roles to
     * @param rolesToGrant_ roles to grant
     */
    function grantRoles(
        address to_,
        string[] memory rolesToGrant_
    ) public virtual override onlyPermission(RBAC_RESOURCE, CREATE_PERMISSION) {
        if (rolesToGrant_.length == 0) revert EmptyRoles();

        _grantRoles(to_, rolesToGrant_);
    }

    /**
     * @notice The function to revoke roles
     * @param from_ the user to revoke roles from
     * @param rolesToRevoke_ the roles to revoke
     */
    function revokeRoles(
        address from_,
        string[] memory rolesToRevoke_
    ) public virtual override onlyPermission(RBAC_RESOURCE, DELETE_PERMISSION) {
        if (rolesToRevoke_.length == 0) revert EmptyRoles();

        _revokeRoles(from_, rolesToRevoke_);
    }

    /**
     * @notice The function to add resource permission to role
     * @param role_ the role to add permissions to
     * @param permissionsToAdd_ the array of resources and permissions to add to the role
     * @param allowed_ indicates whether to add permissions to an allowlist or disallowlist
     */
    function addPermissionsToRole(
        string memory role_,
        ResourceWithPermissions[] memory permissionsToAdd_,
        bool allowed_
    ) public virtual override onlyPermission(RBAC_RESOURCE, CREATE_PERMISSION) {
        for (uint256 i = 0; i < permissionsToAdd_.length; i++) {
            _addPermissionsToRole(
                role_,
                permissionsToAdd_[i].resource,
                permissionsToAdd_[i].permissions,
                allowed_
            );
        }
    }

    /**
     * @notice The function to remove permissions from role
     * @param role_ the role to remove permissions from
     * @param permissionsToRemove_ the array of resources and permissions to remove from the role
     * @param allowed_ indicates whether to remove permissions from the allowlist or disallowlist
     */
    function removePermissionsFromRole(
        string memory role_,
        ResourceWithPermissions[] memory permissionsToRemove_,
        bool allowed_
    ) public virtual override onlyPermission(RBAC_RESOURCE, DELETE_PERMISSION) {
        for (uint256 i = 0; i < permissionsToRemove_.length; i++) {
            _removePermissionsFromRole(
                role_,
                permissionsToRemove_[i].resource,
                permissionsToRemove_[i].permissions,
                allowed_
            );
        }
    }

    /**
     * @notice The function to get the list of user roles
     * @param who_ the user
     * @return roles_ the roles of the user
     */
    function getUserRoles(address who_) public view override returns (string[] memory roles_) {
        return _userRoles[who_].values();
    }

    /**
     * @notice The function to get the permissions of the role
     * @param role_ the role
     * @return allowed_ the list of allowed permissions of the role
     * @return disallowed_ the list of disallowed permissions of the role
     */
    function getRolePermissions(
        string memory role_
    )
        public
        view
        override
        returns (
            ResourceWithPermissions[] memory allowed_,
            ResourceWithPermissions[] memory disallowed_
        )
    {
        DynamicSet.StringSet storage _allowedResources = _roleResources[role_][true];
        DynamicSet.StringSet storage _disallowedResources = _roleResources[role_][false];

        mapping(string => DynamicSet.StringSet) storage _allowedPermissions = _rolePermissions[
            role_
        ][true];
        mapping(string => DynamicSet.StringSet) storage _disallowedPermissions = _rolePermissions[
            role_
        ][false];

        allowed_ = new ResourceWithPermissions[](_allowedResources.length());
        disallowed_ = new ResourceWithPermissions[](_disallowedResources.length());

        for (uint256 i = 0; i < allowed_.length; i++) {
            allowed_[i].resource = _allowedResources.at(i);
            allowed_[i].permissions = _allowedPermissions[allowed_[i].resource].values();
        }

        for (uint256 i = 0; i < disallowed_.length; i++) {
            disallowed_[i].resource = _disallowedResources.at(i);
            disallowed_[i].permissions = _disallowedPermissions[disallowed_[i].resource].values();
        }
    }

    /**
     * @notice The function to check the user's possession of the role
     *
     * @dev DO NOT call `super.hasPermission(...)` in derived contracts, because this method
     * handles not 2 but 3 states: NO PERMISSION, ALLOWED, DISALLOWED
     *
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
    }

    /**
     * @notice The internal function to grant roles
     * @param to_ the user to grant roles to
     * @param rolesToGrant_ the roles to grant
     */
    function _grantRoles(address to_, string[] memory rolesToGrant_) internal {
        _userRoles[to_].add(rolesToGrant_);

        emit GrantedRoles(to_, rolesToGrant_);
    }

    /**
     * @notice The internal function to revoke roles
     * @param from_ the user to revoke roles from
     * @param rolesToRevoke_ the roles to revoke
     */
    function _revokeRoles(address from_, string[] memory rolesToRevoke_) internal {
        _userRoles[from_].remove(rolesToRevoke_);

        emit RevokedRoles(from_, rolesToRevoke_);
    }

    /**
     * @notice The internal function to add permission to the role
     * @param role_ the role to add permissions to
     * @param resourceToAdd_ the resource to which the permissions belong
     * @param permissionsToAdd_ the permissions of the resource
     * @param allowed_ whether to add permissions to the allowlist or the disallowlist
     */
    function _addPermissionsToRole(
        string memory role_,
        string memory resourceToAdd_,
        string[] memory permissionsToAdd_,
        bool allowed_
    ) internal {
        DynamicSet.StringSet storage _resources = _roleResources[role_][allowed_];
        DynamicSet.StringSet storage _permissions = _rolePermissions[role_][allowed_][
            resourceToAdd_
        ];

        _permissions.add(permissionsToAdd_);
        _resources.add(resourceToAdd_);

        emit AddedPermissions(role_, resourceToAdd_, permissionsToAdd_, allowed_);
    }

    /**
     * @notice The internal function to remove permissions from the role
     * @param role_ the role to remove permissions from
     * @param resourceToRemove_ the resource to which the permissions belong
     * @param permissionsToRemove_ the permissions of the resource
     * @param allowed_ whether to remove permissions from the allowlist or the disallowlist
     */
    function _removePermissionsFromRole(
        string memory role_,
        string memory resourceToRemove_,
        string[] memory permissionsToRemove_,
        bool allowed_
    ) internal {
        DynamicSet.StringSet storage _resources = _roleResources[role_][allowed_];
        DynamicSet.StringSet storage _permissions = _rolePermissions[role_][allowed_][
            resourceToRemove_
        ];

        _permissions.remove(permissionsToRemove_);

        if (_permissions.length() == 0) {
            _resources.remove(resourceToRemove_);
        }

        emit RemovedPermissions(role_, resourceToRemove_, permissionsToRemove_, allowed_);
    }

    /**
     * @notice The function to check if the role has the permission
     * @param role_ the role to search the permission in
     * @param resource_ the role resource to search the permission in
     * @param permission_ the permission to search
     * @return true_ if the role has the permission, false otherwise
     */
    function _isAllowed(
        string memory role_,
        string memory resource_,
        string memory permission_
    ) internal view returns (bool) {
        mapping(string => DynamicSet.StringSet) storage _resources = _rolePermissions[role_][true];

        DynamicSet.StringSet storage _allAllowed = _resources[ALL_RESOURCE];
        DynamicSet.StringSet storage _allowed = _resources[resource_];

        return (_allAllowed.contains(ALL_PERMISSION) ||
            _allAllowed.contains(permission_) ||
            _allowed.contains(ALL_PERMISSION) ||
            _allowed.contains(permission_));
    }

    /**
     * @notice The function to check if the role has the antipermission
     * @param role_ the role to search the antipermission in
     * @param resource_ the role resource to search the antipermission in
     * @param permission_ the antipermission to search
     * @return true_ if the role has the antipermission, false otherwise
     */
    function _isDisallowed(
        string memory role_,
        string memory resource_,
        string memory permission_
    ) internal view returns (bool) {
        mapping(string => DynamicSet.StringSet) storage _resources = _rolePermissions[role_][
            false
        ];

        DynamicSet.StringSet storage _allDisallowed = _resources[ALL_RESOURCE];
        DynamicSet.StringSet storage _disallowed = _resources[resource_];

        return (_allDisallowed.contains(ALL_PERMISSION) ||
            _allDisallowed.contains(permission_) ||
            _disallowed.contains(ALL_PERMISSION) ||
            _disallowed.contains(permission_));
    }
}
