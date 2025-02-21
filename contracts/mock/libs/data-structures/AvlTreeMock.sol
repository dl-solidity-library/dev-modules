// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {TypeCaster} from "../../../libs/utils/TypeCaster.sol";

import {AvlTree, Traversal} from "../../../libs/data-structures/AvlTree.sol";

contract AvlTreeMock {
    using TypeCaster for *;
    using AvlTree for *;
    using Traversal for *;

    AvlTree.UintAVL internal _uintTree;
    AvlTree.Bytes32AVL internal _bytes32Tree;
    AvlTree.AddressAVL internal _addressTree;

    function setUintDescComparator() external {
        _uintTree.setComparator(_descComparator);
    }

    function setBytes32DescComparator() external {
        _bytes32Tree.setComparator(_descComparator);
    }

    function setAddressDescComparator() external {
        _addressTree.setComparator(_descComparator);
    }

    function insertUint(uint256 key_, uint256 value_) external {
        _uintTree.insert(bytes32(key_), value_);
    }

    function insertBytes32(uint256 key_, bytes32 value_) external {
        _bytes32Tree.insert(bytes32(key_), value_);
    }

    function insertAddress(uint256 key_, address value_) external {
        _addressTree.insert(bytes32(key_), value_);
    }

    function removeUint(uint256 key_) external {
        _uintTree.remove(bytes32(key_));
    }

    function removeBytes32(uint256 key_) external {
        _bytes32Tree.remove(bytes32(key_));
    }

    function removeAddress(uint256 key_) external {
        _addressTree.remove(bytes32(key_));
    }

    function getUint(uint256 key_) external view returns (uint256) {
        return _uintTree.get(bytes32(key_));
    }

    function getBytes32(uint256 key_) external view returns (bytes32) {
        return _bytes32Tree.get(bytes32(key_));
    }

    function getAddressValue(uint256 key_) external view returns (address) {
        return _addressTree.get(bytes32(key_));
    }

    function tryGetUint(uint256 key_) external view returns (bool, uint256) {
        return _uintTree.tryGet(bytes32(key_));
    }

    function tryGetBytes32(uint256 key_) external view returns (bool, bytes32) {
        return _bytes32Tree.tryGet(bytes32(key_));
    }

    function tryGetAddress(uint256 key_) external view returns (bool, address) {
        return _addressTree.tryGet(bytes32(key_));
    }

    function sizeUint() external view returns (uint64) {
        return _uintTree.size();
    }

    function sizeBytes32() external view returns (uint64) {
        return _bytes32Tree.size();
    }

    function sizeAddress() external view returns (uint64) {
        return _addressTree.size();
    }

    function rootUint() external view returns (uint256) {
        return uint256(_uintTree._tree.tree[_uintTree._tree.root].key);
    }

    function rootBytes32() external view returns (uint256) {
        return uint256(_bytes32Tree._tree.tree[_bytes32Tree._tree.root].key);
    }

    function rootAddress() external view returns (uint256) {
        return uint256(_addressTree._tree.tree[_addressTree._tree.root].key);
    }

    function traverseUint() external view returns (uint256[] memory, uint256[] memory) {
        (uint256[] memory keys_, bytes32[] memory values_) = _traverseAll(
            _uintTree.first(),
            _uintTree.size(),
            true
        );

        return (keys_, values_.asUint256Array());
    }

    function backwardsTraversalUint() external view returns (uint256[] memory, uint256[] memory) {
        (uint256[] memory keys_, bytes32[] memory values_) = _traverseAll(
            _uintTree.last(),
            _uintTree.size(),
            false
        );

        return (keys_, values_.asUint256Array());
    }

    function brokenTraversalUint() external view {
        Traversal.Iterator memory iterator_ = _uintTree.first();

        iterator_.currentNode = 0;
        iterator_.next();
    }

    function backAndForthTraverseUint()
        external
        view
        returns (uint256[] memory, uint256[] memory)
    {
        Traversal.Iterator memory iterator_ = _uintTree.first();

        uint256[] memory keys_ = new uint256[](12);
        uint256[] memory values_ = new uint256[](12);

        bool[12] memory directions_ = [
            true,
            true,
            false,
            true,
            false,
            false,
            true,
            true,
            true,
            true,
            true,
            true
        ];

        bytes32 bytesKey_;
        bytes32 bytesValue_;

        for (uint256 i = 0; i < 12; i++) {
            (bytesKey_, bytesValue_) = iterator_.value();

            keys_[i] = uint256(bytesKey_);
            values_[i] = uint256(bytesValue_);

            directions_[i] ? iterator_.next() : iterator_.prev();
        }

        return (keys_, values_);
    }

    function traverseBytes32() external view returns (uint256[] memory, bytes32[] memory) {
        return _traverseAll(_bytes32Tree.first(), _bytes32Tree.size(), true);
    }

    function backwardsTraversalBytes32()
        external
        view
        returns (uint256[] memory, bytes32[] memory)
    {
        return _traverseAll(_bytes32Tree.last(), _bytes32Tree.size(), false);
    }

    function traverseAddress() external view returns (uint256[] memory, address[] memory) {
        Traversal.Iterator memory iterator_ = _addressTree.first();

        bytes32[] memory keys_ = new bytes32[](_addressTree.size());
        bytes32[] memory values_ = new bytes32[](keys_.length);

        if (keys_.length != 0) {
            (keys_[0], values_[0]) = iterator_.value();
        }

        uint256 index_ = 1;

        while (iterator_.hasNext()) {
            (keys_[index_], values_[index_]) = iterator_.next();

            index_++;
        }

        return (keys_.asUint256Array(), values_.asAddressArray());
    }

    function backwardsTraversalAddress()
        external
        view
        returns (uint256[] memory, address[] memory)
    {
        Traversal.Iterator memory iterator_ = _addressTree.last();

        bytes32[] memory keys_ = new bytes32[](_addressTree.size());
        bytes32[] memory values_ = new bytes32[](keys_.length);

        if (keys_.length != 0) {
            (keys_[0], values_[0]) = iterator_.value();
        }

        uint256 index_ = 1;

        while (iterator_.hasPrev()) {
            (keys_[index_], values_[index_]) = iterator_.prev();

            index_++;
        }

        return (keys_.asUint256Array(), values_.asAddressArray());
    }

    function nextOnLast() external view returns (uint256, uint256) {
        Traversal.Iterator memory iterator_ = _uintTree.last();

        (bytes32 key_, bytes32 value_) = iterator_.next();

        return (uint256(key_), uint256(value_));
    }

    function prevOnFirst() external view returns (uint256, uint256) {
        Traversal.Iterator memory iterator_ = _uintTree.first();

        (bytes32 key_, bytes32 value_) = iterator_.prev();

        return (uint256(key_), uint256(value_));
    }

    function isCustomComparatorSetUint() external view returns (bool) {
        return _uintTree.isCustomComparatorSet();
    }

    function isCustomComparatorSetBytes32() external view returns (bool) {
        return _bytes32Tree.isCustomComparatorSet();
    }

    function isCustomComparatorSetAddress() external view returns (bool) {
        return _addressTree.isCustomComparatorSet();
    }

    function _traverseAll(
        Traversal.Iterator memory iterator_,
        uint256 size_,
        bool direction_
    ) private view returns (uint256[] memory, bytes32[] memory) {
        uint256[] memory keys_ = new uint256[](size_);
        bytes32[] memory values_ = new bytes32[](size_);

        uint256 index_;

        while (iterator_.isValid()) {
            (bytes32 bytesKey_, bytes32 bytesValue_) = iterator_.value();

            keys_[index_] = uint256(bytesKey_);
            values_[index_] = bytesValue_;

            direction_ ? iterator_.next() : iterator_.prev();

            index_++;
        }

        return (keys_, values_);
    }

    function _descComparator(bytes32 key1_, bytes32 key2_) private pure returns (int256) {
        if (key1_ > key2_) {
            return -1;
        }

        if (key1_ < key2_) {
            return 1;
        }

        return 0;
    }
}
