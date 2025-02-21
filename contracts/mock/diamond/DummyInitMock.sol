// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {DummyFacetMock} from "./DummyFacetMock.sol";

contract DummyInitMock is DummyFacetMock {
    event Initialized();

    error InitError();

    function init() external {
        setDummyString("dummy facet initialized");
        emit Initialized();
    }

    function initWithError() external pure {
        revert();
    }

    function initWithErrorMsg() external pure {
        revert InitError();
    }
}
