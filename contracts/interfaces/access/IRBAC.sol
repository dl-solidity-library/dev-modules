// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @notice The RBAC module
 */
interface IRBAC {
    struct ResourceWithPermissions {
        string resource;
        string[] permissions;
    }

    event GrantedRoles(address to, string[] rolesToGrant);
    event RevokedRoles(address from, string[] rolesToRevoke);

    event AddedPermissions(string role, string resource, string[] permissionsToAdd, bool allowed);
    event RemovedPermissions(
        string role,
        string resource,
        string[] permissionsToRemove,
        bool allowed
    );

    /**
     * @notice The function to grant roles to a user
     * @param to_ the user to grant roles to
     * @param rolesToGrant_ roles to grant
     */
    function grantRoles(address to_, string[] calldata rolesToGrant_) external;

    /**
     * @notice The function to revoke roles
     * @param from_ the user to revoke roles from
     * @param rolesToRevoke_ the roles to revoke
     */
    function revokeRoles(address from_, string[] calldata rolesToRevoke_) external;

    /**
     * @notice The function to add resource permission to role
     * @param role_ the role to add permissions to
     * @param permissionsToAdd_ the array of resources and permissions to add to the role
     * @param allowed_ indicates whether to add permissions to an allowlist or disallowlist
     */
    function addPermissionsToRole(
        string calldata role_,
        ResourceWithPermissions[] calldata permissionsToAdd_,
        bool allowed_
    ) external;

    /**
     * @notice The function to remove permissions from role
     * @param role_ the role to remove permissions from
     * @param permissionsToRemove_ the array of resources and permissions to remove from the role
     * @param allowed_ indicates whether to remove permissions from the allowlist or disallowlist
     */
    function removePermissionsFromRole(
        string calldata role_,
        ResourceWithPermissions[] calldata permissionsToRemove_,
        bool allowed_
    ) external;

    /**
     * @notice The function to get the list of user roles
     * @param who_ the user
     * @return roles_ the roles of the user
     */
    function getUserRoles(address who_) external view returns (string[] calldata roles_);

    /**
     * @notice The function to get the permissions of the role
     * @param role_ the role
     * @return allowed_ the list of allowed permissions of the role
     * @return disallowed_ the list of disallowed permissions of the role
     */
    function getRolePermissions(
        string calldata role_
    )
        external
        view
        returns (
            ResourceWithPermissions[] calldata allowed_,
            ResourceWithPermissions[] calldata disallowed_
        );

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
        string calldata resource_,
        string calldata permission_
    ) external view returns (bool isAllowed_);
}
