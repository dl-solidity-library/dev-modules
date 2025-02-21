// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// solhint-disable-next-line no-unused-import
import {ADiamondAccessControlStorage, IAccessControl} from "./ADiamondAccessControlStorage.sol";

/**
 * @notice The Diamond standard module
 *
 * This is modified version of OpenZeppelin's AccessControl contract to be used as a Storage contract
 * by the Diamond Standard.
 */
abstract contract ADiamondAccessControl is ADiamondAccessControlStorage {
    error UnauthorizedAccount(address account);
    error RoleAlreadyGranted(bytes32 role, address account);

    /**
     * @notice Sets `DEFAULT_ADMIN_ROLE` to `msg.sender`
     */
    function __ADiamondAccessControl_init()
        internal
        onlyInitializing(DIAMOND_ACCESS_CONTROL_STORAGE_SLOT)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function grantRole(
        bytes32 role_,
        address account_
    ) public virtual override onlyRole(getRoleAdmin(role_)) {
        _grantRole(role_, account_);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function revokeRole(
        bytes32 role_,
        address account_
    ) public virtual override onlyRole(getRoleAdmin(role_)) {
        _revokeRole(role_, account_);
    }

    /**
     * @inheritdoc IAccessControl
     */
    function renounceRole(bytes32 role_, address account_) public virtual override {
        if (account_ != msg.sender) revert UnauthorizedAccount(msg.sender);

        _revokeRole(role_, account_);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role_, bytes32 adminRole_) internal virtual {
        bytes32 previousAdminRole_ = getRoleAdmin(role_);

        _getAccessControlStorage().roles[role_].adminRole = adminRole_;

        emit RoleAdminChanged(role_, previousAdminRole_, adminRole_);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role_, address account_) internal virtual {
        if (hasRole(role_, account_)) revert RoleAlreadyGranted(role_, account_);

        _getAccessControlStorage().roles[role_].members[account_] = true;

        emit RoleGranted(role_, account_, msg.sender);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role_, address account_) internal virtual {
        if (!hasRole(role_, account_)) revert RoleNotGranted(role_, account_);

        _getAccessControlStorage().roles[role_].members[account_] = false;

        emit RoleRevoked(role_, account_, msg.sender);
    }
}
