// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {TypeCaster} from "../utils/TypeCaster.sol";

/**
 * @notice The library that realizes a heap based priority queue.
 *
 * Courtesy of heap property,
 * add() and removeTop() operations are O(log(n)) complex
 * top(), topValue() operations are O(1)
 *
 * The library might be useful to implement priority withdrawals/purchases, reputation based systems, and similar logic.
 *
 * The library is a maximal priority queue. The element with the highest priority is the topmost element.
 * If you wish a minimal queue, change the priority of the elements to type(uint256).max - priority.
 *
 * IMPORTANT
 * The queue order of the elements is NOT guaranteed.
 * The interaction with the data structure must be made via the topmost element only.
 *
 * ## Usage example:
 *
 * ```
 * using PriorityQueue for PriorityQueue.UintQueue;
 * using PriorityQueue for PriorityQueue.AddressQueue;
 * using PriorityQueue for PriorityQueue.Bytes32Queue;
 * ```
 */
library PriorityQueue {
    using TypeCaster for *;

    /**
     ************************
     *      UintQueue       *
     ************************
     */

    struct UintQueue {
        Queue _queue;
    }

    error QueueIsEmpty();

    /**
     * @notice The function to add an element to the uint256 queue. O(log(n)) complex
     * @param queue self
     * @param value_ the element value
     * @param priority_ the element priority
     */
    function add(UintQueue storage queue, uint256 value_, uint256 priority_) internal {
        _add(queue._queue, bytes32(value_), priority_);
    }

    /**
     * @notice The function to remove the element with the highest priority. O(log(n)) complex
     * @param queue self
     */
    function removeTop(UintQueue storage queue) internal {
        _removeTop(queue._queue);
    }

    /**
     * @notice The function to read the value of the element with the highest priority. O(1) complex
     * @param queue self
     * @return the value of the element with the highest priority
     */
    function topValue(UintQueue storage queue) internal view returns (uint256) {
        return uint256(_topValue(queue._queue));
    }

    /**
     * @notice The function to read the element with the highest priority. O(1) complex
     * @param queue self
     * @return the element with the highest priority
     */
    function top(UintQueue storage queue) internal view returns (uint256, uint256) {
        (bytes32 value_, uint256 priority_) = _top(queue._queue);

        return (uint256(value_), priority_);
    }

    /**
     * @notice The function to read the size of the queue. O(1) complex
     * @param queue self
     * @return the size of the queue
     */
    function length(UintQueue storage queue) internal view returns (uint256) {
        return _length(queue._queue);
    }

    /**
     * @notice The function to get the values stored in the queue. O(n) complex
     * It is very expensive to call this function as it reads all the queue elements. Use cautiously
     * @param queue self
     * @return values_ the values of the elements stored
     */
    function values(UintQueue storage queue) internal view returns (uint256[] memory values_) {
        return _values(queue._queue).asUint256Array();
    }

    /**
     * @notice The function to get the values and priorities stored in the queue. O(n) complex
     * It is very expensive to call this function as it reads all the queue elements. Use cautiously
     * @param queue self
     * @return values_ the values of the elements stored
     * @return priorities_ the priorities of the elements stored
     */
    function elements(
        UintQueue storage queue
    ) internal view returns (uint256[] memory values_, uint256[] memory priorities_) {
        return (_values(queue._queue).asUint256Array(), _priorities(queue._queue));
    }

    /**
     ************************
     *     Bytes32Queue     *
     ************************
     */

    struct Bytes32Queue {
        Queue _queue;
    }

    /**
     * @notice The function to add an element to the bytes32 queue. O(log(n)) complex
     */
    function add(Bytes32Queue storage queue, bytes32 value_, uint256 priority_) internal {
        _add(queue._queue, value_, priority_);
    }

    /**
     * @notice The function to remove the element with the highest priority. O(log(n)) complex
     */
    function removeTop(Bytes32Queue storage queue) internal {
        _removeTop(queue._queue);
    }

    /**
     * @notice The function to read the value of the element with the highest priority. O(1) complex
     */
    function topValue(Bytes32Queue storage queue) internal view returns (bytes32) {
        return _topValue(queue._queue);
    }

    /**
     * @notice The function to read the element with the highest priority. O(1) complex
     */
    function top(Bytes32Queue storage queue) internal view returns (bytes32, uint256) {
        return _top(queue._queue);
    }

    /**
     * @notice The function to read the size of the queue. O(1) complex
     */
    function length(Bytes32Queue storage queue) internal view returns (uint256) {
        return _length(queue._queue);
    }

    /**
     * @notice The function to get the values stored in the queue. O(n) complex
     * It is very expensive to call this function as it reads all the queue elements. Use cautiously
     */
    function values(Bytes32Queue storage queue) internal view returns (bytes32[] memory values_) {
        values_ = _values(queue._queue);
    }

    /**
     * @notice The function to get the values and priorities stored in the queue. O(n) complex
     * It is very expensive to call this function as it reads all the queue elements. Use cautiously
     */
    function elements(
        Bytes32Queue storage queue
    ) internal view returns (bytes32[] memory values_, uint256[] memory priorities_) {
        values_ = _values(queue._queue);
        priorities_ = _priorities(queue._queue);
    }

    /**
     ************************
     *     AddressQueue     *
     ************************
     */

    struct AddressQueue {
        Queue _queue;
    }

    /**
     * @notice The function to add an element to the address queue. O(log(n)) complex
     */
    function add(AddressQueue storage queue, address value_, uint256 priority_) internal {
        _add(queue._queue, bytes32(uint256(uint160(value_))), priority_);
    }

    /**
     * @notice The function to remove the element with the highest priority. O(log(n)) complex
     */
    function removeTop(AddressQueue storage queue) internal {
        _removeTop(queue._queue);
    }

    /**
     * @notice The function to read the value of the element with the highest priority. O(1) complex
     */
    function topValue(AddressQueue storage queue) internal view returns (address) {
        return address(uint160(uint256(_topValue(queue._queue))));
    }

    /**
     * @notice The function to read the element with the highest priority. O(1) complex
     */
    function top(AddressQueue storage queue) internal view returns (address, uint256) {
        (bytes32 value_, uint256 priority_) = _top(queue._queue);

        return (address(uint160(uint256(value_))), priority_);
    }

    /**
     * @notice The function to read the size of the queue. O(1) complex
     */
    function length(AddressQueue storage queue) internal view returns (uint256) {
        return _length(queue._queue);
    }

    /**
     * @notice The function to get the values stored in the queue. O(n) complex
     * It is very expensive to call this function as it reads all the queue elements. Use cautiously
     */
    function values(AddressQueue storage queue) internal view returns (address[] memory values_) {
        return _values(queue._queue).asAddressArray();
    }

    /**
     * @notice The function to get the values and priorities stored in the queue. O(n) complex
     * It is very expensive to call this function as it reads all the queue elements. Use cautiously
     */
    function elements(
        AddressQueue storage queue
    ) internal view returns (address[] memory values_, uint256[] memory priorities_) {
        return (_values(queue._queue).asAddressArray(), _priorities(queue._queue));
    }

    /**
     ************************
     *    Internal Queue    *
     ************************
     */

    struct Queue {
        bytes32[] _values;
        uint256[] _priorities;
    }

    function _add(Queue storage queue, bytes32 value_, uint256 priority_) private {
        queue._values.push(value_);
        queue._priorities.push(priority_);

        _shiftUp(queue, queue._values.length - 1);
    }

    function _removeTop(Queue storage queue) private {
        _requireNotEmpty(queue);

        uint256 length_ = _length(queue);

        queue._values[0] = queue._values[length_ - 1];
        queue._priorities[0] = queue._priorities[length_ - 1];

        queue._values.pop();
        queue._priorities.pop();

        _shiftDown(queue, 0);
    }

    function _topValue(Queue storage queue) private view returns (bytes32) {
        _requireNotEmpty(queue);

        return queue._values[0];
    }

    function _top(Queue storage queue) private view returns (bytes32, uint256) {
        return (_topValue(queue), queue._priorities[0]);
    }

    function _length(Queue storage queue) private view returns (uint256) {
        return queue._values.length;
    }

    function _values(Queue storage queue) private view returns (bytes32[] memory) {
        return queue._values;
    }

    function _priorities(Queue storage queue) private view returns (uint256[] memory) {
        return queue._priorities;
    }

    function _shiftUp(Queue storage queue, uint256 index_) private {
        uint256 priority_ = queue._priorities[index_];

        while (index_ > 0) {
            uint256 parent_ = _parent(index_);

            if (queue._priorities[parent_] >= priority_) {
                break;
            }

            _swap(queue, parent_, index_);

            index_ = parent_;
        }
    }

    function _shiftDown(Queue storage queue, uint256 index_) private {
        while (true) {
            uint256 maxIndex_ = _maxPriorityIndex(queue, index_);

            if (index_ == maxIndex_) {
                break;
            }

            _swap(queue, maxIndex_, index_);

            index_ = maxIndex_;
        }
    }

    function _swap(Queue storage queue, uint256 index1_, uint256 index2_) private {
        bytes32[] storage _vals = queue._values;
        uint256[] storage _priors = queue._priorities;

        (_vals[index1_], _vals[index2_]) = (_vals[index2_], _vals[index1_]);
        (_priors[index1_], _priors[index2_]) = (_priors[index2_], _priors[index1_]);
    }

    function _maxPriorityIndex(
        Queue storage queue,
        uint256 index_
    ) private view returns (uint256) {
        uint256[] storage _priors = queue._priorities;

        uint256 length_ = _priors.length;
        uint256 maxIndex_ = index_;

        uint256 child_ = _leftChild(index_);

        if (child_ < length_ && _priors[child_] > _priors[maxIndex_]) {
            maxIndex_ = child_;
        }

        child_ = _rightChild(index_);

        if (child_ < length_ && _priors[child_] > _priors[maxIndex_]) {
            maxIndex_ = child_;
        }

        return maxIndex_;
    }

    function _parent(uint256 index_) private pure returns (uint256) {
        return (index_ - 1) / 2;
    }

    function _leftChild(uint256 index_) private pure returns (uint256) {
        return index_ * 2 + 1;
    }

    function _rightChild(uint256 index_) private pure returns (uint256) {
        return index_ * 2 + 2;
    }

    function _requireNotEmpty(Queue storage queue) private view {
        if (_length(queue) == 0) revert QueueIsEmpty();
    }
}
