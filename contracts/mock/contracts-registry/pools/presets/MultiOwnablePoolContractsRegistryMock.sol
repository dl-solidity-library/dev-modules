// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {MultiOwnablePoolContractsRegistry} from "../../../../contracts-registry/pools/presets/MultiOwnablePoolContractsRegistry.sol";

contract MultiOwnablePoolContractsRegistryMock is MultiOwnablePoolContractsRegistry {
    function addProxyPool(string memory name_, address poolAddress_) public override {
        _addProxyPool(name_, poolAddress_);
    }
}
