// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {ACompoundRateKeeper} from "../ACompoundRateKeeper.sol";

/**
 * @notice The Ownable preset of CompoundRateKeeper
 */
contract OwnableCompoundRateKeeper is ACompoundRateKeeper, OwnableUpgradeable {
    /**
     * @notice The initialization function
     * @param capitalizationRate_ the compound interest rate with 10\**25 precision
     * @param capitalizationPeriod_ the compounding period in seconds
     */
    function __OwnableCompoundRateKeeper_init(
        uint256 capitalizationRate_,
        uint64 capitalizationPeriod_
    ) public initializer {
        __Ownable_init(msg.sender);
        __ACompoundRateKeeper_init(capitalizationRate_, capitalizationPeriod_);
    }

    /**
     * The function to set the compound interest rate
     * @param capitalizationRate_ new compound interest rate
     */
    function setCapitalizationRate(uint256 capitalizationRate_) external onlyOwner {
        _setCapitalizationRate(capitalizationRate_);
    }

    /**
     * @notice The function to set the compounding period
     * @param capitalizationPeriod_ new compounding period in seconds
     */
    function setCapitalizationPeriod(uint64 capitalizationPeriod_) external onlyOwner {
        _setCapitalizationPeriod(capitalizationPeriod_);
    }
}
