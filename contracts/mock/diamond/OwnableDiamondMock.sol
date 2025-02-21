// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {OwnableDiamond} from "../../diamond/presets/OwnableDiamond.sol";

contract OwnableDiamondMock is OwnableDiamond {
    function __OwnableDiamondDirect_init() external {
        __DiamondOwnable_init();
    }

    function __OwnableDiamondMock_init() external initializer(DIAMOND_OWNABLE_STORAGE_SLOT) {
        __DiamondOwnable_init();
    }

    function diamondCutShort(Facet[] memory facets_) public {
        diamondCut(facets_);
    }

    function diamondCutLong(Facet[] memory facets_, address init_, bytes memory calldata_) public {
        diamondCut(facets_, init_, calldata_);
    }
}
