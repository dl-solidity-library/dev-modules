// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {AValueDistributor} from "./AValueDistributor.sol";

/**
 * @notice The Abstarct Staking module
 *
 * Contract module for staking tokens and earning rewards based on shares.
 */
abstract contract AStaking is AValueDistributor, Initializable {
    using SafeERC20 for IERC20;

    address private _sharesToken;
    address private _rewardsToken;

    /**
     * @dev The rate of rewards distribution per second.
     *
     * It determines the rate at which rewards are earned and distributed
     * to stakers based on their shares.
     *
     * Note: Ensure that the `_rate` value is set correctly to match
     * the decimal precision of the `_rewardsToken` to ensure accurate rewards distribution.
     */
    uint256 private _rate;

    uint256 private _stakingStartTime;

    error RewardsTokenIsZeroAddress();
    error SharesTokenIsZeroAddress();
    error StakingHasNotStarted(uint256 currentTimestamp, uint256 stakingStartTime);

    /**
     * @dev Throws if the staking has not started yet.
     */
    modifier stakingStarted() {
        _checkStakingStarted();
        _;
    }

    /**
     * @notice Initializes the contract setting the values provided as shares token, rewards token, reward rate and staking start time.
     *
     * Warning: when shares and rewards tokens are the same, users may accidentally withdraw
     * other users' shares as a reward if the rewards token balance is improperly handled.
     *
     * @param sharesToken_ The address of the shares token.
     * @param rewardsToken_ The address of the rewards token.
     * @param rate_ The reward rate.
     * @param stakingStartTime_ The staking start time
     */
    function __AStaking_init(
        address sharesToken_,
        address rewardsToken_,
        uint256 rate_,
        uint256 stakingStartTime_
    ) internal onlyInitializing {
        if (sharesToken_ == address(0)) revert SharesTokenIsZeroAddress();
        if (rewardsToken_ == address(0)) revert RewardsTokenIsZeroAddress();

        _sharesToken = sharesToken_;
        _rewardsToken = rewardsToken_;
        _setRate(rate_);
        _setStakingStartTime(stakingStartTime_);
    }

    /**
     * @notice Stakes the specified amount of tokens.
     * @param amount_ The amount of tokens to stake.
     */
    function stake(uint256 amount_) public stakingStarted {
        _addShares(msg.sender, amount_);
    }

    /**
     * @notice Unstakes the specified amount of tokens.
     * @param amount_ The amount of tokens to unstake.
     */
    function unstake(uint256 amount_) public stakingStarted {
        _removeShares(msg.sender, amount_);
    }

    /**
     * @notice Claims the specified amount of rewards.
     * @param amount_ The amount of rewards to claim.
     */
    function claim(uint256 amount_) public stakingStarted {
        _distributeValue(msg.sender, amount_);
    }

    /**
     * @notice Claims all the available rewards.
     * @return The total value of the rewards claimed.
     */
    function claimAll() public stakingStarted returns (uint256) {
        return _distributeAllValue(msg.sender);
    }

    /**
     * @notice Withdraws all the staked tokens together with rewards.
     *
     * Note: All the rewards are claimed after the shares are removed.
     *
     * @return shares_ The amount of shares being withdrawn.
     * @return owedValue_ The total value of the rewards owed to the user.
     */
    function withdraw() public stakingStarted returns (uint256 shares_, uint256 owedValue_) {
        shares_ = userDistribution(msg.sender).shares;
        owedValue_ = getOwedValue(msg.sender);

        unstake(shares_);

        if (owedValue_ > 0) {
            claim(owedValue_);
        }
    }

    /**
     * @notice Returns the shares token.
     * @return The address of the shares token contract.
     */
    function sharesToken() public view returns (address) {
        return _sharesToken;
    }

    /**
     * @notice Returns the rewards token.
     * @return The address of the rewards token contract.
     */
    function rewardsToken() public view returns (address) {
        return _rewardsToken;
    }

    /**
     * @notice Returns the staking start time.
     * @return The timestamp when staking starts.
     */
    function stakingStartTime() public view returns (uint256) {
        return _stakingStartTime;
    }

    /**
     * @notice Returns the rate of rewards distribution.
     * @return The rate of rewards distribution per second.
     */
    function rate() public view returns (uint256) {
        return _rate;
    }

    /**
     * @notice Sets the staking start time.
     * @param stakingStartTime_ The timestamp when staking will start.
     */
    function _setStakingStartTime(uint256 stakingStartTime_) internal {
        _stakingStartTime = stakingStartTime_;
    }

    /**
     * @notice Sets the rate of rewards distribution per second.
     * @param newRate_ The new rate of rewards distribution.
     */
    function _setRate(uint256 newRate_) internal {
        _update(address(0));

        _rate = newRate_;
    }

    /**
     * @notice Hook function that is called after shares have been added to a user's distribution.
     * @param user_ The address of the user.
     * @param amount_ The amount of shares added.
     */
    function _afterAddShares(address user_, uint256 amount_) internal virtual override {
        IERC20(_sharesToken).safeTransferFrom(user_, address(this), amount_);
    }

    /**
     * @notice Hook function that is called after shares have been removed from a user's distribution.
     * @param user_ The address of the user.
     * @param amount_ The amount of shares removed.
     */
    function _afterRemoveShares(address user_, uint256 amount_) internal virtual override {
        IERC20(_sharesToken).safeTransfer(user_, amount_);
    }

    /**
     * @notice Hook function that is called after value has been distributed to a user.
     * @param user_ The address of the user.
     * @param amount_ The amount of value distributed.
     */
    function _afterDistributeValue(address user_, uint256 amount_) internal virtual override {
        IERC20(_rewardsToken).safeTransfer(user_, amount_);
    }

    /**
     * @dev Throws if the staking has not started yet.
     */
    function _checkStakingStarted() internal view {
        if (block.timestamp < _stakingStartTime)
            revert StakingHasNotStarted(block.timestamp, _stakingStartTime);
    }

    /**
     * @notice Gets the value to be distributed for a given time period.
     * @param timeUpTo_ The end timestamp of the period.
     * @param timeLastUpdate_ The start timestamp of the period.
     * @return The value to be distributed for the period.
     */
    function _getValueToDistribute(
        uint256 timeUpTo_,
        uint256 timeLastUpdate_
    ) internal view virtual override returns (uint256) {
        return _rate * (timeUpTo_ - timeLastUpdate_);
    }
}
