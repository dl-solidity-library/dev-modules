// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {APermanentOwnable} from "../../access/APermanentOwnable.sol";

contract PermanentOwnableMock is APermanentOwnable {
    event ValidOwner();

    constructor(address _owner) APermanentOwnable(_owner) {}

    function onlyOwnerMethod() external onlyOwner {
        emit ValidOwner();
    }
}
