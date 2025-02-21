// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {RSASSAPSS} from "../../../libs/crypto/RSASSAPSS.sol";

contract RSASSAPSSMock {
    using RSASSAPSS for *;

    function verifySha256(
        bytes calldata message_,
        bytes calldata s_,
        bytes calldata e_,
        bytes calldata n_
    ) external view returns (bool) {
        return message_.verifySha256(s_, e_, n_);
    }
}
