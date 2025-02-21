// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;
// solhint-disable-previous-line one-contract-per-file

import {CartesianMerkleTree} from "../../../libs/data-structures/CartesianMerkleTree.sol";

library PoseidonUnit3L {
    function poseidon(uint256[3] calldata) public pure returns (uint256) {}
}

contract CartesianMerkleTreeMock {
    using CartesianMerkleTree for *;

    CartesianMerkleTree.UintCMT internal _uintCMT;
    CartesianMerkleTree.Bytes32CMT internal _bytes32CMT;
    CartesianMerkleTree.AddressCMT internal _addressCMT;

    function initializeUintTreaple(uint32 maxDepth_) external {
        _uintCMT.initialize(maxDepth_);
    }

    function initializeBytes32Treaple(uint32 maxDepth_) external {
        _bytes32CMT.initialize(maxDepth_);
    }

    function initializeAddressTreaple(uint32 maxDepth_) external {
        _addressCMT.initialize(maxDepth_);
    }

    function setDesiredProofSizeUintTreaple(uint32 maxDepth_) external {
        _uintCMT.setDesiredProofSize(maxDepth_);
    }

    function setDesiredProofSizeBytes32Treaple(uint32 maxDepth_) external {
        _bytes32CMT.setDesiredProofSize(maxDepth_);
    }

    function setDesiredProofSizeAddressTreaple(uint32 maxDepth_) external {
        _addressCMT.setDesiredProofSize(maxDepth_);
    }

    function setUintPoseidonHasher() external {
        _uintCMT.setHasher(_hash3);
    }

    function setBytes32PoseidonHasher() external {
        _bytes32CMT.setHasher(_hash3);
    }

    function setAddressPoseidonHasher() external {
        _addressCMT.setHasher(_hash3);
    }

    function addUint(uint256 key_) external {
        _uintCMT.add(key_);
    }

    function removeUint(uint256 key_) external {
        _uintCMT.remove(key_);
    }

    function addBytes32(bytes32 key_) external {
        _bytes32CMT.add(key_);
    }

    function removeBytes32(bytes32 key_) external {
        _bytes32CMT.remove(key_);
    }

    function addAddress(address key_) external {
        _addressCMT.add(key_);
    }

    function removeAddress(address key_) external {
        _addressCMT.remove(key_);
    }

    function getUintProof(
        uint256 key_,
        uint32 desiredProofSize_
    ) external view returns (CartesianMerkleTree.Proof memory) {
        return _uintCMT.getProof(key_, desiredProofSize_);
    }

    function getBytes32Proof(
        bytes32 key_,
        uint32 desiredProofSize_
    ) external view returns (CartesianMerkleTree.Proof memory) {
        return _bytes32CMT.getProof(key_, desiredProofSize_);
    }

    function getAddressProof(
        address key_,
        uint32 desiredProofSize_
    ) external view returns (CartesianMerkleTree.Proof memory) {
        return _addressCMT.getProof(key_, desiredProofSize_);
    }

    function getUintRoot() external view returns (bytes32) {
        return _uintCMT.getRoot();
    }

    function getBytes32Root() external view returns (bytes32) {
        return _bytes32CMT.getRoot();
    }

    function getAddressRoot() external view returns (bytes32) {
        return _addressCMT.getRoot();
    }

    function getUintNode(uint256 nodeId_) external view returns (CartesianMerkleTree.Node memory) {
        return _uintCMT.getNode(nodeId_);
    }

    function getBytes32Node(
        uint256 nodeId_
    ) external view returns (CartesianMerkleTree.Node memory) {
        return _bytes32CMT.getNode(nodeId_);
    }

    function getAddressNode(
        uint256 nodeId_
    ) external view returns (CartesianMerkleTree.Node memory) {
        return _addressCMT.getNode(nodeId_);
    }

    function getUintNodeByKey(
        uint256 key_
    ) external view returns (CartesianMerkleTree.Node memory) {
        return _uintCMT.getNodeByKey(key_);
    }

    function getBytes32NodeByKey(
        bytes32 key_
    ) external view returns (CartesianMerkleTree.Node memory) {
        return _bytes32CMT.getNodeByKey(key_);
    }

    function getAddressNodeByKey(
        address key_
    ) external view returns (CartesianMerkleTree.Node memory) {
        return _addressCMT.getNodeByKey(key_);
    }

    function getUintDesiredProofSize() external view returns (uint256) {
        return _uintCMT.getDesiredProofSize();
    }

    function getBytes32DesiredProofSize() external view returns (uint256) {
        return _bytes32CMT.getDesiredProofSize();
    }

    function getAddressDesiredProofSize() external view returns (uint256) {
        return _addressCMT.getDesiredProofSize();
    }

    function getUintNodesCount() external view returns (uint256) {
        return _uintCMT.getNodesCount();
    }

    function getBytes32NodesCount() external view returns (uint256) {
        return _bytes32CMT.getNodesCount();
    }

    function getAddressNodesCount() external view returns (uint256) {
        return _addressCMT.getNodesCount();
    }

    function isUintCustomHasherSet() external view returns (bool) {
        return _uintCMT.isCustomHasherSet();
    }

    function isBytes32CustomHasherSet() external view returns (bool) {
        return _bytes32CMT.isCustomHasherSet();
    }

    function isAddressCustomHasherSet() external view returns (bool) {
        return _addressCMT.isCustomHasherSet();
    }

    function hash3(
        bytes32 element1_,
        bytes32 element2_,
        bytes32 element3_
    ) external pure returns (bytes32) {
        return _hash3(element1_, element2_, element3_);
    }

    function _hash3(
        bytes32 element1_,
        bytes32 element2_,
        bytes32 element3_
    ) internal pure returns (bytes32) {
        return
            bytes32(
                PoseidonUnit3L.poseidon(
                    [uint256(element1_), uint256(element2_), uint256(element3_)]
                )
            );
    }
}
