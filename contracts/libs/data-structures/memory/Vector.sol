// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {TypeCaster} from "../../utils/TypeCaster.sol";

/**
 * @notice The memory data structures module
 *
 * This library is inspired by C++ STD vector to enable push() and pop() operations for memory arrays.
 *
 * Currently Solidity allows resizing only storage arrays, which may be a roadblock if you need to
 * filter the elements by a specific property or add new ones without writing bulky code. The Vector library
 * is meant to help with that.
 *
 * It is very important to create Vectors via constructors (newUint, newBytes32, newAddress) as they allocate and clean
 * the memory for the data structure.
 *
 * The Vector works by knowing how much memory it uses (allocation) and keeping the reference to the underlying
 * low-level Solidity array. When a new element gets pushed, the Vector tries to store it in the underlying array. If the
 * number of elements exceed the allocation, the Vector will reallocate the array to a bigger memory chunk and store the
 * new element there.
 *
 * ## Usage example:
 * ```
 * using Vector for Vector.UintVector;
 *
 * Vector.UintVector memory vector = Vector.newUint();
 *
 * vector.push(123);
 * ```
 */
library Vector {
    using TypeCaster for *;

    /**
     ************************
     *      UintVector      *
     ************************
     */

    struct UintVector {
        Vector _vector;
    }

    error IndexOutOfBounds(uint256 index, uint256 vectorLength);
    error PopEmptyVector();

    /**
     * @notice The UintVector constructor, creates an empty vector instance, O(1) complex
     * @return vector the newly created instance
     */
    function newUint() internal pure returns (UintVector memory vector) {
        vector._vector = _new();
    }

    /**
     * @notice The UintVector constructor, creates a vector instance with defined length, O(n) complex
     * @dev The length_ number of default value elements will be added to the vector
     * @param length_ the initial number of elements
     * @return vector the newly created instance
     */
    function newUint(uint256 length_) internal pure returns (UintVector memory vector) {
        vector._vector = _new(length_);
    }

    /**
     * @notice The UintVector constructor, creates a vector instance from the array, O(1) complex
     * @param array_ the initial array
     * @return vector the newly created instance
     */
    function newUint(uint256[] memory array_) internal pure returns (UintVector memory vector) {
        vector._vector = _new(array_.asBytes32Array());
    }

    /**
     * @notice The function to push new elements (as an array) to the uint256 vector, amortized O(n)
     * @param vector self
     * @param values_ the new elements to add
     */
    function push(UintVector memory vector, uint256[] memory values_) internal pure {
        _push(vector._vector, values_.asBytes32Array());
    }

    /**
     * @notice The function to push a new element to the uint256 vector, amortized O(1)
     * @param vector self
     * @param value_ the new element to add
     */
    function push(UintVector memory vector, uint256 value_) internal pure {
        _push(vector._vector, bytes32(value_));
    }

    /**
     * @notice The function to pop the last element from the uint256 vector, O(1)
     * @param vector self
     */
    function pop(UintVector memory vector) internal pure {
        _pop(vector._vector);
    }

    /**
     * @notice The function to assign the value to a uint256 vector element
     * @param vector self
     * @param index_ the index of the element to be assigned
     * @param value_ the value to assign
     */
    function set(UintVector memory vector, uint256 index_, uint256 value_) internal pure {
        _set(vector._vector, index_, bytes32(value_));
    }

    /**
     * @notice The function to read the element of the uint256 vector
     * @param vector self
     * @param index_ the index of the element to read
     * @return the vector element
     */
    function at(UintVector memory vector, uint256 index_) internal pure returns (uint256) {
        return uint256(_at(vector._vector, index_));
    }

    /**
     * @notice The function to get the number of uint256 vector elements
     * @param vector self
     * @return the number of vector elements
     */
    function length(UintVector memory vector) internal pure returns (uint256) {
        return _length(vector._vector);
    }

    /**
     * @notice The function to cast the uint256 vector to an array
     * @dev The function returns the *reference* to the underlying array. Modifying the reference
     * will also modify the vector itself. However, this might not always be the case as the vector
     * resizes
     * @param vector self
     * @return the reference to the solidity array of elements
     */
    function toArray(UintVector memory vector) internal pure returns (uint256[] memory) {
        return _toArray(vector._vector).asUint256Array();
    }

    /**
     ************************
     *     Bytes32Vector    *
     ************************
     */

    struct Bytes32Vector {
        Vector _vector;
    }

    /**
     * @notice The Bytes32Vector constructor, creates an empty vector instance, O(1) complex
     */
    function newBytes32() internal pure returns (Bytes32Vector memory vector) {
        vector._vector = _new();
    }

    /**
     * @notice The Bytes32Vector constructor, creates a vector instance with defined length, O(n) complex
     */
    function newBytes32(uint256 length_) internal pure returns (Bytes32Vector memory vector) {
        vector._vector = _new(length_);
    }

    /**
     * @notice The Bytes32Vector constructor, creates a vector instance from the array, O(1) complex
     */
    function newBytes32(
        bytes32[] memory array_
    ) internal pure returns (Bytes32Vector memory vector) {
        vector._vector = _new(array_);
    }

    /**
     * @notice The function to push new elements (as an array) to the bytes32 vector, amortized O(n)
     */
    function push(Bytes32Vector memory vector, bytes32[] memory values_) internal pure {
        _push(vector._vector, values_);
    }

    /**
     * @notice The function to push a new element to the bytes32 vector, amortized O(1)
     */
    function push(Bytes32Vector memory vector, bytes32 value_) internal pure {
        _push(vector._vector, value_);
    }

    /**
     * @notice The function to pop the last element from the bytes32 vector, O(1)
     */
    function pop(Bytes32Vector memory vector) internal pure {
        _pop(vector._vector);
    }

    /**
     * @notice The function to assign the value to a bytes32 vector element
     */
    function set(Bytes32Vector memory vector, uint256 index_, bytes32 value_) internal pure {
        _set(vector._vector, index_, value_);
    }

    /**
     * @notice The function to read the element of the bytes32 vector
     */
    function at(Bytes32Vector memory vector, uint256 index_) internal pure returns (bytes32) {
        return _at(vector._vector, index_);
    }

    /**
     * @notice The function to get the number of bytes32 vector elements
     */
    function length(Bytes32Vector memory vector) internal pure returns (uint256) {
        return _length(vector._vector);
    }

    /**
     * @notice The function to cast the bytes32 vector to an array
     */
    function toArray(Bytes32Vector memory vector) internal pure returns (bytes32[] memory) {
        return _toArray(vector._vector);
    }

    /**
     ************************
     *     AddressVector    *
     ************************
     */

    struct AddressVector {
        Vector _vector;
    }

    /**
     * @notice The AddressVector constructor, creates an empty vector instance, O(1) complex
     */
    function newAddress() internal pure returns (AddressVector memory vector) {
        vector._vector = _new();
    }

    /**
     * @notice The AddressVector constructor, creates a vector instance with defined length, O(n) complex
     */
    function newAddress(uint256 length_) internal pure returns (AddressVector memory vector) {
        vector._vector = _new(length_);
    }

    /**
     * @notice The AddressVector constructor, creates a vector instance from the array, O(1) complex
     */
    function newAddress(
        address[] memory array_
    ) internal pure returns (AddressVector memory vector) {
        vector._vector = _new(array_.asBytes32Array());
    }

    /**
     * @notice The function to push new elements (as an array) to the address vector, amortized O(n)
     */
    function push(AddressVector memory vector, address[] memory values_) internal pure {
        _push(vector._vector, values_.asBytes32Array());
    }

    /**
     * @notice The function to push a new element to the address vector, amortized O(1)
     */
    function push(AddressVector memory vector, address value_) internal pure {
        _push(vector._vector, bytes32(uint256(uint160(value_))));
    }

    /**
     * @notice The function to pop the last element from the address vector, O(1)
     */
    function pop(AddressVector memory vector) internal pure {
        _pop(vector._vector);
    }

    /**
     * @notice The function to assign the value to an address vector element
     */
    function set(AddressVector memory vector, uint256 index_, address value_) internal pure {
        _set(vector._vector, index_, bytes32(uint256(uint160(value_))));
    }

    /**
     * @notice The function to read the element of the address vector
     */
    function at(AddressVector memory vector, uint256 index_) internal pure returns (address) {
        return address(uint160(uint256(_at(vector._vector, index_))));
    }

    /**
     * @notice The function to get the number of address vector elements
     */
    function length(AddressVector memory vector) internal pure returns (uint256) {
        return _length(vector._vector);
    }

    /**
     * @notice The function to cast the address vector to an array
     */
    function toArray(AddressVector memory vector) internal pure returns (address[] memory) {
        return _toArray(vector._vector).asAddressArray();
    }

    /**
     ************************
     *      InnerVector     *
     ************************
     */

    struct Vector {
        uint256 _allocation;
        uint256 _dataPointer;
    }

    function _new() private pure returns (Vector memory vector) {
        uint256 dataPointer_ = _allocate(5);

        _clean(dataPointer_, 1);

        vector._allocation = 5;
        vector._dataPointer = dataPointer_;
    }

    function _new(uint256 length_) private pure returns (Vector memory vector) {
        uint256 allocation_ = length_ + 1;
        uint256 dataPointer_ = _allocate(allocation_);

        _clean(dataPointer_, allocation_);

        vector._allocation = allocation_;
        vector._dataPointer = dataPointer_;

        assembly {
            mstore(dataPointer_, length_)
        }
    }

    function _new(bytes32[] memory array_) private pure returns (Vector memory vector) {
        assembly {
            mstore(vector, add(mload(array_), 0x1))
            mstore(add(vector, 0x20), array_)
        }
    }

    function _push(Vector memory vector, bytes32[] memory values_) private pure {
        uint256 length_ = values_.length;

        for (uint256 i = 0; i < length_; ++i) {
            _push(vector, values_[i]);
        }
    }

    function _push(Vector memory vector, bytes32 value_) private pure {
        uint256 length_ = _length(vector);

        if (length_ + 1 == vector._allocation) {
            _resize(vector, vector._allocation * 2);
        }

        assembly {
            let dataPointer_ := mload(add(vector, 0x20))

            mstore(dataPointer_, add(length_, 0x1))
            mstore(add(dataPointer_, add(mul(length_, 0x20), 0x20)), value_)
        }
    }

    function _pop(Vector memory vector) private pure {
        uint256 length_ = _length(vector);

        if (length_ == 0) revert PopEmptyVector();

        assembly {
            mstore(mload(add(vector, 0x20)), sub(length_, 0x1))
        }
    }

    function _set(Vector memory vector, uint256 index_, bytes32 value_) private pure {
        _requireInBounds(vector, index_);

        assembly {
            mstore(add(mload(add(vector, 0x20)), add(mul(index_, 0x20), 0x20)), value_)
        }
    }

    function _at(Vector memory vector, uint256 index_) private pure returns (bytes32 value_) {
        _requireInBounds(vector, index_);

        assembly {
            value_ := mload(add(mload(add(vector, 0x20)), add(mul(index_, 0x20), 0x20)))
        }
    }

    function _length(Vector memory vector) private pure returns (uint256 length_) {
        assembly {
            length_ := mload(mload(add(vector, 0x20)))
        }
    }

    function _toArray(Vector memory vector) private pure returns (bytes32[] memory array_) {
        assembly {
            array_ := mload(add(vector, 0x20))
        }
    }

    function _resize(Vector memory vector, uint256 newAllocation_) private pure {
        uint256 newDataPointer_ = _allocate(newAllocation_);

        assembly {
            let oldDataPointer_ := mload(add(vector, 0x20))
            let length_ := mload(oldDataPointer_)

            for {
                let i := 0
            } lt(i, add(mul(length_, 0x20), 0x20)) {
                i := add(i, 0x20)
            } {
                mstore(add(newDataPointer_, i), mload(add(oldDataPointer_, i)))
            }

            mstore(vector, newAllocation_)
            mstore(add(vector, 0x20), newDataPointer_)
        }
    }

    function _requireInBounds(Vector memory vector, uint256 index_) private pure {
        if (index_ >= _length(vector)) revert IndexOutOfBounds(index_, _length(vector));
    }

    function _clean(uint256 dataPointer_, uint256 slots_) private pure {
        assembly {
            for {
                let i := 0
            } lt(i, mul(slots_, 0x20)) {
                i := add(i, 0x20)
            } {
                mstore(add(dataPointer_, i), 0x0)
            }
        }
    }

    function _allocate(uint256 allocation_) private pure returns (uint256 pointer_) {
        assembly {
            pointer_ := mload(0x40)
            mstore(0x40, add(pointer_, mul(allocation_, 0x20)))
        }
    }
}
