// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @notice A simple library to work with arrays
 */
library ArrayHelper {
    error InvalidRange(uint256 beginIndex, uint256 endIndex);

    /**
     * @notice The function that searches for the index of the first occurring element, which is
     * greater than or equal to the `element_`. The time complexity is O(log n)
     * @param array the array to search in
     * @param element_ the element
     * @return index_ the index of the found element or the length of the `array` if no such element
     */
    function lowerBound(
        uint256[] storage array,
        uint256 element_
    ) internal view returns (uint256 index_) {
        (uint256 low_, uint256 high_) = (0, array.length);

        while (low_ < high_) {
            uint256 mid_ = Math.average(low_, high_);

            if (array[mid_] >= element_) {
                high_ = mid_;
            } else {
                low_ = mid_ + 1;
            }
        }

        return high_;
    }

    /**
     * @notice The function that searches for the index of the first occurring element, which is
     * greater than the `element_`. The time complexity is O(log n)
     * @param array the array to search in
     * @param element_ the element
     * @return index_ the index of the found element or the length of the `array` if no such element
     */
    function upperBound(
        uint256[] storage array,
        uint256 element_
    ) internal view returns (uint256 index_) {
        (uint256 low_, uint256 high_) = (0, array.length);

        while (low_ < high_) {
            uint256 mid_ = Math.average(low_, high_);

            if (array[mid_] > element_) {
                high_ = mid_;
            } else {
                low_ = mid_ + 1;
            }
        }

        return high_;
    }

    /**
     * @notice The function that searches for the `element_` and returns whether it is present in the array.
     * The time complexity is O(log n)
     * @param array the array to search in
     * @param element_ the element
     * @return whether the `element_` is present in the array
     */
    function contains(uint256[] storage array, uint256 element_) internal view returns (bool) {
        (uint256 low_, uint256 high_) = (0, array.length);

        while (low_ < high_) {
            uint256 mid_ = Math.average(low_, high_);
            uint256 midElement_ = array[mid_];

            if (midElement_ == element_) {
                return true;
            } else if (midElement_ > element_) {
                high_ = mid_;
            } else {
                low_ = mid_ + 1;
            }
        }

        return false;
    }

    /**
     * @notice The function that calculates the sum of all array elements from `beginIndex_` to
     * `endIndex_` inclusive using its prefix sum array
     * @param beginIndex_ the index of the first range element
     * @param endIndex_ the index of the last range element
     * @return the sum of all elements of the range
     */
    function getRangeSum(
        uint256[] storage prefixes,
        uint256 beginIndex_,
        uint256 endIndex_
    ) internal view returns (uint256) {
        if (beginIndex_ > endIndex_) revert InvalidRange(beginIndex_, endIndex_);

        if (beginIndex_ == 0) {
            return prefixes[endIndex_];
        }

        return prefixes[endIndex_] - prefixes[beginIndex_ - 1];
    }

    /**
     * @notice The function to compute the prefix sum array
     * @param arr_ the initial array to be turned into the prefix sum array
     * @return prefixes_ the prefix sum array
     */
    function countPrefixes(
        uint256[] memory arr_
    ) internal pure returns (uint256[] memory prefixes_) {
        if (arr_.length == 0) {
            return prefixes_;
        }

        prefixes_ = new uint256[](arr_.length);
        prefixes_[0] = arr_[0];

        for (uint256 i = 1; i < prefixes_.length; i++) {
            prefixes_[i] = prefixes_[i - 1] + arr_[i];
        }
    }

    /**
     * @notice The function to reverse a uint256 array
     * @param arr_ the array to reverse
     * @return reversed_ the reversed array
     */
    function reverse(uint256[] memory arr_) internal pure returns (uint256[] memory reversed_) {
        reversed_ = new uint256[](arr_.length);
        uint256 i = arr_.length;

        while (i > 0) {
            i--;
            reversed_[arr_.length - 1 - i] = arr_[i];
        }
    }

    /**
     * @notice The function to reverse an address array
     */
    function reverse(address[] memory arr_) internal pure returns (address[] memory reversed_) {
        reversed_ = new address[](arr_.length);
        uint256 i = arr_.length;

        while (i > 0) {
            i--;
            reversed_[arr_.length - 1 - i] = arr_[i];
        }
    }

    /**
     * @notice The function to reverse a bool array
     */
    function reverse(bool[] memory arr_) internal pure returns (bool[] memory reversed_) {
        reversed_ = new bool[](arr_.length);
        uint256 i = arr_.length;

        while (i > 0) {
            i--;
            reversed_[arr_.length - 1 - i] = arr_[i];
        }
    }

    /**
     * @notice The function to reverse a string array
     */
    function reverse(string[] memory arr_) internal pure returns (string[] memory reversed_) {
        reversed_ = new string[](arr_.length);
        uint256 i = arr_.length;

        while (i > 0) {
            i--;
            reversed_[arr_.length - 1 - i] = arr_[i];
        }
    }

    /**
     * @notice The function to reverse a bytes32 array
     */
    function reverse(bytes32[] memory arr_) internal pure returns (bytes32[] memory reversed_) {
        reversed_ = new bytes32[](arr_.length);
        uint256 i = arr_.length;

        while (i > 0) {
            i--;
            reversed_[arr_.length - 1 - i] = arr_[i];
        }
    }

    /**
     * @notice The function to insert a uint256 array into the other array
     * @param to_ the array to insert into
     * @param index_ the insertion starting index
     * @param what_ the array to be inserted
     * @return the index to start the next insertion from
     */
    function insert(
        uint256[] memory to_,
        uint256 index_,
        uint256[] memory what_
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < what_.length; i++) {
            to_[index_ + i] = what_[i];
        }

        return index_ + what_.length;
    }

    /**
     * @notice The function to insert an address array into the other array
     */
    function insert(
        address[] memory to_,
        uint256 index_,
        address[] memory what_
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < what_.length; i++) {
            to_[index_ + i] = what_[i];
        }

        return index_ + what_.length;
    }

    /**
     * @notice The function to insert a bool array into the other array
     */
    function insert(
        bool[] memory to_,
        uint256 index_,
        bool[] memory what_
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < what_.length; i++) {
            to_[index_ + i] = what_[i];
        }

        return index_ + what_.length;
    }

    /**
     * @notice The function to insert a string array into the other array
     */
    function insert(
        string[] memory to_,
        uint256 index_,
        string[] memory what_
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < what_.length; i++) {
            to_[index_ + i] = what_[i];
        }

        return index_ + what_.length;
    }

    /**
     * @notice The function to insert a bytes32 array into the other array
     */
    function insert(
        bytes32[] memory to_,
        uint256 index_,
        bytes32[] memory what_
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < what_.length; i++) {
            to_[index_ + i] = what_[i];
        }

        return index_ + what_.length;
    }

    /**
     * @notice The function to crop a uint256 array
     * @param array_ the array to crop
     * @param newLength_ the new length of the array (has to be less or equal)
     * @return ref to cropped array
     */
    function crop(
        uint256[] memory array_,
        uint256 newLength_
    ) internal pure returns (uint256[] memory) {
        if (newLength_ < array_.length) {
            assembly {
                mstore(array_, newLength_)
            }
        }

        return array_;
    }

    /**
     * @notice The function to crop an address array
     */
    function crop(
        address[] memory array_,
        uint256 newLength_
    ) internal pure returns (address[] memory) {
        if (newLength_ < array_.length) {
            assembly {
                mstore(array_, newLength_)
            }
        }

        return array_;
    }

    /**
     * @notice The function to crop a bool array
     */
    function crop(bool[] memory array_, uint256 newLength_) internal pure returns (bool[] memory) {
        if (newLength_ < array_.length) {
            assembly {
                mstore(array_, newLength_)
            }
        }

        return array_;
    }

    /**
     * @notice The function to crop a string array
     */
    function crop(
        string[] memory array_,
        uint256 newLength_
    ) internal pure returns (string[] memory) {
        if (newLength_ < array_.length) {
            assembly {
                mstore(array_, newLength_)
            }
        }

        return array_;
    }

    /**
     * @notice The function to crop a bytes32 array
     */
    function crop(
        bytes32[] memory array_,
        uint256 newLength_
    ) internal pure returns (bytes32[] memory) {
        if (newLength_ < array_.length) {
            assembly {
                mstore(array_, newLength_)
            }
        }

        return array_;
    }
}
