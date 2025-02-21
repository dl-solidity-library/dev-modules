// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {AUniswapV2Oracle} from "../../../oracles/AUniswapV2Oracle.sol";

contract UniswapV2OracleMock is AUniswapV2Oracle {
    using EnumerableSet for EnumerableSet.AddressSet;

    function __OracleV2Mock_init(
        address uniswapV2Factory_,
        uint256 timeWindow_
    ) external initializer {
        __OracleV2_init(uniswapV2Factory_, timeWindow_);
    }

    function mockInit(address uniswapV2Factory_, uint256 timeWindow_) external {
        __OracleV2_init(uniswapV2Factory_, timeWindow_);
    }

    function addPaths(address[][] calldata paths_) external {
        _addPaths(paths_);
    }

    function removePaths(address[] calldata tokenIns_) external {
        _removePaths(tokenIns_);
    }

    function setTimeWindow(uint256 newTimeWindow_) external {
        _setTimeWindow(newTimeWindow_);
    }

    function doubleUpdatePrice() external {
        updatePrices();
        updatePrices();
    }
}
