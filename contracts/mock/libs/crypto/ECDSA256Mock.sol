// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ECDSA256} from "../../../libs/crypto/ECDSA256.sol";

contract ECDSA256Mock {
    using ECDSA256 for *;

    ECDSA256.Parameters private _secp256r1CurveParams =
        ECDSA256.Parameters({
            a: 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC,
            b: 0x5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B,
            gx: 0x6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296,
            gy: 0x4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5,
            p: 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF,
            n: 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551,
            lowSmax: 0x7fffffff800000007fffffffffffffffde737d56d38bcf4279dce5617e3192a8
        });

    ECDSA256.Parameters private _brainpoolP256r1CurveParams =
        ECDSA256.Parameters({
            a: 0x7D5A0975FC2C3057EEF67530417AFFE7FB8055C126DC5C6CE94A4B44F330B5D9,
            b: 0x26DC5C6CE94A4B44F330B5D9BBD77CBF958416295CF7E1CE6BCCDC18FF8C07B6,
            gx: 0x8BD2AEB9CB7E57CB2C4B482FFC81B7AFB9DE27E1E3BD23C23A4453BD9ACE3262,
            gy: 0x547EF835C3DAC4FD97F8461A14611DC9C27745132DED8E545C1D54C72F046997,
            p: 0xA9FB57DBA1EEA9BC3E660A909D838D726E3BF623D52620282013481D1F6E5377,
            n: 0xA9FB57DBA1EEA9BC3E660A909D838D718C397AA3B561A6F7901E0E82974856A7,
            lowSmax: 0x54fdabedd0f754de1f3305484ec1c6b9371dfb11ea9310141009a40e8fb729bb
        });

    function verifySECP256r1(
        bytes memory message_,
        bytes memory signature_,
        bytes memory pubKey_
    ) external view returns (bool) {
        return _secp256r1CurveParams.verify(sha256(message_), signature_, pubKey_);
    }

    function verifyBrainpoolP256r1(
        bytes calldata message_,
        bytes memory signature_,
        bytes memory pubKey_
    ) external view returns (bool) {
        return _brainpoolP256r1CurveParams.verify(sha256(message_), signature_, pubKey_);
    }
}
