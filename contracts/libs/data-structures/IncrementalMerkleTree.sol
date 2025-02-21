// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @notice Incremental Merkle Tree module
 *
 * This implementation is a modification of the Incremental Merkle Tree data structure described
 * in [Deposit Contract Verification](https://github.com/runtimeverification/deposit-contract-verification/blob/master/deposit-contract-verification.pdf).
 *
 * This implementation aims to optimize and improve the original data structure.
 *
 * The main differences are:
 * - No explicit constructor; the tree is initialized when the first element is added
 * - Growth is not constrained; the height of the tree automatically increases as elements are added
 *
 * Zero hashes are computed each time the getRoot function is called.
 *
 * Gas usage for _add and _root functions (where count is the number of elements added to the tree):
 *
 * | Statistic | _add         | _root            |
 * | --------- | ------------ | ---------------- |
 * | count     | 49999        | 49999            |
 * | mean      | 38972 gas    | 60213 gas        |
 * | std       | 3871 gas     | 4996 gas         |
 * | min       | 36251 gas    | 31238 gas        |
 * | 25%       | 36263 gas    | 57020 gas        |
 * | 50%       | 38954 gas    | 60292 gas        |
 * | 75%       | 41657 gas    | 63564 gas        |
 * | max       | 96758 gas    | 78071 gas        |
 *
 * ## Usage example:
 *
 * ```
 * using IncrementalMerkleTree for IncrementalMerkleTree.UintIMT;
 *
 * IncrementalMerkleTree.UintIMT internal uintTree;
 *
 * ................................................
 *
 * uintTree.add(1234);
 *
 * uintTree.root();
 *
 * uintTree.height();
 *
 * uintTree.length();
 * ```
 */
library IncrementalMerkleTree {
    /**
     *********************
     *      UintIMT      *
     *********************
     */

    struct UintIMT {
        IMT _tree;
    }

    error NewHeightMustBeGreater(uint256 currentHeight, uint256 newHeight);
    error TreeIsNotEmpty();
    error TreeIsFull();

    /**
     * @notice The function to set the height of the uint256 tree.
     * Complexity is O(1).
     *
     * @param tree self.
     * @param height_ The new height of the Merkle tree. Should be greater than the current one.
     */
    function setHeight(UintIMT storage tree, uint256 height_) internal {
        _setHeight(tree._tree, height_);
    }

    /**
     * @notice The function to add a new element to the uint256 tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     *
     * @param tree self.
     * @param element_ The new element to add.
     */
    function add(UintIMT storage tree, uint256 element_) internal {
        _add(tree._tree, bytes32(element_));
    }

    /**
     * @notice The function to set a custom hash functions, that will be used to build the Merkle Tree.
     *
     * @param tree self.
     * @param hash1_ The hash function that accepts one argument.
     * @param hash2_ The hash function that accepts two arguments.
     */
    function setHashers(
        UintIMT storage tree,
        function(bytes32) view returns (bytes32) hash1_,
        function(bytes32, bytes32) view returns (bytes32) hash2_
    ) internal {
        _setHashers(tree._tree, hash1_, hash2_);
    }

    /**
     * @notice The function to return the root hash of the uint256 tree.
     * Complexity is O(log(n) + h), where n is the number of elements in the tree and
     * h is the height of the tree.
     *
     * @param tree self.
     * @return The root hash of the Merkle tree.
     */
    function root(UintIMT storage tree) internal view returns (bytes32) {
        return _root(tree._tree);
    }

    /**
     * @notice The function to return the height of the uint256 tree. Complexity is O(1).
     * @param tree self.
     * @return The height of the Merkle tree.
     */
    function height(UintIMT storage tree) internal view returns (uint256) {
        return _height(tree._tree);
    }

    /**
     * @notice The function to return the number of elements in the uint256 tree. Complexity is O(1).
     * @param tree self.
     * @return The number of elements in the Merkle tree.
     */
    function length(UintIMT storage tree) internal view returns (uint256) {
        return _length(tree._tree);
    }

    /**
     * @notice The function to check whether the custom hash functions are set.
     * @param tree self.
     * @return True if the custom hash functions are set, false otherwise.
     */
    function isCustomHasherSet(UintIMT storage tree) internal view returns (bool) {
        return tree._tree.isCustomHasherSet;
    }

    /**
     **********************
     *     Bytes32IMT     *
     **********************
     */

    struct Bytes32IMT {
        IMT _tree;
    }

    /**
     * @notice The function to set the height of the bytes32 tree.
     * Complexity is O(1).
     *
     * @param tree self.
     * @param height_ The new height of the Merkle tree. Should be greater than the current one.
     */
    function setHeight(Bytes32IMT storage tree, uint256 height_) internal {
        _setHeight(tree._tree, height_);
    }

    /**
     * @notice The function to add a new element to the bytes32 tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     */
    function add(Bytes32IMT storage tree, bytes32 element_) internal {
        _add(tree._tree, element_);
    }

    /**
     * @notice The function to set a custom hash functions, that will be used to build the Merkle Tree.
     *
     * @param tree self.
     * @param hash1_ The hash function that accepts one argument.
     * @param hash2_ The hash function that accepts two arguments.
     */
    function setHashers(
        Bytes32IMT storage tree,
        function(bytes32) view returns (bytes32) hash1_,
        function(bytes32, bytes32) view returns (bytes32) hash2_
    ) internal {
        _setHashers(tree._tree, hash1_, hash2_);
    }

    /**
     * @notice The function to return the root hash of the bytes32 tree.
     * Complexity is O(log(n) + h), where n is the number of elements in the tree and
     * h is the height of the tree.
     */
    function root(Bytes32IMT storage tree) internal view returns (bytes32) {
        return _root(tree._tree);
    }

    /**
     * @notice The function to return the height of the bytes32 tree. Complexity is O(1).
     */
    function height(Bytes32IMT storage tree) internal view returns (uint256) {
        return _height(tree._tree);
    }

    /**
     * @notice The function to return the number of elements in the bytes32 tree. Complexity is O(1).
     */
    function length(Bytes32IMT storage tree) internal view returns (uint256) {
        return _length(tree._tree);
    }

    /**
     * @notice The function to check whether the custom hash functions are set.
     * @param tree self.
     * @return True if the custom hash functions are set, false otherwise.
     */
    function isCustomHasherSet(Bytes32IMT storage tree) internal view returns (bool) {
        return tree._tree.isCustomHasherSet;
    }

    /**
     ************************
     *      AddressIMT      *
     ************************
     */

    struct AddressIMT {
        IMT _tree;
    }

    /**
     * @notice The function to set the height of the address tree.
     * Complexity is O(1).
     *
     * @param tree self.
     * @param height_ The new height of the Merkle tree. Should be greater than the current one.
     */
    function setHeight(AddressIMT storage tree, uint256 height_) internal {
        _setHeight(tree._tree, height_);
    }

    /**
     * @notice The function to add a new element to the address tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     */
    function add(AddressIMT storage tree, address element_) internal {
        _add(tree._tree, bytes32(uint256(uint160(element_))));
    }

    /**
     * @notice The function to set a custom hash functions, that will be used to build the Merkle Tree.
     *
     * @param tree self.
     * @param hash1_ The hash function that accepts one argument.
     * @param hash2_ The hash function that accepts two arguments.
     */
    function setHashers(
        AddressIMT storage tree,
        function(bytes32) view returns (bytes32) hash1_,
        function(bytes32, bytes32) view returns (bytes32) hash2_
    ) internal {
        _setHashers(tree._tree, hash1_, hash2_);
    }

    /**
     * @notice The function to return the root hash of the address tree.
     * Complexity is O(log(n) + h), where n is the number of elements in the tree and
     * h is the height of the tree.
     */
    function root(AddressIMT storage tree) internal view returns (bytes32) {
        return _root(tree._tree);
    }

    /**
     * @notice The function to return the height of the address tree. Complexity is O(1).
     */
    function height(AddressIMT storage tree) internal view returns (uint256) {
        return _height(tree._tree);
    }

    /**
     * @notice The function to return the number of elements in the address tree. Complexity is O(1).
     */
    function length(AddressIMT storage tree) internal view returns (uint256) {
        return _length(tree._tree);
    }

    /**
     * @notice The function to check whether the custom hash functions are set.
     * @param tree self.
     * @return True if the custom hash functions are set, false otherwise.
     */
    function isCustomHasherSet(AddressIMT storage tree) internal view returns (bool) {
        return tree._tree.isCustomHasherSet;
    }

    /**
     ************************
     *       InnerIMT       *
     ************************
     */

    struct IMT {
        bytes32[] branches;
        uint256 leavesCount;
        bool isStrictHeightSet;
        bool isCustomHasherSet;
        function(bytes32) view returns (bytes32) hash1;
        function(bytes32, bytes32) view returns (bytes32) hash2;
    }

    function _setHeight(IMT storage tree, uint256 height_) private {
        uint256 currentHeight_ = _height(tree);

        if (height_ <= currentHeight_) revert NewHeightMustBeGreater(currentHeight_, height_);

        tree.isStrictHeightSet = true;

        assembly {
            sstore(tree.slot, height_)
        }
    }

    function _setHashers(
        IMT storage tree,
        function(bytes32) view returns (bytes32) hash1_,
        function(bytes32, bytes32) view returns (bytes32) hash2_
    ) private {
        if (_length(tree) != 0) revert TreeIsNotEmpty();

        tree.isCustomHasherSet = true;

        tree.hash1 = hash1_;
        tree.hash2 = hash2_;
    }

    function _add(IMT storage tree, bytes32 element_) private {
        function(bytes32) view returns (bytes32) hash1_ = tree.isCustomHasherSet
            ? tree.hash1
            : _hash1;
        function(bytes32, bytes32) view returns (bytes32) hash2_ = tree.isCustomHasherSet
            ? tree.hash2
            : _hash2;

        bytes32 resultValue_ = hash1_(element_);

        uint256 index_ = 0;
        uint256 size_ = ++tree.leavesCount;
        uint256 treeHeight_ = tree.branches.length;

        while (index_ < treeHeight_) {
            if (size_ & 1 == 1) {
                break;
            }

            bytes32 branch_ = tree.branches[index_];
            resultValue_ = hash2_(branch_, resultValue_);

            size_ >>= 1;
            ++index_;
        }

        if (index_ == treeHeight_) {
            if (tree.isStrictHeightSet) revert TreeIsFull();

            tree.branches.push(resultValue_);
        } else {
            tree.branches[index_] = resultValue_;
        }
    }

    function _root(IMT storage tree) private view returns (bytes32) {
        function(bytes32) view returns (bytes32) hash1_ = tree.isCustomHasherSet
            ? tree.hash1
            : _hash1;
        function(bytes32, bytes32) view returns (bytes32) hash2_ = tree.isCustomHasherSet
            ? tree.hash2
            : _hash2;

        uint256 treeHeight_ = tree.branches.length;

        if (treeHeight_ == 0) {
            return hash1_(bytes32(0));
        }

        uint256 height_;
        uint256 size_ = tree.leavesCount;
        bytes32 root_ = hash1_(bytes32(0));
        bytes32[] memory zeroHashes_ = _getZeroHashes(tree, treeHeight_);

        while (height_ < treeHeight_) {
            if (size_ & 1 == 1) {
                bytes32 branch_ = tree.branches[height_];

                root_ = hash2_(branch_, root_);
            } else {
                bytes32 zeroHash_ = zeroHashes_[height_];

                root_ = hash2_(root_, zeroHash_);
            }

            size_ >>= 1;
            ++height_;
        }

        return root_;
    }

    function _height(IMT storage tree) private view returns (uint256) {
        return tree.branches.length;
    }

    function _length(IMT storage tree) private view returns (uint256) {
        return tree.leavesCount;
    }

    function _getZeroHashes(
        IMT storage tree,
        uint256 height_
    ) private view returns (bytes32[] memory) {
        function(bytes32) view returns (bytes32) hash1_ = tree.isCustomHasherSet
            ? tree.hash1
            : _hash1;
        function(bytes32, bytes32) view returns (bytes32) hash2_ = tree.isCustomHasherSet
            ? tree.hash2
            : _hash2;

        bytes32[] memory zeroHashes_ = new bytes32[](height_);

        zeroHashes_[0] = hash1_(bytes32(0));

        for (uint256 i = 1; i < height_; ++i) {
            bytes32 prevHash_ = zeroHashes_[i - 1];

            zeroHashes_[i] = hash2_(prevHash_, prevHash_);
        }

        return zeroHashes_;
    }

    function _hash1(bytes32 a) private pure returns (bytes32 result) {
        assembly {
            mstore(0, a)

            result := keccak256(0, 32)
        }
    }

    function _hash2(bytes32 a, bytes32 b) private pure returns (bytes32 result) {
        assembly {
            mstore(0, a)
            mstore(32, b)

            result := keccak256(0, 64)
        }
    }
}
