// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title MemoryUtils
 * @notice A library that provides utility functions for memory manipulation in Solidity.
 */
library MemoryUtils {
    /**
     * @notice Copies the contents of the source bytes to the destination bytes. strings can be casted
     * to bytes in order to use this function.
     *
     * @param source_ The source bytes to copy from.
     * @return destination_ The newly allocated bytes.
     */
    function copy(bytes memory source_) internal view returns (bytes memory destination_) {
        destination_ = new bytes(source_.length);

        unsafeCopy(getDataPointer(source_), getDataPointer(destination_), source_.length);
    }

    /**
     * @notice Copies the contents of the source bytes32 array to the destination bytes32 array.
     * uint256[], address[] array can be casted to bytes32[] via `TypeCaster` library.
     *
     * @param source_ The source bytes32 array to copy from.
     * @return destination_ The newly allocated bytes32 array.
     */
    function copy(bytes32[] memory source_) internal view returns (bytes32[] memory destination_) {
        destination_ = new bytes32[](source_.length);

        unsafeCopy(getDataPointer(source_), getDataPointer(destination_), source_.length * 32);
    }

    /**
     * @notice Copies memory from one location to another efficiently via identity precompile.
     * @param sourcePointer_ The offset in the memory from which to copy.
     * @param destinationPointer_ The offset in the memory where the result will be copied.
     * @param size_ The size of the memory to copy.
     *
     * @dev This function does not account for free memory pointer and should be used with caution.
     *
     * This signature of calling identity precompile is:
     * staticcall(gas(), address(0x04), argsOffset, argsSize, retOffset, retSize)
     */
    function unsafeCopy(
        uint256 sourcePointer_,
        uint256 destinationPointer_,
        uint256 size_
    ) internal view {
        assembly {
            pop(staticcall(gas(), 4, sourcePointer_, size_, destinationPointer_, size_))
        }
    }

    /**
     * @notice Returns the memory pointer to the given bytes starting position including the length.
     */
    function getPointer(bytes memory data_) internal pure returns (uint256 pointer_) {
        assembly {
            pointer_ := data_
        }
    }

    /**
     * @notice Returns the memory pointer to the given bytes starting position including the length.
     * Cast uint256[] and address[] to bytes32[] via `TypeCaster` library.
     */
    function getPointer(bytes32[] memory data_) internal pure returns (uint256 pointer_) {
        assembly {
            pointer_ := data_
        }
    }

    /**
     * @notice Returns the memory pointer to the given bytes data starting position skipping the length.
     */
    function getDataPointer(bytes memory data_) internal pure returns (uint256 pointer_) {
        assembly {
            pointer_ := add(data_, 32)
        }
    }

    /**
     * @notice Returns the memory pointer to the given bytes data starting position skipping the length.
     * Cast uint256[] and address[] to bytes32[] via `TypeCaster` library.
     */
    function getDataPointer(bytes32[] memory data_) internal pure returns (uint256 pointer_) {
        assembly {
            pointer_ := add(data_, 32)
        }
    }
}
