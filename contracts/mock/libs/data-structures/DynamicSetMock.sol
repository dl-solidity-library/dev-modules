// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {DynamicSet} from "../../../libs/data-structures/DynamicSet.sol";

contract DynamicSetMock {
    using DynamicSet for *;

    DynamicSet.BytesSet internal _bytesSet;
    DynamicSet.StringSet internal _stringSet;

    function addBytes(bytes calldata value_) external returns (bool) {
        return _bytesSet.add(value_);
    }

    function addString(string calldata value_) external returns (bool) {
        return _stringSet.add(value_);
    }

    function removeBytes(bytes calldata value_) external returns (bool) {
        return _bytesSet.remove(value_);
    }

    function removeString(string calldata value_) external returns (bool) {
        return _stringSet.remove(value_);
    }

    function containsBytes(bytes calldata value_) external view returns (bool) {
        return _bytesSet.contains(value_);
    }

    function containsString(string calldata value_) external view returns (bool) {
        return _stringSet.contains(value_);
    }

    function lengthBytes() external view returns (uint256) {
        return _bytesSet.length();
    }

    function lengthString() external view returns (uint256) {
        return _stringSet.length();
    }

    function atBytes(uint256 index_) external view returns (bytes memory) {
        return _bytesSet.at(index_);
    }

    function atString(uint256 index_) external view returns (string memory) {
        return _stringSet.at(index_);
    }

    function valuesBytes() external view returns (bytes[] memory) {
        return _bytesSet.values();
    }

    function valuesString() external view returns (string[] memory) {
        return _stringSet.values();
    }

    function getBytesSet() external view returns (bytes[] memory set_) {
        set_ = new bytes[](_bytesSet.length());

        for (uint256 i = 0; i < set_.length; i++) {
            set_[i] = _bytesSet.at(i);
        }
    }

    function getStringSet() external view returns (string[] memory set_) {
        set_ = new string[](_stringSet.length());

        for (uint256 i = 0; i < set_.length; i++) {
            set_[i] = _stringSet.at(i);
        }
    }
}
