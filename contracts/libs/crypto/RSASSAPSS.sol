// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @notice Cryptography module
 *
 * This library provides functionality to verify RSASSA-PSS signatures with MGF1 mask generation function.
 *
 * Users may provide custom hash functions via `Parameters` struct. However, the usage of `sha256` is recommended.
 * The RSASSA-PSS signature verification costs ~340k gas.
 *
 * Learn more about the algorithm [here](https://datatracker.ietf.org/doc/html/rfc3447#section-8.1).
 */
library RSASSAPSS {
    /**
     * @notice The RSASSA-PSS parameters.
     * @param hashLength the hash function output length in bytes.
     * @param saltLength the pss encoding salt length in bytes.
     * @param hasher the function-pointer to a custom hash function.
     */
    struct Parameters {
        uint256 hashLength;
        uint256 saltLength;
        function(bytes memory) internal pure returns (bytes memory) hasher;
    }

    /**
     * @notice Same as `verify` but with `sha256` hash function preconfiguration.
     */
    function verifySha256(
        bytes memory message_,
        bytes memory s_,
        bytes memory e_,
        bytes memory n_
    ) internal view returns (bool) {
        unchecked {
            Parameters memory params_ = Parameters({
                hashLength: 32,
                saltLength: 32,
                hasher: _sha256
            });

            return verify(params_, message_, s_, e_, n_);
        }
    }

    /**
     * @notice Verifies RSAPSS-SSA signature with custom parameters.
     * @param params_ The parameters to specify the hash length, salt length, and hash function of choice.
     * @param message_ The arbitrary message to be verified.
     * @param s_ The "encrypted" signature
     * @param e_ The public key exponent. `65537` is a recommended value.
     * @param n_ The modulus of a public key.
     */
    function verify(
        Parameters memory params_,
        bytes memory message_,
        bytes memory s_,
        bytes memory e_,
        bytes memory n_
    ) internal view returns (bool) {
        unchecked {
            if (s_.length == 0 || e_.length == 0 || n_.length == 0) {
                return false;
            }

            bytes memory decipher_ = _rsa(s_, e_, n_);

            return _pss(message_, decipher_, params_);
        }
    }

    /**
     * @notice Calculates RSA via modexp (0x05) precompile.
     */
    function _rsa(
        bytes memory s_,
        bytes memory e_,
        bytes memory n_
    ) private view returns (bytes memory decipher_) {
        unchecked {
            bytes memory input_ = abi.encodePacked(s_.length, e_.length, n_.length, s_, e_, n_);

            decipher_ = new bytes(n_.length);

            assembly {
                pop(
                    staticcall(
                        sub(gas(), 2000), // gas buffer
                        5,
                        add(input_, 0x20),
                        mload(input_),
                        add(decipher_, 0x20),
                        mload(n_)
                    )
                )
            }
        }
    }

    /**
     * @notice Checks the PSS encoding.
     */
    function _pss(
        bytes memory message_,
        bytes memory signature_,
        Parameters memory params_
    ) private pure returns (bool) {
        unchecked {
            uint256 hashLength_ = params_.hashLength;
            uint256 saltLength_ = params_.saltLength;
            uint256 sigBytes_ = signature_.length;
            uint256 sigBits_ = (sigBytes_ * 8 - 1) & 7;

            assert(message_.length < 2 ** 61);

            bytes memory messageHash_ = params_.hasher(message_);

            if (sigBytes_ < hashLength_ + saltLength_ + 2) {
                return false;
            }

            if (signature_[sigBytes_ - 1] != hex"BC") {
                return false;
            }

            bytes memory db_ = new bytes(sigBytes_ - hashLength_ - 1);
            bytes memory h_ = new bytes(hashLength_);

            for (uint256 i = 0; i < db_.length; ++i) {
                db_[i] = signature_[i];
            }

            for (uint256 i = 0; i < hashLength_; ++i) {
                h_[i] = signature_[i + db_.length];
            }

            if (uint8(db_[0] & bytes1(uint8(((0xFF << (sigBits_)))))) == 1) {
                return false;
            }

            bytes memory dbMask_ = _mgf(params_, h_, db_.length);

            for (uint256 i = 0; i < db_.length; ++i) {
                db_[i] ^= dbMask_[i];
            }

            if (sigBits_ > 0) {
                db_[0] &= bytes1(uint8(0xFF >> (8 - sigBits_)));
            }

            uint256 zeroBytes_;

            for (
                zeroBytes_ = 0;
                db_[zeroBytes_] == 0 && zeroBytes_ < (db_.length - 1);
                ++zeroBytes_
            ) {}

            if (db_[zeroBytes_] != hex"01") {
                return false;
            }

            bytes memory salt_ = new bytes(saltLength_);

            for (uint256 i = 0; i < salt_.length; ++i) {
                salt_[i] = db_[db_.length - salt_.length + i];
            }

            bytes memory hh_ = params_.hasher(
                abi.encodePacked(hex"0000000000000000", messageHash_, salt_)
            );

            /// check bytes equality
            if (keccak256(h_) != keccak256(hh_)) {
                return false;
            }

            return true;
        }
    }

    /**
     * @notice MGF1 mask generation function
     */
    function _mgf(
        Parameters memory params_,
        bytes memory message_,
        uint256 maskLen_
    ) private pure returns (bytes memory res_) {
        unchecked {
            uint256 hashLength_ = params_.hashLength;

            bytes memory cnt_ = new bytes(4);

            assert(maskLen_ <= (2 ** 32) * hashLength_);

            for (uint256 i = 0; i < (maskLen_ + hashLength_ - 1) / hashLength_; ++i) {
                cnt_[0] = bytes1(uint8((i >> 24) & 255));
                cnt_[1] = bytes1(uint8((i >> 16) & 255));
                cnt_[2] = bytes1(uint8((i >> 8) & 255));
                cnt_[3] = bytes1(uint8(i & 255));

                bytes memory hashedResInter_ = params_.hasher(abi.encodePacked(message_, cnt_));

                res_ = abi.encodePacked(res_, hashedResInter_);
            }

            assembly {
                mstore(res_, maskLen_)
            }
        }
    }

    /**
     * @notice Utility `sha256` wrapper.
     */
    function _sha256(bytes memory data) private pure returns (bytes memory) {
        unchecked {
            return abi.encodePacked(sha256(data));
        }
    }
}
