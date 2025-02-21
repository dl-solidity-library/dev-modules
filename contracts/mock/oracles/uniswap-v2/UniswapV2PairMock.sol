// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

contract UniswapV2PairMock {
    address public token0;
    address public token1;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;

    uint112 private _reserve0;
    uint112 private _reserve1;
    uint32 private _blockTimestampLast;

    function initialize(address token0_, address token1_) external {
        token0 = token0_;
        token1 = token1_;

        _reserve0 = 1 ether;
        _reserve1 = 1 ether;
        _blockTimestampLast = uint32(block.timestamp);
    }

    function swap(uint256 amount0Out_, uint256 amount1Out_) external {
        unchecked {
            uint32 blockTimestamp_ = uint32(block.timestamp);
            uint32 timeElapsed_ = blockTimestamp_ - _blockTimestampLast; // overflow is desired

            if (timeElapsed_ > 0 && _reserve0 != 0 && _reserve1 != 0) {
                price0CumulativeLast += ((uint256(_reserve1) << 112) / (_reserve0)) * timeElapsed_;
                price1CumulativeLast += ((uint256(_reserve0) << 112) / (_reserve1)) * timeElapsed_;
            }

            _reserve0 = uint112(_reserve0 - amount0Out_);
            _reserve1 = uint112(_reserve1 - amount1Out_);
            _blockTimestampLast = blockTimestamp_;
        }
    }

    function getReserves()
        external
        view
        returns (uint112 reserve0_, uint112 reserve1_, uint32 blockTimestampLast_)
    {
        reserve0_ = _reserve0;
        reserve1_ = _reserve1;
        blockTimestampLast_ = _blockTimestampLast;
    }
}
