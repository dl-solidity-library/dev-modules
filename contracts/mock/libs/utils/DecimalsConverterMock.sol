// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity ^0.8.21;

import {DecimalsConverter} from "../../../libs/utils/DecimalsConverter.sol";

contract DecimalsConverterMock {
    using DecimalsConverter for *;

    function decimals(address token_) external view returns (uint8) {
        return token_.decimals();
    }

    function to18(uint256 amount_, uint256 baseDecimals_) external pure returns (uint256) {
        return amount_.to18(baseDecimals_);
    }

    function tokenTo18(uint256 amount_, address token_) external view returns (uint256) {
        return amount_.to18(token_);
    }

    function to18Safe(uint256 amount_, uint256 baseDecimals_) external pure returns (uint256) {
        return amount_.to18Safe(baseDecimals_);
    }

    function tokenTo18Safe(uint256 amount_, address token_) external view returns (uint256) {
        return amount_.to18Safe(token_);
    }

    function from18(uint256 amount_, uint256 destDecimals_) external pure returns (uint256) {
        return amount_.from18(destDecimals_);
    }

    function tokenFrom18(uint256 amount_, address token_) external view returns (uint256) {
        return amount_.from18(token_);
    }

    function from18Safe(uint256 amount_, uint256 destDecimals_) external pure returns (uint256) {
        return amount_.from18Safe(destDecimals_);
    }

    function tokenFrom18Safe(uint256 amount_, address token_) external view returns (uint256) {
        return amount_.from18Safe(token_);
    }

    function round18(uint256 amount_, uint256 decimals_) external pure returns (uint256) {
        return amount_.round18(decimals_);
    }

    function tokenRound18(uint256 amount_, address token_) external view returns (uint256) {
        return amount_.round18(token_);
    }

    function round18Safe(uint256 amount_, uint256 decimals_) external pure returns (uint256) {
        return amount_.round18Safe(decimals_);
    }

    function tokenRound18Safe(uint256 amount_, address token_) external view returns (uint256) {
        return amount_.round18Safe(token_);
    }

    function convert(
        uint256 amount_,
        uint256 baseDecimals_,
        uint256 destDecimals_
    ) external pure returns (uint256) {
        return amount_.convert(baseDecimals_, destDecimals_);
    }

    function convertTokens(
        uint256 amount_,
        address baseToken_,
        address destToken_
    ) external view returns (uint256) {
        return amount_.convert(baseToken_, destToken_);
    }
}
