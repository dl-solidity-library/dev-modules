// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {Vector} from "../../../../libs/data-structures/memory/Vector.sol";
import {TypeCaster} from "../../../../libs/utils/TypeCaster.sol";

contract VectorMock {
    using Vector for *;
    using TypeCaster for *;

    function testNew() external pure {
        assembly {
            mstore(
                add(mload(0x40), 0x40),
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            )
        }

        Vector.UintVector memory vector1_ = Vector.newUint();

        if (vector1_.length() != 0) revert();

        assembly {
            mstore(
                add(mload(0x40), 0x60),
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            )
            mstore(
                add(mload(0x40), 0x80),
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            )
            mstore(
                add(mload(0x40), 0x100),
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            )
        }

        Vector.UintVector memory vector2_ = Vector.newUint(3);

        if (vector2_.length() != 3) revert();

        for (uint256 i = 0; i < vector2_.length(); i++) {
            if (vector2_.at(i) != 0) revert();
        }
    }

    function testArrayPush() external pure {
        Vector.UintVector memory vector_ = Vector.newUint();

        if (vector_._vector._allocation != 5) revert();
        if (vector_.length() != 0) revert();

        vector_.push([uint256(1), 2, 3].asDynamic());

        if (vector_.length() != 3) revert();
    }

    function testPushAndPop() external pure {
        Vector.UintVector memory vector_ = Vector.newUint();

        if (vector_._vector._allocation != 5) revert();
        if (vector_.length() != 0) revert();

        vector_.push(1);
        vector_.push(2);
        vector_.push(3);

        if (vector_.length() != 3) revert();

        for (uint256 i = 0; i < vector_.length(); i++) {
            if (vector_.at(i) != i + 1) revert();
        }

        vector_.pop();

        if (vector_.length() != 2) revert();

        vector_.push(0);

        if (vector_.at(2) != 0) revert();
    }

    function testResize() external pure {
        Vector.UintVector memory vector_ = Vector.newUint(0);

        if (vector_._vector._allocation != 1) revert();
        if (vector_.length() != 0) revert();

        for (uint256 i = 0; i < 10; i++) {
            vector_.push(i);
        }

        if (vector_._vector._allocation != 16) revert();
        if (vector_.length() != 10) revert();

        uint256[] memory array_ = vector_.toArray();

        if (array_.length != 10) revert();

        for (uint256 i = 0; i < array_.length; i++) {
            if (array_[i] != i) revert();
        }
    }

    function testResizeAndSet() external pure {
        Vector.UintVector memory vector1_ = Vector.newUint(1);

        if (vector1_.length() != 1) revert();
        if (vector1_.at(0) != 0) revert();

        for (uint256 i = 1; i < 50; i++) {
            vector1_.push(i);
        }

        uint256[] memory array_ = vector1_.toArray();

        if (array_.length != 50) revert();

        Vector.UintVector memory vector2_ = Vector.newUint(array_);

        if (vector2_.length() != 50) revert();

        for (uint256 i = 0; i < 50; i++) {
            if (vector2_.at(i) != i) revert();

            vector2_.set(i, 50 - i);

            if (vector2_.at(i) != 50 - i) revert();
        }
    }

    function testEmptyPop() external pure {
        Vector.UintVector memory vector_ = Vector.newUint(0);

        vector_.pop();
    }

    function testEmptySet() external pure {
        Vector.UintVector memory vector_ = Vector.newUint(0);

        vector_.set(1, 0);
    }

    function testEmptyAt() external pure {
        Vector.UintVector memory vector_ = Vector.newUint(0);

        vector_.at(0);
    }

    function testUintFunctionality() external pure {
        Vector.UintVector memory vector_ = Vector.newUint();

        if (vector_.length() != 0) revert();

        vector_.push(1);
        vector_.set(0, 2);
        vector_.push(2);
        vector_.set(vector_.length() - 1, 3);

        uint256[] memory array_ = vector_.toArray();

        if (array_.length != 2) revert();
        if (array_[0] != 2) revert();
        if (array_[1] != 3) revert();

        array_[0] = 10;

        if (vector_.at(0) != 10) revert();

        vector_ = Vector.newUint(5);
        array_ = vector_.toArray();

        if (array_.length != 5) revert();

        vector_.push(0);
        vector_.pop();

        array_ = vector_.toArray();

        if (array_.length != 5) revert();

        array_[array_.length - 1] = 1;
        vector_ = Vector.newUint(array_);

        if (vector_.length() != 5) revert();
        if (vector_.at(vector_.length() - 1) != 1) revert();

        vector_.push([uint256(1), 2, 3].asDynamic());

        if (vector_.length() != 8) revert();
    }

    function testBytes32Functionality() external pure {
        Vector.Bytes32Vector memory vector_ = Vector.newBytes32();

        if (vector_.length() != 0) revert();

        vector_.push(bytes32(uint256(1)));
        vector_.set(0, bytes32(uint256(2)));
        vector_.push(bytes32(uint256(2)));
        vector_.set(vector_.length() - 1, bytes32(uint256(3)));

        bytes32[] memory array_ = vector_.toArray();

        if (array_.length != 2) revert();
        if (array_[0] != bytes32(uint256(2))) revert();
        if (array_[1] != bytes32(uint256(3))) revert();

        array_[0] = bytes32(uint256(10));

        if (vector_.at(0) != bytes32(uint256(10))) revert();

        vector_ = Vector.newBytes32(5);
        array_ = vector_.toArray();

        if (array_.length != 5) revert();

        vector_.push(0);
        vector_.pop();

        array_ = vector_.toArray();

        if (array_.length != 5) revert();

        array_[array_.length - 1] = bytes32(uint256(1));
        vector_ = Vector.newBytes32(array_);

        if (vector_.length() != 5) revert();
        if (vector_.at(vector_.length() - 1) != bytes32(uint256(1))) revert();

        vector_.push([bytes32(uint256(5)), bytes32(uint256(4)), bytes32(uint256(3))].asDynamic());

        if (vector_.length() != 8) revert();
    }

    function testAddressFunctionality() external pure {
        Vector.AddressVector memory vector_ = Vector.newAddress();

        if (vector_.length() != 0) revert();

        vector_.push(address(1));
        vector_.set(0, address(2));
        vector_.push(address(2));
        vector_.set(vector_.length() - 1, address(3));

        address[] memory array_ = vector_.toArray();

        if (array_.length != 2) revert();
        if (array_[0] != address(2)) revert();
        if (array_[1] != address(3)) revert();

        array_[0] = address(10);

        if (vector_.at(0) != address(10)) revert();

        vector_ = Vector.newAddress(5);
        array_ = vector_.toArray();

        if (array_.length != 5) revert();

        vector_.push(address(0));
        vector_.pop();

        array_ = vector_.toArray();

        if (array_.length != 5) revert();

        array_[array_.length - 1] = address(1);
        vector_ = Vector.newAddress(array_);

        if (vector_.length() != 5) revert();
        if (vector_.at(vector_.length() - 1) != address(1)) revert();

        vector_.push([address(5), address(4), address(3)].asDynamic());

        if (vector_.length() != 8) revert();
    }
}
