// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @notice The Diamond standard module
 *
 * DiamondERC165 - Contract implementing ERC165 interface for Diamonds
 */
contract DiamondERC165 is ERC165 {
    /**
     * @notice The function to check whether the Diamond supports the interface
     * @param interfaceId_ the interface to check
     * @return true if the interface is supported, false otherwise
     */
    function supportsInterface(bytes4 interfaceId_) public view virtual override returns (bool) {
        // This section of code provides support for the Diamond Loupe and Diamond Cut interfaces.
        // Diamond Loupe interface is defined as: 0x48e2b093
        // Diamond Cut interface is defined as: 0x1f931c1c
        return
            interfaceId_ == 0x1f931c1c ||
            interfaceId_ == 0x48e2b093 ||
            super.supportsInterface(interfaceId_);
    }
}
