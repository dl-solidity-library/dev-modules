// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// solhint-disable-next-line no-unused-import
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {ADiamondERC721Storage} from "./ADiamondERC721Storage.sol";

/**
 * @notice The Diamond standard module
 *
 * This is modified version of OpenZeppelin's ERC721 contract to be used as a Storage contract
 * by the Diamond Standard.
 */
contract DiamondERC721 is ADiamondERC721Storage {
    error ApproveToCaller(address caller);
    error ApprovalToCurrentOwner(address owner, uint256 tokenId);
    error ConsecutiveTransfersNotSupported();
    error InvalidApprover(address approver, address owner);
    error InvalidSpender(address spender, uint256 tokenId);
    error NonERC721Receiver(address receiver);
    error ReceiverIsZeroAddress();
    error TokenAlreadyMinted(uint256 tokenId);
    error UnauthorizedAccount(address account);

    /**
     * @notice Sets the values for {name} and {symbol}.
     */
    function __DiamondERC721_init(
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing(DIAMOND_ERC721_STORAGE_SLOT) {
        DERC721Storage storage _erc721Storage = _getErc721Storage();

        _erc721Storage.name = name_;
        _erc721Storage.symbol = symbol_;
    }

    /**
     * @inheritdoc IERC721
     */
    function approve(address to_, uint256 tokenId_) public virtual override {
        address owner_ = ownerOf(tokenId_);

        if (to_ == owner_) revert ApprovalToCurrentOwner(owner_, tokenId_);
        if (msg.sender != owner_ && !isApprovedForAll(owner_, msg.sender))
            revert InvalidApprover(msg.sender, owner_);

        _approve(to_, tokenId_);
    }

    /**
     * @inheritdoc IERC721
     */
    function setApprovalForAll(address operator_, bool approved_) public virtual override {
        _setApprovalForAll(msg.sender, operator_, approved_);
    }

    /**
     * @inheritdoc IERC721
     */
    function transferFrom(address from_, address to_, uint256 tokenId_) public virtual override {
        if (!_isApprovedOrOwner(msg.sender, tokenId_)) revert InvalidSpender(msg.sender, tokenId_);

        _transfer(from_, to_, tokenId_);
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public virtual override {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    /**
     * @inheritdoc IERC721
     */
    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public virtual override {
        if (!_isApprovedOrOwner(msg.sender, tokenId_)) revert InvalidSpender(msg.sender, tokenId_);

        _safeTransfer(from_, to_, tokenId_, data_);
    }

    /**
     * @notice Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     */
    function _safeTransfer(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) internal virtual {
        _transfer(from_, to_, tokenId_);

        if (!_checkOnERC721Received(from_, to_, tokenId_, data_)) revert NonERC721Receiver(to_);
    }

    /**
     * @notice Safely mints `tokenId` and transfers it to `to`.
     */
    function _safeMint(address to_, uint256 tokenId_) internal virtual {
        _safeMint(to_, tokenId_, "");
    }

    /**
     * @notice Same as _safeMint, with an additional `data` parameter.
     */
    function _safeMint(address to_, uint256 tokenId_, bytes memory data_) internal virtual {
        _mint(to_, tokenId_);

        if (!_checkOnERC721Received(address(0), to_, tokenId_, data_))
            revert NonERC721Receiver(to_);
    }

    /**
     * @notice Mints `tokenId` and transfers it to `to`.
     * @dev This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address to_, uint256 tokenId_) internal {
        if (to_ == address(0)) revert ReceiverIsZeroAddress();
        if (_exists(tokenId_)) revert TokenAlreadyMinted(tokenId_);

        address previousOwner_ = _update(to_, tokenId_, 1);

        if (previousOwner_ != address(0)) revert TokenAlreadyMinted(tokenId_);
    }

    /**
     * @notice Destroys `tokenId`.
     * @dev This function is not virtual, {_update} should be overridden instead.
     */
    function _burn(uint256 tokenId_) internal {
        address owner_ = _update(address(0), tokenId_, 1);

        if (owner_ == address(0)) revert NonexistentToken(tokenId_);
    }

    /**
     * @notice Transfers `tokenId` from `from` to `to`.
     * @dev This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from_, address to_, uint256 tokenId_) internal {
        if (to_ == address(0)) revert ReceiverIsZeroAddress();

        address previousOwner_ = _update(to_, tokenId_, 1);

        if (previousOwner_ == address(0)) {
            revert NonexistentToken(tokenId_);
        } else if (previousOwner_ != from_) {
            revert UnauthorizedAccount(from_);
        }
    }

    /**
     * @notice Transfers `tokenId` from its current owner to `to`, or alternatively mints (or burns) if the
     * current owner (or `to`) is the zero address. Returns the owner of the `tokenId` before the update.
     * Emits a {Transfer} event.
     */
    function _update(
        address to_,
        uint256 tokenId_,
        uint256 batchSize_
    ) internal virtual returns (address) {
        if (batchSize_ > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert ConsecutiveTransfersNotSupported();
        }

        DERC721Storage storage _erc721Storage = _getErc721Storage();

        address from_ = _ownerOf(tokenId_);

        if (from_ == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId_);
        } else {
            if (from_ != to_) {
                _removeTokenFromOwnerEnumeration(from_, tokenId_);
            }

            delete _erc721Storage.tokenApprovals[tokenId_];

            unchecked {
                _erc721Storage.balances[from_] -= 1;
            }
        }

        if (to_ == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId_);
        } else {
            if (to_ != from_) {
                _addTokenToOwnerEnumeration(to_, tokenId_);
            }

            unchecked {
                _erc721Storage.balances[to_] += 1;
            }
        }

        _getErc721Storage().owners[tokenId_] = to_;

        emit Transfer(from_, to_, tokenId_);

        return from_;
    }

    /**
     * @notice Approve `to` to operate on `tokenId`.
     */
    function _approve(address to_, uint256 tokenId_) internal virtual {
        _getErc721Storage().tokenApprovals[tokenId_] = to_;

        emit Approval(ownerOf(tokenId_), to_, tokenId_);
    }

    /**
     * @notice Approve `operator` to operate on all of `owner` tokens.
     */
    function _setApprovalForAll(
        address owner_,
        address operator_,
        bool approved_
    ) internal virtual {
        if (owner_ == operator_) revert ApproveToCaller(owner_);

        _getErc721Storage().operatorApprovals[owner_][operator_] = approved_;

        emit ApprovalForAll(owner_, operator_, approved_);
    }

    /**
     * @notice Function to check if the 'to' can receive token.
     * The call is not executed if the target address is not a contract.
     */
    function _checkOnERC721Received(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) internal virtual returns (bool) {
        if (to_.code.length > 0) {
            try IERC721Receiver(to_).onERC721Received(msg.sender, from_, tokenId_, data_) returns (
                bytes4 retval
            ) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert NonERC721Receiver(to_);
                } else {
                    // @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @notice Private function to add a token to ownership-tracking data structures.
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        DERC721Storage storage _erc721Storage = _getErc721Storage();

        uint256 length_ = balanceOf(to);
        _erc721Storage.ownedTokens[to][length_] = tokenId;
        _erc721Storage.ownedTokensIndex[tokenId] = length_;
    }

    /**
     * @notice Private function to add a token to token tracking data structures.
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        DERC721Storage storage _erc721Storage = _getErc721Storage();

        _erc721Storage.allTokensIndex[tokenId] = _erc721Storage.allTokens.length;
        _erc721Storage.allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from ownership-tracking data structures.
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        DERC721Storage storage _erc721Storage = _getErc721Storage();

        uint256 lastTokenIndex_ = balanceOf(from) - 1;
        uint256 tokenIndex_ = _erc721Storage.ownedTokensIndex[tokenId];

        if (tokenIndex_ != lastTokenIndex_) {
            uint256 lastTokenId = _erc721Storage.ownedTokens[from][lastTokenIndex_];

            _erc721Storage.ownedTokens[from][tokenIndex_] = lastTokenId;
            _erc721Storage.ownedTokensIndex[lastTokenId] = tokenIndex_;
        }

        delete _erc721Storage.ownedTokensIndex[tokenId];
        delete _erc721Storage.ownedTokens[from][lastTokenIndex_];
    }

    /**
     * @dev Private function to remove a token from token tracking data structures.
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        DERC721Storage storage _erc721Storage = _getErc721Storage();

        // "swap and pop" pattern is used
        uint256 lastTokenIndex_ = _erc721Storage.allTokens.length - 1;
        uint256 tokenIndex_ = _erc721Storage.allTokensIndex[tokenId];
        uint256 lastTokenId_ = _erc721Storage.allTokens[lastTokenIndex_];

        _erc721Storage.allTokens[tokenIndex_] = lastTokenId_;
        _erc721Storage.allTokensIndex[lastTokenId_] = tokenIndex_;

        delete _erc721Storage.allTokensIndex[tokenId];
        _erc721Storage.allTokens.pop();
    }
}
