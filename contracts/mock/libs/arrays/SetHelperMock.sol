// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {DynamicSet} from "../../../libs/data-structures/DynamicSet.sol";
import {SetHelper} from "../../../libs/arrays/SetHelper.sol";

contract SetHelperMock {
    using EnumerableSet for *;
    using DynamicSet for *;
    using SetHelper for *;

    EnumerableSet.AddressSet internal addressSet;
    EnumerableSet.UintSet internal uintSet;
    EnumerableSet.Bytes32Set internal bytes32Set;
    DynamicSet.BytesSet internal bytesSet;
    DynamicSet.StringSet internal stringSet;

    function addToAddressSet(address[] memory arr_) external {
        addressSet.add(arr_);
    }

    function addToUintSet(uint256[] memory arr_) external {
        uintSet.add(arr_);
    }

    function addToBytes32Set(bytes32[] memory arr_) external {
        bytes32Set.add(arr_);
    }

    function addToBytesSet(bytes[] memory arr_) external {
        bytesSet.add(arr_);
    }

    function addToStringSet(string[] memory arr_) external {
        stringSet.add(arr_);
    }

    function strictAddToAddressSet(address[] memory arr_) external {
        addressSet.strictAdd(arr_);
    }

    function strictAddToUintSet(uint256[] memory arr_) external {
        uintSet.strictAdd(arr_);
    }

    function strictAddToBytes32Set(bytes32[] memory arr_) external {
        bytes32Set.strictAdd(arr_);
    }

    function strictAddToBytesSet(bytes[] memory arr_) external {
        bytesSet.strictAdd(arr_);
    }

    function strictAddToStringSet(string[] memory arr_) external {
        stringSet.strictAdd(arr_);
    }

    function removeFromAddressSet(address[] memory arr_) external {
        addressSet.remove(arr_);
    }

    function removeFromUintSet(uint256[] memory arr_) external {
        uintSet.remove(arr_);
    }

    function removeFromBytes32Set(bytes32[] memory arr_) external {
        bytes32Set.remove(arr_);
    }

    function removeFromBytesSet(bytes[] memory arr_) external {
        bytesSet.remove(arr_);
    }

    function removeFromStringSet(string[] memory arr_) external {
        stringSet.remove(arr_);
    }

    function strictRemoveFromAddressSet(address[] memory arr_) external {
        addressSet.strictRemove(arr_);
    }

    function strictRemoveFromUintSet(uint256[] memory arr_) external {
        uintSet.strictRemove(arr_);
    }

    function strictRemoveFromBytes32Set(bytes32[] memory arr_) external {
        bytes32Set.strictRemove(arr_);
    }

    function strictRemoveFromBytesSet(bytes[] memory arr_) external {
        bytesSet.strictRemove(arr_);
    }

    function strictRemoveFromStringSet(string[] memory arr_) external {
        stringSet.strictRemove(arr_);
    }

    function getAddressSet() external view returns (address[] memory) {
        return addressSet.values();
    }

    function getUintSet() external view returns (uint256[] memory) {
        return uintSet.values();
    }

    function getBytes32Set() external view returns (bytes32[] memory) {
        return bytes32Set.values();
    }

    function getBytesSet() external view returns (bytes[] memory) {
        return bytesSet.values();
    }

    function getStringSet() external view returns (string[] memory) {
        return stringSet.values();
    }
}
