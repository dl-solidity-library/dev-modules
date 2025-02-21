// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {DiamondERC721Mock} from "./DiamondERC721Mock.sol";

contract DiamondERC721NotReceiverMock is DiamondERC721Mock {
    function mockMint(address to_, uint256 tokenId_) external {
        _mint(to_, tokenId_);
    }

    function _checkOnERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) internal pure override returns (bool) {
        return false;
    }
}
