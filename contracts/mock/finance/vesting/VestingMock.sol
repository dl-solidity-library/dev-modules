// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {AVesting} from "../../../finance/vesting/AVesting.sol";
import {ERC20Mock} from "../../tokens/ERC20Mock.sol";

contract VestingMock is AVesting {
    function __VestingMock_init() public initializer {
        __AVesting_init();
    }

    function vestingInit() public {
        __AVesting_init();
    }

    function createSchedule(Schedule memory _schedule) public {
        _createSchedule(_schedule);
    }

    function createBaseSchedule(BaseSchedule memory _schedule) public {
        _createSchedule(_schedule);
    }

    function createVesting(VestingData memory vestingData_) public returns (uint256 vestingId_) {
        vestingId_ = _createVesting(vestingData_);

        ERC20Mock(vestingData_.vestingToken).transferFrom(
            msg.sender,
            address(this),
            vestingData_.vestingAmount
        );
    }

    function vestingCalculation(
        uint256 scheduleId_,
        uint256 totalVestingAmount_,
        uint256 vestingStartTime_,
        uint256 timestampUpTo_
    ) public view returns (uint256 vestedAmount_) {
        return
            _vestingCalculation(
                scheduleId_,
                totalVestingAmount_,
                vestingStartTime_,
                timestampUpTo_
            );
    }
}
