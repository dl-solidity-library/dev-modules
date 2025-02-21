// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {call512, uint512, U512} from "../bn/U512.sol";
import {MemoryUtils} from "../utils/MemoryUtils.sol";

/**
 * @notice Cryptography module
 *
 * This library provides functionality for ECDSA verification over any 512-bit curve. Currently,
 * this is the most efficient implementation out there, consuming ~13.6 million gas per call.
 *
 * The approach is Strauss-Shamir double scalar multiplication with 6 bits of precompute + affine coordinates.
 */
library ECDSA512 {
    using MemoryUtils for *;

    /**
     * @notice 512-bit curve parameters.
     */
    struct Parameters {
        bytes a;
        bytes b;
        bytes gx;
        bytes gy;
        bytes p;
        bytes n;
        bytes lowSmax;
    }

    // solhint-disable-next-line contract-name-capwords
    struct _Parameters {
        uint512 a;
        uint512 b;
        uint512 gx;
        uint512 gy;
        uint512 p;
        uint512 n;
        uint512 lowSmax;
    }

    // solhint-disable-next-line contract-name-capwords
    struct _Inputs {
        uint512 r;
        uint512 s;
        uint512 x;
        uint512 y;
    }

    /**
     * @notice The function to verify the ECDSA signature
     * @param curveParams_ the 512-bit curve parameters. `lowSmax` is `n / 2`.
     * @param hashedMessage_ the already hashed message to be verified.
     * @param signature_ the ECDSA signature. Equals to `bytes(r) + bytes(s)`.
     * @param pubKey_ the full public key of a signer. Equals to `bytes(x) + bytes(y)`.
     *
     * Note that signatures only from the lower part of the curve are accepted.
     * If your `s > n / 2`, change it to `s = n - s`.
     */
    function verify(
        Parameters memory curveParams_,
        bytes memory hashedMessage_,
        bytes memory signature_,
        bytes memory pubKey_
    ) internal view returns (bool) {
        unchecked {
            _Inputs memory inputs_;

            (inputs_.r, inputs_.s) = _u512FromBytes2(signature_);
            (inputs_.x, inputs_.y) = _u512FromBytes2(pubKey_);

            _Parameters memory params_ = _Parameters({
                a: U512.fromBytes(curveParams_.a),
                b: U512.fromBytes(curveParams_.b),
                gx: U512.fromBytes(curveParams_.gx),
                gy: U512.fromBytes(curveParams_.gy),
                p: U512.fromBytes(curveParams_.p),
                n: U512.fromBytes(curveParams_.n),
                lowSmax: U512.fromBytes(curveParams_.lowSmax)
            });

            call512 call_ = U512.initCall();

            /// accept s only from the lower part of the curve
            if (
                U512.eqU256(inputs_.r, 0) ||
                U512.cmp(inputs_.r, params_.n) >= 0 ||
                U512.eqU256(inputs_.s, 0) ||
                U512.cmp(inputs_.s, params_.lowSmax) > 0
            ) {
                return false;
            }

            if (!_isOnCurve(call_, params_.p, params_.a, params_.b, inputs_.x, inputs_.y)) {
                return false;
            }

            uint512 scalar1_ = U512.moddiv(
                call_,
                U512.fromBytes(hashedMessage_),
                inputs_.s,
                params_.n
            );
            uint512 scalar2_ = U512.moddiv(call_, inputs_.r, inputs_.s, params_.n);

            {
                /// We use 6-bit masks where the first 3 bits refer to `scalar1` and the last 3 bits refer to `scalar2`.
                uint512[2][64] memory points_ = _precomputePointsTable(
                    call_,
                    params_.p,
                    U512.fromUint256(2),
                    U512.fromUint256(3),
                    params_.a,
                    inputs_.x,
                    inputs_.y,
                    params_.gx,
                    params_.gy
                );

                (scalar1_, ) = _doubleScalarMultiplication(
                    call_,
                    params_.p,
                    U512.fromUint256(2),
                    U512.fromUint256(3),
                    params_.a,
                    points_,
                    scalar1_,
                    scalar2_
                );
            }

            U512.modAssign(call_, scalar1_, params_.n);

            return U512.eq(scalar1_, inputs_.r);
        }
    }

    /**
     * @dev Check if a point in affine coordinates is on the curve.
     */
    function _isOnCurve(
        call512 call_,
        uint512 p_,
        uint512 a_,
        uint512 b_,
        uint512 x_,
        uint512 y_
    ) private view returns (bool) {
        unchecked {
            if (U512.eqU256(x_, 0) || U512.eq(x_, p_) || U512.eqU256(y_, 0) || U512.eq(y_, p_)) {
                return false;
            }

            uint512 lhs_ = U512.modexpU256(call_, y_, 2, p_);
            uint512 rhs_ = U512.modexpU256(call_, x_, 3, p_);

            if (!U512.eqU256(a_, 0)) {
                rhs_ = U512.redadd(call_, rhs_, U512.modmul(call_, x_, a_, p_), p_); // x^3 + a*x
            }

            if (!U512.eqU256(b_, 0)) {
                rhs_ = U512.redadd(call_, rhs_, b_, p_); // x^3 + a*x + b
            }

            return U512.eq(lhs_, rhs_);
        }
    }

    /**
     * @dev Compute the Strauss-Shamir double scalar multiplication scalar1*G + scalar2*H.
     */
    function _doubleScalarMultiplication(
        call512 call_,
        uint512 p_,
        uint512 two_,
        uint512 three_,
        uint512 a_,
        uint512[2][64] memory points_,
        uint512 scalar1_,
        uint512 scalar2_
    ) private view returns (uint512 x_, uint512 y_) {
        unchecked {
            uint256 mask_;
            uint256 mask1_;
            uint256 mask2_;

            for (uint256 bit = 3; bit <= 514; ) {
                if (bit <= 512) {
                    mask1_ = _getWord(scalar1_, 512 - bit);
                    mask2_ = _getWord(scalar2_, 512 - bit);

                    if ((mask1_ >> 2) == 0 && (mask2_ >> 2) == 0) {
                        (x_, y_) = _twiceAffine(call_, p_, two_, three_, a_, x_, y_);
                        ++bit;
                        continue;
                    }

                    (x_, y_) = _twiceAffine(call_, p_, two_, three_, a_, x_, y_);
                    (x_, y_) = _twiceAffine(call_, p_, two_, three_, a_, x_, y_);
                    (x_, y_) = _twiceAffine(call_, p_, two_, three_, a_, x_, y_);

                    bit += 3;
                } else if (bit == 513) {
                    mask1_ = _getWord(scalar1_, 0) & 0x03;
                    mask2_ = _getWord(scalar2_, 0) & 0x03;

                    (x_, y_) = _twiceAffine(call_, p_, two_, three_, a_, x_, y_);
                    (x_, y_) = _twiceAffine(call_, p_, two_, three_, a_, x_, y_);

                    bit += 2;
                } else {
                    mask1_ = _getWord(scalar1_, 0) & 0x01;
                    mask2_ = _getWord(scalar2_, 0) & 0x01;

                    (x_, y_) = _twiceAffine(call_, p_, two_, three_, a_, x_, y_);

                    ++bit;
                }

                mask_ = (mask1_ << 3) | mask2_;

                if (mask_ != 0) {
                    (x_, y_) = _addAffine(
                        call_,
                        p_,
                        two_,
                        three_,
                        a_,
                        points_[mask_][0],
                        points_[mask_][1],
                        x_,
                        y_
                    );
                }
            }

            return (x_, y_);
        }
    }

    function _getWord(uint512 scalar_, uint256 bit_) private pure returns (uint256) {
        unchecked {
            uint256 word_;
            if (bit_ <= 253) {
                assembly {
                    word_ := mload(add(scalar_, 0x20))
                }

                return (word_ >> bit_) & 0x07;
            }

            if (bit_ <= 381) {
                assembly {
                    word_ := mload(add(scalar_, 0x10))
                }

                return (word_ >> (bit_ - 128)) & 0x07;
            }

            assembly {
                word_ := mload(scalar_)
            }

            return (word_ >> (bit_ - 256)) & 0x07;
        }
    }

    /**
     * @dev Double an elliptic curve point in affine coordinates.
     */
    function _twiceAffine(
        call512 call_,
        uint512 p_,
        uint512 two_,
        uint512 three_,
        uint512 a_,
        uint512 x1_,
        uint512 y1_
    ) private view returns (uint512 x2_, uint512 y2_) {
        unchecked {
            if (U512.isNull(x1_)) {
                return (x2_, y2_);
            }

            if (U512.eqU256(y1_, 0)) {
                return (x2_, y2_);
            }

            uint512 m1_ = U512.modexpU256(call_, x1_, 2, p_);
            U512.modmulAssign(call_, m1_, three_, p_);
            U512.redaddAssign(call_, m1_, a_, p_);

            uint512 m2_ = U512.modmul(call_, y1_, two_, p_);
            U512.moddivAssign(call_, m1_, m2_, p_);

            x2_ = U512.modexpU256(call_, m1_, 2, p_);
            U512.redsubAssign(call_, x2_, x1_, p_);
            U512.redsubAssign(call_, x2_, x1_, p_);

            y2_ = U512.redsub(call_, x1_, x2_, p_);
            U512.modmulAssign(call_, y2_, m1_, p_);
            U512.redsubAssign(call_, y2_, y1_, p_);
        }
    }

    /**
     * @dev Add two elliptic curve points in affine coordinates.
     */
    function _addAffine(
        call512 call_,
        uint512 p_,
        uint512 two_,
        uint512 three_,
        uint512 a_,
        uint512 x1_,
        uint512 y1_,
        uint512 x2_,
        uint512 y2_
    ) private view returns (uint512 x3, uint512 y3) {
        unchecked {
            if (U512.isNull(x1_) || U512.isNull(x2_)) {
                if (U512.isNull(x1_) && U512.isNull(x2_)) {
                    return (x3, y3);
                }

                return
                    U512.isNull(x1_)
                        ? (U512.copy(x2_), U512.copy(y2_))
                        : (U512.copy(x1_), U512.copy(y1_));
            }

            if (U512.eq(x1_, x2_)) {
                if (U512.eq(y1_, y2_)) {
                    return _twiceAffine(call_, p_, two_, three_, a_, x1_, y1_);
                }

                return (x3, y3);
            }

            uint512 m1_ = U512.redsub(call_, y1_, y2_, p_);
            uint512 m2_ = U512.redsub(call_, x1_, x2_, p_);

            U512.moddivAssign(call_, m1_, m2_, p_);

            x3 = U512.modexpU256(call_, m1_, 2, p_);
            U512.redsubAssign(call_, x3, x1_, p_);
            U512.redsubAssign(call_, x3, x2_, p_);

            y3 = U512.redsub(call_, x1_, x3, p_);
            U512.modmulAssign(call_, y3, m1_, p_);
            U512.redsubAssign(call_, y3, y1_, p_);
        }
    }

    function _precomputePointsTable(
        call512 call_,
        uint512 p_,
        uint512 two_,
        uint512 three_,
        uint512 a_,
        uint512 hx_,
        uint512 hy_,
        uint512 gx_,
        uint512 gy_
    ) private view returns (uint512[2][64] memory points_) {
        unchecked {
            (points_[0x01][0], points_[0x01][1]) = (U512.copy(hx_), U512.copy(hy_));
            (points_[0x08][0], points_[0x08][1]) = (U512.copy(gx_), U512.copy(gy_));

            for (uint256 i = 0; i < 8; ++i) {
                for (uint256 j = 0; j < 8; ++j) {
                    if (i + j < 2) {
                        continue;
                    }

                    uint256 maskTo = (i << 3) | j;

                    if (i != 0) {
                        uint256 maskFrom = ((i - 1) << 3) | j;

                        (points_[maskTo][0], points_[maskTo][1]) = _addAffine(
                            call_,
                            p_,
                            two_,
                            three_,
                            a_,
                            points_[maskFrom][0],
                            points_[maskFrom][1],
                            gx_,
                            gy_
                        );
                    } else {
                        (points_[maskTo][0], points_[maskTo][1]) = _addAffine(
                            call_,
                            p_,
                            two_,
                            three_,
                            a_,
                            points_[(i << 3) | (j - 1)][0],
                            points_[(i << 3) | (j - 1)][1],
                            hx_,
                            hy_
                        );
                    }
                }
            }

            return points_;
        }
    }

    /**
     * @dev Convert 128 bytes to two 512-bit unsigned integers.
     */
    function _u512FromBytes2(bytes memory bytes_) private view returns (uint512, uint512) {
        unchecked {
            assert(bytes_.length == 128);

            bytes memory lhs_ = new bytes(64);
            bytes memory rhs_ = new bytes(64);

            MemoryUtils.unsafeCopy(bytes_.getDataPointer(), lhs_.getDataPointer(), 64);
            MemoryUtils.unsafeCopy(bytes_.getDataPointer() + 64, rhs_.getDataPointer(), 64);

            return (U512.fromBytes(lhs_), U512.fromBytes(rhs_));
        }
    }
}
