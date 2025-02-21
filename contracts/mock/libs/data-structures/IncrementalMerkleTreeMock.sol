// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {IncrementalMerkleTree} from "../../../libs/data-structures/IncrementalMerkleTree.sol";

library PoseidonUnit1L {
    function poseidon(uint256[1] calldata) public pure returns (uint256) {}
}

library PoseidonUnit2L {
    function poseidon(uint256[2] calldata) public pure returns (uint256) {}
}

contract IncrementalMerkleTreeMock {
    using IncrementalMerkleTree for *;

    IncrementalMerkleTree.UintIMT internal _uintTree;
    IncrementalMerkleTree.Bytes32IMT internal _bytes32Tree;
    IncrementalMerkleTree.AddressIMT internal _addressTree;

    function setUintTreeHeight(uint256 height_) external {
        _uintTree.setHeight(height_);
    }

    function setBytes32TreeHeight(uint256 height_) external {
        _bytes32Tree.setHeight(height_);
    }

    function setAddressTreeHeight(uint256 height_) external {
        _addressTree.setHeight(height_);
    }

    function addUint(uint256 element_) external {
        _uintTree.add(element_);
    }

    function addBytes32(bytes32 element_) external {
        _bytes32Tree.add(element_);
    }

    function addAddress(address element_) external {
        _addressTree.add(element_);
    }

    function setUintPoseidonHasher() external {
        _uintTree.setHashers(_hash1, _hash2);
    }

    function setBytes32PoseidonHasher() external {
        _bytes32Tree.setHashers(_hash1, _hash2);
    }

    function setAddressPoseidonHasher() external {
        _addressTree.setHashers(_hash1, _hash2);
    }

    function getUintRoot() external view returns (bytes32) {
        return _uintTree.root();
    }

    function getBytes32Root() external view returns (bytes32) {
        return _bytes32Tree.root();
    }

    function getAddressRoot() external view returns (bytes32) {
        return _addressTree.root();
    }

    function getUintTreeHeight() external view returns (uint256) {
        return _uintTree.height();
    }

    function getBytes32TreeHeight() external view returns (uint256) {
        return _bytes32Tree.height();
    }

    function getAddressTreeHeight() external view returns (uint256) {
        return _addressTree.height();
    }

    function getUintTreeLength() external view returns (uint256) {
        return _uintTree.length();
    }

    function getBytes32TreeLength() external view returns (uint256) {
        return _bytes32Tree.length();
    }

    function getAddressTreeLength() external view returns (uint256) {
        return _addressTree.length();
    }

    function isUnitHashFnSet() external view returns (bool) {
        return _uintTree.isCustomHasherSet();
    }

    function isBytes32HashFnSet() external view returns (bool) {
        return _bytes32Tree.isCustomHasherSet();
    }

    function isAddressHashFnSet() external view returns (bool) {
        return _addressTree.isCustomHasherSet();
    }

    function _hash1(bytes32 element1_) internal pure returns (bytes32) {
        return bytes32(PoseidonUnit1L.poseidon([uint256(element1_)]));
    }

    function _hash2(bytes32 element1_, bytes32 element2_) internal pure returns (bytes32) {
        return bytes32(PoseidonUnit2L.poseidon([uint256(element1_), uint256(element2_)]));
    }
}
