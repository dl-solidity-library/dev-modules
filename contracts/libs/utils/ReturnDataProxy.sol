// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @notice This is a pure assembly library for "yielding" the returned data without doubling the
 * encoding and decoding when tunneling calls.
 *
 * May be used to optimize gas if "facade" architectural pattern is used.
 */
library ReturnDataProxy {
    /**
     * @notice This function is used to call a function of another contract without storing the result.
     * It uses inline assembly for efficiency and low-level control over the EVM execution.
     * Should be used as the last call of the function as it terminates the current context.
     * @param target_ The address of the contract to call.
     * @param value_ amount of ether to be transferred.
     * @param calldata_ The function signature and encoded arguments for the function to call.
     */
    function yield(address target_, uint256 value_, bytes memory calldata_) internal {
        assembly {
            let len := mload(calldata_)
            let result := call(gas(), target_, value_, add(calldata_, 0x20), len, 0x00, 0x00)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @notice The same purpose as `yield` but without value transfer.
     */
    function yield(address target_, bytes memory calldata_) internal {
        yield(target_, 0, calldata_);
    }

    /**
     * @notice The same purpose as `yield` but uses `delegatecall` instead of `call`.
     */
    function delegateYield(address target_, bytes memory calldata_) internal {
        assembly {
            let len := mload(calldata_)
            let result := delegatecall(gas(), target_, add(calldata_, 0x20), len, 0x00, 0x00)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @notice The same purpose as `yield` but uses `staticcall` instead of `call`.
     */
    function staticYield(address target_, bytes memory calldata_) internal view {
        assembly {
            let len := mload(calldata_)
            let result := staticcall(gas(), target_, add(calldata_, 0x20), len, 0x00, 0x00)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}
