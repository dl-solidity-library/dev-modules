// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// solhint-disable-next-line no-unused-import
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ADiamondERC20Storage} from "./ADiamondERC20Storage.sol";

/**
 * @notice The Diamond standard module
 *
 * This is modified version of OpenZeppelin's ERC20 contract to be used as a Storage contract
 * by the Diamond Standard.
 */
contract DiamondERC20 is ADiamondERC20Storage {
    error ApproverIsZeroAddress();
    error InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error InsufficientBalance(address sender, uint256 balance, uint256 needed);
    error ReceiverIsZeroAddress();
    error SenderIsZeroAddress();
    error SpenderIsZeroAddress();

    /**
     * @notice Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18.
     */
    function __DiamondERC20_init(
        string memory name_,
        string memory symbol_
    ) internal onlyInitializing(DIAMOND_ERC20_STORAGE_SLOT) {
        DERC20Storage storage _erc20Storage = _getErc20Storage();

        _erc20Storage.name = name_;
        _erc20Storage.symbol = symbol_;
    }

    /**
     * @inheritdoc IERC20
     */
    function transfer(address to_, uint256 amount_) public virtual override returns (bool) {
        _transfer(msg.sender, to_, amount_);

        return true;
    }

    /**
     * @inheritdoc IERC20
     */
    function approve(address spender_, uint256 amount_) public virtual override returns (bool) {
        _approve(msg.sender, spender_, amount_);

        return true;
    }

    /**
     * @inheritdoc IERC20
     */
    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    ) public virtual override returns (bool) {
        _spendAllowance(from_, msg.sender, amount_);
        _transfer(from_, to_, amount_);

        return true;
    }

    /**
     * @notice Moves `amount` of tokens from `from` to `to`.
     * @dev This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from_, address to_, uint256 amount_) internal {
        if (from_ == address(0)) revert SenderIsZeroAddress();
        if (to_ == address(0)) revert ReceiverIsZeroAddress();

        _update(from_, to_, amount_);
    }

    /**
     * @notice Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     * @dev This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account_, uint256 amount_) internal {
        if (account_ == address(0)) revert ReceiverIsZeroAddress();

        _update(address(0), account_, amount_);
    }

    /**
     * @notice Destroys `amount` tokens from `account`, reducing the
     * total supply.
     * @dev This function is not virtual, {_update} should be overridden instead.
     */
    function _burn(address account_, uint256 amount_) internal {
        if (account_ == address(0)) revert SenderIsZeroAddress();

        _update(account_, address(0), amount_);
    }

    /**
     * @dev Transfers a `amount` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     * Emits a {Transfer} event.
     */
    function _update(address from_, address to_, uint256 amount_) internal virtual {
        DERC20Storage storage _erc20Storage = _getErc20Storage();

        if (from_ == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _erc20Storage.totalSupply += amount_;
        } else {
            uint256 fromBalance_ = _erc20Storage.balances[from_];

            if (fromBalance_ < amount_) revert InsufficientBalance(from_, fromBalance_, amount_);

            unchecked {
                // Overflow not possible: amount <= fromBalance <= totalSupply.
                _erc20Storage.balances[from_] = fromBalance_ - amount_;
            }
        }

        if (to_ == address(0)) {
            unchecked {
                // Overflow not possible: amount <= fromBalance <= totalSupply.
                _erc20Storage.totalSupply -= amount_;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
                _erc20Storage.balances[to_] += amount_;
            }
        }

        emit Transfer(from_, to_, amount_);
    }

    /**
     * @notice Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     */
    function _approve(address owner_, address spender_, uint256 amount_) internal virtual {
        if (owner_ == address(0)) revert ApproverIsZeroAddress();
        if (spender_ == address(0)) revert SpenderIsZeroAddress();

        _getErc20Storage().allowances[owner_][spender_] = amount_;

        emit Approval(owner_, spender_, amount_);
    }

    /**
     * @notice Updates `owner` s allowance for `spender` based on spent `amount`.
     */
    function _spendAllowance(address owner_, address spender_, uint256 amount_) internal virtual {
        uint256 currentAllowance_ = allowance(owner_, spender_);

        if (currentAllowance_ != type(uint256).max) {
            if (currentAllowance_ < amount_)
                revert InsufficientAllowance(spender_, currentAllowance_, amount_);

            unchecked {
                _approve(owner_, spender_, currentAllowance_ - amount_);
            }
        }
    }
}
