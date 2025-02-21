// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @notice The RBAC module
 */
interface IRBACGroupable {
    event AddedToGroups(address who, string[] groupsToAddTo);
    event RemovedFromGroups(address who, string[] groupsToRemoveFrom);

    event GrantedGroupRoles(string groupTo, string[] rolesToGrant);
    event RevokedGroupRoles(string groupFrom, string[] rolesToRevoke);

    event ToggledDefaultGroup(bool defaultGroupEnabled);

    /**
     * @notice The function to assign the user to groups
     * @param who_ the user to be assigned
     * @param groupsToAddTo_ the list of groups to assign the user to
     */
    function addUserToGroups(address who_, string[] calldata groupsToAddTo_) external;

    /**
     * @notice The function to remove the user from groups
     * @param who_ the user to be removed from groups
     * @param groupsToRemoveFrom_ the list of groups to remove the user from
     */
    function removeUserFromGroups(address who_, string[] calldata groupsToRemoveFrom_) external;

    /**
     * @notice The function to grant roles to the group
     * @param groupTo_ the group to grant roles to
     * @param rolesToGrant_ the list of roles to grant
     */
    function grantGroupRoles(string calldata groupTo_, string[] calldata rolesToGrant_) external;

    /**
     * @notice The function to revoke roles from the group
     * @param groupFrom_ the group to revoke roles from
     * @param rolesToRevoke_ the list of roles to revoke
     */
    function revokeGroupRoles(
        string calldata groupFrom_,
        string[] calldata rolesToRevoke_
    ) external;

    /**
     * @notice The function to toggle the default group state. When `defaultGroupEnabled` is set
     * to true, the default group is enabled, otherwise it is disabled
     */
    function toggleDefaultGroup() external;

    /**
     * @notice The function to get the list of user groups
     * @param who_ the user
     * @return groups_ the list of user groups
     */
    function getUserGroups(address who_) external view returns (string[] calldata groups_);

    /**
     * @notice The function to get the list of groups roles
     * @param group_ the group
     * @return roles_ the list of group roles
     */
    function getGroupRoles(
        string calldata group_
    ) external view returns (string[] calldata roles_);

    /**
     * @notice The function to get the current state of the default group
     * @return defaultGroupEnabled_ the boolean indicating whether the default group is enabled
     */
    function getDefaultGroupEnabled() external view returns (bool);
}
