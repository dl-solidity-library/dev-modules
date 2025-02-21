// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
// solhint-disable-previous-line one-contract-per-file

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @notice AVL Tree module
 *
 * This library provides implementation of three sets with dynamic `value` types:
 * `UintAVL`, `Bytes32AVL` and `AddressAVL`.
 *
 * Each element in the tree has a bytes32 `key` field to allow storing values
 * associated with different types of keys
 *
 * The implementation supports setting custom comparator function
 *
 * Gas usage for _insert and _remove functions (where count is the number of elements added to the tree):
 *
 * | Statistic | _insert      | _remove          |
 * | --------- | ------------ | ---------------- |
 * | count     | 5000         | 5000             |
 * | mean      | 222,578 gas  | 115,744 gas      |
 * | min       | 110,520 gas  | 34,461 gas       |
 * | max       | 263,275 gas  | 171,815 gas      |
 *
 * ## Usage example:
 *
 * ```
 * using AvlTree for AvlTree.UintAVL;
 * using Traversal for Traversal.Iterator;
 *
 * AvlTree.UintAVL internal uintTree;
 *
 * ................................................
 *
 * uintTree.setComparator(comparatorFunction);
 *
 * uintTree.insert(bytes32(1), 1234);
 * uintTree.insert(bytes32(3), 100);
 *
 * uintTree.tryGet(bytes32(1));
 *
 * uintTree.remove(bytes32(1));
 *
 * ................................................
 *
 * Traversal.Iterator memory iterator_ = uintTree.first();
 *
 * bytes32[] memory keys_ = new bytes32[](_uintTree.size());
 * bytes32[] memory values_ = new bytes32[](_uintTree.size());
 *
 * while (iterator_.isValid()) {
 *      (keys_[i], values_[i]) = iterator_.value();
 *      iterator_.next();
 * }
 * ```
 */
library AvlTree {
    /**
     *********************
     *      UintAVL      *
     *********************
     */

    struct UintAVL {
        Tree _tree;
    }

    error NodeAlreadyExists(bytes32 key);
    error NodeDoesNotExist(bytes32 key);
    error KeyIsZero();
    error TreeNotEmpty();

    /**
     * @notice The function to set a custom comparator function, that will be used to build the uint256 tree.
     * @param tree self.
     * @param comparator_ The function that accepts keys of the nodes to compare.
     */
    function setComparator(
        UintAVL storage tree,
        function(bytes32, bytes32) view returns (int256) comparator_
    ) internal {
        _setComparator(tree._tree, comparator_);
    }

    /**
     * @notice The function to insert a node into the uint256 tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     *
     * @param tree self.
     * @param key_ the key to insert.
     * @param value_ the value to insert.
     */
    function insert(UintAVL storage tree, bytes32 key_, uint256 value_) internal {
        _insert(tree._tree, key_, bytes32(value_));
    }

    /**
     * @notice The function to remove a node from the uint256 tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     *
     * @param tree self.
     * @param key_ the key of the node to remove.
     */
    function remove(UintAVL storage tree, bytes32 key_) internal {
        _remove(tree._tree, key_);
    }

    /**
     * @notice The function to retrieve the value associated with a key in the uint256 tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     *
     * Note: Reverts if the node with the specified key doesn't exist.
     *
     * @param tree self.
     * @param key_ the key to retrieve the value for.
     * @return The value associated with the key.
     */
    function get(UintAVL storage tree, bytes32 key_) internal view returns (uint256) {
        return uint256(_get(tree._tree, key_));
    }

    /**
     * @notice The function to try to retrieve the value associated with a key in the uint256 tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     *
     * @dev Does not revert if the node with the specified key doesn't exist.
     *
     * @param tree self.
     * @param key_ the key of the node to try to retrieve the value for.
     * @return True if the node with the specified key exists, false otherwise.
     * @return The value associated with the key.
     */
    function tryGet(UintAVL storage tree, bytes32 key_) internal view returns (bool, uint256) {
        (bool exists_, bytes32 value_) = _tryGet(tree._tree, key_);

        return (exists_, uint256(value_));
    }

    /**
     * @notice The function to retrieve the size of the uint256 tree.
     * @param tree self.
     * @return The size of the tree.
     */
    function size(UintAVL storage tree) internal view returns (uint64) {
        return uint64(_size(tree._tree));
    }

    /**
     * @notice The function to get the iterator pointing to the first (leftmost) node in the uint256 tree.
     * @dev The functions can be utilized for an in-order traversal of the tree.
     * @param tree self.
     * @return The iterator pointing to the first node.
     */
    function first(UintAVL storage tree) internal view returns (Traversal.Iterator memory) {
        return _first(tree._tree);
    }

    /**
     * @notice The function to get the iterator pointing to the last (rightmost) node in the uint256 tree.
     * @dev The functions can be utilized for an in-order backwards traversal of the tree.
     * @param tree self.
     * @return The iterator pointing to the last node.
     */
    function last(UintAVL storage tree) internal view returns (Traversal.Iterator memory) {
        return _last(tree._tree);
    }

    /**
     * @notice The function to check whether the custom comparator function is set for the uint256 tree.
     * @param tree self.
     * @return True if the custom comparator function is set, false otherwise.
     */
    function isCustomComparatorSet(UintAVL storage tree) internal view returns (bool) {
        return tree._tree.isCustomComparatorSet;
    }

    /**
     **********************
     *     Bytes32AVL     *
     **********************
     */

    struct Bytes32AVL {
        Tree _tree;
    }

    /**
     * @notice The function to set a custom comparator function, that will be used to build the bytes32 tree.
     * @param tree self.
     * @param comparator_ The function that accepts keys and values of the nodes to compare.
     */
    function setComparator(
        Bytes32AVL storage tree,
        function(bytes32, bytes32) view returns (int256) comparator_
    ) internal {
        _setComparator(tree._tree, comparator_);
    }

    /**
     * @notice The function to insert a node into the bytes32 tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     *
     * @param tree self.
     * @param key_ the key to insert.
     * @param value_ the value to insert.
     */
    function insert(Bytes32AVL storage tree, bytes32 key_, bytes32 value_) internal {
        _insert(tree._tree, key_, value_);
    }

    /**
     * @notice The function to remove a node from the bytes32 tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     *
     * @param tree self.
     * @param key_ the key of the node to remove.
     */
    function remove(Bytes32AVL storage tree, bytes32 key_) internal {
        _remove(tree._tree, key_);
    }

    /**
     * @notice The function to retrieve the value associated with a key in the bytes32 tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     *
     * Note: Reverts if the node with the specified key doesn't exist.
     *
     * @param tree self.
     * @param key_ the key to retrieve the value for.
     * @return The value associated with the key.
     */
    function get(Bytes32AVL storage tree, bytes32 key_) internal view returns (bytes32) {
        return _get(tree._tree, key_);
    }

    /**
     * @notice The function to try to retrieve the value associated with a key in the bytes32 tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     *
     * @dev Does not revert if the node with the specified key doesn't exist.
     *
     * @param tree self.
     * @param key_ the key of the node to try to retrieve the value for.
     * @return True if the node with the specified key exists, false otherwise.
     * @return The value associated with the key.
     */
    function tryGet(Bytes32AVL storage tree, bytes32 key_) internal view returns (bool, bytes32) {
        return _tryGet(tree._tree, key_);
    }

    /**
     * @notice The function to retrieve the size of the bytes32 tree.
     * @param tree self.
     * @return The size of the tree.
     */
    function size(Bytes32AVL storage tree) internal view returns (uint64) {
        return uint64(_size(tree._tree));
    }

    /**
     * @notice The function to get the iterator pointing to the first (leftmost) node in the bytes32 tree.
     * @dev The functions can be utilized for an in-order traversal of the tree.
     * @param tree self.
     * @return The iterator pointing to the first node.
     */
    function first(Bytes32AVL storage tree) internal view returns (Traversal.Iterator memory) {
        return _first(tree._tree);
    }

    /**
     * @notice The function to get the iterator pointing to the last (rightmost) node in the bytes32 tree.
     * @dev The functions can be utilized for an in-order backwards traversal of the tree.
     * @param tree self.
     * @return The iterator pointing to the last node.
     */
    function last(Bytes32AVL storage tree) internal view returns (Traversal.Iterator memory) {
        return _last(tree._tree);
    }

    /**
     * @notice The function to check whether the custom comparator function is set for the bytes32 tree.
     * @param tree self.
     * @return True if the custom comparator function is set, false otherwise.
     */
    function isCustomComparatorSet(Bytes32AVL storage tree) internal view returns (bool) {
        return tree._tree.isCustomComparatorSet;
    }

    /**
     **********************
     *     AddressAVL     *
     **********************
     */

    struct AddressAVL {
        Tree _tree;
    }

    /**
     * @notice The function to set a custom comparator function, that will be used to build the address tree.
     * @param tree self.
     * @param comparator_ The function that accepts keys and values of the nodes to compare.
     */
    function setComparator(
        AddressAVL storage tree,
        function(bytes32, bytes32) view returns (int256) comparator_
    ) internal {
        _setComparator(tree._tree, comparator_);
    }

    /**
     * @notice The function to insert a node into the address tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     *
     * @param tree self.
     * @param key_ The key to insert.
     * @param value_ The value to insert.
     */
    function insert(AddressAVL storage tree, bytes32 key_, address value_) internal {
        _insert(tree._tree, key_, bytes32(uint256(uint160(value_))));
    }

    /**
     * @notice The function to remove a node from the address tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     *
     * @param tree self.
     * @param key_ the key of the node to remove.
     */
    function remove(AddressAVL storage tree, bytes32 key_) internal {
        _remove(tree._tree, key_);
    }

    /**
     * @notice The function to retrieve the value associated with a key in the address tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     *
     * Note: Reverts if the node with the specified key doesn't exist.
     *
     * @param tree self.
     * @param key_ the key to retrieve the value for.
     * @return The value associated with the key.
     */
    function get(AddressAVL storage tree, bytes32 key_) internal view returns (address) {
        return address(uint160(uint256(_get(tree._tree, key_))));
    }

    /**
     * @notice The function to try to retrieve the value associated with a key in the address tree.
     * Complexity is O(log(n)), where n is the number of elements in the tree.
     *
     * @dev Does not revert if the node with the specified key doesn't exist.
     *
     * @param tree self.
     * @param key_ the key of the node to try to retrieve the value for.
     * @return True if the node with the specified key exists, false otherwise.
     * @return The value associated with the key.
     */
    function tryGet(AddressAVL storage tree, bytes32 key_) internal view returns (bool, address) {
        (bool exists_, bytes32 value_) = _tryGet(tree._tree, key_);

        return (exists_, address(uint160(uint256(value_))));
    }

    /**
     * @notice The function to retrieve the size of the address tree.
     * @param tree self.
     * @return The size of the tree.
     */
    function size(AddressAVL storage tree) internal view returns (uint64) {
        return uint64(_size(tree._tree));
    }

    /**
     * @notice The function to get the iterator pointing to the first (leftmost) node in the address tree.
     * @dev The functions can be utilized for an in-order traversal of the tree.
     * @param tree self.
     * @return The iterator pointing to the first node.
     */
    function first(AddressAVL storage tree) internal view returns (Traversal.Iterator memory) {
        return _first(tree._tree);
    }

    /**
     * @notice The function to get the iterator pointing to the last (rightmost) node in the address tree.
     * @dev The functions can be utilized for an in-order backwards traversal of the tree.
     * @param tree self.
     * @return The iterator pointing to the last node.
     */
    function last(AddressAVL storage tree) internal view returns (Traversal.Iterator memory) {
        return _last(tree._tree);
    }

    /**
     * @notice The function to check whether the custom comparator function is set for the address tree.
     * @param tree self.
     * @return True if the custom comparator function is set, false otherwise.
     */
    function isCustomComparatorSet(AddressAVL storage tree) internal view returns (bool) {
        return tree._tree.isCustomComparatorSet;
    }

    /**
     *************************
     *     Internal Tree     *
     *************************
     */

    struct Node {
        bytes32 key;
        bytes32 value;
        uint64 height;
        uint64 parent;
        uint64 left;
        uint64 right;
    }

    struct Tree {
        uint64 root;
        uint64 totalCount;
        uint64 removedCount;
        bool isCustomComparatorSet;
        mapping(uint64 => Node) tree;
        function(bytes32, bytes32) view returns (int256) comparator;
    }

    function _setComparator(
        Tree storage tree,
        function(bytes32, bytes32) view returns (int256) comparator_
    ) private {
        if (_size(tree) != 0) revert TreeNotEmpty();

        tree.isCustomComparatorSet = true;

        tree.comparator = comparator_;
    }

    function _insert(Tree storage tree, bytes32 key_, bytes32 value_) private {
        if (key_ == 0) revert KeyIsZero();

        tree.totalCount++;

        tree.root = _insertNode(
            tree.tree,
            tree.totalCount,
            tree.root,
            0,
            key_,
            value_,
            _getComparator(tree)
        );
    }

    function _remove(Tree storage tree, bytes32 key_) private {
        if (key_ == 0) revert KeyIsZero();

        tree.root = _removeNode(tree.tree, tree.root, 0, bytes32(key_), _getComparator(tree));

        tree.removedCount++;
    }

    function _insertNode(
        mapping(uint64 => Node) storage _tree,
        uint64 index_,
        uint64 node_,
        uint64 parent_,
        bytes32 key_,
        bytes32 value_,
        function(bytes32, bytes32) view returns (int256) comparator_
    ) private returns (uint64) {
        int256 comparison_ = comparator_(key_, _tree[node_].key);

        if (_tree[node_].key == 0) {
            _tree[index_] = Node({
                key: key_,
                value: value_,
                parent: parent_,
                left: 0,
                right: 0,
                height: 1
            });

            return index_;
        }

        if (comparison_ < 0) {
            _tree[node_].left = _insertNode(
                _tree,
                index_,
                _tree[node_].left,
                node_,
                key_,
                value_,
                comparator_
            );
        } else if (comparison_ == 0) {
            revert NodeAlreadyExists(key_);
        } else {
            _tree[node_].right = _insertNode(
                _tree,
                index_,
                _tree[node_].right,
                node_,
                key_,
                value_,
                comparator_
            );
        }

        return _balance(_tree, node_);
    }

    function _removeNode(
        mapping(uint64 => Node) storage _tree,
        uint64 node_,
        uint64 parent_,
        bytes32 key_,
        function(bytes32, bytes32) view returns (int256) comparator_
    ) private returns (uint64) {
        if (node_ == 0) revert NodeDoesNotExist(key_);

        int256 comparison_ = comparator_(key_, _tree[node_].key);

        if (comparison_ == 0) {
            uint64 left_ = _tree[node_].left;
            uint64 right_ = _tree[node_].right;

            delete _tree[node_];

            if (right_ == 0) {
                if (left_ != 0) {
                    _tree[left_].parent = parent_;
                }

                return left_;
            }

            uint64 temp_;

            for (temp_ = right_; _tree[temp_].left != 0; temp_ = _tree[temp_].left) {}

            right_ = _removeMin(_tree, right_);

            _tree[temp_].left = left_;
            _tree[temp_].right = right_;

            if (left_ != 0) {
                _tree[left_].parent = temp_;
            }

            if (right_ != 0) {
                _tree[right_].parent = temp_;
            }

            _tree[temp_].parent = parent_;

            return _balance(_tree, temp_);
        } else if (comparison_ < 0) {
            _tree[node_].left = _removeNode(_tree, _tree[node_].left, node_, key_, comparator_);
        } else {
            _tree[node_].right = _removeNode(_tree, _tree[node_].right, node_, key_, comparator_);
        }

        return _balance(_tree, node_);
    }

    function _removeMin(
        mapping(uint64 => Node) storage _tree,
        uint64 node_
    ) private returns (uint64) {
        Node storage _node = _tree[node_];

        if (_node.left == 0) {
            if (_node.right != 0) {
                _tree[_node.right].parent = _node.parent;
            }

            return _node.right;
        }

        _node.left = _removeMin(_tree, _node.left);

        return _balance(_tree, node_);
    }

    function _rotateRight(
        mapping(uint64 => Node) storage _tree,
        uint64 node_
    ) private returns (uint64) {
        Node storage _node = _tree[node_];

        uint64 temp_ = _node.left;

        _tree[temp_].parent = _node.parent;
        _node.parent = temp_;

        if (_tree[temp_].right != 0) {
            _tree[_tree[temp_].right].parent = node_;
        }

        _node.left = _tree[temp_].right;
        _tree[temp_].right = node_;

        _updateHeight(_tree, node_);
        _updateHeight(_tree, temp_);

        return temp_;
    }

    function _rotateLeft(
        mapping(uint64 => Node) storage _tree,
        uint64 node_
    ) private returns (uint64) {
        Node storage _node = _tree[node_];

        uint64 temp_ = _node.right;

        _tree[temp_].parent = _node.parent;
        _node.parent = temp_;

        if (_tree[temp_].left != 0) {
            _tree[_tree[temp_].left].parent = node_;
        }

        _node.right = _tree[temp_].left;
        _tree[temp_].left = node_;

        _updateHeight(_tree, node_);
        _updateHeight(_tree, temp_);

        return temp_;
    }

    function _balance(
        mapping(uint64 => Node) storage _tree,
        uint64 node_
    ) private returns (uint64) {
        _updateHeight(_tree, node_);

        Node storage _left = _tree[_tree[node_].left];
        Node storage _right = _tree[_tree[node_].right];

        if (_left.height > _right.height + 1) {
            if (_tree[_left.right].height > _tree[_left.left].height) {
                _tree[node_].left = _rotateLeft(_tree, _tree[node_].left);
            }

            return _rotateRight(_tree, node_);
        } else if (_right.height > _left.height + 1) {
            if (_tree[_right.left].height > _tree[_right.right].height) {
                _tree[node_].right = _rotateRight(_tree, _tree[node_].right);
            }

            return _rotateLeft(_tree, node_);
        }

        return node_;
    }

    function _updateHeight(mapping(uint64 => Node) storage _tree, uint64 node_) private {
        Node storage _node = _tree[node_];

        _node.height = uint64(1 + Math.max(_tree[_node.left].height, _tree[_node.right].height));
    }

    function _search(
        mapping(uint64 => Node) storage _tree,
        uint64 node_,
        bytes32 key_,
        function(bytes32, bytes32) view returns (int256) comparator_
    ) private view returns (uint64) {
        if (node_ == 0) {
            return 0;
        }

        int256 comparison_ = comparator_(key_, _tree[node_].key);

        if (comparison_ == 0) {
            return node_;
        } else if (comparison_ < 0) {
            return _search(_tree, _tree[node_].left, key_, comparator_);
        } else {
            return _search(_tree, _tree[node_].right, key_, comparator_);
        }
    }

    function _get(Tree storage tree, bytes32 key_) private view returns (bytes32) {
        uint64 index_ = _search(tree.tree, tree.root, key_, _getComparator(tree));

        if (index_ == 0) revert NodeDoesNotExist(key_);

        return tree.tree[index_].value;
    }

    function _tryGet(Tree storage tree, bytes32 key_) private view returns (bool, bytes32) {
        uint64 index_ = _search(tree.tree, tree.root, key_, _getComparator(tree));

        if (index_ == 0) {
            return (false, 0);
        }

        return (true, tree.tree[index_].value);
    }

    function _size(Tree storage tree) private view returns (uint256) {
        return tree.totalCount - tree.removedCount;
    }

    function _first(Tree storage tree) private view returns (Traversal.Iterator memory) {
        uint256 treeMappingSlot_;
        assembly {
            treeMappingSlot_ := add(tree.slot, 1)
        }

        uint64 current_ = tree.root;
        while (tree.tree[current_].left != 0) {
            current_ = tree.tree[current_].left;
        }

        return Traversal.Iterator({treeMappingSlot: treeMappingSlot_, currentNode: current_});
    }

    function _last(Tree storage tree) private view returns (Traversal.Iterator memory) {
        uint256 treeMappingSlot_;
        assembly {
            treeMappingSlot_ := add(tree.slot, 1)
        }

        uint64 current_ = tree.root;
        while (tree.tree[current_].right != 0) {
            current_ = tree.tree[current_].right;
        }

        return Traversal.Iterator({treeMappingSlot: treeMappingSlot_, currentNode: current_});
    }

    function _getComparator(
        Tree storage tree
    ) private view returns (function(bytes32, bytes32) view returns (int256)) {
        return tree.isCustomComparatorSet ? tree.comparator : _defaultComparator;
    }

    function _defaultComparator(bytes32 key1_, bytes32 key2_) private pure returns (int256) {
        if (key1_ < key2_) {
            return -1;
        }

        if (key1_ > key2_) {
            return 1;
        }

        return 0;
    }
}

/**
 * @notice Traversal module
 *
 * This library provides functions to perform an in-order traversal of the AVL Tree
 */
library Traversal {
    /**
     * @notice Iterator struct to keep track of the current position in the tree.
     * @param treeMappingSlot The storage slot of the tree mapping.
     * @param currentNode The index of the current node in the traversal.
     */
    struct Iterator {
        uint256 treeMappingSlot;
        uint64 currentNode;
    }

    error NoNodesLeft();

    /**
     * @notice The function to check if the iterator is currently valid (has not reached the end of the traversal).
     * @param iterator_ self.
     * @return True if the iterator is valid, false otherwise.
     */
    function isValid(Iterator memory iterator_) internal pure returns (bool) {
        return iterator_.currentNode != 0;
    }

    /**
     * @notice The function to check if there is a next node in the traversal.
     * @param iterator_ self.
     * @return True if there is a next node, false otherwise.
     */
    function hasNext(Iterator memory iterator_) internal view returns (bool) {
        return _has(iterator_, true);
    }

    /**
     * @notice The function to check if there is a previous node in the traversal.
     * @param iterator_ self.
     * @return True if there is a previous node, false otherwise.
     */
    function hasPrev(Iterator memory iterator_) internal view returns (bool) {
        return _has(iterator_, false);
    }

    /**
     * @notice The function to move the iterator to the next node and retrieve its key and value.
     * @param iterator_ self.
     * @return The key of the next node.
     * @return The value of the next node.
     */
    function next(Iterator memory iterator_) internal view returns (bytes32, bytes32) {
        return _moveToAdjacent(iterator_, true);
    }

    /**
     * @notice The function to move the iterator to the previous node and retrieve its key and value.
     * @param iterator_ self.
     * @return The key of the previous node.
     * @return The value of the previous node.
     */
    function prev(Iterator memory iterator_) internal view returns (bytes32, bytes32) {
        return _moveToAdjacent(iterator_, false);
    }

    /**
     * @notice The function to retrieve the key and value of the current node.
     * @param iterator_ self.
     * @return The key of the current node.
     * @return The value of the current node.
     */
    function value(Iterator memory iterator_) internal view returns (bytes32, bytes32) {
        AvlTree.Node memory node_ = _getNode(iterator_.treeMappingSlot, iterator_.currentNode);

        return (node_.key, node_.value);
    }

    function _has(Iterator memory iterator_, bool next_) private view returns (bool) {
        AvlTree.Node memory node_ = _getNode(iterator_.treeMappingSlot, iterator_.currentNode);

        if (_adjacent(node_, next_) != 0) {
            return true;
        }

        uint64 currentNodeIndex_ = iterator_.currentNode;

        while (currentNodeIndex_ != 0) {
            AvlTree.Node memory parent_ = _getNode(iterator_.treeMappingSlot, node_.parent);

            if (currentNodeIndex_ == _adjacent(parent_, !next_)) {
                return true;
            }

            currentNodeIndex_ = node_.parent;
            node_ = parent_;
        }

        return false;
    }

    function _moveToAdjacent(
        Iterator memory iterator_,
        bool next_
    ) internal view returns (bytes32, bytes32) {
        uint64 currentNodeIndex_ = iterator_.currentNode;

        if (currentNodeIndex_ == 0) revert NoNodesLeft();

        AvlTree.Node memory node_ = _getNode(iterator_.treeMappingSlot, currentNodeIndex_);

        if (_adjacent(node_, next_) != 0) {
            currentNodeIndex_ = _adjacent(node_, next_);

            AvlTree.Node memory childNode_ = _getNode(
                iterator_.treeMappingSlot,
                currentNodeIndex_
            );

            while (_adjacent(childNode_, !next_) != 0) {
                currentNodeIndex_ = _adjacent(childNode_, !next_);
                childNode_ = _getNode(iterator_.treeMappingSlot, currentNodeIndex_);
            }
        } else {
            uint64 parentIndex_ = node_.parent;

            AvlTree.Node memory parentNode_ = _getNode(iterator_.treeMappingSlot, parentIndex_);

            while (parentIndex_ != 0 && currentNodeIndex_ == _adjacent(parentNode_, next_)) {
                currentNodeIndex_ = parentIndex_;

                parentIndex_ = parentNode_.parent;
                parentNode_ = _getNode(iterator_.treeMappingSlot, parentIndex_);
            }

            currentNodeIndex_ = parentIndex_;
        }

        iterator_.currentNode = currentNodeIndex_;

        return value(iterator_);
    }

    function _adjacent(AvlTree.Node memory node_, bool next_) private pure returns (uint64) {
        return next_ ? node_.right : node_.left;
    }

    function _getNode(
        uint256 slot_,
        uint64 index_
    ) private view returns (AvlTree.Node memory node_) {
        bytes32 baseSlot_ = keccak256(abi.encode(index_, slot_));

        assembly {
            let valueSlot_ := add(baseSlot_, 1)
            let packedSlot_ := add(baseSlot_, 2)

            let packedData_ := sload(packedSlot_)

            mstore(node_, sload(baseSlot_))
            mstore(add(node_, 0x20), sload(valueSlot_))
            mstore(add(node_, 0x40), and(packedData_, 0xFFFFFFFFFFFFFFFF))
            mstore(add(node_, 0x60), and(shr(64, packedData_), 0xFFFFFFFFFFFFFFFF))
            mstore(add(node_, 0x80), and(shr(128, packedData_), 0xFFFFFFFFFFFFFFFF))
            mstore(add(node_, 0xa0), and(shr(192, packedData_), 0xFFFFFFFFFFFFFFFF))
        }

        return node_;
    }
}
