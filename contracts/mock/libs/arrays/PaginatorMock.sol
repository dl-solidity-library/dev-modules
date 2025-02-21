// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {DynamicSet} from "../../../libs/data-structures/DynamicSet.sol";
import {Paginator} from "../../../libs/arrays/Paginator.sol";

contract PaginatorMock {
    using Paginator for *;
    using EnumerableSet for *;
    using DynamicSet for *;
    using Strings for uint256;

    uint256[] internal _uintArr;
    address[] internal _addressArr;
    bytes32[] internal _bytes32Arr;
    EnumerableSet.UintSet internal _uintSet;
    EnumerableSet.AddressSet internal _addressSet;
    EnumerableSet.Bytes32Set internal _bytes32Set;
    DynamicSet.BytesSet internal _bytesSet;
    DynamicSet.StringSet internal _stringSet;

    function pushUint(uint256 length_) external {
        for (uint256 i; i < length_; i++) {
            _uintArr.push(100 + i);
            _uintSet.add(100 + i);
        }
    }

    function pushAddress(uint256 length_) external {
        for (uint256 i; i < length_; i++) {
            _addressArr.push(address(uint160(i)));
            _addressSet.add(address(uint160(i)));
        }
    }

    function pushBytes32(uint256 length_) external {
        for (uint256 i; i < length_; i++) {
            _bytes32Arr.push(bytes32(i));
            _bytes32Set.add(bytes32(i));
        }
    }

    function pushBytes(uint256 length_) external {
        for (uint256 i = 0; i < length_; i++) {
            _bytesSet.add(abi.encode(i));
        }
    }

    function pushString(uint256 length_) external {
        for (uint256 i = 0; i < length_; i++) {
            _stringSet.add(i.toString());
        }
    }

    function partUintArr(
        uint256 offset_,
        uint256 limit_
    ) external view returns (uint256[] memory) {
        return _uintArr.part(offset_, limit_);
    }

    function partUintSet(
        uint256 offset_,
        uint256 limit_
    ) external view returns (uint256[] memory) {
        return _uintSet.part(offset_, limit_);
    }

    function partAddressArr(
        uint256 offset_,
        uint256 limit_
    ) external view returns (address[] memory) {
        return _addressArr.part(offset_, limit_);
    }

    function partAddressSet(
        uint256 offset_,
        uint256 limit_
    ) external view returns (address[] memory) {
        return _addressSet.part(offset_, limit_);
    }

    function partBytes32Arr(
        uint256 offset_,
        uint256 limit_
    ) external view returns (bytes32[] memory) {
        return _bytes32Arr.part(offset_, limit_);
    }

    function partBytes32Set(
        uint256 offset_,
        uint256 limit_
    ) external view returns (bytes32[] memory) {
        return _bytes32Set.part(offset_, limit_);
    }

    function partBytesSet(uint256 offset_, uint256 limit_) external view returns (bytes[] memory) {
        return _bytesSet.part(offset_, limit_);
    }

    function partStringSet(
        uint256 offset_,
        uint256 limit_
    ) external view returns (string[] memory) {
        return _stringSet.part(offset_, limit_);
    }
}
