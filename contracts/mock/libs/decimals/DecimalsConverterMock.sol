// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {DecimalsConverter} from "../../../libs/decimals/DecimalsConverter.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DecimalsConverterMock {
    using DecimalsConverter for *;

    function decimals(address token_) external view returns (uint8) {
        return token_.decimals();
    }

    function to18(uint256 amount_, uint256 baseDecimals_) external pure returns (uint256) {
        return amount_.to18(baseDecimals_);
    }

    function to18Safe(uint256 amount_, uint256 baseDecimals_) external pure returns (uint256) {
        return amount_.to18Safe(baseDecimals_);
    }

    function from18(uint256 amount_, uint256 destDecimals_) external pure returns (uint256) {
        return amount_.from18(destDecimals_);
    }

    function from18Safe(uint256 amount_, uint256 destDecimals_) external pure returns (uint256) {
        return amount_.from18Safe(destDecimals_);
    }

    function round18(uint256 amount_, uint256 decimals_) external pure returns (uint256) {
        return amount_.round18(decimals_);
    }

    function round18Safe(uint256 amount_, uint256 decimals_) external pure returns (uint256) {
        return amount_.round18Safe(decimals_);
    }

    function roundTokens(
        uint256 amount_,
        address baseToken_,
        address destToken_
    ) public view returns (uint256) {
        return amount_.roundTokens(baseToken_, destToken_);
    }

    function roundTokensSave(
        uint256 amount_,
        address baseToken_,
        address destToken_
    ) external view returns (uint256) {
        return amount_.roundTokensSave(baseToken_, destToken_);
    }

    function convert(
        uint256 amount_,
        uint256 baseDecimals_,
        uint256 destDecimals_
    ) external pure returns (uint256) {
        return amount_.convert(baseDecimals_, destDecimals_);
    }
}
