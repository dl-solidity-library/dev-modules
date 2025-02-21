// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

type uint512 is uint256;
type call512 is uint256;

/**
 * @notice Low-level library that implements unsigned 512-bit arithmetics.
 *
 * | Statistic   | Avg          |
 * | ----------- | ------------ |
 * | add         | 269 gas      |
 * | sub         | 278 gas      |
 * | mul         | 353 gas      |
 * | mod         | 682 gas      |
 * | modinv      | 6083 gas     |
 * | modadd      | 780 gas      |
 * | redadd      | 590 gas      |
 * | modmul      | 1176 gas     |
 * | modsub      | 1017 gas     |
 * | redsub      | 533 gas      |
 * | modexp      | 5981 gas     |
 * | modexpU256  | 692 gas      |
 * | moddiv      | 7092 gas     |
 * | and         | 251 gas      |
 * | or          | 251 gas      |
 * | xor         | 251 gas      |
 * | not         | 216 gas      |
 * | shl         | 272 gas      |
 * | shr         | 272 gas      |
 *
 * ## Imports:
 *
 * First import the library and all the necessary types.
 *
 * ```
 * import {U512, uint512, call512} from "U512.sol";
 * ```
 *
 * ## Usage example:
 *
 * ```
 * using U512 for uint512;
 *
 * uint512 a_ = U512.fromUint256(3);
 * uint512 b_ = U512.fromUint256(6);
 * uint512 m_ = U512.fromUint256(5);
 * uint512 r_ = a.modadd(b_, m_);
 * r_.eq(U512.fromUint256(4)); // true
 * ```
 *
 * Note that each mod call allocates extra memory for invoking the precompile. This is fine for lightweight
 * functions. However, for heavy functions, consider allocating memory once and reusing it in subsequent calls.
 * This approach can help reduce gas costs. Additionally, use assignment functions to avoid
 * allocating memory for new local variables, instead assigning values to existing ones.
 *
 * ```
 * using U512 for uint512;
 *
 * call512 call_ = U512.initCall();
 * uint512 a_ = U512.fromUint256(3);
 * uint512 b_ = U512.fromUint256(6);
 * uint512 m_ = U512.fromUint256(5);
 * uint512 r_ = a.modadd(call_, b_, m_); // 4
 * r_.modmulAssign(a_, m_); // 2
 * r_.eq(U512.fromUint256(2)); // true
 * r_.toBytes(); // "0x00..02"
 * ```
 */
library U512 {
    uint256 private constant _UINT512_ALLOCATION = 64;
    uint256 private constant _BYTES_ALLOCATION = 96;
    uint256 private constant _CALL_ALLOCATION = 384;

    /**
     * @notice Initializes a memory pointer for precompile call arguments.
     * @return call_ A memory pointer for precompile operations.
     */
    function initCall() internal pure returns (call512 call_) {
        unchecked {
            call_ = call512.wrap(_allocate(_CALL_ALLOCATION));

            assembly {
                call_ := add(call_, 0x40)
            }
        }
    }

    /**
     * @notice Converts a 256-bit unsigned integer to a 512-bit unsigned integer.
     * @param u256_ The 256-bit unsigned integer to convert.
     * @return u512_ The 512-bit representation of the input.
     */
    function fromUint256(uint256 u256_) internal pure returns (uint512 u512_) {
        unchecked {
            u512_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            assembly {
                mstore(u512_, 0x00)
                mstore(add(u512_, 0x20), u256_)
            }
        }
    }

    /**
     * @notice Converts a byte array to a 512-bit unsigned integer.
     * @dev The byte array must be less than 65 bytes.
     * @param bytes_ The byte array to convert.
     * @return u512_ The 512-bit representation of the byte array.
     */
    function fromBytes(bytes memory bytes_) internal view returns (uint512 u512_) {
        unchecked {
            assert(bytes_.length < 65);

            u512_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            assembly {
                mstore(u512_, 0)
                mstore(add(u512_, 0x20), 0)

                let size_ := mload(bytes_)
                pop(
                    staticcall(
                        gas(),
                        0x4,
                        add(bytes_, 0x20),
                        size_,
                        add(u512_, sub(0x40, size_)),
                        size_
                    )
                )
            }
        }
    }

    /**
     * @notice Copies a 512-bit unsigned integer to a new memory location.
     * @param u512_ The 512-bit unsigned integer to copy.
     * @return u512Copy_ A pointer to the new copy of the 512-bit unsigned integer.
     */
    function copy(uint512 u512_) internal pure returns (uint512 u512Copy_) {
        unchecked {
            u512Copy_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            assembly {
                mstore(u512Copy_, mload(u512_))
                mstore(add(u512Copy_, 0x20), mload(add(u512_, 0x20)))
            }
        }
    }

    /**
     * @notice Assigns a 512-bit unsigned integer to another.
     * @param u512_ The 512-bit unsigned integer to assign.
     * @param to_ The target 512-bit unsigned integer to store the result.
     */
    function assign(uint512 u512_, uint512 to_) internal pure {
        unchecked {
            assembly {
                mstore(to_, mload(u512_))
                mstore(add(to_, 0x20), mload(add(u512_, 0x20)))
            }
        }
    }

    /**
     * @notice Converts a 512-bit unsigned integer to a byte array.
     * @param u512_ The 512-bit unsigned integer to convert.
     * @return bytes_ A byte array representation of the 512-bit unsigned integer.
     */
    function toBytes(uint512 u512_) internal pure returns (bytes memory bytes_) {
        unchecked {
            uint256 handler_ = _allocate(_BYTES_ALLOCATION);

            assembly {
                mstore(handler_, 0x40)
                mstore(add(handler_, 0x20), mload(u512_))
                mstore(add(handler_, 0x40), mload(add(u512_, 0x20)))

                bytes_ := handler_
            }
        }
    }

    /**
     * @notice Checks if a uint512 pointer is null.
     * @param u512_ The uint512 pointer to check.
     * @return isNull_ True if the pointer is null, false otherwise.
     */
    function isNull(uint512 u512_) internal pure returns (bool isNull_) {
        unchecked {
            assembly {
                isNull_ := iszero(u512_)
            }
        }
    }

    /**
     * @notice Compares two 512-bit unsigned integers for equality.
     * @param a_ The first 512-bit unsigned integer.
     * @param b_ The second 512-bit unsigned integer.
     * @return eq_ True if the integers are equal, false otherwise.
     */
    function eq(uint512 a_, uint512 b_) internal pure returns (bool eq_) {
        unchecked {
            assembly {
                eq_ := and(
                    eq(mload(a_), mload(b_)),
                    eq(mload(add(a_, 0x20)), mload(add(b_, 0x20)))
                )
            }
        }
    }

    /**
     * @notice Compares a 512-bit unsigned integer with a 256-bit unsigned integer for equality.
     * @param a_ The 512-bit unsigned integer.
     * @param u256_ The 256-bit unsigned integer.
     * @return eq_ True if the integers are equal, false otherwise.
     */
    function eqU256(uint512 a_, uint256 u256_) internal pure returns (bool eq_) {
        unchecked {
            assembly {
                eq_ := and(eq(mload(a_), 0), eq(mload(add(a_, 0x20)), u256_))
            }
        }
    }

    /**
     * @notice Compares two 512-bit unsigned integers.
     * @param a_ The first 512-bit unsigned integer.
     * @param b_ The second 512-bit unsigned integer.
     * @return 1 if `a_ > b_`, -1 if `a_ < b_`, and 0 if they are equal.
     */
    function cmp(uint512 a_, uint512 b_) internal pure returns (int256) {
        unchecked {
            uint256 aWord_;
            uint256 bWord_;

            assembly {
                aWord_ := mload(a_)
                bWord_ := mload(b_)
            }

            if (aWord_ > bWord_) {
                return 1;
            }

            if (aWord_ < bWord_) {
                return -1;
            }

            assembly {
                aWord_ := mload(add(a_, 0x20))
                bWord_ := mload(add(b_, 0x20))
            }

            if (aWord_ > bWord_) {
                return 1;
            }

            if (aWord_ < bWord_) {
                return -1;
            }

            return 0;
        }
    }

    /**
     * @notice Performs modular arithmetic on 512-bit integers.
     * @param call_ A memory pointer for precompile call arguments.
     * @param a_ The dividend.
     * @param m_ The modulus.
     * @return r_ The result of the modular operation `(a_ % m_)`.
     */
    function mod(call512 call_, uint512 a_, uint512 m_) internal view returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            _mod(call_, a_, m_, r_);
        }
    }

    /**
     * @notice Performs modular arithmetic on 512-bit integers.
     * @dev Allocates memory for `call` every time it's called.
     * @param a_ The dividend.
     * @param m_ The modulus.
     * @return r_ The result of the modular operation `(a_ % m_)`.
     */
    function mod(uint512 a_, uint512 m_) internal view returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));
            call512 call_ = initCall();

            _mod(call_, a_, m_, r_);
        }
    }

    /**
     * @notice Performs modular assignment on a 512-bit unsigned integer.
     * @dev Updates the value of `a_` to `(a_ % m_)`.
     * @param call_ A memory pointer for precompile call arguments.
     * @param a_ The dividend.
     * @param m_ The modulus.
     */
    function modAssign(call512 call_, uint512 a_, uint512 m_) internal view {
        unchecked {
            _mod(call_, a_, m_, a_);
        }
    }

    /**
     * @notice Performs modular assignment and stores the result in a separate 512-bit unsigned integer.
     * @dev Assigns the result `(a_ % m_)` to `to_`.
     * @param call_ A memory pointer for precompile call arguments.
     * @param a_ The dividend.
     * @param m_ The modulus.
     * @param to_ The target 512-bit unsigned integer to store the result.
     */
    function modAssignTo(call512 call_, uint512 a_, uint512 m_, uint512 to_) internal view {
        unchecked {
            _mod(call_, a_, m_, to_);
        }
    }

    /**
     * @notice Computes the modular inverse of a 512-bit unsigned integer.
     * @dev IMPORTANT: The modulus `m_` must be a prime number
     * @param call_ A memory pointer for precompile call arguments.
     * @param a_ The 512-bit unsigned integer to invert.
     * @param m_ The modulus.
     * @return r_ The modular inverse result `a_^(-1) % m_`.
     */
    function modinv(call512 call_, uint512 a_, uint512 m_) internal view returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            _modinv(call_, a_, m_, r_);
        }
    }

    /**
     * @notice Computes the modular inverse of a 512-bit unsigned integer.
     * @dev IMPORTANT: The modulus `m_` must be a prime number
     * @dev Allocates memory for `call` every time it's called.
     * @param a_ The 512-bit unsigned integer to invert.
     * @param m_ The modulus.
     * @return r_ The modular inverse result `a_^(-1) % m_`.
     */
    function modinv(uint512 a_, uint512 m_) internal view returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));
            call512 call_ = initCall();

            _modinv(call_, a_, m_, r_);
        }
    }

    /**
     * @notice Performs the modular inverse assignment on a 512-bit unsigned integer.
     * @dev IMPORTANT: The modulus `m_` must be a prime number
     * @dev Updates the value of `a_` to `a_^(-1) % m_`.
     * @param call_ A memory pointer for precompile call arguments.
     * @param a_ The 512-bit unsigned integer to invert.
     * @param m_ The modulus.
     */
    function modinvAssign(call512 call_, uint512 a_, uint512 m_) internal view {
        unchecked {
            _modinv(call_, a_, m_, a_);
        }
    }

    /**
     * @notice Computes the modular inverse and stores it in a separate 512-bit unsigned integer.
     * @dev IMPORTANT: The modulus `m_` must be a prime number
     * @dev Assigns the result of `a_^(-1) % m_` to `to_`.
     * @param call_ A memory pointer for precompile call arguments.
     * @param a_ The 512-bit unsigned integer to invert.
     * @param m_ The modulus.
     * @param to_ The target 512-bit unsigned integer to store the result.
     */
    function modinvAssignTo(call512 call_, uint512 a_, uint512 m_, uint512 to_) internal view {
        unchecked {
            _modinv(call_, a_, m_, to_);
        }
    }

    /**
     * @notice Performs modular exponentiation on 512-bit unsigned integers.
     * @param call_ A memory pointer for precompile call arguments.
     * @param b_ The base.
     * @param e_ The exponent.
     * @param m_ The modulus.
     * @return r_ The result of modular exponentiation `(b_^e_) % m_`.
     */
    function modexp(
        call512 call_,
        uint512 b_,
        uint512 e_,
        uint512 m_
    ) internal view returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            _modexp(call_, b_, e_, m_, r_);
        }
    }

    /**
     * @notice Performs modular exponentiation on 512-bit unsigned integers.
     * @dev Allocates memory for `call` every time it's called.
     * @param b_ The base.
     * @param e_ The exponent.
     * @param m_ The modulus.
     * @return r_ The result of modular exponentiation `(b_^e_) % m_`.
     */
    function modexp(uint512 b_, uint512 e_, uint512 m_) internal view returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));
            call512 call_ = initCall();

            _modexp(call_, b_, e_, m_, r_);
        }
    }

    /**
     * @notice Performs modular exponentiation assignment on the base.
     * @dev Updates the value of `b_` to `(b_^e_) % m_`.
     * @param call_ A memory pointer for precompile call arguments.
     * @param b_ The base.
     * @param e_ The exponent.
     * @param m_ The modulus.
     */
    function modexpAssign(call512 call_, uint512 b_, uint512 e_, uint512 m_) internal view {
        unchecked {
            _modexp(call_, b_, e_, m_, b_);
        }
    }

    /**
     * @notice Performs modular exponentiation and stores the result in a separate 512-bit unsigned integer.
     * @dev Assigns the result of `(b_^e_) % m_` to `to_`.
     * @param call_ A memory pointer for precompile call arguments.
     * @param b_ The base.
     * @param e_ The exponent.
     * @param m_ The modulus.
     * @param to_ The target 512-bit unsigned integer to store the result.
     */
    function modexpAssignTo(
        call512 call_,
        uint512 b_,
        uint512 e_,
        uint512 m_,
        uint512 to_
    ) internal view {
        unchecked {
            _modexp(call_, b_, e_, m_, to_);
        }
    }

    /**
     * @notice Performs modular exponentiation on 512-bit unsigned integers.
     * @param call_ A memory pointer for precompile call arguments.
     * @param b_ The base.
     * @param e_ The exponent.
     * @param m_ The modulus.
     * @return r_ The result of modular exponentiation `(b_^e_) % m_`.
     */
    function modexpU256(
        call512 call_,
        uint512 b_,
        uint256 e_,
        uint512 m_
    ) internal view returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            _modexpU256(call_, b_, e_, m_, r_);
        }
    }

    /**
     * @notice Performs modular exponentiation of a 512-bit unsigned integer base and a 256-bit unsigned integer exponent.
     * @dev Allocates memory for `call` every time it's called.
     * @param b_ The base.
     * @param e_ The exponent.
     * @param m_ The modulus.
     * @return r_ The result of modular exponentiation `(b_^e_) % m_`.
     */
    function modexpU256(uint512 b_, uint256 e_, uint512 m_) internal view returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));
            call512 call_ = initCall();

            _modexpU256(call_, b_, e_, m_, r_);
        }
    }

    /**
     * @notice Performs modular exponentiation of a 512-bit unsigned integer base and a 256-bit unsigned integer exponent.
     * @dev Updates the value of `b_` to `(b_^e_) % m_`.
     * @param call_ A memory pointer for precompile call arguments.
     * @param b_ The base.
     * @param e_ The exponent.
     * @param m_ The modulus.
     */
    function modexpU256Assign(call512 call_, uint512 b_, uint256 e_, uint512 m_) internal view {
        unchecked {
            _modexpU256(call_, b_, e_, m_, b_);
        }
    }

    /**
     * @notice Performs modular exponentiation of a 512-bit unsigned integer base and a 256-bit unsigned integer exponent.
     * @dev Assigns the result of `(b_^e_) % m_` to `to_`.
     * @param call_ A memory pointer for precompile call arguments.
     * @param b_ The base.
     * @param e_ The exponent.
     * @param m_ The modulus.
     * @param to_ The target 512-bit unsigned integer to store the result.
     */
    function modexpU256AssignTo(
        call512 call_,
        uint512 b_,
        uint256 e_,
        uint512 m_,
        uint512 to_
    ) internal view {
        unchecked {
            _modexpU256(call_, b_, e_, m_, to_);
        }
    }

    /**
     * @notice Adds two 512-bit unsigned integers under a modulus.
     * @param call_ A memory pointer for precompile call arguments.
     * @param a_ The first addend.
     * @param b_ The second addend.
     * @param m_ The modulus.
     * @return r_ The result of the modular addition `(a_ + b_) % m_`.
     */
    function modadd(
        call512 call_,
        uint512 a_,
        uint512 b_,
        uint512 m_
    ) internal view returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            _modadd(call_, a_, b_, m_, r_);
        }
    }

    /**
     * @notice Adds two 512-bit unsigned integers under a modulus.
     * @dev Allocates memory for `call` every time it's called.
     * @param a_ The first addend.
     * @param b_ The second addend.
     * @param m_ The modulus.
     * @return r_ The result of the modular addition `(a_ + b_) % m_`.
     */
    function modadd(uint512 a_, uint512 b_, uint512 m_) internal view returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));
            call512 call_ = initCall();

            _modadd(call_, a_, b_, m_, r_);
        }
    }

    /**
     * @notice Performs modular addition assignment on the first 512-bit unsigned integer addend.
     * @dev Updates the value of `a_` to `(a_ + b_) % m_`.
     * @param call_ A memory pointer for precompile call arguments.
     * @param a_ The first addend.
     * @param b_ The second addend.
     * @param m_ The modulus.
     */
    function modaddAssign(call512 call_, uint512 a_, uint512 b_, uint512 m_) internal view {
        unchecked {
            _modadd(call_, a_, b_, m_, a_);
        }
    }

    /**
     * @notice Performs modular addition and stores the result in a separate 512-bit unsigned integer.
     * @dev Assigns the result of `(a_ + b_) % m_` to `to_`.
     * @param call_ A memory pointer for precompile call arguments.
     * @param a_ The first addend.
     * @param b_ The second addend.
     * @param m_ The modulus.
     * @param to_ The target 512-bit unsigned integer to store the result.
     */
    function modaddAssignTo(
        call512 call_,
        uint512 a_,
        uint512 b_,
        uint512 m_,
        uint512 to_
    ) internal view {
        unchecked {
            _modadd(call_, a_, b_, m_, to_);
        }
    }

    /**
     * @notice Adds two 512-bit unsigned integers.
     * @param a_ The first addend.
     * @param b_ The second addend.
     * @return r_ The result of the addition.
     */
    function add(uint512 a_, uint512 b_) internal pure returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            _add(a_, b_, r_);
        }
    }

    /**
     * @notice Performs addition assignment on the first 512-bit unsigned addend.
     * @dev Updates the value of `a_` to `a_ + b_`.
     * @param a_ The first addend.
     * @param b_ The second addend.
     */
    function addAssign(uint512 a_, uint512 b_) internal pure {
        unchecked {
            _add(a_, b_, a_);
        }
    }

    /**
     * @notice Performs addition and stores the result in a separate 512-bit unsigned integer.
     * @dev Assigns the result of `a_ + b_` to `to_`.
     * @param a_ The first addend.
     * @param b_ The second addend.
     * @param to_ The target 512-bit unsigned integer to store the result.
     */
    function addAssignTo(uint512 a_, uint512 b_, uint512 to_) internal pure {
        unchecked {
            _add(a_, b_, to_);
        }
    }

    /**
     * @notice Adds two 512-bit unsigned integers under a modulus.
     * @dev This is an optimized version of `modadd` where the inputs must be pre-reduced by `m_`.
     * @param call_ A memory pointer for precompile call arguments.
     * @param a_ The first addend, reduced by `m_`.
     * @param b_ The second addend, reduced by `m_`.
     * @param m_ The modulus.
     * @return r_ The result of the modular addition `(a_ + b_) % m_`.
     */
    function redadd(
        call512 call_,
        uint512 a_,
        uint512 b_,
        uint512 m_
    ) internal pure returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            _redadd(call_, a_, b_, m_, r_);
        }
    }

    /**
     * @notice Adds two 512-bit unsigned integers under a modulus.
     * @dev This is an optimized version of `modadd` where the inputs must be pre-reduced by `m_`.
     * @dev Allocates memory for `call` every time it's called.
     * @param a_ The first addend, reduced by `m_`.
     * @param b_ The second addend, reduced by `m_`.
     * @param m_ The modulus.
     * @return r_ The result of the modular addition `(a_ + b_) % m_`.
     */
    function redadd(uint512 a_, uint512 b_, uint512 m_) internal pure returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            // `redadd` doesn't make calls, it only requires 2 words for buffer.
            call512 call_ = call512.wrap(_allocate(_UINT512_ALLOCATION));

            _redadd(call_, a_, b_, m_, r_);
        }
    }

    /**
     * @notice Performs modular addition assignment on the first 512-bit unsigned integer addend.
     * @dev This is an optimized version of `modaddAssign` where the inputs must be pre-reduced by `m_`.
     * @param call_ A memory pointer for precompile call arguments.
     * @param a_ The first addend, reduced by `m_`.
     * @param b_ The second addend, reduced by `m_`.
     * @param m_ The modulus.
     */
    function redaddAssign(call512 call_, uint512 a_, uint512 b_, uint512 m_) internal pure {
        unchecked {
            _redadd(call_, a_, b_, m_, a_);
        }
    }

    /**
     * @notice Performs modular addition and stores the result in a separate 512-bit unsigned integer.
     * @dev This is an optimized version of `modaddAssignTo` where the inputs must be pre-reduced by `m_`.
     * @param call_ A memory pointer for precompile call arguments.
     * @param a_ The first addend, reduced by `m_`.
     * @param b_ The second addend, reduced by `m_`.
     * @param m_ The modulus.
     * @param to_ The target 512-bit unsigned integer to store the result.
     */
    function redaddAssignTo(
        call512 call_,
        uint512 a_,
        uint512 b_,
        uint512 m_,
        uint512 to_
    ) internal pure {
        unchecked {
            _redadd(call_, a_, b_, m_, to_);
        }
    }

    /**
     * @notice Subtracts one 512-bit unsigned integer from another under a modulus.
     * @param call_ A memory pointer for precompile call arguments.
     * @param a_ The minuend.
     * @param b_ The subtrahend.
     * @param m_ The modulus.
     * @return r_ The result of the modular subtraction `(a_ - b_) % m_`.
     */
    function modsub(
        call512 call_,
        uint512 a_,
        uint512 b_,
        uint512 m_
    ) internal view returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            _modsub(call_, a_, b_, m_, r_);
        }
    }

    /**
     * @notice Subtracts one 512-bit unsigned integer from another under a modulus.
     * @dev Allocates memory for `call` every time it's called.
     * @param a_ The minuend.
     * @param b_ The subtrahend.
     * @param m_ The modulus.
     * @return r_ The result of the modular subtraction `(a_ - b_) % m_`.
     */
    function modsub(uint512 a_, uint512 b_, uint512 m_) internal view returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));
            call512 call_ = initCall();

            _modsub(call_, a_, b_, m_, r_);
        }
    }

    /**
     * @notice Performs modular subtraction assignment on the 512-bit unsigned integer minuend.
     * @param call_ A memory pointer for precompile call arguments.
     * @param a_ The minuend.
     * @param b_ The subtrahend.
     * @param m_ The modulus.
     */
    function modsubAssign(call512 call_, uint512 a_, uint512 b_, uint512 m_) internal view {
        unchecked {
            _modsub(call_, a_, b_, m_, a_);
        }
    }

    /**
     * @notice Performs modular subtraction and stores the result in a separate 512-bit unsigned integer.
     * @param call_ A memory pointer for precompile call arguments.
     * @param a_ The minuend.
     * @param b_ The subtrahend.
     * @param m_ The modulus.
     * @param to_ The target 512-bit unsigned integer to store the result.
     */
    function modsubAssignTo(
        call512 call_,
        uint512 a_,
        uint512 b_,
        uint512 m_,
        uint512 to_
    ) internal view {
        unchecked {
            _modsub(call_, a_, b_, m_, to_);
        }
    }

    /**
     * @notice Subtracts one 512-bit unsigned integer from another.
     * @param a_ The minuend.
     * @param b_ The subtrahend.
     * @return r_ The result of the subtraction.
     */
    function sub(uint512 a_, uint512 b_) internal pure returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            _sub(a_, b_, r_);
        }
    }

    /**
     * @notice Performs subtraction assignment on the 512-bit unsigned minuend.
     * @dev Updates the value of `a_` to `a_ - b_`.
     * @param a_ The minuend.
     * @param b_ The subtrahend.
     */
    function subAssign(uint512 a_, uint512 b_) internal pure {
        unchecked {
            _sub(a_, b_, a_);
        }
    }

    /**
     * @notice Performs subtraction and stores the result in a separate 512-bit unsigned integer.
     * @dev Assigns the result of `a_ - b_` to `to_`.
     * @param a_ The minuend.
     * @param b_ The subtrahend.
     * @param to_ The target 512-bit unsigned integer to store the result.
     */
    function subAssignTo(uint512 a_, uint512 b_, uint512 to_) internal pure {
        unchecked {
            _sub(a_, b_, to_);
        }
    }

    /**
     * @notice Subtracts one 512-bit unsigned integer from another under a modulus.
     * @dev This is an optimized version of `modsub` where the inputs must be pre-reduced by `m_`.
     * @param call_ A memory pointer for precompile call arguments.
     * @param a_ The minuend, reduced by `m_`.
     * @param b_ The subtrahend, reduced by `m_`.
     * @param m_ The modulus.
     * @return r_ The result of the modular subtraction `(a_ - b_) % m_`.
     */
    function redsub(
        call512 call_,
        uint512 a_,
        uint512 b_,
        uint512 m_
    ) internal pure returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            _redsub(call_, a_, b_, m_, r_);
        }
    }

    /**
     * @notice Subtracts one 512-bit unsigned integer from another under a modulus.
     * @dev This is an optimized version of `modsub` where the inputs must be pre-reduced by `m_`.
     * @dev Allocates memory for `call` every time it's called.
     * @param a_ The minuend, reduced by `m_`.
     * @param b_ The subtrahend, reduced by `m_`.
     * @param m_ The modulus.
     * @return r_ The result of the modular subtraction `(a_ - b_) % m_`.
     */
    function redsub(uint512 a_, uint512 b_, uint512 m_) internal pure returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            // `redsub` doesn't make calls, it only requires 2 words for buffer.
            call512 call_ = call512.wrap(_allocate(_UINT512_ALLOCATION));

            _redsub(call_, a_, b_, m_, r_);
        }
    }

    /**
     * @notice Performs modular subtraction assignment on the 512-bit unsigned integer minuend.
     * @dev This is an optimized version of `modsubAssign` where the inputs must be pre-reduced by `m_`.
     * @param call_ A memory pointer for precompile call arguments.
     * @param a_ The minuend, reduced by `m_`.
     * @param b_ The subtrahend, reduced by `m_`.
     * @param m_ The modulus.
     */
    function redsubAssign(call512 call_, uint512 a_, uint512 b_, uint512 m_) internal pure {
        unchecked {
            _redsub(call_, a_, b_, m_, a_);
        }
    }

    /**
     * @notice Performs modular subtraction and stores the result in a separate 512-bit unsigned integer.
     * @dev This is an optimized version of `modsubAssignTo` where the inputs must be pre-reduced by `m_`.
     * @param call_ A memory pointer for precompile call arguments.
     * @param a_ The minuend, reduced by `m_`.
     * @param b_ The subtrahend, reduced by `m_`.
     * @param m_ The modulus.
     * @param to_ The target 512-bit unsigned integer to store the result.
     */
    function redsubAssignTo(
        call512 call_,
        uint512 a_,
        uint512 b_,
        uint512 m_,
        uint512 to_
    ) internal pure {
        unchecked {
            _redsub(call_, a_, b_, m_, to_);
        }
    }

    /**
     * @notice Multiplies two 512-bit unsigned integers under a modulus.
     * @param call_ A memory pointer for precompile call arguments.
     * @param a_ The first factor.
     * @param b_ The second factor.
     * @param m_ The modulus.
     * @return r_ The result of the modular multiplication `(a_ * b_) % m_`.
     */
    function modmul(
        call512 call_,
        uint512 a_,
        uint512 b_,
        uint512 m_
    ) internal view returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            _modmul(call_, a_, b_, m_, r_);
        }
    }

    /**
     * @notice Multiplies two 512-bit unsigned integers under a modulus.
     * @dev Allocates memory for `call` every time it's called.
     * @param a_ The first factor.
     * @param b_ The second factor.
     * @param m_ The modulus.
     * @return r_ The result of the modular multiplication `(a_ * b_) % m_`.
     */
    function modmul(uint512 a_, uint512 b_, uint512 m_) internal view returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));
            call512 call_ = initCall();

            _modmul(call_, a_, b_, m_, r_);
        }
    }

    /**
     * @notice Performs modular multiplication assignment on the first 512-bit unsigned integer factor.
     * @dev Updates the value of `a_` to `(a_ * b_) % m_`.
     * @param call_ A memory pointer for precompile call arguments.
     * @param a_ The first factor.
     * @param b_ The second factor.
     * @param m_ The modulus.
     */
    function modmulAssign(call512 call_, uint512 a_, uint512 b_, uint512 m_) internal view {
        unchecked {
            _modmul(call_, a_, b_, m_, a_);
        }
    }

    /**
     * @notice Performs modular multiplication and stores the result in a separate 512-bit unsigned integer.
     * @dev Assigns the result of `(a_ * b_) % m_` to `to_`.
     * @param call_ A memory pointer for precompile call arguments.
     * @param a_ The first factor.
     * @param b_ The second factor.
     * @param m_ The modulus.
     * @param to_ The target 512-bit unsigned integer to store the result.
     */
    function modmulAssignTo(
        call512 call_,
        uint512 a_,
        uint512 b_,
        uint512 m_,
        uint512 to_
    ) internal view {
        unchecked {
            _modmul(call_, a_, b_, m_, to_);
        }
    }

    /**
     * @notice Multiplies two 512-bit unsigned integers.
     * @param a_ The first factor.
     * @param b_ The second factor.
     * @return r_ The result of the multiplication.
     */
    function mul(uint512 a_, uint512 b_) internal pure returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            _mul(a_, b_, r_);
        }
    }

    /**
     * @notice Performs multiplication assignment on the first 512-bit unsigned factor.
     * @dev Updates the value of `a_` to `a_ * b_`.
     * @param a_ The first factor.
     * @param b_ The second factor.
     */
    function mulAssign(uint512 a_, uint512 b_) internal pure {
        unchecked {
            _mul(a_, b_, a_);
        }
    }

    /**
     * @notice Performs multiplication and stores the result in a separate 512-bit unsigned integer.
     * @dev Assigns the result of `a_ * b_` to `to_`.
     * @param a_ The first factor.
     * @param b_ The second factor.
     * @param to_ The target 512-bit unsigned integer to store the result.
     */
    function mulAssignTo(uint512 a_, uint512 b_, uint512 to_) internal pure {
        unchecked {
            _mul(a_, b_, to_);
        }
    }

    /**
     * @notice Divides two 512-bit unsigned integers under a modulus.
     * @dev IMPORTANT: The modulus `m_` must be a prime number.
     * @dev Returns the result of `(a_ * b_^(-1)) % m_`.
     * @param call_ A memory pointer for precompile call arguments.
     * @param a_ The dividend.
     * @param b_ The divisor.
     * @param m_ The modulus.
     * @return r_ The result of the modular division.
     */
    function moddiv(
        call512 call_,
        uint512 a_,
        uint512 b_,
        uint512 m_
    ) internal view returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            _moddiv(call_, a_, b_, m_, r_);
        }
    }

    /**
     * @notice Divides two 512-bit unsigned integers under a modulus.
     * @dev IMPORTANT: The modulus `m_` must be a prime number.
     * @dev Returns the result of `(a_ * b_^(-1)) % m_`.
     * @dev Allocates memory for `call` every time it's called.
     * @param a_ The dividend.
     * @param b_ The divisor.
     * @param m_ The modulus.
     * @return r_ The result of the modular division.
     */
    function moddiv(uint512 a_, uint512 b_, uint512 m_) internal view returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));
            call512 call_ = initCall();

            _moddiv(call_, a_, b_, m_, r_);
        }
    }

    /**
     * @notice Performs the modular division assignment on a 512-bit unsigned dividend.
     * @dev IMPORTANT: The modulus `m_` must be a prime number.
     * @dev Updates the value of `a_` to `(a_ * b_^(-1)) % m_`.
     * @param call_ A memory pointer for precompile call arguments.
     * @param a_ The dividend.
     * @param b_ The divisor.
     * @param m_ The modulus.
     */
    function moddivAssign(call512 call_, uint512 a_, uint512 b_, uint512 m_) internal view {
        unchecked {
            _moddiv(call_, a_, b_, m_, a_);
        }
    }

    /**
     * @notice Performs the modular division and stores the result in a separate 512-bit unsigned integer.
     * @dev IMPORTANT: The modulus `m_` must be a prime number.
     * @dev Assigns the result of `(a_ * b_^(-1)) % m_` to `to_`.
     * @param call_ A memory pointer for precompile call arguments.
     * @param a_ The dividend.
     * @param b_ The divisor.
     * @param m_ The modulus.
     * @param to_ The target 512-bit unsigned integer to store the result.
     */
    function moddivAssignTo(
        call512 call_,
        uint512 a_,
        uint512 b_,
        uint512 m_,
        uint512 to_
    ) internal view {
        unchecked {
            _moddiv(call_, a_, b_, m_, to_);
        }
    }

    /**
     * @notice Performs bitwise AND of two 512-bit unsigned integers.
     * @param a_ The first 512-bit unsigned integer.
     * @param b_ The second 512-bit unsigned integer.
     * @return r_ The result of the bitwise AND operation.
     */
    function and(uint512 a_, uint512 b_) internal pure returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            _and(a_, b_, r_);
        }
    }

    /**
     * @notice Performs bitwise AND assignment on the first 512-bit unsigned integer.
     * @dev Updates the value of `a_` to `a_ & b_`.
     * @param a_ The first 512-bit unsigned integer.
     * @param b_ The second 512-bit unsigned integer.
     */
    function andAssign(uint512 a_, uint512 b_) internal pure {
        unchecked {
            _and(a_, b_, a_);
        }
    }

    /**
     * @notice Performs bitwise AND and stores the result in a separate 512-bit unsigned integer.
     * @dev Assigns the result of `a_ & b_` to `to_`.
     * @param a_ The first 512-bit unsigned integer.
     * @param b_ The second 512-bit unsigned integer.
     * @param to_ The target 512-bit unsigned integer to store the result.
     */
    function andAssignTo(uint512 a_, uint512 b_, uint512 to_) internal pure {
        unchecked {
            _and(a_, b_, to_);
        }
    }

    /**
     * @notice Performs bitwise OR of two 512-bit unsigned integers.
     * @param a_ The first 512-bit unsigned integer.
     * @param b_ The second 512-bit unsigned integer.
     * @return r_ The result of the bitwise OR operation.
     */
    function or(uint512 a_, uint512 b_) internal pure returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            _or(a_, b_, r_);
        }
    }

    /**
     * @notice Performs bitwise OR assignment on the first 512-bit unsigned integer.
     * @dev Updates the value of `a_` to `a_ | b_`.
     * @param a_ The first 512-bit unsigned integer.
     * @param b_ The second 512-bit unsigned integer.
     */
    function orAssign(uint512 a_, uint512 b_) internal pure {
        unchecked {
            _or(a_, b_, a_);
        }
    }

    /**
     * @notice Performs bitwise OR and stores the result in a separate 512-bit unsigned integer.
     * @dev Assigns the result of `a_ | b_` to `to_`.
     * @param a_ The first 512-bit unsigned integer.
     * @param b_ The second 512-bit unsigned integer.
     * @param to_ The target 512-bit unsigned integer to store the result.
     */
    function orAssignTo(uint512 a_, uint512 b_, uint512 to_) internal pure {
        unchecked {
            _or(a_, b_, to_);
        }
    }

    /**
     * @notice Performs bitwise XOR of two 512-bit unsigned integers.
     * @param a_ The first 512-bit unsigned integer.
     * @param b_ The second 512-bit unsigned integer.
     * @return r_ The result of the bitwise XOR operation.
     */
    function xor(uint512 a_, uint512 b_) internal pure returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            _xor(a_, b_, r_);
        }
    }

    /**
     * @notice Performs bitwise XOR assignment on the first 512-bit unsigned integer.
     * @dev Updates the value of `a_` to `a_ ^ b_`.
     * @param a_ The first 512-bit unsigned integer.
     * @param b_ The second 512-bit unsigned integer.
     */
    function xorAssign(uint512 a_, uint512 b_) internal pure {
        unchecked {
            _xor(a_, b_, a_);
        }
    }

    /**
     * @notice Performs bitwise XOR and stores the result in a separate 512-bit unsigned integer.
     * @dev Assigns the result of `a_ ^ b_` to `to_`.
     * @param a_ The first 512-bit unsigned integer.
     * @param b_ The second 512-bit unsigned integer.
     * @param to_ The target 512-bit unsigned integer to store the result.
     */
    function xorAssignTo(uint512 a_, uint512 b_, uint512 to_) internal pure {
        unchecked {
            _xor(a_, b_, to_);
        }
    }

    /**
     * @notice Performs bitwise NOT of a 512-bit unsigned integer.
     * @param a_ The 512-bit unsigned integer.
     * @return r_ The result of the bitwise NOT operation.
     */
    function not(uint512 a_) internal pure returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            _not(a_, r_);
        }
    }

    /**
     * @notice Performs bitwise NOT assignment on a 512-bit unsigned integer.
     * @dev Updates the value of `a_` to `~a_`.
     * @param a_ The 512-bit unsigned integer.
     */
    function notAssign(uint512 a_) internal pure {
        unchecked {
            _not(a_, a_);
        }
    }

    /**
     * @notice Performs bitwise NOT and stores the result in a separate 512-bit unsigned integer.
     * @dev Assigns the result of `~a_` to `to_`.
     * @param a_ The 512-bit unsigned integer.
     * @param to_ The target 512-bit unsigned integer to store the result.
     */
    function notAssignTo(uint512 a_, uint512 to_) internal pure {
        unchecked {
            _not(a_, to_);
        }
    }

    /**
     * @notice Shifts a 512-bit unsigned integer to the left by a specified number of bits.
     * @param a_ The 512-bit unsigned integer to shift.
     * @param b_ The number of bits to shift by.
     * @return r_ The result of the left shift operation.
     */
    function shl(uint512 a_, uint8 b_) internal pure returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            _shl(a_, b_, r_);
        }
    }

    /**
     * @notice Shifts a 512-bit unsigned integer to the left by a specified number of bits.
     * @dev Updates the value of `a_` to `a_ << b_`.
     * @param a_ The 512-bit unsigned integer to shift.
     * @param b_ The number of bits to shift by.
     */
    function shlAssign(uint512 a_, uint8 b_) internal pure {
        unchecked {
            _shl(a_, b_, a_);
        }
    }

    /**
     * @notice Shifts a 512-bit unsigned integer to the left by a specified number of bits.
     * @dev Assigns the result of `a_ << b_` to `to_`.
     * @param a_ The 512-bit unsigned integer to shift.
     * @param b_ The number of bits to shift by.
     * @param to_ The target 512-bit unsigned integer to store the result.
     */
    function shlAssignTo(uint512 a_, uint8 b_, uint512 to_) internal pure {
        unchecked {
            _shl(a_, b_, to_);
        }
    }

    /**
     * @notice Shifts a 512-bit unsigned integer to the right by a specified number of bits.
     * @param a_ The 512-bit unsigned integer to shift.
     * @param b_ The number of bits to shift by.
     * @return r_ The result of the right shift operation.
     */
    function shr(uint512 a_, uint8 b_) internal pure returns (uint512 r_) {
        unchecked {
            r_ = uint512.wrap(_allocate(_UINT512_ALLOCATION));

            _shr(a_, b_, r_);
        }
    }

    /**
     * @notice Shifts a 512-bit unsigned integer to the right by a specified number of bits.
     * @dev Updates the value of `a_` to `a_ >> b_`.
     * @param a_ The 512-bit unsigned integer to shift.
     * @param b_ The number of bits to shift by.
     */
    function shrAssign(uint512 a_, uint8 b_) internal pure {
        unchecked {
            _shr(a_, b_, a_);
        }
    }

    /**
     * @notice Shifts a 512-bit unsigned integer to the right by a specified number of bits.
     * @dev Assigns the result of `a_ >> b_` to `to_`.
     * @param a_ The 512-bit unsigned integer to shift.
     * @param b_ The number of bits to shift by.
     * @param to_ The target 512-bit unsigned integer to store the result.
     */
    function shrAssignTo(uint512 a_, uint8 b_, uint512 to_) internal pure {
        unchecked {
            _shr(a_, b_, to_);
        }
    }

    /**
     * @notice Performs modular arithmetic using the EVM precompiled contract.
     * @dev Computes `(a_ % m_)` and stores the result in `r_`.
     */
    function _mod(call512 call_, uint512 a_, uint512 m_, uint512 r_) private view {
        unchecked {
            assembly {
                mstore(call_, 0x40)
                mstore(add(call_, 0x20), 0x20)
                mstore(add(call_, 0x40), 0x40)
                mstore(add(call_, 0x60), mload(a_))
                mstore(add(call_, 0x80), mload(add(a_, 0x20)))
                mstore(add(call_, 0xA0), 0x01)
                mstore(add(call_, 0xC0), mload(m_))
                mstore(add(call_, 0xE0), mload(add(m_, 0x20)))

                pop(staticcall(gas(), 0x5, call_, 0x0100, r_, 0x40))
            }
        }
    }

    /**
     * @notice Performs modular exponentiation using the EVM precompiled contract.
     * @dev Computes `(a_^e_) % m_` and stores the result in `r_`.
     */
    function _modexp(call512 call_, uint512 a_, uint512 e_, uint512 m_, uint512 r_) private view {
        unchecked {
            assembly {
                mstore(call_, 0x40)
                mstore(add(call_, 0x20), 0x40)
                mstore(add(call_, 0x40), 0x40)
                mstore(add(call_, 0x60), mload(a_))
                mstore(add(call_, 0x80), mload(add(a_, 0x20)))
                mstore(add(call_, 0xA0), mload(e_))
                mstore(add(call_, 0xC0), mload(add(e_, 0x20)))
                mstore(add(call_, 0xE0), mload(m_))
                mstore(add(call_, 0x0100), mload(add(m_, 0x20)))

                pop(staticcall(gas(), 0x5, call_, 0x0120, r_, 0x40))
            }
        }
    }

    /**
     * @notice Performs modular exponentiation using the EVM precompiled contract.
     * @dev Computes `(a_^e_) % m_` and stores the result in `r_`.
     */
    function _modexpU256(
        call512 call_,
        uint512 a_,
        uint256 e_,
        uint512 m_,
        uint512 r_
    ) private view {
        unchecked {
            assembly {
                mstore(call_, 0x40)
                mstore(add(call_, 0x20), 0x20)
                mstore(add(call_, 0x40), 0x40)
                mstore(add(call_, 0x60), mload(a_))
                mstore(add(call_, 0x80), mload(add(a_, 0x20)))
                mstore(add(call_, 0xA0), e_)
                mstore(add(call_, 0xC0), mload(m_))
                mstore(add(call_, 0xE0), mload(add(m_, 0x20)))

                pop(staticcall(gas(), 0x5, call_, 0x0100, r_, 0x40))
            }
        }
    }

    /**
     * @notice Computes the modular inverse using the EVM precompiled contract.
     * @dev The modulus `m_` must be a prime number.
     * @dev Computes `a_^(-1) % m_` and stores the result in `r_`.
     */
    function _modinv(call512 call_, uint512 a_, uint512 m_, uint512 r_) private view {
        unchecked {
            uint512 buffer_ = _buffer(call_);

            assembly {
                mstore(buffer_, 0x00)
                mstore(add(buffer_, 0x20), 0x02)
            }

            _sub(m_, buffer_, buffer_);

            assembly {
                mstore(call_, 0x40)
                mstore(add(0x20, call_), 0x40)
                mstore(add(0x40, call_), 0x40)
                mstore(add(0x60, call_), mload(a_))
                mstore(add(0x80, call_), mload(add(a_, 0x20)))
                mstore(add(0xA0, call_), mload(buffer_))
                mstore(add(0xC0, call_), mload(add(buffer_, 0x20)))
                mstore(add(0xE0, call_), mload(m_))
                mstore(add(0x0100, call_), mload(add(m_, 0x20)))

                pop(staticcall(gas(), 0x5, call_, 0x0120, r_, 0x40))
            }
        }
    }

    /**
     * @notice Performs addition of two 512-bit unsigned integers.
     * @dev Computes `a_ + b_` and stores the result in `r_`.
     */
    function _add(uint512 a_, uint512 b_, uint512 r_) private pure {
        unchecked {
            assembly {
                let aWord_ := mload(add(a_, 0x20))
                let sum_ := add(aWord_, mload(add(b_, 0x20)))

                mstore(add(r_, 0x20), sum_)

                sum_ := gt(aWord_, sum_)
                sum_ := add(sum_, add(mload(a_), mload(b_)))

                mstore(r_, sum_)
            }
        }
    }

    /**
     * @notice Performs modular addition using the EVM precompiled contract.
     * @dev Computes `(a_ + b_) % m_` and stores the result in `r_`.
     */
    function _modadd(call512 call_, uint512 a_, uint512 b_, uint512 m_, uint512 r_) private view {
        unchecked {
            assembly {
                let aWord_ := mload(add(a_, 0x20))
                let sum_ := add(aWord_, mload(add(b_, 0x20)))

                mstore(add(call_, 0xA0), sum_)

                sum_ := gt(aWord_, sum_)
                sum_ := add(sum_, add(mload(a_), mload(b_)))

                mstore(add(call_, 0x80), sum_)
                mstore(add(call_, 0x60), gt(mload(a_), sum_))

                mstore(call_, 0x60)
                mstore(add(call_, 0x20), 0x20)
                mstore(add(call_, 0x40), 0x40)
                mstore(add(call_, 0xC0), 0x01)
                mstore(add(call_, 0xE0), mload(m_))
                mstore(add(call_, 0x0100), mload(add(m_, 0x20)))

                pop(staticcall(gas(), 0x5, call_, 0x0120, r_, 0x40))
            }
        }
    }

    /**
     * @notice Performs reduced modular addition of two 512-bit unsigned integers.
     * @dev Computes `(a_ + b_) % m_` assuming `a_` and `b_` are already reduced by `m_`.
     */
    function _redadd(call512 call_, uint512 a_, uint512 b_, uint512 m_, uint512 r_) private pure {
        unchecked {
            uint512 buffer_ = _buffer(call_);
            bool overflowed_;

            assembly {
                let aWord_ := mload(add(a_, 0x20))
                let sum_ := add(aWord_, mload(add(b_, 0x20)))

                mstore(add(buffer_, 0x20), sum_)

                sum_ := gt(aWord_, sum_)
                sum_ := add(sum_, add(mload(a_), mload(b_)))

                mstore(buffer_, sum_)
                overflowed_ := gt(mload(a_), sum_)
            }

            if (overflowed_ || cmp(buffer_, m_) >= 0) {
                _sub(buffer_, m_, r_);
                return;
            }

            assign(buffer_, r_);
        }
    }

    /**
     * @notice Performs subtraction of two 512-bit unsigned integers.
     * @dev Computes `a_ - b_` and stores the result in `r_`.
     */
    function _sub(uint512 a_, uint512 b_, uint512 r_) private pure {
        unchecked {
            assembly {
                let aWord_ := mload(add(a_, 0x20))
                let diff_ := sub(aWord_, mload(add(b_, 0x20)))

                mstore(add(r_, 0x20), diff_)

                diff_ := gt(diff_, aWord_)
                diff_ := sub(sub(mload(a_), mload(b_)), diff_)

                mstore(r_, diff_)
            }
        }
    }

    /**
     * @notice Performs modular subtraction using the EVM precompiled contract.
     * @dev Computes `(a_ - b_) % m_` and stores the result in `r_`.
     */
    function _modsub(call512 call_, uint512 a_, uint512 b_, uint512 m_, uint512 r_) private view {
        unchecked {
            int256 cmp_ = cmp(a_, b_);

            if (cmp_ >= 0) {
                _sub(a_, b_, r_);
            } else {
                _sub(b_, a_, r_);
            }

            assembly {
                mstore(call_, 0x40)
                mstore(add(call_, 0x20), 0x20)
                mstore(add(call_, 0x40), 0x40)
                mstore(add(call_, 0x60), mload(r_))
                mstore(add(call_, 0x80), mload(add(r_, 0x20)))
                mstore(add(call_, 0xA0), 0x01)
                mstore(add(call_, 0xC0), mload(m_))
                mstore(add(call_, 0xE0), mload(add(m_, 0x20)))

                pop(staticcall(gas(), 0x5, call_, 0x0100, r_, 0x40))
            }

            if (cmp_ < 0) {
                _sub(m_, r_, r_);
            }
        }
    }

    /**
     * @notice Performs reduced modular subtraction of two 512-bit unsigned integers.
     * @dev Computes `(a_ - b_) % m_` assuming `a_` and `b_` are already reduced by `m_`.
     */
    function _redsub(call512 call_, uint512 a_, uint512 b_, uint512 m_, uint512 r_) private pure {
        unchecked {
            if (cmp(a_, b_) >= 0) {
                _sub(a_, b_, r_);
                return;
            }

            uint512 buffer_ = _buffer(call_);

            _add(a_, m_, buffer_);
            _sub(buffer_, b_, r_);
        }
    }

    /**
     * @notice Multiplies two 512-bit unsigned integers.
     * @dev Computes `a_ * b_` and stores the result in `r_`.
     * @dev Generalizes the "muldiv" algorithm to split 512-bit unsigned integers into chunks, as detailed at https://xn--2-umb.com/21/muldiv/.
     */
    function _mul(uint512 a_, uint512 b_, uint512 r_) private pure {
        unchecked {
            assembly {
                let a0_ := mload(a_)
                let a1_ := mload(add(a_, 0x20))
                let b0_ := mload(b_)
                let b1_ := mload(add(b_, 0x20))

                let mm_ := mulmod(
                    a1_,
                    b1_,
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                )
                let c3_ := mul(a1_, b1_)
                let c2_ := sub(sub(mm_, c3_), lt(mm_, c3_))

                c2_ := add(c2_, mul(a0_, b1_))
                c2_ := add(c2_, mul(a1_, b0_))

                mstore(add(r_, 0x20), c3_)
                mstore(r_, c2_)
            }
        }
    }

    /**
     * @notice Prepares intermediate results for modular multiplication.
     * @dev Calculates partial products and stores them in `call_` for further processing.
     * @dev Generalizes the "muldiv" algorithm to split 512-bit unsigned integers into chunks, as detailed at https://xn--2-umb.com/21/muldiv/.
     */
    function _modmul2p(call512 call_, uint512 a_, uint512 b_) private pure {
        unchecked {
            assembly {
                let a0_ := mload(a_)
                let a1_ := mload(add(a_, 0x20))
                let b0_ := mload(b_)
                let b1_ := mload(add(b_, 0x20))

                let mm_ := mulmod(
                    a1_,
                    b1_,
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                )
                let c3_ := mul(a1_, b1_)
                let c2_ := sub(sub(mm_, c3_), lt(mm_, c3_))

                mm_ := mulmod(
                    a0_,
                    b1_,
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                )
                let prod1_ := mul(a0_, b1_)
                let prod0_ := sub(sub(mm_, prod1_), lt(mm_, prod1_))

                c2_ := add(c2_, prod1_)
                let c1_ := lt(c2_, prod1_)
                c1_ := add(c1_, prod0_)
                let c0_ := lt(c1_, prod0_)

                mm_ := mulmod(
                    a1_,
                    b0_,
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                )
                prod1_ := mul(a1_, b0_)
                prod0_ := sub(sub(mm_, prod1_), lt(mm_, prod1_))

                c2_ := add(c2_, prod1_)
                c1_ := add(c1_, lt(c2_, prod1_))
                c1_ := add(c1_, prod0_)
                c0_ := add(c0_, lt(c1_, prod0_))

                mm_ := mulmod(
                    a0_,
                    b0_,
                    0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
                )
                prod1_ := mul(a0_, b0_)
                prod0_ := sub(sub(mm_, prod1_), lt(mm_, prod1_))

                c1_ := add(c1_, prod1_)
                c0_ := add(c0_, lt(c1_, prod1_))
                c0_ := add(c0_, prod0_)

                mstore(add(call_, 0xC0), c3_)
                mstore(add(call_, 0xA0), c2_)
                mstore(add(call_, 0x80), c1_)
                mstore(add(call_, 0x60), c0_)
            }
        }
    }

    /**
     * @notice Performs modular multiplication using the EVM precompiled contract.
     * @dev Computes `(a_ * b_) % m_` and stores the result in `r_`.
     */
    function _modmul(call512 call_, uint512 a_, uint512 b_, uint512 m_, uint512 r_) private view {
        unchecked {
            _modmul2p(call_, a_, b_);

            assembly {
                mstore(call_, 0x80)
                mstore(add(call_, 0x20), 0x20)
                mstore(add(call_, 0x40), 0x40)
                mstore(add(call_, 0xE0), 0x01)
                mstore(add(call_, 0x0100), mload(m_))
                mstore(add(call_, 0x0120), mload(add(m_, 0x20)))

                pop(staticcall(gas(), 0x5, call_, 0x0140, r_, 0x40))
            }
        }
    }

    /**
     * @notice Computes the modular division using the EVM precompiled contract.
     * @dev The modulus `m_` must be a prime number.
     * @dev Computes `(a_ * b_^(-1)) % m_` and stores the result in `r_`.
     */
    function _moddiv(call512 call_, uint512 a_, uint512 b_, uint512 m_, uint512 r_) private view {
        unchecked {
            uint512 buffer_ = _buffer(call_);

            _modinv(call_, b_, m_, buffer_);
            _modmul2p(call_, a_, buffer_);

            assembly {
                mstore(call_, 0x80)
                mstore(add(call_, 0x20), 0x20)
                mstore(add(call_, 0x40), 0x40)
                mstore(add(call_, 0xE0), 0x01)
                mstore(add(call_, 0x0100), mload(m_))
                mstore(add(call_, 0x0120), mload(add(m_, 0x20)))

                pop(staticcall(gas(), 0x5, call_, 0x0140, r_, 0x40))
            }
        }
    }

    /**
     * @notice Performs bitwise AND of two 512-bit unsigned integers.
     * @dev Computes `a_ & b_` and stores the result in `r_`.
     */
    function _and(uint512 a_, uint512 b_, uint512 r_) private pure {
        unchecked {
            assembly {
                mstore(r_, and(mload(a_), mload(b_)))
                mstore(add(r_, 0x20), and(mload(add(a_, 0x20)), mload(add(b_, 0x20))))
            }
        }
    }

    /**
     * @notice Performs bitwise OR of two 512-bit unsigned integers.
     * @dev Computes `a_ | b_` and stores the result in `r_`.
     */
    function _or(uint512 a_, uint512 b_, uint512 r_) private pure {
        unchecked {
            assembly {
                mstore(r_, or(mload(a_), mload(b_)))
                mstore(add(r_, 0x20), or(mload(add(a_, 0x20)), mload(add(b_, 0x20))))
            }
        }
    }

    /**
     * @notice Performs bitwise XOR of two 512-bit unsigned integers.
     * @dev Computes `a_ ^ b_` and stores the result in `r_`.
     */
    function _xor(uint512 a_, uint512 b_, uint512 r_) private pure {
        unchecked {
            assembly {
                mstore(r_, xor(mload(a_), mload(b_)))
                mstore(add(r_, 0x20), xor(mload(add(a_, 0x20)), mload(add(b_, 0x20))))
            }
        }
    }

    /**
     * @notice Performs bitwise NOT of a 512-bit unsigned integer.
     * @dev Computes `~a_` and stores the result in `r_`.
     */
    function _not(uint512 a_, uint512 r_) private pure {
        unchecked {
            assembly {
                mstore(r_, not(mload(a_)))
                mstore(add(r_, 0x20), not(mload(add(a_, 0x20))))
            }
        }
    }

    /**
     * @notice Performs left shift of a 512-bit unsigned integer.
     * @dev Computes `a_ << b_` and stores the result in `r_`.
     */
    function _shl(uint512 a_, uint8 b_, uint512 r_) private pure {
        unchecked {
            assembly {
                mstore(r_, or(shl(b_, mload(a_)), shr(sub(256, b_), mload(add(a_, 0x20)))))
                mstore(add(r_, 0x20), shl(b_, mload(add(a_, 0x20))))
            }
        }
    }

    /**
     * @notice Performs right shift of a 512-bit unsigned integer.
     * @dev Computes `a_ >> b_` and stores the result in `r_`.
     */
    function _shr(uint512 a_, uint8 b_, uint512 r_) private pure {
        unchecked {
            assembly {
                mstore(
                    add(r_, 0x20),
                    or(shr(b_, mload(add(a_, 0x20))), shl(sub(256, b_), mload(a_)))
                )
                mstore(r_, shr(b_, mload(a_)))
            }
        }
    }

    /**
     * @notice Calculates a memory pointer for a buffer based on the provided `call_` pointer.
     */
    function _buffer(call512 call_) private pure returns (uint512 buffer_) {
        unchecked {
            assembly {
                buffer_ := sub(call_, 0x40)
            }
        }
    }

    /**
     * @notice Allocates a specified amount of memory and updates the free memory pointer.
     */
    function _allocate(uint256 bytes_) private pure returns (uint256 handler_) {
        unchecked {
            assembly {
                handler_ := mload(0x40)
                mstore(0x40, add(handler_, bytes_))
            }
        }
    }
}
