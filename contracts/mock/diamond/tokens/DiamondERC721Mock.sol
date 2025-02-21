// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {DiamondERC721} from "../../../diamond/tokens/ERC721/DiamondERC721.sol";

contract DiamondERC721Mock is DiamondERC721 {
    string internal baseUri;
    bool internal replaceOwner;

    constructor() {
        _disableInitializers(DIAMOND_ERC721_STORAGE_SLOT);
    }

    function __DiamondERC721Direct_init(string memory name_, string memory symbol_) external {
        __DiamondERC721_init(name_, symbol_);
    }

    function __DiamondERC721Mock_init(
        string memory name_,
        string memory symbol_
    ) external initializer(DIAMOND_ERC721_STORAGE_SLOT) {
        __DiamondERC721_init(name_, symbol_);
    }

    function toggleReplaceOwner() external {
        replaceOwner = !replaceOwner;
    }

    function setBaseURI(string memory baseUri_) external {
        baseUri = baseUri_;
    }

    function mint(address to_, uint256 tokenId_) external {
        _safeMint(to_, tokenId_);
    }

    function burn(uint256 tokenId_) external {
        _burn(tokenId_);
    }

    function transferFromMock(address from_, address to_, uint256 tokenId_) external {
        _transfer(from_, to_, tokenId_);
    }

    function safeTransferFromMock(address from_, address to_, uint256 tokenId_) external {
        safeTransferFrom(from_, to_, tokenId_);
    }

    function update(uint256 batchSize_) external {
        _update(address(this), 1, batchSize_);
    }

    function disableInitializers() external {
        _disableInitializers(DIAMOND_ERC721_STORAGE_SLOT);
    }

    function _update(
        address to_,
        uint256 tokenId_,
        uint256 batchSize_
    ) internal override returns (address) {
        if (replaceOwner) {
            _getErc721Storage().owners[tokenId_] = address(this);
            return address(this);
        } else {
            return super._update(to_, tokenId_, batchSize_);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        super._baseURI();
        return baseUri;
    }
}

contract NonERC721Receiver is IERC721Receiver {
    error RevertingOnERC721Received();

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        revert RevertingOnERC721Received();
    }
}
