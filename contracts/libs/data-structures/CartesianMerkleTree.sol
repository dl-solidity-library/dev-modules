// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @notice Cartesian Merkle Tree Module
 *
 * A magnificent ZK-friendly data structure based on a Binary Search Tree + Heap + Merkle Tree. Short names: CMT, Treaple.
 * Possesses deterministic and idemponent properties. Can be used as a substitute for a Sparse Merkle Tree (SMT).
 *
 * Gas usage for adding and removing 1,000 elements to a CMT with the keccak256 and poseidon hash functions is detailed below:
 *
 * Keccak256:
 * - CMT.add - 249k
 * - CMT.remove - 181k
 *
 * Poseidon:
 * - CMT.add - 896k
 * - CMT.remove - 746k
 *
 * ## Usage Example:
 *
 * ```solidity
 * using CartesianMerkleTree for CartesianMerkleTree.UintCMT;
 *
 * CartesianMerkleTree.UintCMT internal uintTreaple;
 * ...
 * uintTreaple.initialize(80);
 *
 * uintTreaple.add(100);
 *
 * uintTreaple.getRoot();
 *
 * CartesianMerkleTree.Proof memory proof = uintTreaple.getProof(100, 0);
 *
 * uintTreaple.getNodeByKey(100);
 *
 * uintTreaple.remove(100);
 * ```
 */
library CartesianMerkleTree {
    /**
     *********************
     *      UintCMT      *
     *********************
     */

    struct UintCMT {
        CMT _treaple;
    }

    error TreapleNotInitialized();
    error TreapleAlreadyInitialized();
    error TreapleNotEmpty();

    error ZeroDesiredProofSize();
    error ProofSizeTooLow(uint256 attemptedIndex, uint256 maxIndex);

    error ZeroKeyProvided();
    error KeyAlreadyExists();
    error NodeDoesNotExist();

    /**
     * @notice The function to initialize the Cartesian Merkle tree.
     * Under the hood it sets the desired proof size of the CMT proofs, therefore can be considered
     * alias function for the `setDesiredProofSize`.
     *
     * Requirements:
     * - The desired proof size value must be greater than 0.
     *
     * @param treaple self.
     * @param desiredProofSize_ The desired proof size of the CMT proofs.
     */
    function initialize(UintCMT storage treaple, uint32 desiredProofSize_) internal {
        _initialize(treaple._treaple, desiredProofSize_);
    }

    /**
     * @notice The function to set a custom hash function, that will be used to build the Cartesian Merkle Tree.
     *
     * Requirements:
     * - The tree must be empty.
     *
     * @param treaple self.
     * @param hash3_ The hash function that accepts three arguments.
     */
    function setHasher(
        UintCMT storage treaple,
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_
    ) internal {
        _setHasher(treaple._treaple, hash3_);
    }

    /**
     * @notice The function to set a desired proof size, that will be used to build the Cartesian Merkle Tree proofs.
     *
     * Requirements:
     * - The desired proof size value must be greater than 0.
     *
     * @param treaple self.
     * @param desiredProofSize_ The desired proof size of the CMT proofs.
     */
    function setDesiredProofSize(UintCMT storage treaple, uint32 desiredProofSize_) internal {
        _setDesiredProofSize(treaple._treaple, desiredProofSize_);
    }

    /**
     * @notice The function to add a new element to the uint256 treaple.
     * Complexity is O(log(n)), where n is the max depth of the treaple.
     *
     * @param treaple self.
     * @param key_ The key of the element.
     */
    function add(UintCMT storage treaple, uint256 key_) internal {
        _add(treaple._treaple, bytes32(key_));
    }

    /**
     * @notice The function to remove an element from the uint256 treaple.
     * Complexity is O(log(n)), where n is the max depth of the treaple.
     *
     * @param treaple self.
     * @param key_ The key of the element.
     */
    function remove(UintCMT storage treaple, uint256 key_) internal {
        _remove(treaple._treaple, bytes32(key_));
    }

    /**
     * @notice The function to get the proof if a node with specific key exists or not exists in the CMT.
     * Complexity is O(log(n)), where n is the max depth of the treaple.
     *
     * @param treaple self.
     * @param key_ The key of the element.
     * @param desiredProofSize_ The desired siblings length in the proof.
     * @return CMT proof struct.
     */
    function getProof(
        UintCMT storage treaple,
        uint256 key_,
        uint32 desiredProofSize_
    ) internal view returns (Proof memory) {
        return _proof(treaple._treaple, bytes32(key_), desiredProofSize_);
    }

    /**
     * @notice The function to get the root of the Cartesian Merkle Tree.
     * Complexity is O(1).
     *
     * @param treaple self.
     * @return The root of the Cartesian Merkle Tree.
     */
    function getRoot(UintCMT storage treaple) internal view returns (bytes32) {
        return _rootMerkleHash(treaple._treaple);
    }

    /**
     * @notice The function to get the node by its index.
     * Complexity is O(1).
     *
     * @param treaple self.
     * @param nodeId_ The index of the node.
     * @return The node.
     */
    function getNode(
        UintCMT storage treaple,
        uint256 nodeId_
    ) internal view returns (Node memory) {
        return _node(treaple._treaple, nodeId_);
    }

    /**
     * @notice The function to get the node by its key.
     * Complexity is O(log(n)), where n is the max depth of the treaple.
     *
     * @param treaple self.
     * @param key_ The key of the element.
     * @return The node.
     */
    function getNodeByKey(
        UintCMT storage treaple,
        uint256 key_
    ) internal view returns (Node memory) {
        return _nodeByKey(treaple._treaple, bytes32(key_));
    }

    /**
     * @notice The function to get the desired proof size value.
     *
     * @param treaple self.
     * @return The desired proof size value.
     */
    function getDesiredProofSize(UintCMT storage treaple) internal view returns (uint256) {
        return _desiredProofSize(treaple._treaple);
    }

    /**
     * @notice The function to get the number of nodes in the Cartesian Merkle Tree.
     *
     * @param treaple self.
     * @return The number of nodes in the Cartesian Merkle Tree.
     */
    function getNodesCount(UintCMT storage treaple) internal view returns (uint64) {
        return uint64(_nodesCount(treaple._treaple));
    }

    /**
     * @notice The function to check if custom hash function is set.
     *
     * @param treaple self.
     * @return True if custom hash function is set, otherwise false.
     */
    function isCustomHasherSet(UintCMT storage treaple) internal view returns (bool) {
        return _isCustomHasherSet(treaple._treaple);
    }

    /**
     **********************
     *     Bytes32CMT     *
     **********************
     */

    struct Bytes32CMT {
        CMT _treaple;
    }

    /**
     * @notice The function to initialize the Cartesian Merkle tree.
     * Under the hood it sets the desired proof size of the CMT proofs, therefore can be considered
     * alias function for the `setDesiredProofSize`.
     *
     * Requirements:
     * - The desired proof size value must be greater than 0.
     *
     * @param treaple self.
     * @param desiredProofSize_ The desired proof size of the CMT proofs.
     */
    function initialize(Bytes32CMT storage treaple, uint32 desiredProofSize_) internal {
        _initialize(treaple._treaple, desiredProofSize_);
    }

    /**
     * @notice The function to set a custom hash function, that will be used to build the Cartesian Merkle Tree.
     *
     * Requirements:
     * - The tree must be empty.
     *
     * @param treaple self.
     * @param hash3_ The hash function that accepts three arguments.
     */
    function setHasher(
        Bytes32CMT storage treaple,
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_
    ) internal {
        _setHasher(treaple._treaple, hash3_);
    }

    /**
     * @notice The function to set a desired proof size, that will be used to build the Cartesian Merkle Tree proofs.
     *
     * Requirements:
     * - The desired proof size value must be greater than 0.
     *
     * @param treaple self.
     * @param desiredProofSize_ The desired proof size of the CMT proofs.
     */
    function setDesiredProofSize(Bytes32CMT storage treaple, uint32 desiredProofSize_) internal {
        _setDesiredProofSize(treaple._treaple, desiredProofSize_);
    }

    /**
     * @notice The function to add a new element to the bytes32 treaple.
     * Complexity is O(log(n)), where n is the max depth of the treaple.
     *
     * @param treaple self.
     * @param key_ The key of the element.
     */
    function add(Bytes32CMT storage treaple, bytes32 key_) internal {
        _add(treaple._treaple, key_);
    }

    /**
     * @notice The function to remove an element from the bytes32 treaple.
     * Complexity is O(log(n)), where n is the max depth of the treaple.
     *
     * @param treaple self.
     * @param key_ The key of the element.
     */
    function remove(Bytes32CMT storage treaple, bytes32 key_) internal {
        _remove(treaple._treaple, key_);
    }

    /**
     * @notice The function to get the proof if a node with specific key exists or not exists in the CMT.
     * Complexity is O(log(n)), where n is the max depth of the treaple.
     *
     * @param treaple self.
     * @param key_ The key of the element.
     * @param desiredProofSize_ The desired siblings length in the proof.
     * @return CMT proof struct.
     */
    function getProof(
        Bytes32CMT storage treaple,
        bytes32 key_,
        uint32 desiredProofSize_
    ) internal view returns (Proof memory) {
        return _proof(treaple._treaple, key_, desiredProofSize_);
    }

    /**
     * @notice The function to get the root of the Cartesian Merkle Tree.
     * Complexity is O(1).
     *
     * @param treaple self.
     * @return The root of the Cartesian Merkle Tree.
     */
    function getRoot(Bytes32CMT storage treaple) internal view returns (bytes32) {
        return _rootMerkleHash(treaple._treaple);
    }

    /**
     * @notice The function to get the node by its index.
     * Complexity is O(1).
     *
     * @param treaple self.
     * @param nodeId_ The index of the node.
     * @return The node.
     */
    function getNode(
        Bytes32CMT storage treaple,
        uint256 nodeId_
    ) internal view returns (Node memory) {
        return _node(treaple._treaple, nodeId_);
    }

    /**
     * @notice The function to get the node by its key.
     * Complexity is O(log(n)), where n is the max depth of the treaple.
     *
     * @param treaple self.
     * @param key_ The key of the element.
     * @return The node.
     */
    function getNodeByKey(
        Bytes32CMT storage treaple,
        bytes32 key_
    ) internal view returns (Node memory) {
        return _nodeByKey(treaple._treaple, key_);
    }

    /**
     * @notice The function to get the desired proof size value.
     *
     * @param treaple self.
     * @return The desired proof size value.
     */
    function getDesiredProofSize(Bytes32CMT storage treaple) internal view returns (uint256) {
        return _desiredProofSize(treaple._treaple);
    }

    /**
     * @notice The function to get the number of nodes in the Cartesian Merkle Tree.
     *
     * @param treaple self.
     * @return The number of nodes in the Cartesian Merkle Tree.
     */
    function getNodesCount(Bytes32CMT storage treaple) internal view returns (uint64) {
        return uint64(_nodesCount(treaple._treaple));
    }

    /**
     * @notice The function to check if custom hash function is set.
     *
     * @param treaple self.
     * @return True if custom hash function is set, otherwise false.
     */
    function isCustomHasherSet(Bytes32CMT storage treaple) internal view returns (bool) {
        return _isCustomHasherSet(treaple._treaple);
    }

    /**
     ************************
     *      AddressCMT      *
     ************************
     */

    struct AddressCMT {
        CMT _treaple;
    }

    /**
     * @notice The function to initialize the Cartesian Merkle tree.
     * Under the hood it sets the desired proof size of the CMT proofs, therefore can be considered
     * alias function for the `setDesiredProofSize`.
     *
     * Requirements:
     * - The desired proof size value must be greater than 0.
     *
     * @param treaple self.
     * @param desiredProofSize_ The desired proof size of the CMT proofs.
     */
    function initialize(AddressCMT storage treaple, uint32 desiredProofSize_) internal {
        _initialize(treaple._treaple, desiredProofSize_);
    }

    /**
     * @notice The function to set a custom hash function, that will be used to build the Cartesian Merkle Tree.
     *
     * Requirements:
     * - The tree must be empty.
     *
     * @param treaple self.
     * @param hash3_ The hash function that accepts three arguments.
     */
    function setHasher(
        AddressCMT storage treaple,
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_
    ) internal {
        _setHasher(treaple._treaple, hash3_);
    }

    /**
     * @notice The function to set a desired proof size, that will be used to build the Cartesian Merkle Tree proofs.
     *
     * Requirements:
     * - The desired proof size value must be greater than 0.
     *
     * @param treaple self.
     * @param desiredProofSize_ The desired proof size of the CMT proofs.
     */
    function setDesiredProofSize(AddressCMT storage treaple, uint32 desiredProofSize_) internal {
        _setDesiredProofSize(treaple._treaple, desiredProofSize_);
    }

    /**
     * @notice The function to add a new element to the address treaple.
     * Complexity is O(log(n)), where n is the max depth of the treaple.
     *
     * @param treaple self.
     * @param key_ The key of the element.
     */
    function add(AddressCMT storage treaple, address key_) internal {
        _add(treaple._treaple, _fromAddressToBytes32(key_));
    }

    /**
     * @notice The function to remove an element from the address treaple.
     * Complexity is O(log(n)), where n is the max depth of the treaple.
     *
     * @param treaple self.
     * @param key_ The key of the element.
     */
    function remove(AddressCMT storage treaple, address key_) internal {
        _remove(treaple._treaple, _fromAddressToBytes32(key_));
    }

    /**
     * @notice The function to get the proof if a node with specific key exists or not exists in the CMT.
     * Complexity is O(log(n)), where n is the max depth of the treaple.
     *
     * @param treaple self.
     * @param key_ The key of the element.
     * @param desiredProofSize_ The desired siblings length in the proof.
     * @return CMT proof struct.
     */
    function getProof(
        AddressCMT storage treaple,
        address key_,
        uint32 desiredProofSize_
    ) internal view returns (Proof memory) {
        return _proof(treaple._treaple, _fromAddressToBytes32(key_), desiredProofSize_);
    }

    /**
     * @notice The function to get the root of the Cartesian Merkle Tree.
     * Complexity is O(1).
     *
     * @param treaple self.
     * @return The root of the Cartesian Merkle Tree.
     */
    function getRoot(AddressCMT storage treaple) internal view returns (bytes32) {
        return _rootMerkleHash(treaple._treaple);
    }

    /**
     * @notice The function to get the node by its index.
     * Complexity is O(1).
     *
     * @param treaple self.
     * @param nodeId_ The index of the node.
     * @return The node.
     */
    function getNode(
        AddressCMT storage treaple,
        uint256 nodeId_
    ) internal view returns (Node memory) {
        return _node(treaple._treaple, nodeId_);
    }

    /**
     * @notice The function to get the node by its key.
     * Complexity is O(log(n)), where n is the max depth of the treaple.
     *
     * @param treaple self.
     * @param key_ The key of the element.
     * @return The node.
     */
    function getNodeByKey(
        AddressCMT storage treaple,
        address key_
    ) internal view returns (Node memory) {
        return _nodeByKey(treaple._treaple, _fromAddressToBytes32(key_));
    }

    /**
     * @notice The function to get the desired proof size value.
     *
     * @param treaple self.
     * @return The desired proof size value.
     */
    function getDesiredProofSize(AddressCMT storage treaple) internal view returns (uint256) {
        return _desiredProofSize(treaple._treaple);
    }

    /**
     * @notice The function to get the number of nodes in the Cartesian Merkle Tree.
     *
     * @param treaple self.
     * @return The number of nodes in the Cartesian Merkle Tree.
     */
    function getNodesCount(AddressCMT storage treaple) internal view returns (uint64) {
        return uint64(_nodesCount(treaple._treaple));
    }

    /**
     * @notice The function to check if custom hash function is set.
     *
     * @param treaple self.
     * @return True if custom hash function is set, otherwise false.
     */
    function isCustomHasherSet(AddressCMT storage treaple) internal view returns (bool) {
        return _isCustomHasherSet(treaple._treaple);
    }

    function _fromAddressToBytes32(address key_) private pure returns (bytes32 result_) {
        assembly {
            result_ := key_
        }
    }

    /**
     ************************
     *       InnerCMT       *
     ************************
     */

    /**
     * @notice Defines the structure of the Cartesian Merkle Tree.
     *
     * @param nodes A mapping of the treaple's nodes, where the key is the node's index, starting from 1 upon node addition.
     *
     * @param merkleRootId The index of the root node.
     * @param nodesCount The total number of nodes within the Cartesian Merkle Tree.
     * @param deletedNodesCount The total number of the deleted nodes within the Cartesian Merkle Tree.
     * @param desiredProofSize The desired proof size of the CMT proofs.
     * @param isCustomHasherSet Indicates whether custom hash function has been configured (true) or not (false).
     * @param hash3 A hash function accepting three arguments.
     */
    struct CMT {
        mapping(uint64 => Node) nodes;
        uint64 merkleRootId;
        uint64 nodesCount;
        uint64 deletedNodesCount;
        uint32 desiredProofSize;
        bool isCustomHasherSet;
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3;
    }

    /**
     * @notice Describes a node within the Cartesian Merkle tree, including its children, hash, priority and key.
     *
     * @param childLeft The index of the left child node.
     * @param childRight The index of the right child node.
     * @param priority The priority of the node that counts as `keccak256(key)`
     * @param merkleHash The hash of the node, calculated as follows:
     * - H(k || child1 || child2) where k is the current node key;
     * child1 and child2 are merkleHash values of child nodes that were sorted in ascending order
     *
     * @param key The key associated with the node.
     */
    struct Node {
        uint64 childLeft;
        uint64 childRight;
        bytes16 priority;
        bytes32 merkleHash;
        bytes32 key;
    }

    /**
     * @notice Represents the proof of a node's (non-)existence within the Cartesian Merkle tree.
     *
     * @param root The root hash of the Cartesian Merkle tree.
     * @param siblings An array of sibling hashes can be used to get the Cartesian Merkle Root.
     * @param siblingsLength The number of siblings to be used for evidence.
     * @param directionBits A path from the root to the node.
     * @param existence Indicates the presence (true) or absence (false) of the node.
     * @param key The key associated with the node.
     * @param nonExistenceKey The non-existence key of the auxiliary node in case when existence is false.
     */
    struct Proof {
        bytes32 root;
        bytes32[] siblings;
        uint256 siblingsLength;
        uint256 directionBits;
        bool existence;
        bytes32 key;
        bytes32 nonExistenceKey;
    }

    bytes32 internal constant ZERO_HASH = bytes32(0);

    modifier onlyInitialized(CMT storage treaple) {
        if (!_isInitialized(treaple)) revert TreapleNotInitialized();
        _;
    }

    function _initialize(CMT storage treaple, uint32 desiredProofSize_) private {
        if (_isInitialized(treaple)) revert TreapleAlreadyInitialized();

        _setDesiredProofSize(treaple, desiredProofSize_);
    }

    function _setDesiredProofSize(CMT storage treaple, uint32 desiredProofSize_) private {
        if (desiredProofSize_ == 0) revert ZeroDesiredProofSize();

        treaple.desiredProofSize = desiredProofSize_;
    }

    function _setHasher(
        CMT storage treaple,
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_
    ) private {
        if (_nodesCount(treaple) != 0) revert TreapleNotEmpty();

        treaple.isCustomHasherSet = true;

        treaple.hash3 = hash3_;
    }

    function _add(CMT storage treaple, bytes32 key_) private onlyInitialized(treaple) {
        if (key_ == 0) revert ZeroKeyProvided();

        treaple.merkleRootId = uint64(_add(treaple, treaple.merkleRootId, key_));
    }

    function _remove(CMT storage treaple, bytes32 key_) private onlyInitialized(treaple) {
        if (key_ == 0) revert ZeroKeyProvided();

        treaple.merkleRootId = uint64(_remove(treaple, treaple.merkleRootId, key_));
    }

    function _add(
        CMT storage treaple,
        uint256 rootNodeId_,
        bytes32 key_
    ) private returns (uint256) {
        Node storage rootNode = treaple.nodes[uint64(rootNodeId_)];

        if (rootNode.key == 0) {
            return _newNode(treaple, key_);
        }

        if (rootNode.key == key_) revert KeyAlreadyExists();

        if (rootNode.key > key_) {
            rootNode.childLeft = uint64(_add(treaple, rootNode.childLeft, key_));

            if (treaple.nodes[rootNode.childLeft].priority > rootNode.priority) {
                rootNodeId_ = _rightRotate(treaple, rootNodeId_);
                rootNode = treaple.nodes[uint64(rootNodeId_)];
            }
        } else {
            rootNode.childRight = uint64(_add(treaple, rootNode.childRight, key_));

            if (treaple.nodes[rootNode.childRight].priority > rootNode.priority) {
                rootNodeId_ = _leftRotate(treaple, rootNodeId_);
                rootNode = treaple.nodes[uint64(rootNodeId_)];
            }
        }

        rootNode.merkleHash = _hashNodes(treaple, rootNodeId_);

        return rootNodeId_;
    }

    function _remove(
        CMT storage treaple,
        uint256 rootNodeId_,
        bytes32 key_
    ) private returns (uint256) {
        Node storage rootNode = treaple.nodes[uint64(rootNodeId_)];

        if (rootNode.key == 0) revert NodeDoesNotExist();

        if (key_ < rootNode.key) {
            rootNode.childLeft = uint64(_remove(treaple, rootNode.childLeft, key_));
        } else if (key_ > rootNode.key) {
            rootNode.childRight = uint64(_remove(treaple, rootNode.childRight, key_));
        }

        if (rootNode.key == key_) {
            Node storage leftRootChildNode = treaple.nodes[rootNode.childLeft];
            Node storage rightRootChildNode = treaple.nodes[rootNode.childRight];

            if (leftRootChildNode.key == 0 || rightRootChildNode.key == 0) {
                uint64 nodeIdToRemove_ = uint64(rootNodeId_);

                rootNodeId_ = leftRootChildNode.key == 0
                    ? rootNode.childRight
                    : rootNode.childLeft;

                treaple.deletedNodesCount++;
                delete treaple.nodes[nodeIdToRemove_];
            } else if (leftRootChildNode.priority < rightRootChildNode.priority) {
                rootNodeId_ = _leftRotate(treaple, rootNodeId_);
                rootNode = treaple.nodes[uint64(rootNodeId_)];

                rootNode.childLeft = uint64(_remove(treaple, rootNode.childLeft, key_));
            } else {
                rootNodeId_ = _rightRotate(treaple, rootNodeId_);
                rootNode = treaple.nodes[uint64(rootNodeId_)];

                rootNode.childRight = uint64(_remove(treaple, rootNode.childRight, key_));
            }
        }

        rootNode.merkleHash = _hashNodes(treaple, rootNodeId_);

        return rootNodeId_;
    }

    function _rightRotate(CMT storage treaple, uint256 nodeId_) private returns (uint256) {
        Node storage node = treaple.nodes[uint64(nodeId_)];

        uint64 leftId_ = node.childLeft;

        Node storage leftNode = treaple.nodes[leftId_];

        uint64 leftRightId_ = leftNode.childRight;

        leftNode.childRight = uint64(nodeId_);
        node.childLeft = leftRightId_;

        node.merkleHash = _hashNodes(treaple, nodeId_);

        return leftId_;
    }

    function _leftRotate(CMT storage treaple, uint256 nodeId_) private returns (uint256) {
        Node storage node = treaple.nodes[uint64(nodeId_)];

        uint64 rightId_ = node.childRight;

        Node storage rightNode = treaple.nodes[rightId_];

        uint64 rightLeftId_ = rightNode.childLeft;

        rightNode.childLeft = uint64(nodeId_);
        node.childRight = rightLeftId_;

        node.merkleHash = _hashNodes(treaple, nodeId_);

        return rightId_;
    }

    function _proof(
        CMT storage treaple,
        bytes32 key_,
        uint256 desiredProofSize_
    ) private view returns (Proof memory) {
        desiredProofSize_ = desiredProofSize_ == 0
            ? _desiredProofSize(treaple)
            : desiredProofSize_;

        Proof memory proof_ = Proof({
            root: _rootMerkleHash(treaple),
            siblings: new bytes32[](desiredProofSize_),
            siblingsLength: 0,
            directionBits: 0,
            existence: false,
            key: key_,
            nonExistenceKey: ZERO_HASH
        });

        if (treaple.merkleRootId == 0) {
            return proof_;
        }

        Node storage node;
        uint256 currentSiblingsIndex_;
        uint256 nextNodeId_ = treaple.merkleRootId;
        uint256 directionBits_;

        while (true) {
            node = treaple.nodes[uint64(nextNodeId_)];

            if (node.key == key_) {
                bytes32 leftHash_ = treaple.nodes[node.childLeft].merkleHash;
                bytes32 rightHash_ = treaple.nodes[node.childRight].merkleHash;

                _addProofSibling(proof_, currentSiblingsIndex_++, leftHash_);
                _addProofSibling(proof_, currentSiblingsIndex_++, rightHash_);

                proof_.directionBits = _calculateDirectionBit(
                    directionBits_,
                    currentSiblingsIndex_,
                    leftHash_,
                    rightHash_
                );

                proof_.existence = true;
                proof_.siblingsLength = currentSiblingsIndex_;

                break;
            }

            uint64 otherNodeId_;

            if (node.key > key_) {
                otherNodeId_ = node.childRight;
                nextNodeId_ = node.childLeft;
            } else {
                otherNodeId_ = node.childLeft;
                nextNodeId_ = node.childRight;
            }

            if (nextNodeId_ == 0) {
                bytes32 leftHash_ = treaple.nodes[node.childLeft].merkleHash;
                bytes32 rightHash_ = treaple.nodes[node.childRight].merkleHash;

                _addProofSibling(proof_, currentSiblingsIndex_++, leftHash_);
                _addProofSibling(proof_, currentSiblingsIndex_++, rightHash_);

                proof_.directionBits = _calculateDirectionBit(
                    directionBits_,
                    currentSiblingsIndex_,
                    leftHash_,
                    rightHash_
                );

                proof_.nonExistenceKey = node.key;
                proof_.siblingsLength = currentSiblingsIndex_;

                break;
            }

            _addProofSibling(proof_, currentSiblingsIndex_++, node.key);
            _addProofSibling(
                proof_,
                currentSiblingsIndex_++,
                treaple.nodes[otherNodeId_].merkleHash
            );

            directionBits_ = _calculateDirectionBit(
                directionBits_,
                currentSiblingsIndex_,
                treaple.nodes[uint64(nextNodeId_)].merkleHash,
                treaple.nodes[otherNodeId_].merkleHash
            );
        }

        return proof_;
    }

    function _newNode(CMT storage treaple, bytes32 key_) private returns (uint256) {
        uint64 nodeId_ = ++treaple.nodesCount;

        treaple.nodes[nodeId_] = Node({
            childLeft: 0,
            childRight: 0,
            priority: bytes16(keccak256(abi.encodePacked(key_))),
            merkleHash: _getNodesHash(treaple, key_, 0, 0),
            key: key_
        });

        return nodeId_;
    }

    function _addProofSibling(
        Proof memory proof_,
        uint256 currentSiblingsIndex_,
        bytes32 siblingToAdd_
    ) private pure {
        if (currentSiblingsIndex_ >= proof_.siblings.length) {
            revert ProofSizeTooLow(currentSiblingsIndex_, proof_.siblings.length);
        }

        proof_.siblings[currentSiblingsIndex_] = siblingToAdd_;
    }

    function _calculateDirectionBit(
        uint256 directionBits_,
        uint256 currentSiblingsIndex_,
        bytes32 leftHash_,
        bytes32 rightHash_
    ) private pure returns (uint256) {
        if (currentSiblingsIndex_ != 2) {
            directionBits_ <<= 1;
        }

        if (leftHash_ > rightHash_) {
            directionBits_ |= 1;
        }

        return directionBits_;
    }

    function _hashNodes(CMT storage treaple, uint256 nodeId_) private view returns (bytes32) {
        Node storage node = treaple.nodes[uint64(nodeId_)];

        bytes32 leftHash_ = treaple.nodes[node.childLeft].merkleHash;
        bytes32 rightHash_ = treaple.nodes[node.childRight].merkleHash;

        if (leftHash_ > rightHash_) {
            (leftHash_, rightHash_) = (rightHash_, leftHash_);
        }

        return _getNodesHash(treaple, node.key, leftHash_, rightHash_);
    }

    function _getNodesHash(
        CMT storage treaple,
        bytes32 nodeKey_,
        bytes32 leftNodeKey_,
        bytes32 rightNodeKey_
    ) private view returns (bytes32) {
        function(bytes32, bytes32, bytes32) view returns (bytes32) hash3_ = treaple
            .isCustomHasherSet
            ? treaple.hash3
            : _hash3;

        return hash3_(nodeKey_, leftNodeKey_, rightNodeKey_);
    }

    function _nodeByKey(
        CMT storage treaple,
        bytes32 key_
    ) private view returns (Node memory result_) {
        uint256 nextNodeId_ = treaple.merkleRootId;

        Node storage currentNode;

        while (true) {
            currentNode = treaple.nodes[uint64(nextNodeId_)];

            if (currentNode.key == 0) {
                break;
            }

            if (currentNode.key == key_) {
                result_ = currentNode;

                break;
            }

            nextNodeId_ = currentNode.key < key_ ? currentNode.childRight : currentNode.childLeft;
        }
    }

    function _hash3(bytes32 a_, bytes32 b_, bytes32 c) private pure returns (bytes32 result_) {
        assembly {
            let freePtr_ := mload(64)

            mstore(freePtr_, a_)
            mstore(add(freePtr_, 32), b_)
            mstore(add(freePtr_, 64), c)

            result_ := keccak256(freePtr_, 96)
        }
    }

    function _rootMerkleHash(CMT storage treaple) private view returns (bytes32) {
        return treaple.nodes[treaple.merkleRootId].merkleHash;
    }

    function _node(CMT storage treaple, uint256 nodeId_) private view returns (Node memory) {
        return treaple.nodes[uint64(nodeId_)];
    }

    function _desiredProofSize(CMT storage treaple) private view returns (uint256) {
        return treaple.desiredProofSize;
    }

    function _nodesCount(CMT storage treaple) private view returns (uint256) {
        return treaple.nodesCount - treaple.deletedNodesCount;
    }

    function _isInitialized(CMT storage treaple) private view returns (bool) {
        return treaple.desiredProofSize > 0;
    }

    function _isCustomHasherSet(CMT storage treaple) private view returns (bool) {
        return treaple.isCustomHasherSet;
    }
}
