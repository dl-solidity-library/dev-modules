// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @notice The Compound Rate Keeper module
 */
interface ICompoundRateKeeper {
    event CapitalizationPeriodChanged(uint256 newCapitalizationPeriod);
    event CapitalizationRateChanged(uint256 newCapitalizationRate);

    /**
     * @notice The function to force-update the compound rate if the getter reverts, sets isMaxRateReached to true
     */
    function emergencyUpdateCompoundRate() external;

    /**
     * @notice The function to get current compound rate
     * @return current compound rate
     */
    function getCompoundRate() external view returns (uint256);

    /**
     * @notice The function to get future compound rate (the timestamp_ may be equal to the lastUpdate)
     * @param timestamp_ the timestamp to calculate the rate for
     * @return the compound rate for the provided timestamp
     */
    function getFutureCompoundRate(uint64 timestamp_) external view returns (uint256);

    /**
     * @notice The function to get the current capitalization rate
     * @return capitalizationRate_ the current capitalization rate
     */
    function getCapitalizationRate() external view returns (uint256);

    /**
     * @notice The function to get the current capitalization period
     * @return capitalizationPeriod_ the current capitalization period
     */
    function getCapitalizationPeriod() external view returns (uint64);

    /**
     * @notice The function to get the timestamp of the last update
     * @return lastUpdate_ the timestamp of the last update
     */
    function getLastUpdate() external view returns (uint64);

    /**
     * @notice The function to get the status of whether the max rate is reached
     * @return isMaxRateReached_ the boolean indicating if the max rate is reached
     */
    function getIsMaxRateReached() external view returns (bool);

    /**
     * @notice The function to get the current rate
     * @return currentRate_ the current rate
     */
    function getCurrentRate() external view returns (uint256);
}
