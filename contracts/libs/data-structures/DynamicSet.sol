// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @notice Dynamic Set Library
 *
 * This library provides implementation of two sets with dynamic data types: `BytesSet` and `StingSet`.
 * The library can also be used to create sets that store custom structures via ABI encoding.
 *
 * ## Usage example:
 *
 * ```
 * using DynamicSet for DynamicSet.BytesSet;
 *
 * DynamicSet.BytesSet internal _set;
 * ```
 */
library DynamicSet {
    /**
     *********************
     *      BytesSet     *
     *********************
     */

    struct BytesSet {
        Set _inner;
    }

    /**
     * @notice The function to add a bytes value to the set
     * @param set The BytesSet storage reference
     * @param value_ The value to be added
     * @return True if the value was added successfully, false otherwise
     */
    function add(BytesSet storage set, bytes memory value_) internal returns (bool) {
        return _add(set._inner, value_);
    }

    /**
     * @notice The function to remove a bytes value from the set
     * @param set The BytesSet storage reference
     * @param value_ The value to be removed
     * @return True if the value was removed successfully, false otherwise
     */
    function remove(BytesSet storage set, bytes memory value_) internal returns (bool) {
        return _remove(set._inner, value_);
    }

    /**
     * @notice The function to check if a value is contained in the set
     * @param set The BytesSet storage reference
     * @param value_ The value to be checked
     * @return True if the value is contained in the set, false otherwise
     */
    function contains(BytesSet storage set, bytes memory value_) internal view returns (bool) {
        return _contains(set._inner, value_);
    }

    /**
     * @notice The function to get the number of values in the set
     * @param set The BytesSet storage reference
     * @return The number of values in the set
     */
    function length(BytesSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @notice The function to get the value at the specified index in the set
     * @param set The BytesSet storage reference
     * @param index_ The index of the value to retrieve
     * @return The value at the specified index
     */
    function at(BytesSet storage set, uint256 index_) internal view returns (bytes memory) {
        return _at(set._inner, index_);
    }

    /**
     * @notice The function to get an array containing all values in the set
     * @param set The BytesSet storage reference
     * @return An array containing all values in the set
     */
    function values(BytesSet storage set) internal view returns (bytes[] memory) {
        return _values(set._inner);
    }

    /**
     *********************
     *     StringSet     *
     *********************
     */

    struct StringSet {
        Set _inner;
    }

    /**
     * @notice The function to add a string value to the set
     * @param set The StringSet storage reference
     * @param value_ The value to be added
     * @return True if the value was added successfully, false otherwise
     */
    function add(StringSet storage set, string memory value_) internal returns (bool) {
        return _add(set._inner, bytes(value_));
    }

    /**
     * @notice The function to remove a string value from the set
     * @param set The StringSet storage reference
     * @param value_ The value to be removed
     * @return True if the value was removed successfully, false otherwise
     */
    function remove(StringSet storage set, string memory value_) internal returns (bool) {
        return _remove(set._inner, bytes(value_));
    }

    /**
     * @notice The function to check if a value is contained in the set
     * @param set The StringSet storage reference
     * @param value_ The value to be checked
     * @return True if the value is contained in the set, false otherwise
     */
    function contains(StringSet storage set, string memory value_) internal view returns (bool) {
        return _contains(set._inner, bytes(value_));
    }

    /**
     * @notice The function to get the number of values in the set
     * @param set The StringSet storage reference
     * @return The number of values in the set
     */
    function length(StringSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @notice The function to get the value at the specified index in the set
     * @param set The StringSet storage reference
     * @param index_ The index of the value to retrieve
     * @return The value at the specified index
     */
    function at(StringSet storage set, uint256 index_) internal view returns (string memory) {
        return string(_at(set._inner, index_));
    }

    /**
     * @notice The function to get an array containing all values in the set
     * @param set The StringSet storage reference
     * @return values_ An array containing all values in the set
     */
    function values(StringSet storage set) internal view returns (string[] memory values_) {
        bytes[] memory store_ = _values(set._inner);

        assembly {
            values_ := store_
        }
    }

    struct Set {
        bytes[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes memory value_) internal returns (bool) {
        if (!_contains(set, value_)) {
            set._values.push(value_);
            set._indexes[keccak256(value_)] = set._values.length;

            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes memory value_) internal returns (bool) {
        bytes32 valueKey_ = keccak256(value_);
        uint256 valueIndex_ = set._indexes[valueKey_];

        if (valueIndex_ != 0) {
            uint256 toDeleteIndex_ = valueIndex_ - 1;
            uint256 lastIndex_ = set._values.length - 1;

            if (lastIndex_ != toDeleteIndex_) {
                bytes memory lastValue_ = set._values[lastIndex_];

                set._values[toDeleteIndex_] = lastValue_;
                set._indexes[keccak256(lastValue_)] = valueIndex_;
            }

            set._values.pop();

            delete set._indexes[valueKey_];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes memory value_) internal view returns (bool) {
        return set._indexes[keccak256(value_)] != 0;
    }

    function _length(Set storage set) internal view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index_) internal view returns (bytes memory) {
        return set._values[index_];
    }

    function _values(Set storage set) internal view returns (bytes[] memory) {
        return set._values;
    }
}
