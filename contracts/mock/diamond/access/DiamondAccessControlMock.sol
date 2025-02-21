// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {ADiamondAccessControl} from "../../../diamond/access/access-control/ADiamondAccessControl.sol";

contract DiamondAccessControlMock is ADiamondAccessControl {
    bytes32 public constant AGENT_ROLE = bytes32(uint256(0x01));

    function __DiamondAccessControlDirect_init() external {
        __ADiamondAccessControl_init();
    }

    function __DiamondAccessControlMock_init()
        external
        initializer(DIAMOND_ACCESS_CONTROL_STORAGE_SLOT)
    {
        __ADiamondAccessControl_init();
    }

    function setRoleAdmin(
        bytes32 role_,
        bytes32 adminRole_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRoleAdmin(role_, adminRole_);
    }
}
