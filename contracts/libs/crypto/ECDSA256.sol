// SPDX-License-Identifier: MIT
// Reference: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.1.0/contracts/utils/cryptography/P256.sol
pragma solidity ^0.8.21;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @notice Cryptography module
 *
 * This library provides functionality for ECDSA verification over any 256-bit curve.
 *
 * For more information, please refer to the OpenZeppelin documentation.
 */
library ECDSA256 {
    /**
     * @notice 256-bit curve parameters.
     */
    struct Parameters {
        uint256 a;
        uint256 b;
        uint256 gx;
        uint256 gy;
        uint256 p;
        uint256 n;
        uint256 lowSmax;
    }

    // solhint-disable-next-line contract-name-capwords
    struct _JPoint {
        uint256 x;
        uint256 y;
        uint256 z;
    }

    // solhint-disable-next-line contract-name-capwords
    struct _Inputs {
        uint256 r;
        uint256 s;
        uint256 x;
        uint256 y;
    }

    error LengthIsNot64();

    /**
     * @notice The function to verify the ECDSA signature
     * @param curveParams_ the 256-bit curve parameters. `lowSmax` is `n / 2`.
     * @param hashedMessage_ the already hashed message to be verified.
     * @param signature_ the ECDSA signature. Equals to `bytes(r) + bytes(s)`.
     * @param pubKey_ the full public key of a signer. Equals to `bytes(x) + bytes(y)`.
     *
     * Note that signatures only from the lower part of the curve are accepted.
     * If your `s > n / 2`, change it to `s = n - s`.
     */
    function verify(
        Parameters memory curveParams_,
        bytes32 hashedMessage_,
        bytes memory signature_,
        bytes memory pubKey_
    ) internal view returns (bool) {
        unchecked {
            _Inputs memory inputs_;

            (inputs_.r, inputs_.s) = _split(signature_);
            (inputs_.x, inputs_.y) = _split(pubKey_);

            if (
                !_isProperSignature(inputs_.r, inputs_.s, curveParams_.n, curveParams_.lowSmax) ||
                !_isOnCurve(inputs_.x, inputs_.y, curveParams_.a, curveParams_.b, curveParams_.p)
            ) {
                return false;
            }

            uint256 u1_;
            uint256 u2_;

            {
                uint256 w_ = Math.invModPrime(inputs_.s, curveParams_.n);
                u1_ = mulmod(uint256(hashedMessage_), w_, curveParams_.n);
                u2_ = mulmod(inputs_.r, w_, curveParams_.n);
            }

            uint256 x_;

            {
                _JPoint[16] memory points_ = _preComputeJacobianPoints(
                    inputs_.x,
                    inputs_.y,
                    curveParams_.gx,
                    curveParams_.gy,
                    curveParams_.p,
                    curveParams_.a
                );

                (x_, ) = _jMultShamir(points_, u1_, u2_, curveParams_.p, curveParams_.a);
            }

            return x_ % curveParams_.n == inputs_.r;
        }
    }

    /**
     * @dev Checks if (x, y) are valid coordinates of a point on the curve.
     * In particular this function checks that x < P and y < P.
     */
    function _isOnCurve(
        uint256 x_,
        uint256 y_,
        uint256 a_,
        uint256 b_,
        uint256 p_
    ) private pure returns (bool result_) {
        assembly ("memory-safe") {
            let lhs_ := mulmod(y_, y_, p_)
            let rhs_ := addmod(mulmod(addmod(mulmod(x_, x_, p_), a_, p_), x_, p_), b_, p_)

            result_ := and(and(lt(x_, p_), lt(y_, p_)), eq(lhs_, rhs_)) // Should conform with the Weierstrass equation
        }
    }

    /**
     * @dev Checks if (r, s) is a proper signature.
     * In particular, this checks that `s` is in the "lower-range", making the signature non-malleable
     */
    function _isProperSignature(
        uint256 r_,
        uint256 s_,
        uint256 n_,
        uint256 lowSmax_
    ) private pure returns (bool) {
        return r_ > 0 && r_ < n_ && s_ > 0 && s_ <= lowSmax_;
    }

    /**
     * @dev Reduce from jacobian to affine coordinates
     * @param point_ - point with jacobian coordinate x, y and z
     * @return ax_ - affine coordinate x
     * @return ay_ - affine coordinate y
     */
    function _affineFromJacobian(
        _JPoint memory point_,
        uint256 p_
    ) private view returns (uint256 ax_, uint256 ay_) {
        if (point_.z == 0) return (0, 0);

        uint256 zInverse_ = Math.invModPrime(point_.z, p_);

        assembly ("memory-safe") {
            let zzInverse_ := mulmod(zInverse_, zInverse_, p_)

            ax_ := mulmod(mload(point_), zzInverse_, p_)
            ay_ := mulmod(mload(add(point_, 0x20)), mulmod(zzInverse_, zInverse_, p_), p_)
        }
    }

    /**
     * @dev Point addition on the jacobian coordinates
     * Reference: https://www.hyperelliptic.org/EFD/g1p/auto-shortw-jacobian.html#addition-add-1998-cmo-2
     */
    function _jAdd(
        _JPoint memory point1_,
        _JPoint memory point2_,
        uint256 p_,
        uint256 a_
    ) private pure returns (uint256 resX_, uint256 resY_, uint256 resZ_) {
        assembly ("memory-safe") {
            let zz1_ := mulmod(mload(add(point1_, 0x40)), mload(add(point1_, 0x40)), p_)
            let s1_ := mulmod(
                mload(add(point1_, 0x20)),
                mulmod(
                    mulmod(mload(add(point2_, 0x40)), mload(add(point2_, 0x40)), p_),
                    mload(add(point2_, 0x40)),
                    p_
                ),
                p_
            )
            let r_ := addmod(
                mulmod(mload(add(point2_, 0x20)), mulmod(zz1_, mload(add(point1_, 0x40)), p_), p_),
                sub(p_, s1_),
                p_
            )
            let u1_ := mulmod(
                mload(point1_),
                mulmod(mload(add(point2_, 0x40)), mload(add(point2_, 0x40)), p_),
                p_
            )
            let h_ := addmod(mulmod(mload(point2_), zz1_, p_), sub(p_, u1_), p_)

            // detect edge cases where inputs are identical
            switch and(iszero(r_), iszero(h_))
            // case 0: points are different
            case 0 {
                let hh_ := mulmod(h_, h_, p_)

                resX_ := addmod(
                    addmod(mulmod(r_, r_, p_), sub(p_, mulmod(h_, hh_, p_)), p_),
                    sub(p_, mulmod(2, mulmod(u1_, hh_, p_), p_)),
                    p_
                )
                resY_ := addmod(
                    mulmod(r_, addmod(mulmod(u1_, hh_, p_), sub(p_, resX_), p_), p_),
                    sub(p_, mulmod(s1_, mulmod(h_, hh_, p_), p_)),
                    p_
                )
                resZ_ := mulmod(
                    h_,
                    mulmod(mload(add(point1_, 0x40)), mload(add(point2_, 0x40)), p_),
                    p_
                )
            }
            // case 1: points are equal
            case 1 {
                let yy_ := mulmod(mload(add(point2_, 0x20)), mload(add(point2_, 0x20)), p_)
                let zz_ := mulmod(mload(add(point2_, 0x40)), mload(add(point2_, 0x40)), p_)
                let xx_ := mulmod(mload(point2_), mload(point2_), p_)
                let m_ := addmod(mulmod(3, xx_, p_), mulmod(a_, mulmod(zz_, zz_, p_), p_), p_)
                let s_ := mulmod(4, mulmod(mload(point2_), yy_, p_), p_)

                resX_ := addmod(mulmod(m_, m_, p_), sub(p_, mulmod(2, s_, p_)), p_)

                // cut the computation to avoid stack too deep
                let rytmp1_ := sub(p_, mulmod(8, mulmod(yy_, yy_, p_), p_))
                let rytmp2_ := addmod(s_, sub(p_, resX_), p_)
                resY_ := addmod(mulmod(m_, rytmp2_, p_), rytmp1_, p_)

                resZ_ := mulmod(
                    2,
                    mulmod(mload(add(point2_, 0x20)), mload(add(point2_, 0x40)), p_),
                    p_
                )
            }
        }
    }

    /**
     * @dev Point doubling on the jacobian coordinates
     * Reference: https://www.hyperelliptic.org/EFD/g1p/auto-shortw-jacobian.html#doubling-dbl-1998-cmo-2
     */
    function _jDouble(
        uint256 x_,
        uint256 y_,
        uint256 z_,
        uint256 p_,
        uint256 a_
    ) private pure returns (uint256 resX_, uint256 resY_, uint256 resZ_) {
        assembly ("memory-safe") {
            let yy_ := mulmod(y_, y_, p_)
            let zz_ := mulmod(z_, z_, p_)
            let m_ := addmod(
                mulmod(3, mulmod(x_, x_, p_), p_),
                mulmod(a_, mulmod(zz_, zz_, p_), p_),
                p_
            )
            let s_ := mulmod(4, mulmod(x_, yy_, p_), p_)

            resX_ := addmod(mulmod(m_, m_, p_), sub(p_, mulmod(2, s_, p_)), p_)
            resY_ := addmod(
                mulmod(m_, addmod(s_, sub(p_, resX_), p_), p_),
                sub(p_, mulmod(8, mulmod(yy_, yy_, p_), p_)),
                p_
            )
            resZ_ := mulmod(2, mulmod(y_, z_, p_), p_)
        }
    }

    /**
     * @dev Compute G·u1 + P·u2 using the precomputed points for G and P (see {_preComputeJacobianPoints}).
     *
     * Uses Strauss Shamir trick for EC multiplication
     * https://stackoverflow.com/questions/50993471/ec-scalar-multiplication-with-strauss-shamir-method
     */
    function _jMultShamir(
        _JPoint[16] memory points_,
        uint256 u1_,
        uint256 u2_,
        uint256 p_,
        uint256 a_
    ) private view returns (uint256 resX_, uint256 resY_) {
        _JPoint memory point_;

        unchecked {
            for (uint256 i = 0; i < 128; ++i) {
                if (point_.z > 0) {
                    (point_.x, point_.y, point_.z) = _jDouble(
                        point_.x,
                        point_.y,
                        point_.z,
                        p_,
                        a_
                    );
                    (point_.x, point_.y, point_.z) = _jDouble(
                        point_.x,
                        point_.y,
                        point_.z,
                        p_,
                        a_
                    );
                }
                // Read 2 bits of u1, and 2 bits of u2. Combining the two gives the lookup index in the table.
                uint256 pos_ = ((u1_ >> 252) & 0xc) | ((u2_ >> 254) & 0x3);
                // Points that have z = 0 are points at infinity. They are the additive 0 of the group
                // - if the lookup point is a 0, we can skip it
                // - otherwise:
                //   - if the current point (x, y, z) is 0, we use the lookup point as our new value (0+P=P)
                //   - if the current point (x, y, z) is not 0, both points are valid and we can use `_jAdd`
                if (points_[pos_].z != 0) {
                    if (point_.z == 0) {
                        (point_.x, point_.y, point_.z) = (
                            points_[pos_].x,
                            points_[pos_].y,
                            points_[pos_].z
                        );
                    } else {
                        (point_.x, point_.y, point_.z) = _jAdd(points_[pos_], point_, p_, a_);
                    }
                }
                u1_ <<= 2;
                u2_ <<= 2;
            }
        }
        return _affineFromJacobian(point_, p_);
    }

    /**
     * @dev Precompute a matrice of useful jacobian points associated with a given P. This can be seen as a 4x4 matrix
     * that contains combination of P and G (generator) up to 3 times each
     */
    function _preComputeJacobianPoints(
        uint256 x_,
        uint256 y_,
        uint256 gx_,
        uint256 gy_,
        uint256 p_,
        uint256 a_
    ) private pure returns (_JPoint[16] memory points_) {
        points_[0x00] = _JPoint(0, 0, 0);
        points_[0x01] = _JPoint(x_, y_, 1);
        points_[0x04] = _JPoint(gx_, gy_, 1);
        points_[0x02] = _jDoublePoint(points_[0x01], p_, a_);
        points_[0x08] = _jDoublePoint(points_[0x04], p_, a_);
        points_[0x03] = _jAddPoint(points_[0x01], points_[0x02], p_, a_);
        points_[0x05] = _jAddPoint(points_[0x01], points_[0x04], p_, a_);
        points_[0x06] = _jAddPoint(points_[0x02], points_[0x04], p_, a_);
        points_[0x07] = _jAddPoint(points_[0x03], points_[0x04], p_, a_);
        points_[0x09] = _jAddPoint(points_[0x01], points_[0x08], p_, a_);
        points_[0x0a] = _jAddPoint(points_[0x02], points_[0x08], p_, a_);
        points_[0x0b] = _jAddPoint(points_[0x03], points_[0x08], p_, a_);
        points_[0x0c] = _jAddPoint(points_[0x04], points_[0x08], p_, a_);
        points_[0x0d] = _jAddPoint(points_[0x01], points_[0x0c], p_, a_);
        points_[0x0e] = _jAddPoint(points_[0x02], points_[0x0c], p_, a_);
        points_[0x0f] = _jAddPoint(points_[0x03], points_[0x0c], p_, a_);
    }

    function _jAddPoint(
        _JPoint memory point1_,
        _JPoint memory point2_,
        uint256 p_,
        uint256 a_
    ) private pure returns (_JPoint memory) {
        (uint256 x_, uint256 y_, uint256 z_) = _jAdd(point1_, point2_, p_, a_);

        return _JPoint(x_, y_, z_);
    }

    function _jDoublePoint(
        _JPoint memory point_,
        uint256 p_,
        uint256 a_
    ) private pure returns (_JPoint memory) {
        (uint256 x_, uint256 y_, uint256 z_) = _jDouble(point_.x, point_.y, point_.z, p_, a_);

        return _JPoint(x_, y_, z_);
    }

    /**
     * @dev Helper function for splitting bytes into two uint256 values. Used for 64-byte signatures and public keys
     */
    function _split(
        bytes memory from2_
    ) private pure returns (uint256 leftPart_, uint256 rightPart_) {
        unchecked {
            if (from2_.length != 64) revert LengthIsNot64();

            assembly ("memory-safe") {
                leftPart_ := mload(add(from2_, 32))
                rightPart_ := mload(add(from2_, 64))
            }

            return (leftPart_, rightPart_);
        }
    }
}
