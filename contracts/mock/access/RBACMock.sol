// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {TypeCaster} from "../../libs/utils/TypeCaster.sol";

import {ARBAC} from "../../access/ARBAC.sol";

contract RBACMock is ARBAC {
    using TypeCaster for string;

    function __RBACMock_init() external initializer {
        __ARBAC_init();

        _grantRoles(msg.sender, MASTER_ROLE.asSingletonArray());
    }

    function mockInit() external {
        __ARBAC_init();
    }
}
