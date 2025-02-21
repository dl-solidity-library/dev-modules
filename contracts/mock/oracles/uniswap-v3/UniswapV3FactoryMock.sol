// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity >=0.5.0 <0.8.0;

import {UniswapV3PoolMock} from "./UniswapV3PoolMock.sol";

contract UniswapV3FactoryMock {
    mapping(address => mapping(address => mapping(uint24 => address))) public getPool;

    function createPool(
        address tokenA_,
        address tokenB_,
        uint24 fee_
    ) external returns (address pool_) {
        (address token0_, address token1_) = tokenA_ < tokenB_
            ? (tokenA_, tokenB_)
            : (tokenB_, tokenA_);

        pool_ = _deploy(token0_, token1_, fee_);

        getPool[token0_][token1_][fee_] = pool_;
        getPool[token1_][token0_][fee_] = pool_;
    }

    function _deploy(
        address token0_,
        address token1_,
        uint24 fee_
    ) internal returns (address pool_) {
        pool_ = address(
            new UniswapV3PoolMock{salt: keccak256(abi.encode(token0_, token1_, fee_))}()
        );
    }
}
