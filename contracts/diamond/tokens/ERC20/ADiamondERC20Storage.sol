// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {AInitializableStorage} from "../../utils/AInitializableStorage.sol";

/**
 * @notice The Diamond standard module
 *
 * This is an ERC20 token Storage contract with Diamond Standard support
 */
abstract contract ADiamondERC20Storage is AInitializableStorage, IERC20, IERC20Metadata {
    bytes32 public constant DIAMOND_ERC20_STORAGE_SLOT =
        keccak256("diamond.standard.diamond.erc20.storage");

    struct DERC20Storage {
        string name;
        string symbol;
        uint256 totalSupply;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
    }

    function _getErc20Storage() internal pure returns (DERC20Storage storage _erc20Storage) {
        bytes32 slot_ = DIAMOND_ERC20_STORAGE_SLOT;

        assembly {
            _erc20Storage.slot := slot_
        }
    }

    /**
     * @notice The function to get the name of the token.
     * @return The name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _getErc20Storage().name;
    }

    /**
     * @notice The function to get the symbol of the token.
     * @return The symbol of the token.
     */
    function symbol() public view virtual override returns (string memory) {
        return _getErc20Storage().symbol;
    }

    /**
     * @notice The function to get the number of decimals used for user representation.
     * @return The number of decimals.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @inheritdoc IERC20
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _getErc20Storage().totalSupply;
    }

    /**
     * @inheritdoc IERC20
     */
    function balanceOf(address account_) public view virtual override returns (uint256) {
        return _getErc20Storage().balances[account_];
    }

    /**
     * @inheritdoc IERC20
     */
    function allowance(
        address owner_,
        address spender_
    ) public view virtual override returns (uint256) {
        return _getErc20Storage().allowances[owner_][spender_];
    }
}
