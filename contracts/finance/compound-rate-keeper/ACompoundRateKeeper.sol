// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {ICompoundRateKeeper} from "../../interfaces/compound-rate-keeper/ICompoundRateKeeper.sol";

import {PRECISION} from "../../utils/Globals.sol";

/**
 * @notice The Compound Rate Keeper module
 *
 * The purpose of this module is to calculate the compound interest rate via 2 parameters:
 * `capitalizationRate` and `capitalizationPeriod`. Where `capitalizationRate` is the compound percentage
 * and `capitalizationPeriod` is the number of elapsed seconds the `capitalizationRate` has to be applied to get the interest.
 *
 * The CompoundRateKeeper can be used in lending protocols to calculate the interest and borrow rates. It can
 * also be used in regular staking contracts to get users' rewards accrual, where the APY is fixed.
 *
 * The compound interest formula is the following:
 *
 * newRate = curRate * (capitalizationRate\**(secondsPassed / capitalizationPeriod)), where curRate is initially 1
 *
 * The compound rate is calculated with 10\**25 precision.
 * The maximal possible compound rate is (type(uint128).max * 10\**25)
 */
abstract contract ACompoundRateKeeper is ICompoundRateKeeper, Initializable {
    using Math for uint256;

    uint256 private _capitalizationRate;
    uint64 private _capitalizationPeriod;

    uint64 private _lastUpdate;

    bool private _isMaxRateReached;

    uint256 private _currentRate;

    error CapitalizationPeriodIsZero();
    error MaxRateIsReached();
    error RateIsLessThanOne(uint256 rate);

    /**
     * @notice The initialization function
     */
    function __ACompoundRateKeeper_init(
        uint256 capitalizationRate_,
        uint64 capitalizationPeriod_
    ) internal onlyInitializing {
        _currentRate = PRECISION;
        _lastUpdate = uint64(block.timestamp);

        _changeCapitalizationRate(capitalizationRate_);
        _changeCapitalizationPeriod(capitalizationPeriod_);
    }

    /**
     * @notice The function to force-update the compound rate if the getter reverts, sets isMaxRateReached to true
     */
    function emergencyUpdateCompoundRate() public override {
        try this.getCompoundRate() returns (uint256 rate_) {
            if (rate_ == _getMaxRate()) {
                _isMaxRateReached = true;
            }
        } catch {
            _isMaxRateReached = true;
        }
    }

    /**
     * @notice The function to get current compound rate
     * @return current compound rate
     */
    function getCompoundRate() public view override returns (uint256) {
        return getFutureCompoundRate(uint64(block.timestamp));
    }

    /**
     * @notice The function to get future compound rate (the timestamp_ may be equal to the lastUpdate)
     * @param timestamp_ the timestamp to calculate the rate for
     * @return the compound rate for the provided timestamp
     */
    function getFutureCompoundRate(uint64 timestamp_) public view override returns (uint256) {
        if (_isMaxRateReached) {
            return _getMaxRate();
        }

        uint64 lastUpdate_ = _lastUpdate;

        if (lastUpdate_ >= timestamp_) {
            return _currentRate;
        }

        uint64 secondsPassed_ = timestamp_ - lastUpdate_;

        uint64 capitalizationPeriod_ = _capitalizationPeriod;
        uint64 capitalizationPeriodsNum_ = secondsPassed_ / capitalizationPeriod_;
        uint64 secondsLeft_ = secondsPassed_ % capitalizationPeriod_;

        uint256 capitalizationRate_ = _capitalizationRate;
        uint256 rate_ = _currentRate;

        if (capitalizationPeriodsNum_ != 0) {
            uint256 capitalizationPeriodRate_ = _raiseToPower(
                capitalizationRate_,
                capitalizationPeriodsNum_
            );
            rate_ = (rate_ * capitalizationPeriodRate_) / PRECISION;
        }

        if (secondsLeft_ > 0) {
            uint256 rateLeft_ = PRECISION +
                ((capitalizationRate_ - PRECISION) * secondsLeft_) /
                capitalizationPeriod_;
            rate_ = (rate_ * rateLeft_) / PRECISION;
        }

        return rate_.min(_getMaxRate());
    }

    /**
     * @notice The function to get the current capitalization rate
     * @return capitalizationRate_ the current capitalization rate
     */
    function getCapitalizationRate() public view returns (uint256 capitalizationRate_) {
        return _capitalizationRate;
    }

    /**
     * @notice The function to get the current capitalization period
     * @return capitalizationPeriod_ the current capitalization period
     */
    function getCapitalizationPeriod() public view returns (uint64 capitalizationPeriod_) {
        return _capitalizationPeriod;
    }

    /**
     * @notice The function to get the timestamp of the last update
     * @return lastUpdate_ the timestamp of the last update
     */
    function getLastUpdate() public view returns (uint64 lastUpdate_) {
        return _lastUpdate;
    }

    /**
     * @notice The function to get the status of whether the max rate is reached
     * @return isMaxRateReached_ the boolean indicating if the max rate is reached
     */
    function getIsMaxRateReached() public view returns (bool isMaxRateReached_) {
        return _isMaxRateReached;
    }

    /**
     * @notice The function to get the current rate
     * @return currentRate_ the current rate
     */
    function getCurrentRate() public view returns (uint256 currentRate_) {
        return _currentRate;
    }

    /**
     * @notice The internal function to set the capitalization rate
     * @param capitalizationRate_ new capitalization rate
     */
    function _setCapitalizationRate(uint256 capitalizationRate_) internal virtual {
        _update();
        _changeCapitalizationRate(capitalizationRate_);
    }

    /**
     * @notice The internal function to set the capitalization period
     * @param capitalizationPeriod_ new capitalization period
     */
    function _setCapitalizationPeriod(uint64 capitalizationPeriod_) internal virtual {
        _update();
        _changeCapitalizationPeriod(capitalizationPeriod_);
    }

    /**
     * @notice The private function to update the compound rate
     */
    function _update() private {
        if (_isMaxRateReached) revert MaxRateIsReached();

        _currentRate = getCompoundRate();
        _lastUpdate = uint64(block.timestamp);
    }

    /**
     * @notice The private function that changes to capitalization rate
     */
    function _changeCapitalizationRate(uint256 capitalizationRate_) private {
        if (capitalizationRate_ < PRECISION) revert RateIsLessThanOne(capitalizationRate_);

        _capitalizationRate = capitalizationRate_;

        emit CapitalizationRateChanged(capitalizationRate_);
    }

    /**
     * @notice The private function that changes to capitalization period
     */
    function _changeCapitalizationPeriod(uint64 capitalizationPeriod_) private {
        if (capitalizationPeriod_ == 0) revert CapitalizationPeriodIsZero();

        _capitalizationPeriod = capitalizationPeriod_;

        emit CapitalizationPeriodChanged(capitalizationPeriod_);
    }

    /**
     * @notice Implementation of exponentiation by squaring with fixed precision
     * @dev Checks if base or exponent equal to 0 done before
     */
    function _raiseToPower(
        uint256 base_,
        uint256 exponent_
    ) private pure returns (uint256 result_) {
        result_ = exponent_ & 1 == 0 ? PRECISION : base_;

        while ((exponent_ >>= 1) > 0) {
            base_ = (base_ * base_) / PRECISION;

            if (exponent_ & 1 == 1) {
                result_ = (result_ * base_) / PRECISION;
            }
        }
    }

    /**
     * @notice The private function to get the maximal possible compound rate
     */
    function _getMaxRate() private pure returns (uint256) {
        return type(uint128).max * PRECISION;
    }
}
