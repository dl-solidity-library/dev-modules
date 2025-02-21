// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {TypeCaster} from "../../../libs/utils/TypeCaster.sol";

contract TypeCasterMock {
    using TypeCaster for *;

    function asUint256ArrayFromBytes32Array(
        bytes32[] memory from_
    ) external pure returns (uint256[] memory) {
        return from_.asUint256Array();
    }

    function asUint256ArrayFromAddressArray(
        address[] memory from_
    ) external pure returns (uint256[] memory) {
        return from_.asUint256Array();
    }

    function asAddressArrayFromBytes32Array(
        bytes32[] memory from_
    ) external pure returns (address[] memory) {
        return from_.asAddressArray();
    }

    function asAddressArrayFromUint256Array(
        uint256[] memory from_
    ) external pure returns (address[] memory) {
        return from_.asAddressArray();
    }

    function asBytes32ArrayFromUint256Array(
        uint256[] memory from_
    ) external pure returns (bytes32[] memory) {
        return from_.asBytes32Array();
    }

    function asBytes32ArrayFromAddressArray(
        address[] memory from_
    ) external pure returns (bytes32[] memory) {
        return from_.asBytes32Array();
    }

    function asSingletonArrayFromUint256(uint256 from_) external pure returns (uint256[] memory) {
        return from_.asSingletonArray();
    }

    function asSingletonArrayFromAddress(address from_) external pure returns (address[] memory) {
        return from_.asSingletonArray();
    }

    function asSingletonArrayFromBool(bool from_) external pure returns (bool[] memory) {
        return from_.asSingletonArray();
    }

    function asSingletonArrayFromString(
        string memory from_
    ) external pure returns (string[] memory) {
        return from_.asSingletonArray();
    }

    function asSingletonArrayFromBytes32(bytes32 from_) external pure returns (bytes32[] memory) {
        return from_.asSingletonArray();
    }

    function testUint() external pure returns (bool) {
        return
            (1 == _testLength([uint256(1)].asDynamic())) &&
            (2 == _testLength([uint256(1), 2].asDynamic())) &&
            (3 == _testLength([uint256(2), 3, 2].asDynamic())) &&
            (4 == _testLength([uint256(2), 4, 3, 2].asDynamic())) &&
            (5 == _testLength([uint256(2), 3, 2, 1, 5].asDynamic()));
    }

    function testAddress() external pure returns (bool) {
        return
            (1 == _testLength([address(0)].asDynamic())) &&
            (2 == _testLength([address(0), address(1)].asDynamic())) &&
            (3 == _testLength([address(0), address(1), address(0)].asDynamic())) &&
            (4 == _testLength([address(0), address(1), address(0), address(1)].asDynamic())) &&
            (5 ==
                _testLength(
                    [address(0), address(1), address(0), address(1), address(0)].asDynamic()
                ));
    }

    function testBool() external pure returns (bool) {
        return
            (1 == _testLength([true].asDynamic())) &&
            (2 == _testLength([true, true].asDynamic())) &&
            (3 == _testLength([true, true, true].asDynamic())) &&
            (4 == _testLength([true, true, true, true].asDynamic())) &&
            (5 == _testLength([true, true, true, true, true].asDynamic()));
    }

    function testString() external pure returns (bool) {
        return
            (1 == _testLength([""].asDynamic())) &&
            (2 == _testLength(["", ""].asDynamic())) &&
            (3 == _testLength(["", "", ""].asDynamic())) &&
            (4 == _testLength(["", "", "", ""].asDynamic())) &&
            (5 == _testLength(["", "", "", "", ""].asDynamic()));
    }

    function testBytes32() external pure returns (bool) {
        return
            (1 == _testLength([bytes32(0)].asDynamic())) &&
            (2 == _testLength([bytes32(0), bytes32(0)].asDynamic())) &&
            (3 == _testLength([bytes32(0), bytes32(0), bytes32(0)].asDynamic())) &&
            (4 == _testLength([bytes32(0), bytes32(0), bytes32(0), bytes32(0)].asDynamic())) &&
            (5 ==
                _testLength(
                    [bytes32(0), bytes32(0), bytes32(0), bytes32(0), bytes32(0)].asDynamic()
                ));
    }

    function _testLength(uint256[] memory array_) internal pure returns (uint256) {
        return array_.length;
    }

    function _testLength(address[] memory array_) internal pure returns (uint256) {
        return array_.length;
    }

    function _testLength(bool[] memory array_) internal pure returns (uint256) {
        return array_.length;
    }

    function _testLength(string[] memory array_) internal pure returns (uint256) {
        return array_.length;
    }

    function _testLength(bytes32[] memory array_) internal pure returns (uint256) {
        return array_.length;
    }
}
