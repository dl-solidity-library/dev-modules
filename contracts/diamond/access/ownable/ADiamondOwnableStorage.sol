// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {AInitializableStorage} from "../../utils/AInitializableStorage.sol";

/**
 * @notice The Diamond standard module
 *
 * This is an Ownable Storage contract with Diamond Standard support
 */
abstract contract ADiamondOwnableStorage is AInitializableStorage {
    bytes32 public constant DIAMOND_OWNABLE_STORAGE_SLOT =
        keccak256("diamond.standard.diamond.ownable.storage");

    struct DOStorage {
        address owner;
    }

    error CallerNotOwner(address caller, address owner);

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _getDiamondOwnableStorage() internal pure returns (DOStorage storage _dos) {
        bytes32 slot_ = DIAMOND_OWNABLE_STORAGE_SLOT;

        assembly {
            _dos.slot := slot_
        }
    }

    /**
     * @notice The function to get the Diamond owner
     * @return the owner of the Diamond
     */
    function owner() public view virtual returns (address) {
        return _getDiamondOwnableStorage().owner;
    }

    /**
     * @notice The function to check if `msg.sender` is the owner
     */
    function _onlyOwner() internal view virtual {
        if (owner() != msg.sender) revert CallerNotOwner(msg.sender, owner());
    }
}
