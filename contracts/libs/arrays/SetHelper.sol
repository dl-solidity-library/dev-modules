// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {DynamicSet} from "../data-structures/DynamicSet.sol";

/**
 * @notice A simple library to work with Openzeppelin sets
 */
library SetHelper {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using DynamicSet for *;

    error ElementAlreadyExistsAddress(address element);
    error ElementAlreadyExistsUint256(uint256 element);
    error ElementAlreadyExistsBytes32(bytes32 element);
    error ElementAlreadyExistsBytes(bytes element);
    error ElementAlreadyExistsString(string element);

    error NoSuchAddress(address element);
    error NoSuchUint256(uint256 element);
    error NoSuchBytes32(bytes32 element);
    error NoSuchBytes(bytes element);
    error NoSuchString(string element);

    /**
     * @notice The function to insert an array of elements into the address set
     * @param set the set to insert the elements into
     * @param array_ the elements to be inserted
     */
    function add(EnumerableSet.AddressSet storage set, address[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.add(array_[i]);
        }
    }

    /**
     * @notice The function to insert an array of elements into the uint256 set
     */
    function add(EnumerableSet.UintSet storage set, uint256[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.add(array_[i]);
        }
    }

    /**
     * @notice The function to insert an array of elements into the bytes32 set
     */
    function add(EnumerableSet.Bytes32Set storage set, bytes32[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.add(array_[i]);
        }
    }

    /**
     * @notice The function to insert an array of elements into the bytes set
     */
    function add(DynamicSet.BytesSet storage set, bytes[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.add(array_[i]);
        }
    }

    /**
     * @notice The function to insert an array of elements into the string set
     */
    function add(DynamicSet.StringSet storage set, string[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.add(array_[i]);
        }
    }

    /**
     * @notice The function for the strict insertion of an array of elements into the address set
     * @param set the set to insert the elements into
     * @param array_ the elements to be inserted
     */
    function strictAdd(EnumerableSet.AddressSet storage set, address[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            if (!set.add(array_[i])) revert ElementAlreadyExistsAddress(array_[i]);
        }
    }

    /**
     * @notice The function for the strict insertion of an array of elements into the uint256 set
     */
    function strictAdd(EnumerableSet.UintSet storage set, uint256[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            if (!set.add(array_[i])) revert ElementAlreadyExistsUint256(array_[i]);
        }
    }

    /**
     * @notice The function for the strict insertion of an array of elements into the bytes32 set
     */
    function strictAdd(EnumerableSet.Bytes32Set storage set, bytes32[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            if (!set.add(array_[i])) revert ElementAlreadyExistsBytes32(array_[i]);
        }
    }

    /**
     * @notice The function for the strict insertion of an array of elements into the bytes set
     */
    function strictAdd(DynamicSet.BytesSet storage set, bytes[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            if (!set.add(array_[i])) revert ElementAlreadyExistsBytes(array_[i]);
        }
    }

    /**
     * @notice The function for the strict insertion of an array of elements into the string set
     */
    function strictAdd(DynamicSet.StringSet storage set, string[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            if (!set.add(array_[i])) revert ElementAlreadyExistsString(array_[i]);
        }
    }

    /**
     * @notice The function to remove an array of elements from the address set
     * @param set the set to remove the elements from
     * @param array_ the elements to be removed
     */
    function remove(EnumerableSet.AddressSet storage set, address[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.remove(array_[i]);
        }
    }

    /**
     * @notice The function to remove an array of elements from the uint256 set
     */
    function remove(EnumerableSet.UintSet storage set, uint256[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.remove(array_[i]);
        }
    }

    /**
     * @notice The function to remove an array of elements from the bytes32 set
     */
    function remove(EnumerableSet.Bytes32Set storage set, bytes32[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.remove(array_[i]);
        }
    }

    /**
     * @notice The function to remove an array of elements from the bytes set
     */
    function remove(DynamicSet.BytesSet storage set, bytes[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.remove(array_[i]);
        }
    }

    /**
     * @notice The function to remove an array of elements from the string set
     */
    function remove(DynamicSet.StringSet storage set, string[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            set.remove(array_[i]);
        }
    }

    /**
     * @notice The function for the strict removal of an array of elements from the address set
     * @param set the set to remove the elements from
     * @param array_ the elements to be removed
     */
    function strictRemove(EnumerableSet.AddressSet storage set, address[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            if (!set.remove(array_[i])) revert NoSuchAddress(array_[i]);
        }
    }

    /**
     * @notice The function for the strict removal of an array of elements from the uint256 set
     */
    function strictRemove(EnumerableSet.UintSet storage set, uint256[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            if (!set.remove(array_[i])) revert NoSuchUint256(array_[i]);
        }
    }

    /**
     * @notice The function for the strict removal of an array of elements from the bytes32 set
     */
    function strictRemove(EnumerableSet.Bytes32Set storage set, bytes32[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            if (!set.remove(array_[i])) revert NoSuchBytes32(array_[i]);
        }
    }

    /**
     * @notice The function for the strict removal of an array of elements from the bytes set
     */
    function strictRemove(DynamicSet.BytesSet storage set, bytes[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            if (!set.remove(array_[i])) revert NoSuchBytes(array_[i]);
        }
    }

    /**
     * @notice The function for the strict removal of an array of elements from the string set
     */
    function strictRemove(DynamicSet.StringSet storage set, string[] memory array_) internal {
        for (uint256 i = 0; i < array_.length; i++) {
            if (!set.remove(array_[i])) revert NoSuchString(array_[i]);
        }
    }
}
