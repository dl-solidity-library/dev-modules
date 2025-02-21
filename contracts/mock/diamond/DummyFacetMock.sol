// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {DummyStorageMock} from "./DummyStorageMock.sol";

contract DummyFacetMock is DummyStorageMock {
    function setDummyString(string memory dummyString_) public {
        getDummyFacetStorage().dummyString = dummyString_;
    }

    receive() external payable {}
}
