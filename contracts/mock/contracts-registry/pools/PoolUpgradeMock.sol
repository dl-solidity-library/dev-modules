// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {PoolMock} from "./PoolMock.sol";

contract PoolUpgradeMock is PoolMock {
    function addedFunction() external pure returns (uint256) {
        return 42;
    }
}
