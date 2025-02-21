// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {PRECISION} from "../../utils/Globals.sol";

/**
 * @title Vesting
 * @notice The Abstract Vesting Contract serves as a robust module
 * designed to seamlessly manage vestings and associated schedules for
 * multiple beneficiaries and ERC20 tokens. This module stands out for its
 * flexibility, offering support for both linear and exponential vesting calculations out of the box.
 *
 * Linear and Exponential Vesting:
 *
 * Linear vesting has a constant release rate over time (exponent = 1), resulting in a linear graph.
 * Exponential vesting allows for a more flexible release rate, defined by the exponent.
 * Higher exponents result in a steeper release curve.
 *
 * Vesting formula:
 *
 * vestedAmount = elapsedPeriodsPercentage ** exponent * (totalVestingAmount_)).
 *
 * Key concepts:
 *
 * Vesting contract contains two main components: Schedule struct and Vesting struct.
 * Each vesting contains scheduleId, which is associated with a schedule struct.
 *
 * You can create as much Schedules as needed with different parameters with an associated scheduleId.
 * Then a schedule can be assigned to vestings. So it's possible to create multiple vestings with the same schedule.
 *
 * Schedule defines the base structure for the vesting and how the vested amount will be calculated,
 * with the following parameters such as the duration, cliff, period, and exponent.
 *
 * Schedule parameters description:
 *  - secondsInPeriod: The duration of each vesting period in seconds. (i.e. 86,400 sec for 1 day)
 *  - durationInPeriods: The total number of periods for the vesting. (i.e. 20 for 20 days)
 *  - cliffInPeriods: The number of periods before the vesting starts. (i.e. 3 for 3 days).
 *  - exponent: The exponent for the vesting calculation. (i.e. 1 for linear vesting, 5 for exponential)
 *
 * Example of schedule:
 * Let's define a schedule with the following parameters:
 * - secondsInPeriod = 86,400 (1 day)
 * - durationInPeriods = 20 (20 days)
 * - cliffInPeriods = 3 (3 days)
 * - exponent = 1 (linear vesting)
 *
 * Using the provided schedule, you can create a vesting that will release vested amount linearly over 20 days with a 3-day cliff.
 * Let's say you have 1000 tokens to vest; then the vested amount will be released as follows:
 * - 1 day: 0 tokens
 * - 2 days: 0 tokens
 * - 3 days: 0 tokens
 * - 4 days: 200 tokens
 * - 5 days: 250 tokens
 * ...
 * - 20 days: 1000 tokens
 *
 * For defining linear vesting, the exponent should be set to 1,
 * or there is an option to create a linear schedule just by defining the baseSchedule struct
 * and the exponent will be automatically set to 1.
 *
 * For the creation of exponential vesting, the exponent should be set to a value greater than 1.
 *
 * It's not possible to create a schedule with an exponent equal to 0.
 */
abstract contract AVesting is Initializable {
    using Math for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @notice Struct defining the base schedule parameters.
     */
    struct BaseSchedule {
        uint256 secondsInPeriod;
        uint256 durationInPeriods;
        uint256 cliffInPeriods;
    }

    /**
     * @notice Struct defining a vesting schedule, extending BaseSchedule.
     */
    struct Schedule {
        BaseSchedule scheduleData;
        uint256 exponent;
    }

    /**
     * @notice Struct defining vesting data for an individual beneficiary.
     */
    struct VestingData {
        uint256 vestingStartTime;
        address beneficiary;
        address vestingToken;
        uint256 vestingAmount;
        uint256 paidAmount;
        uint256 scheduleId;
    }

    uint256 public constant LINEAR_EXPONENT = 1;

    uint256 public scheduleId;
    uint256 public vestingId;

    // id => schedule
    mapping(uint256 => Schedule) private _schedules;
    // id => vesting
    mapping(uint256 => VestingData) private _vestings;
    // beneficiary => vesting ids
    mapping(address => EnumerableSet.UintSet) private _beneficiaryIds;

    /**
     * @notice Emitted when a new schedule is created.
     * @param scheduleId The ID of the created schedule.
     */
    event ScheduleCreated(uint256 indexed scheduleId);

    /**
     * @notice Emitted when a new vesting contract is created.
     * @param vestingId The ID of the created vesting contract.
     * @param beneficiary The beneficiary of the vesting contract.
     * @param token The ERC20 token address used for the vesting.
     */
    event VestingCreated(uint256 indexed vestingId, address beneficiary, address token);

    /**
     * @notice Emitted when funds are withdrawn from a vesting contract.
     * @param vestingId The ID of the vesting contract from which funds are withdrawn.
     * @param amount The amount of funds withdrawn.
     */
    event WithdrawnFromVesting(uint256 indexed vestingId, uint256 amount);

    error BeneficiaryIsZeroAddress();
    error ExponentIsZero();
    error NothingToWithdraw();
    error StartTimeIsZero();
    error ScheduleInvalidPeriodParameter(uint256 durationInPeriods, uint256 secondsInPeriod);
    error ScheduleCliffGreaterThanDuration(uint256 cliffInPeriods, uint256 durationInPeriods);
    error UnauthorizedAccount(address account);
    error VestingAmountIsZero();
    error VestingTokenIsZeroAddress();
    error VestingPastDate();

    /**
     * @notice Constructor.
     */
    function __AVesting_init() internal onlyInitializing {}

    /**
     * @notice Withdraws funds from a vesting contract.
     * @param vestingId_ The ID of the vesting contract.
     */
    function withdrawFromVesting(uint256 vestingId_) public virtual {
        VestingData storage _vesting = _vestings[vestingId_];

        if (msg.sender != _vesting.beneficiary) revert UnauthorizedAccount(msg.sender);
        if (_vesting.paidAmount >= _vesting.vestingAmount) revert NothingToWithdraw();

        uint256 amountToPay_ = getWithdrawableAmount(vestingId_);
        address token_ = _vesting.vestingToken;

        _vesting.paidAmount += amountToPay_;

        _releaseTokens(token_, msg.sender, amountToPay_);

        emit WithdrawnFromVesting(vestingId_, amountToPay_);
    }

    /**
     * @notice Retrieves a schedule by ID.
     * @param scheduleId_ The ID of the schedule to retrieve.
     * @return Schedule struct.
     */
    function getSchedule(uint256 scheduleId_) public view virtual returns (Schedule memory) {
        return _schedules[scheduleId_];
    }

    /**
     * @notice Retrieves vesting data by ID.
     * @param vestingId_ The ID of the vesting contract to retrieve.
     * @return VestingData struct.
     */
    function getVesting(uint256 vestingId_) public view virtual returns (VestingData memory) {
        return _vestings[vestingId_];
    }

    /**
     * @notice Retrieves all vesting data for a beneficiary.
     * @param beneficiary_ The address of the beneficiary.
     * @return An array of VestingData struct.
     */
    function getVestings(address beneficiary_) public view virtual returns (VestingData[] memory) {
        uint256[] memory ids_ = _beneficiaryIds[beneficiary_].values();
        VestingData[] memory beneficiaryVestings_ = new VestingData[](ids_.length);

        for (uint256 i = 0; i < ids_.length; i++) {
            beneficiaryVestings_[i] = _vestings[ids_[i]];
        }

        return beneficiaryVestings_;
    }

    /**
     * @notice Retrieves all vesting IDs for a beneficiary.
     * @param beneficiary_ The address of the beneficiary.
     * @return An array of uint256 representing all vesting IDs for the beneficiary.
     */
    function getVestingIds(address beneficiary_) public view virtual returns (uint256[] memory) {
        return _beneficiaryIds[beneficiary_].values();
    }

    /**
     * @notice Retrieves the vested amount for a vesting ID.
     * @param vestingId_ The ID of the vesting contract.
     * @return The amount of tokens vested.
     */
    function getVestedAmount(uint256 vestingId_) public view virtual returns (uint256) {
        VestingData storage _vesting = _vestings[vestingId_];

        return _getVestedAmount(_vesting, _vesting.scheduleId, block.timestamp);
    }

    /**
     * @notice Retrieves the withdrawable amount for a vesting ID.
     * @param vestingId_ The ID of the vesting contract.
     * @return The amount of tokens available to withdraw.
     */
    function getWithdrawableAmount(uint256 vestingId_) public view virtual returns (uint256) {
        VestingData storage _vesting = _vestings[vestingId_];

        return _getWithdrawableAmount(_vesting, _vesting.scheduleId, block.timestamp);
    }

    /**
     * @notice Creates a new vesting schedule.
     * @dev The exponent is set to 1, making the vesting linear.
     * @param baseSchedule_ Base schedule data for the new schedule.
     * @return The ID of the created schedule.
     */
    function _createSchedule(
        BaseSchedule memory baseSchedule_
    ) internal virtual returns (uint256) {
        _validateSchedule(baseSchedule_);

        _schedules[++scheduleId] = Schedule({
            scheduleData: baseSchedule_,
            exponent: LINEAR_EXPONENT
        });

        emit ScheduleCreated(scheduleId);

        return scheduleId;
    }

    /**
     * @notice Creates a new vesting schedule with a custom exponent.
     * @param schedule_ Schedule data for the new schedule.
     * @return The ID of the created schedule.
     */
    function _createSchedule(Schedule memory schedule_) internal virtual returns (uint256) {
        if (schedule_.exponent == 0) revert ExponentIsZero();

        _validateSchedule(schedule_.scheduleData);

        _schedules[++scheduleId] = schedule_;

        emit ScheduleCreated(scheduleId);

        return scheduleId;
    }

    /**
     * @notice Creates a new vesting contract.
     * @param vesting_ Vesting data for the new contract.
     * @return The ID of the created vesting contract.
     */
    function _createVesting(VestingData memory vesting_) internal virtual returns (uint256) {
        _validateVesting(vesting_);

        Schedule storage _schedule = _schedules[vesting_.scheduleId];

        if (
            vesting_.vestingStartTime +
                _schedule.scheduleData.durationInPeriods *
                _schedule.scheduleData.secondsInPeriod <=
            block.timestamp
        ) revert VestingPastDate();

        uint256 _currentVestingId = ++vestingId;

        _beneficiaryIds[vesting_.beneficiary].add(_currentVestingId);

        _vestings[_currentVestingId] = vesting_;

        emit VestingCreated(_currentVestingId, vesting_.beneficiary, vesting_.vestingToken);

        return _currentVestingId;
    }

    /**
     * @notice Releases tokens from vesting.
     * @dev By default, tokens are transferred to the beneficiary. Override this function if custom logic is required.
     * @param token_ The ERC20 token address used for the vesting.
     * @param beneficiary_ The address of the beneficiary.
     * @param amountToPay_ The amount of tokens to be released.
     */
    function _releaseTokens(
        address token_,
        address beneficiary_,
        uint256 amountToPay_
    ) internal virtual {
        IERC20(token_).safeTransfer(beneficiary_, amountToPay_);
    }

    /**
     * @notice Retrieves the vested amount for a vesting ID.
     * @param vesting Vesting data for the vesting contract.
     * @param scheduleId_ Id for the associated schedule.
     * @param timestampUpTo_ The timestamp up to which the calculation is performed.
     * @return The amount of tokens vested.
     */
    function _getVestedAmount(
        VestingData storage vesting,
        uint256 scheduleId_,
        uint256 timestampUpTo_
    ) internal view virtual returns (uint256) {
        return
            _vestingCalculation(
                scheduleId_,
                vesting.vestingAmount,
                vesting.vestingStartTime,
                timestampUpTo_
            );
    }

    /**
     * @notice Retrieves the withdrawable amount for a vesting ID.
     * @param vesting Vesting data for the vesting contract.
     * @param scheduleId_ Id for the associated schedule.
     * @param timestampUpTo_ The timestamp up to which the calculation is performed.
     * @return The amount of tokens withdrawable.
     */
    function _getWithdrawableAmount(
        VestingData storage vesting,
        uint256 scheduleId_,
        uint256 timestampUpTo_
    ) internal view virtual returns (uint256) {
        return
            _vestingCalculation(
                scheduleId_,
                vesting.vestingAmount,
                vesting.vestingStartTime,
                timestampUpTo_
            ) - vesting.paidAmount;
    }

    /**
     * @notice Performs the vesting calculation.
     * @param scheduleId_ Id for the associated schedule.
     * @param totalVestingAmount_ The total amount of tokens to be vested.
     * @param vestingStartTime_ The starting time of the vesting.
     * @param timestampUpTo_ The timestamp up to which the calculation is performed.
     * @return vestedAmount_ The amount of tokens vested.
     */
    function _vestingCalculation(
        uint256 scheduleId_,
        uint256 totalVestingAmount_,
        uint256 vestingStartTime_,
        uint256 timestampUpTo_
    ) internal view virtual returns (uint256 vestedAmount_) {
        Schedule storage _schedule = _schedules[scheduleId_];
        BaseSchedule storage _baseData = _schedule.scheduleData;

        if (vestingStartTime_ > timestampUpTo_) {
            return vestedAmount_;
        }

        uint256 elapsedPeriods_ = _calculateElapsedPeriods(
            vestingStartTime_,
            timestampUpTo_,
            _baseData.secondsInPeriod
        );

        if (elapsedPeriods_ < _baseData.cliffInPeriods) {
            return 0;
        }

        if (elapsedPeriods_ >= _baseData.durationInPeriods) {
            return totalVestingAmount_;
        }

        uint256 elapsedPeriodsPercentage_ = (elapsedPeriods_ * PRECISION) /
            _baseData.durationInPeriods;

        vestedAmount_ =
            (_raiseToPower(elapsedPeriodsPercentage_, _schedule.exponent) *
                (totalVestingAmount_)) /
            _raiseToPower(PRECISION, _schedule.exponent);

        return vestedAmount_.min(totalVestingAmount_);
    }

    /**
     * @notice Validates the base schedule parameters.
     * @param schedule_ Base schedule data to be validated.
     */
    function _validateSchedule(BaseSchedule memory schedule_) internal pure {
        if (schedule_.durationInPeriods == 0 || schedule_.secondsInPeriod == 0)
            revert ScheduleInvalidPeriodParameter(
                schedule_.durationInPeriods,
                schedule_.secondsInPeriod
            );
        if (schedule_.cliffInPeriods >= schedule_.durationInPeriods)
            revert ScheduleCliffGreaterThanDuration(
                schedule_.cliffInPeriods,
                schedule_.durationInPeriods
            );
    }

    /**
     * @notice Validates the vesting parameters.
     * @param vesting_ Vesting data to be validated.
     */
    function _validateVesting(VestingData memory vesting_) internal pure {
        if (vesting_.vestingStartTime == 0) revert StartTimeIsZero();
        if (vesting_.vestingAmount == 0) revert VestingAmountIsZero();
        if (vesting_.beneficiary == address(0)) revert BeneficiaryIsZeroAddress();
        if (vesting_.vestingToken == address(0)) revert VestingTokenIsZeroAddress();
    }

    /**
     * @notice Calculates the elapsed periods.
     * @param startTime_ The starting time of the vesting.
     * @param timestampUpTo_ The timestamp up to which the calculation is performed.
     * @param secondsInPeriod_ The duration of each vesting period in seconds.
     * @return The number of elapsed periods.
     */
    function _calculateElapsedPeriods(
        uint256 startTime_,
        uint256 timestampUpTo_,
        uint256 secondsInPeriod_
    ) internal pure returns (uint256) {
        return
            timestampUpTo_ > startTime_ ? (timestampUpTo_ - startTime_) / (secondsInPeriod_) : 0;
    }

    /**
     * @notice Implementation of exponentiation by squaring with fixed precision.
     * @param base_ The base value.
     * @param exponent_ The exponent value.
     * @return result_ The result of the base raised to the exponent.
     */
    function _raiseToPower(
        uint256 base_,
        uint256 exponent_
    ) internal pure returns (uint256 result_) {
        result_ = exponent_ & 1 == 0 ? PRECISION : base_;

        while ((exponent_ >>= 1) > 0) {
            base_ = (base_ * base_) / PRECISION;

            if (exponent_ & 1 == 1) {
                result_ = (result_ * base_) / PRECISION;
            }
        }
    }
}
