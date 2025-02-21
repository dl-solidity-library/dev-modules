// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import {ArrayHelper} from "../libs/arrays/ArrayHelper.sol";

/**
 * @notice UniswapV2Oracle module
 *
 * The contract for retrieving prices from Uniswap V2 pairs. Works by keeping track of pairs that were
 * added as paths and returns prices of tokens following the configured routes.
 *
 * Arbitrary time window (time between oracle observations) may be configured and the Oracle will adjust automatically.
 *
 * From time to time `updatePrices()` function has to be called in order to calculate correct TWAP.
 */
abstract contract AUniswapV2Oracle is Initializable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using ArrayHelper for uint256[];
    using Math for uint256;

    struct PairInfo {
        uint256[] prices0Cumulative;
        uint256[] prices1Cumulative;
        uint256[] blockTimestamps;
        uint256 refs;
    }

    IUniswapV2Factory public uniswapV2Factory;

    uint256 public timeWindow;

    EnumerableSet.AddressSet private _pairs;
    mapping(address => address[]) private _paths;
    mapping(address => PairInfo) private _pairInfos;

    error InvalidPath(address tokenIn, uint256 pathLength);
    error PathAlreadyRegistered(address tokenIn);
    error PairDoesNotExist(address token1, address token2);
    error TimeWindowIsZero();

    /**
     * @notice Constructor
     * @param uniswapV2Factory_ the Uniswap V2 factory
     * @param timeWindow_ the time between oracle observations
     */
    function __OracleV2_init(
        address uniswapV2Factory_,
        uint256 timeWindow_
    ) internal onlyInitializing {
        uniswapV2Factory = IUniswapV2Factory(uniswapV2Factory_);

        _setTimeWindow(timeWindow_);
    }

    /**
     * @notice Updates the price data for all the registered Uniswap V2 pairs
     *
     * May be called at any time. The time window automatically adjusts
     */
    function updatePrices() public virtual {
        uint256 pairsLength_ = _pairs.length();

        for (uint256 i = 0; i < pairsLength_; i++) {
            address pair_ = _pairs.at(i);

            PairInfo storage pairInfo = _pairInfos[pair_];
            uint256[] storage pairTimestamps = pairInfo.blockTimestamps;

            (
                uint256 price0Cumulative_,
                uint256 price1Cumulative_,
                uint256 blockTimestamp_
            ) = _currentCumulativePrices(pair_);

            if (
                pairTimestamps.length == 0 ||
                blockTimestamp_ > pairTimestamps[pairTimestamps.length - 1]
            ) {
                pairInfo.prices0Cumulative.push(price0Cumulative_);
                pairInfo.prices1Cumulative.push(price1Cumulative_);
                pairInfo.blockTimestamps.push(blockTimestamp_);
            }
        }
    }

    /**
     * @notice The function to retrieve the price of a token following the configured route
     * @param tokenIn_ The input token address
     * @param amount_ The amount of the input token
     * @return The price in the last token of the route
     * @return The output token address
     */
    function getPrice(address tokenIn_, uint256 amount_) public view returns (uint256, address) {
        address[] storage path = _paths[tokenIn_];
        uint256 pathLength_ = path.length;

        if (pathLength_ < 2) revert InvalidPath(tokenIn_, pathLength_);

        address tokenOut_ = path[pathLength_ - 1];

        for (uint256 i = 0; i < pathLength_ - 1; i++) {
            (address currentToken_, address nextToken_) = (path[i], path[i + 1]);
            address pair_ = uniswapV2Factory.getPair(currentToken_, nextToken_);
            uint256 price_ = _getPrice(pair_, currentToken_);

            amount_ = price_.mulDiv(amount_, 2 ** 112);
        }

        return (amount_, tokenOut_);
    }

    /**
     * @notice The function to get the route of the token
     * @param tokenIn_ the token to get the route of
     * @return the route of the provided token
     */
    function getPath(address tokenIn_) public view returns (address[] memory) {
        return _paths[tokenIn_];
    }

    /**
     * @notice The function to get all the pairs the oracle tracks
     * @return the array of pairs
     */
    function getPairs() public view returns (address[] memory) {
        return _pairs.values();
    }

    /**
     * @notice The function to get the number of observations of a pair
     * @param pair_ the pair address
     * @return the number of oracle observations
     */
    function getPairRounds(address pair_) public view returns (uint256) {
        return _pairInfos[pair_].blockTimestamps.length;
    }

    /**
     * @notice The function to get the exact observation of a pair
     * @param pair_ the pair address
     * @param round_ the observation index
     * @return the prices0Cumulative of the observation
     * @return the prices1Cumulative of the observation
     * @return the timestamp of the observation
     */
    function getPairInfo(
        address pair_,
        uint256 round_
    ) public view returns (uint256, uint256, uint256) {
        PairInfo storage _pairInfo = _pairInfos[pair_];

        return (
            _pairInfo.prices0Cumulative[round_],
            _pairInfo.prices1Cumulative[round_],
            _pairInfo.blockTimestamps[round_]
        );
    }

    /**
     * @notice The function to set the time window of TWAP
     * @param newTimeWindow_ the new time window value in seconds
     */
    function _setTimeWindow(uint256 newTimeWindow_) internal {
        if (newTimeWindow_ == 0) revert TimeWindowIsZero();

        timeWindow = newTimeWindow_;
    }

    /**
     * @notice The function to add multiple tokens paths for the oracle to observe. Every token may only have a single path
     * @param paths_ the array of token paths to add
     */
    function _addPaths(address[][] memory paths_) internal {
        uint256 numberOfPaths_ = paths_.length;

        for (uint256 i = 0; i < numberOfPaths_; i++) {
            uint256 pathLength_ = paths_[i].length;
            address tokenIn_ = paths_[i][0];

            if (pathLength_ < 2) revert InvalidPath(tokenIn_, pathLength_);
            if (_paths[tokenIn_].length != 0) revert PathAlreadyRegistered(tokenIn_);

            for (uint256 j = 0; j < pathLength_ - 1; j++) {
                (bool exists_, address pair_) = _pairExists(paths_[i][j], paths_[i][j + 1]);

                if (!exists_) revert PairDoesNotExist(paths_[i][j], paths_[i][j + 1]);

                _pairs.add(pair_);
                _pairInfos[pair_].refs++;
            }

            _paths[tokenIn_] = paths_[i];
        }

        updatePrices();
    }

    /**
     * @notice The function to remove multiple token paths from the oracle. Unregisters the pairs as well
     * @param tokenIns_ The array of token addresses to remove
     */
    function _removePaths(address[] memory tokenIns_) internal {
        uint256 numberOfPaths_ = tokenIns_.length;

        for (uint256 i = 0; i < numberOfPaths_; i++) {
            address tokenIn_ = tokenIns_[i];
            uint256 pathLength_ = _paths[tokenIn_].length;

            if (pathLength_ == 0) {
                continue;
            }

            for (uint256 j = 0; j < pathLength_ - 1; j++) {
                address pair_ = uniswapV2Factory.getPair(
                    _paths[tokenIn_][j],
                    _paths[tokenIn_][j + 1]
                );

                PairInfo storage _pairInfo = _pairInfos[pair_];

                /// @dev can't underflow
                _pairInfo.refs--;

                if (_pairInfo.refs == 0) {
                    _pairs.remove(pair_);
                }
            }

            delete _paths[tokenIn_];
        }
    }

    /**
     * @notice The private function to get the price of a token inside a pair
     */
    function _getPrice(address pair_, address expectedToken_) private view returns (uint256) {
        PairInfo storage pairInfo = _pairInfos[pair_];

        unchecked {
            /// @dev pairInfo.blockTimestamps can't be empty
            uint256 index_ = pairInfo.blockTimestamps.lowerBound(
                (uint32(block.timestamp) - timeWindow) % 2 ** 32
            );
            index_ = index_ == 0 ? index_ : index_ - 1;

            uint256 price0CumulativeOld_ = pairInfo.prices0Cumulative[index_];
            uint256 price1CumulativeOld_ = pairInfo.prices1Cumulative[index_];
            uint256 blockTimestampOld_ = pairInfo.blockTimestamps[index_];

            uint256 price0_;
            uint256 price1_;

            (
                uint256 price0Cumulative_,
                uint256 price1Cumulative_,
                uint256 blockTimestamp_
            ) = _currentCumulativePrices(pair_);

            price0_ =
                (price0Cumulative_ - price0CumulativeOld_) /
                (blockTimestamp_ - blockTimestampOld_);
            price1_ =
                (price1Cumulative_ - price1CumulativeOld_) /
                (blockTimestamp_ - blockTimestampOld_);

            return expectedToken_ == IUniswapV2Pair(pair_).token0() ? price0_ : price1_;
        }
    }

    /**
     * @notice The private function to check the existence of a pair
     */
    function _pairExists(address token1_, address token2_) private view returns (bool, address) {
        address pair_ = uniswapV2Factory.getPair(token1_, token2_);

        return (pair_ != address(0), pair_);
    }

    /**
     * @notice The private function to get the current cumulative prices of a pair. Adopted for Solidity 0.8.0
     */
    function _currentCumulativePrices(
        address pair_
    )
        private
        view
        returns (uint256 price0Cumulative_, uint256 price1Cumulative_, uint32 blockTimestamp_)
    {
        unchecked {
            blockTimestamp_ = uint32(block.timestamp);
            price0Cumulative_ = IUniswapV2Pair(pair_).price0CumulativeLast();
            price1Cumulative_ = IUniswapV2Pair(pair_).price1CumulativeLast();

            (uint112 reserve0_, uint112 reserve1_, uint32 timestampLast_) = IUniswapV2Pair(pair_)
                .getReserves();

            if (timestampLast_ != blockTimestamp_) {
                uint32 timeElapsed_ = blockTimestamp_ - timestampLast_;

                price0Cumulative_ +=
                    uint256((uint224(reserve1_) << 112) / reserve0_) *
                    timeElapsed_;
                price1Cumulative_ +=
                    uint256((uint224(reserve0_) << 112) / reserve1_) *
                    timeElapsed_;
            }
        }
    }
}
