// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {TypeCaster} from "../../../libs/utils/TypeCaster.sol";

import {ARBACGroupable} from "../../../access/extensions/ARBACGroupable.sol";

contract RBACGroupableMock is ARBACGroupable {
    using TypeCaster for string;

    function __RBACGroupableMock_init() external initializer {
        __ARBACGroupable_init();

        _grantRoles(msg.sender, MASTER_ROLE.asSingletonArray());
    }

    function mockInit() external {
        __ARBACGroupable_init();
    }
}
