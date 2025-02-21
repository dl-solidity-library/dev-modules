// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ECDSA384} from "../../../libs/crypto/ECDSA384.sol";
import {uint512, U512} from "../../../libs/bn/U512.sol";

contract ECDSA384Mock {
    using ECDSA384 for *;

    ECDSA384.Parameters private _secp384r1CurveParams =
        ECDSA384.Parameters({
            a: hex"fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeffffffff0000000000000000fffffffc",
            b: hex"b3312fa7e23ee7e4988e056be3f82d19181d9c6efe8141120314088f5013875ac656398d8a2ed19d2a85c8edd3ec2aef",
            gx: hex"aa87ca22be8b05378eb1c71ef320ad746e1d3b628ba79b9859f741e082542a385502f25dbf55296c3a545e3872760ab7",
            gy: hex"3617de4a96262c6f5d9e98bf9292dc29f8f41dbd289a147ce9da3113b5f0b8c00a60b1ce1d7e819d7a431d7c90ea0e5f",
            p: hex"fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeffffffff0000000000000000ffffffff",
            n: hex"ffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf581a0db248b0a77aecec196accc52973",
            lowSmax: hex"7fffffffffffffffffffffffffffffffffffffffffffffffe3b1a6c0fa1b96efac0d06d9245853bd76760cb5666294b9"
        });

    ECDSA384.Parameters private _brainpoolP384r1CurveParams =
        ECDSA384.Parameters({
            a: hex"7bc382c63d8c150c3c72080ace05afa0c2bea28e4fb22787139165efba91f90f8aa5814a503ad4eb04a8c7dd22ce2826",
            b: hex"04a8c7dd22ce28268b39b55416f0447c2fb77de107dcd2a62e880ea53eeb62d57cb4390295dbc9943ab78696fa504c11",
            gx: hex"1d1c64f068cf45ffa2a63a81b7c13f6b8847a3e77ef14fe3db7fcafe0cbd10e8e826e03436d646aaef87b2e247d4af1e",
            gy: hex"8abe1d7520f9c2a45cb1eb8e95cfd55262b70b29feec5864e19c054ff99129280e4646217791811142820341263c5315",
            p: hex"8cb91e82a3386d280f5d6f7e50e641df152f7109ed5456b412b1da197fb71123acd3a729901d1a71874700133107ec53",
            n: hex"8cb91e82a3386d280f5d6f7e50e641df152f7109ed5456b31f166e6cac0425a7cf3ab6af6b7fc3103b883202e9046565",
            lowSmax: hex"465c8f41519c369407aeb7bf287320ef8a97b884f6aa2b598f8b3736560212d3e79d5b57b5bfe1881dc41901748232b2"
        });

    function verifySECP384r1(
        bytes calldata message_,
        bytes calldata signature_,
        bytes calldata pubKey_
    ) external view returns (bool) {
        return
            _secp384r1CurveParams.verify(abi.encodePacked(sha256(message_)), signature_, pubKey_);
    }

    function verifyBrainpoolP384r1(
        bytes calldata message_,
        bytes calldata signature_,
        bytes calldata pubKey_
    ) external view returns (bool) {
        return
            _brainpoolP384r1CurveParams.verify(
                abi.encodePacked(sha256(message_)),
                signature_,
                pubKey_
            );
    }

    function verifySECP384r1CustomCurveParameters(
        bytes calldata message_,
        bytes calldata signature_,
        bytes calldata pubKey_,
        bytes calldata customA_,
        bytes calldata customB_
    ) external view returns (bool) {
        ECDSA384.Parameters memory curveParams_ = _secp384r1CurveParams;
        curveParams_.a = customA_;
        curveParams_.b = customB_;

        return curveParams_.verify(abi.encodePacked(sha256(message_)), signature_, pubKey_);
    }

    function verifySECP384r1WithoutHashing(
        bytes calldata hashedMessage_,
        bytes calldata signature_,
        bytes calldata pubKey_
    ) external view returns (bool) {
        return _secp384r1CurveParams.verify(abi.encodePacked(hashedMessage_), signature_, pubKey_);
    }

    function cmpMock() external pure returns (int256 cmp_) {
        uint512 a_;
        uint512 b_;

        assembly {
            a_ := mload(0x40)
            b_ := add(a_, 0x40)

            mstore(add(a_, 0x20), 0x1234)
            mstore(add(b_, 0x20), 0x5678)

            mstore(0x40, add(b_, 0x40))
        }

        return U512.cmp(a_, b_);
    }
}
