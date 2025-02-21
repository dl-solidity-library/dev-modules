// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity >=0.5.0 <0.8.0;

import {Oracle} from "@uniswap/v3-core/contracts/libraries/Oracle.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";

contract UniswapV3PoolMock {
    using Oracle for Oracle.Observation[65535];

    struct Slot0 {
        uint160 sqrtPriceX96;
        int24 tick;
        uint16 observationIndex;
        uint16 observationCardinality;
        uint16 observationCardinalityNext;
        uint8 feeProtocol;
        bool unlocked;
    }

    Slot0 public slot0;
    Oracle.Observation[65535] public observations;

    function initialize(uint160 sqrtPriceX96_) external {
        int24 tick_ = TickMath.getTickAtSqrtRatio(sqrtPriceX96_);

        (uint16 cardinality_, uint16 cardinalityNext_) = observations.initialize(
            _blockTimestamp()
        );

        slot0 = Slot0({
            sqrtPriceX96: sqrtPriceX96_,
            tick: tick_,
            observationIndex: 0,
            observationCardinality: cardinality_,
            observationCardinalityNext: cardinalityNext_,
            feeProtocol: 0,
            unlocked: true
        });
    }

    function addObservation(int24 tick_) external {
        (slot0.observationIndex, slot0.observationCardinality) = observations.write(
            slot0.observationIndex,
            _blockTimestamp(),
            slot0.tick,
            0,
            slot0.observationCardinality,
            slot0.observationCardinalityNext
        );

        slot0.tick = tick_;
    }

    function increaseObservationCardinalityNext(uint16 observationCardinalityNext_) external {
        slot0.observationCardinalityNext = observations.grow(
            slot0.observationCardinalityNext,
            observationCardinalityNext_
        );
    }

    function observe(
        uint32[] calldata secondAgos_
    )
        external
        view
        returns (
            int56[] memory tickCumulatives_,
            uint160[] memory secondsPerLiquidityCumulativeX128s_
        )
    {
        return
            observations.observe(
                _blockTimestamp(),
                secondAgos_,
                slot0.tick,
                slot0.observationIndex,
                0,
                slot0.observationCardinality
            );
    }

    function _blockTimestamp() internal view virtual returns (uint32) {
        return uint32(block.timestamp); // truncation is desired in original contract
    }
}
