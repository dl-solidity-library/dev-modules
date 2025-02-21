// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {AMerkleWhitelisted} from "../../access/AMerkleWhitelisted.sol";

contract MerkleWhitelistedMock is AMerkleWhitelisted {
    event WhitelistedUser();
    event WhitelistedData();

    function onlyWhitelistedMethod(
        uint256 amount_,
        bytes32[] calldata merkleProof_
    ) external onlyWhitelisted(_encode(amount_), merkleProof_) {
        emit WhitelistedData();
    }

    function onlyWhitelistedUserMethod(
        bytes32[] calldata merkleProof_
    ) external onlyWhitelistedUser(msg.sender, merkleProof_) {
        emit WhitelistedUser();
    }

    function isWhitelisted(
        bytes32 leaf_,
        bytes32[] memory merkleProof_
    ) internal view returns (bool) {
        return _isWhitelisted(leaf_, merkleProof_);
    }

    function isWhitelistedUser(
        address user_,
        bytes32[] memory merkleProof_
    ) internal view returns (bool) {
        return _isWhitelistedUser(user_, merkleProof_);
    }

    function setMerkleRoot(bytes32 merkleRoot_) external {
        _setMerkleRoot(merkleRoot_);
    }

    function _encode(uint256 amount_) private view returns (bytes memory) {
        return abi.encodePacked(amount_, msg.sender);
    }
}
