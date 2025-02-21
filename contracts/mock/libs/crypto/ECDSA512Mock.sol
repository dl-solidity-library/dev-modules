// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ECDSA512} from "../../../libs/crypto/ECDSA512.sol";

contract ECDSA512Mock {
    using ECDSA512 for *;

    ECDSA512.Parameters private _brainpoolP512r1CurveParams =
        ECDSA512.Parameters({
            a: hex"7830a3318b603b89e2327145ac234cc594cbdd8d3df91610a83441caea9863bc2ded5d5aa8253aa10a2ef1c98b9ac8b57f1117a72bf2c7b9e7c1ac4d77fc94ca",
            b: hex"3df91610a83441caea9863bc2ded5d5aa8253aa10a2ef1c98b9ac8b57f1117a72bf2c7b9e7c1ac4d77fc94cadc083e67984050b75ebae5dd2809bd638016f723",
            gx: hex"81aee4bdd82ed9645a21322e9c4c6a9385ed9f70b5d916c1b43b62eef4d0098eff3b1f78e2d0d48d50d1687b93b97d5f7c6d5047406a5e688b352209bcb9f822",
            gy: hex"7dde385d566332ecc0eabfa9cf7822fdf209f70024a57b1aa000c55b881f8111b2dcde494a5f485e5bca4bd88a2763aed1ca2b2fa8f0540678cd1e0f3ad80892",
            p: hex"aadd9db8dbe9c48b3fd4e6ae33c9fc07cb308db3b3c9d20ed6639cca703308717d4d9b009bc66842aecda12ae6a380e62881ff2f2d82c68528aa6056583a48f3",
            n: hex"aadd9db8dbe9c48b3fd4e6ae33c9fc07cb308db3b3c9d20ed6639cca70330870553e5c414ca92619418661197fac10471db1d381085ddaddb58796829ca90069",
            lowSmax: hex"556ecedc6df4e2459fea735719e4fe03e59846d9d9e4e9076b31ce65381984382a9f2e20a654930ca0c3308cbfd608238ed8e9c0842eed6edac3cb414e548034"
        });

    function verifyBrainpoolP512r1WithoutHashing(
        bytes calldata message_,
        bytes calldata signature_,
        bytes calldata pubKey_
    ) external view returns (bool) {
        return _brainpoolP512r1CurveParams.verify(abi.encodePacked(message_), signature_, pubKey_);
    }
}
