// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {OwnableCompoundRateKeeper} from "../../../finance/compound-rate-keeper/presets/OwnableCompoundRateKeeper.sol";

contract CompoundRateKeeperMock is OwnableCompoundRateKeeper {
    function mockInit(uint256 capitalizationRate_, uint64 capitalizationPeriod_) external {
        __ACompoundRateKeeper_init(capitalizationRate_, capitalizationPeriod_);
    }

    function setCapitalizationRateAndPeriod(
        uint256 capitalizationRate_,
        uint64 capitalizationPeriod_
    ) external onlyOwner {
        _setCapitalizationRate(capitalizationRate_);
        _setCapitalizationPeriod(capitalizationPeriod_);
    }
}
