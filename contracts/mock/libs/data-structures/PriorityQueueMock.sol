// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {PriorityQueue} from "../../../libs/data-structures/PriorityQueue.sol";

contract PriorityQueueMock {
    using PriorityQueue for *;

    PriorityQueue.UintQueue internal _uintQueue;
    PriorityQueue.AddressQueue internal _addressQueue;
    PriorityQueue.Bytes32Queue internal _bytes32Queue;

    // Uint

    function addUint(uint256 value_, uint256 priority_) external {
        _uintQueue.add(value_, priority_);
    }

    function removeTopUint() external {
        _uintQueue.removeTop();
    }

    function topValueUint() external view returns (uint256) {
        return _uintQueue.topValue();
    }

    function topUint() external view returns (uint256, uint256) {
        return _uintQueue.top();
    }

    function lengthUint() external view returns (uint256) {
        return _uintQueue.length();
    }

    function valuesUint() external view returns (uint256[] memory) {
        return _uintQueue.values();
    }

    function elementsUint() external view returns (uint256[] memory, uint256[] memory) {
        return _uintQueue.elements();
    }

    // bytes32

    function addBytes32(bytes32 value_, uint256 priority_) external {
        _bytes32Queue.add(value_, priority_);
    }

    function removeTopBytes32() external {
        _bytes32Queue.removeTop();
    }

    function topValueBytes32() external view returns (bytes32) {
        return _bytes32Queue.topValue();
    }

    function topBytes32() external view returns (bytes32, uint256) {
        return _bytes32Queue.top();
    }

    function lengthBytes32() external view returns (uint256) {
        return _bytes32Queue.length();
    }

    function valuesBytes32() external view returns (bytes32[] memory) {
        return _bytes32Queue.values();
    }

    function elementsBytes32() external view returns (bytes32[] memory, uint256[] memory) {
        return _bytes32Queue.elements();
    }

    // Address

    function addAddress(address value_, uint256 priority_) external {
        _addressQueue.add(value_, priority_);
    }

    function removeTopAddress() external {
        _addressQueue.removeTop();
    }

    function topValueAddress() external view returns (address) {
        return _addressQueue.topValue();
    }

    function topAddress() external view returns (address, uint256) {
        return _addressQueue.top();
    }

    function lengthAddress() external view returns (uint256) {
        return _addressQueue.length();
    }

    function valuesAddress() external view returns (address[] memory) {
        return _addressQueue.values();
    }

    function elementsAddress() external view returns (address[] memory, uint256[] memory) {
        return _addressQueue.elements();
    }
}
